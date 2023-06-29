class hmc_agent_driver#(NUM_LANES=16) extends hmc_agent_base_driver#(NUM_LANES);

  `uvm_component_param_utils(hmc_agent_driver#(NUM_LANES))

  bit clear_error = 0; // just a flag for retry handling

   function new (string name, uvm_component parent);
      super.new(name,parent);
      hmc_frp_port = new("hmc_frp_port",this);
   endfunction : new


   function void build_phase(uvm_phase phase);
      super.build_phase(phase); // take cfg and vif handles

      start_clear_retry_event = new("start_retry_event");

      tokens_to_send = hmc_agent_cfg.hmc_tokens; // number of tokens to send in TRET
      `uvm_info("HMC_AGENT_DRIVER_build_phase()", $sformatf("initial_trets token_count = %0d", tokens_to_send), UVM_HIGH)
      token_count_not_zero : assert (tokens_to_send > 0);
   endfunction : build_phase


   task run_phase(uvm_phase phase);
      super.run_phase(phase);

      forever begin : run_phase_forever
         
         if (vif.P_RST_N !== 1) begin // !== means it includes x and z states
            next_state = RESET;
         end

         fork
            //---- THREAD 1 ----//-- Finite state machine and sending packets
            forever begin
               if (next_state != state) begin
                  `uvm_info("HMC_AGENT_DRIVER_run_phase()", $sformatf("in state %s", next_state.name()), UVM_HIGH)
               end
               last_state = state;
               state = next_state; // proceed to next state
               case (state)
                  RESET: reset();
                  POWER_DOWN: power_up();
                  INIT: init();
                  PRBS: prbs();
                  NULL_FLITS: null_flits();
                  TS1: ts1();
                  NULL_FLITS_2: null_flits_2();
                  INITIAL_TRETS: initial_trets();
                  LINK_UP: link_up();
                  START_RETRY_INIT: start_retry_init();
                  CLEAR_RETRY: clear_retry();
                  SEND_RETRY_PACKETS: send_retry_packets();
               endcase
               clear_error = 0;
            end
            //---- THREAD 2 ----//-- burn time during reset
            begin
               @(negedge vif.P_RST_N);
            end
            //---- THREAD 3 ----//-- triggering the retry event
            forever begin
               start_clear_retry_event.wait_ptrigger();
               start_clear_retry_event.reset(0);
               next_state = CLEAR_RETRY;
               `uvm_info("HMC_AGENT_DRIVER_run_phase()", "start retry event was triggered", UVM_HIGH)
               clear_error = 1;
            end
            //---- THREAD 4 ----//-- triggering power down for the first time then wait for power_up
            begin
                time wait_time;
                @(negedge vif.RXPS);
                power_down_time_success : assert (std::randomize(wait_time) with {wait_time>0 && wait_time <= hmc_agent_cfg.t_PST + 3*hmc_agent_cfg.t_SS;});
                #wait_time;
                vif.TXPS = 0;
                link_down_time_success : assert (std::randomize(wait_time) with {wait_time>0 && wait_time <= hmc_agent_cfg.t_SME;});
                #wait_time;
                next_state = POWER_DOWN;
             end 
             //---- THREAD 5 ----//-- generating driver clock
             clk_gen();
         join_any;
         disable fork;
      end : run_phase_forever
   endtask : run_phase

   extern task power_up();
   extern task init();
   extern task prbs();
   extern task null_flits();
   extern task ts1();
   extern task null_flits_2();
   extern function void drive_lanes(input bit[NUM_LANES-1:0] new_value); 
   extern task clear_lanes();

endclass : hmc_agent_driver


//*******************************************************************************
// drive_lanes(input bit[NUM_LANES-1:0] new_value)
//*******************************************************************************
function void hmc_agent_driver::drive_lanes(input bit[NUM_LANES-1:0] new_value);
   bit [NUM_LANES-1:0] lanes_reordered; // just to handle lane reversal if needed

   if (hmc_agent_cfg.reverse_lanes) begin // check lane reversal
      for (int i = 0; i < hmc_agent_cfg.width; i++) begin
         lanes_reordered[i] = new_value[hmc_agent_cfg.width-i-1];
      end
   end else begin
      lanes_reordered = new_value;
   end // check lane reversal
   for (int i = 0; i < hmc_agent_cfg.width; i++) begin
      bit set;
      // handle polarity reversal if needed, and fills the lane queue
      lane_queues[i].push_back(lanes_reordered[i]  ^ hmc_agent_cfg.reverse_polarity[i]);
      if (0 <= lane_queues[i].size()) begin // this is always true bec I deleted lane delays
         set = lane_queues[i].pop_front(); // takes values from lane_queues
         vif.TXP[i] = set;
         vif.TXN[i] = ~set;
      end
   end
endfunction : drive_lanes


//*******************************************************************************
// clear_lanes()
//*******************************************************************************
task hmc_agent_driver::clear_lanes();
   bit empty;
   empty = 1; // while lane_queues.size > 0
   while(empty) begin
      empty = 0;
      @driver_clk;
      for (int i = 0; i < hmc_agent_cfg.width; i++) begin
         logic set;
         if (lane_queues[i].size()>0) begin
            empty = 1;
            set = lane_queues[i].pop_front();
            vif.TXP[i] = set;
            vif.TXN[i] = ~set;
         end else begin
            vif.TXP[i] = 1'bz;
            vif.TXN[i] = 1'bz;
         end
      end
   end
endtask : clear_lanes


//*******************************************************************************
// power_up()
// recover from power down (sleep mode)
//*******************************************************************************
task hmc_agent_driver::power_up();
   time wait_time;

   clear_lanes();
   // vif.TXP = {NUM_LANES {1'bz}}; making sure they are cleared??
   // vif.TXN = {NUM_LANES {1'bz}};
   recover_from_power_down = 1;
   @(posedge vif.RXPS)
   //-- wait some time < t_pst
   power_up_time_success : assert (std::randomize(wait_time) with { wait_time>0 && wait_time <= hmc_agent_cfg.t_PST + 3*hmc_agent_cfg.t_SS;});
   #wait_time;
   vif.TXPS = 1;
   //-- wait some time < t_sme
   link_up_time_success : assert (std::randomize(wait_time) with { wait_time>0 && wait_time <= hmc_agent_cfg.t_SME;});
   #wait_time;
   next_state = PRBS;
endtask : power_up


//*******************************************************************************
// init()
// the time the hmc supposed to initialize internally by JTAG or I2C
//*******************************************************************************
task hmc_agent_driver::init();
   //wait for tINIT to pass
   while ($time < reset_timestamp + hmc_agent_cfg.tINIT)
      @(posedge vif.REFCLKP);
   can_continue = 1;
   set_init_continue(); // just as if..
   //now init_continue is set
   vif.TXPS = 1'b1;
   next_state = PRBS;
endtask : init


//*******************************************************************************
// prbs()
//*******************************************************************************
task hmc_agent_driver::prbs();
   int prbs_time;

   prbs_timestamp = $time();
   // send PRBS at least 4 until Requester locks
   while(!(remote_status.current_state > PRBS))
      for (int i = 0; i < 4; i++) begin
         drive_fit({NUM_LANES/2 {i[1:0]}});
      end
   // Randomize PRBS length
   prbs_time_randomization_succeeds : assert (std::randomize(prbs_time) with {prbs_time > 0ns && prbs_time < hmc_agent_cfg.tRESP1;});
   `uvm_info("HMC_AGENT_DRIVER_prbs()", $sformatf("prbs_time = %0d (between %0d and %0d)", prbs_time, 0ns, hmc_agent_cfg.tRESP1), UVM_HIGH)
   for (int i = 0; i < prbs_time/hmc_agent_cfg.bit_time; i++) begin
      drive_fit({NUM_LANES/2 {i[1:0]}});
   end
   next_state = NULL_FLITS;
endtask : prbs


//*******************************************************************************
// null_flits()
//*******************************************************************************
task hmc_agent_driver::null_flits();
   int null_time;

   null_timestamp = $time();
   reset_lfsr();
   //wait for Requester to send TS1
   while (!(remote_status.current_state > NULL_FLITS))
      drive_fit({NUM_LANES {1'b0}});
   // now requester sent ts1
   req_ts1_timestamp = $time;
   // send a bit more null flits, for at most tRESP2
   null_time_randomization_succeeds : assert (std::randomize(null_time) with {null_time > 0ns && null_time < hmc_agent_cfg.tRESP2;});
   `uvm_info("HMC_AGENT_DRIVER_null_flits()", $sformatf("null time = %0d ", null_time), UVM_HIGH)
   for (int i = 0; i < null_time/hmc_agent_cfg.bit_time-1; i++) begin
      drive_fit({NUM_LANES {1'b0}});
   end
   next_state = TS1;
endtask : null_flits


//*******************************************************************************
// ts1()
//*******************************************************************************
task hmc_agent_driver::ts1();
   int ts1_fits = 0;

   // Save the timestamp
   ts1_timestamp = $time;
   `uvm_info("HMC_AGENT_DRIVER_ts1()", $sformatf("Sending TS1 Sequences"),UVM_MEDIUM)
   //wait for Requester to send NULL FLITs
   while (!(remote_status.current_state>TS1))
      send_ts1(256); // 16 fits per sequence number, 16 sequence numbers
   next_state = NULL_FLITS_2;
endtask : ts1


//*******************************************************************************
// null_flits_2()
//*******************************************************************************
task hmc_agent_driver::null_flits_2();
   int null_flit_count;
   // send at least 32 null flits
   null_flit_count_randomization_succeeds : assert (std::randomize(null_flit_count) with {null_flit_count >= 32 && null_flit_count < 512;});
   for (int i = 0; i < null_flit_count; i++) begin
      drive_flit(128'h0);
   end
   next_state = INITIAL_TRETS;
endtask : null_flits_2