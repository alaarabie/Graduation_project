class hmc_agent_base_driver#(NUM_LANES=16) extends uvm_driver#(hmc_pkt_item);

  `uvm_component_param_utils(hmc_agent_base_driver#(NUM_LANES))

  // interface and config handles
   virtual hmc_agent_if #(NUM_LANES) vif;
   hmc_agent_config #(NUM_LANES) hmc_agent_cfg;

  // Forward Retry Pointer Port (connected with the Monitor)
   `uvm_analysis_imp_decl(_hmc_frp)
   uvm_analysis_imp_hmc_frp #(hmc_pkt_item, hmc_agent_base_driver#(.NUM_LANES(NUM_LANES))) hmc_frp_port;
  // Take request packet from driver
  `uvm_analysis_imp_decl(_request)
   uvm_analysis_imp_request #(hmc_pkt_item, hmc_agent_base_driver#(.NUM_LANES(NUM_LANES))) request_import;
 // not the best approach but it is the way to make coverage check flow packets
 uvm_analysis_port #(hmc_pkt_item) flow_packets_port;
 
  // Initial States Declaration
   init_state_t next_state = RESET;
   init_state_t state = RESET;
   init_state_t last_state = LINK_UP;

  // some classes to handle buffers, tokens, link status
   hmc_token_handler             token_handler;
   hmc_retry_buffer              retry_buffer;
   hmc_link_status               remote_status;

  //-- Packets to send
   hmc_pkt_item packet_queue[$];
   hmc_pkt_item request_queue[$];

  //?? a queue of each lane
   typedef bit lane_queue [$];
   lane_queue lane_queues [NUM_LANES]; 

  // Events
   event driver_clk;
   uvm_event start_clear_retry_event;

   //?? Timestamps for debugging
   int reset_timestamp   = 0;
   int prbs_timestamp    = 0;
   int null_timestamp    = 0;
   int req_ts1_timestamp = 0;
   int ts1_timestamp     = 0;
   //?? Timestamps for controlling packet flow
   int last_packet_timestamp = 0;
   int start_retry_timestamp = 0;
   //-- error propability
   int next_poisoned  = 0;
   int lng_error_prob = 0;
   int seq_error_prob = 0;
   int crc_error_prob = 0;
   //?? a flag to start recovering from power down (re init??)
   bit recover_from_power_down = 0;

   //?? Count retry attempts signalled by the responder (from here)
   int retry_attempts = 0;

   //?? Count retry attempts from the requester
   int remote_retries_signalled = 0;
   int remote_retries_cleared = 0;
   int local_retries_signalled = 0;
   int local_retries_cleared = 0;

   //?? Internal state for scramblers
   bit [14:0] lfsr[NUM_LANES-1:0];

   // Internal state for packets // Sequence number counter and repeat
   bit [2:0] seq_num = 1;

   // State for tokens and frp // Store recieved and sent FRP and RRP of buffers
   bit [7:0] frp_queue [$];
   bit [7:0] last_frp = 0;
   bit [7:0] last_rrp;

   // Counters to store and handle the tokens
   int tokens_to_send = 0;
   int used_tokens = 0;
   int sent_tokens = 0;

   // Scrambler logic Seed Values (pg.18)
   bit [14:0] lfsr_seed[0:15] = {
            15'h4D56,
            15'h47FF,
            15'h75B8,
            15'h1E18,
            15'h2E10,
            15'h3EB2,
            15'h4302,
            15'h1380,
            15'h3EB3,
            15'h2769,
            15'h4580,
            15'h5665,
            15'h6318,
            15'h6014,
            15'h077B,
            15'h261F
      };

   // TS1 Definition (pg.18): 0xF  0x0  Lane Dependent  Sequence
   bit [15:8]  ts1_high       = 8'hF0;
   bit [7:4]   ts1_top_lane   = 4'hC;   // for lane 15(full width) or 7(half width)
   bit [7:4]   ts1_bottom_lane   = 4'h3; // for lane 0
   bit [7:4]   ts1_middle_lane   = 4'h5; // for all in between

   // Initialization flags
   bit init_continue;
   bit can_continue;


  function new (string name, uvm_component parent);
     	super.new(name,parent);
  endfunction : new


  function void build_phase(uvm_phase phase);
     	if(!uvm_config_db #(hmc_agent_config#(NUM_LANES))::get(this, "","hmc_agent_config_t", hmc_agent_cfg))
     		`uvm_fatal("HMC_AGENT_BASE_DRIVER","Failed to get hmc_agent_cfg")
        vif = hmc_agent_cfg.vif ;
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
   super.run_phase(phase);        
  endtask : run_phase 

 extern task reset();
 extern task clk_gen(); //??
 extern task send_ts1(int ts1_fits);
 extern task initial_trets();
 extern task send_packet(input hmc_pkt_item pkt);
 extern task link_up();
 extern task get_packets();
 extern task start_retry_init(); //-- send start retry IRTRYs
 extern task clear_retry(); //-- send clear error abort mode IRTRYs
 extern task send_retry_packets();
 extern task send_irtry_start();
 extern task send_irtry_clear();
 extern task send_irtry(input bit start, input bit clear);
 extern task send_tret();
 extern task send_pret();
 extern task send_poisoned(input hmc_pkt_item pkt);
 extern task retry_send_packet(input hmc_pkt_item pkt);
 extern task drive_fit(input bit[NUM_LANES-1:0] new_value);
 extern task drive_flit(input bit [127:0] flit);
 extern task drive_tx_packet(input hmc_pkt_item pkt);
 extern function void get_response(input hmc_pkt_item request);
 extern function void reset_lfsr();
 extern function void step_scramblers();
 extern function void set_init_continue(); // I2C or JTAG would configure the HMC during reset
 
 virtual function void drive_lanes(input bit[NUM_LANES-1:0] new_value);
   `uvm_info("HMC_AGENT_BASE_DRIVER_drive_lanes()",$sformatf("called virtual function drive_lanes!"), UVM_HIGH)
 endfunction : drive_lanes


 virtual function void write_hmc_frp(input hmc_pkt_item pkt);
    bit [7:0] frp;

    `uvm_info("HMC_AGENT_BASE_DRIVER_write_hmc_frp()", $sformatf("hmc_frp: %s with FRP %0d & size %0d",pkt.command.name(), pkt.forward_retry_ptr, pkt.length),UVM_HIGH)
    // IRTRY and PRET do not have valid frp fields
    if (pkt.command != IRTRY && pkt.command != PRET) begin
       frp = pkt.forward_retry_ptr;
       if (frp != last_frp) begin
          frp_queue.push_back(frp);
          last_frp = frp;
       end
    end
    if (pkt.get_command_type() != FLOW_TYPE && !pkt.poisoned ) begin
      `uvm_info("HMC_AGENT_BASE_DRIVER_write_hmc_frp()", $sformatf("hmc_frp: %s with FRP %0d & size %0d",pkt.command.name(), pkt.forward_retry_ptr, pkt.length),UVM_LOW)
       used_tokens_does_not_overflow : assert ( used_tokens < used_tokens + pkt.length);
       used_tokens = used_tokens + pkt.length;
    end
 endfunction : write_hmc_frp


  virtual function void write_request(input hmc_pkt_item pkt);
    `uvm_info("HMC_AGENT_BASE_DRIVER_write_request()", $sformatf("request: %s",pkt.command.name()),UVM_HIGH)
    if (pkt.get_command_type() != FLOW_TYPE ) begin
       request_queue.push_back(pkt);
    end
 endfunction : write_request


 //*******************************************************************************
 // get_scrambler_value()
 // fills out the get_scrambler_value field
 //*******************************************************************************
 function bit[NUM_LANES-1:0] get_scrambler_value();
    if(hmc_agent_cfg.scramblers_enabled) begin
       for (int i = 0; i < NUM_LANES; i++) begin
          get_scrambler_value[i] = lfsr[i][0];
       end
    end else begin
       for (int i = 0; i < NUM_LANES; i++) begin
          get_scrambler_value = {NUM_LANES{1'b0}};
       end
    end
 endfunction : get_scrambler_value

endclass : hmc_agent_base_driver


//*******************************************************************************
// reset()
//*******************************************************************************
task hmc_agent_base_driver::reset();
   // Reset the interface pins
   vif.TXP = {NUM_LANES {1'bz}};
   vif.TXN = {NUM_LANES {1'bz}};
   vif.TXPS = 1'bz;
   vif.FERR_N = 1'bz;
   // reset the counters and state monitors
   seq_num = 1;
   last_rrp = 0;
   init_continue = 0;
   can_continue = 0;
   // reset the retry buffer class
   retry_buffer.reset();

   //--now wait for the reset to finish
   wait(vif.P_RST_N);
   reset_timestamp = $time();

   // reset is done, now begin initialization
   next_state = INIT;

endtask : reset


//*******************************************************************************
// clk_gen()
//*******************************************************************************
task hmc_agent_base_driver::clk_gen(); // not sure what's the point of driver clk
   @(posedge vif.REFCLKP);
   forever begin
      #hmc_agent_cfg.bit_time -> driver_clk; // 10Gbit speed
   end
endtask : clk_gen


//*******************************************************************************
// send_ts1(int ts1_fits)
// Preparing and sending TS1 flits
//*******************************************************************************
task hmc_agent_base_driver::send_ts1(int ts1_fits); // ts1_fits: number of ts1 to send
    // four bit counter that increments from 0 to 15 with each successive TS1
    // sent on a lane. Sequence value will roll back to 0 after 15 is reached
    bit [4:0] ts1_seq_num; 
    bit [NUM_LANES-1:0] fit_val;
    bit [15:0] ts1_values [NUM_LANES-1:0]; //ts1 word value for each lane

    // filling the lane by lane TS1 word depending on width configuration
                     // 4xF 4x0         4x3         4x0
    ts1_values[0]    = {ts1_high, ts1_bottom_lane, 4'h0}; // lane 0 
    for (int lane=1; lane < hmc_agent_cfg.width-1; lane++)
      ts1_values[lane]  = {ts1_high, ts1_middle_lane, 4'h0}; // middle lanes
   ts1_values[hmc_agent_cfg.width-1] = {ts1_high, ts1_top_lane, 4'h0}; // lane 15 or 7
   //Send some (possibly incomplete) TS1 flits
   while (ts1_fits > 0) begin
      // Cycle through all the sequence numbers
      for (ts1_seq_num=0; ts1_seq_num < 16 && ts1_fits > 0; ts1_seq_num++) begin
         // Add the sequence number to the ts1_values
         for (int i=0; i < hmc_agent_cfg.width; i++) begin
            ts1_values[i][3:0] = ts1_seq_num;
         end
         // Send the fits of the ts1 values
         for (int fit = 0; fit < 16; fit++) begin
            for (int lane=0; lane < hmc_agent_cfg.width; lane++) begin
               fit_val[lane] = ts1_values[lane][fit]; 
            end
            // put the flits on the physical layer
            if(ts1_fits > 0) begin
               drive_fit(fit_val);
            end else begin
               drive_fit({NUM_LANES{1'b0}});
            end
            ts1_fits = ts1_fits - 1; // next iteration
         end
      end
   end
endtask : send_ts1


//*******************************************************************************
// drive_fit(input bit[NUM_LANES-1:0] new_value)
//*******************************************************************************
task hmc_agent_base_driver::drive_fit(input bit[NUM_LANES-1:0] new_value);
   if(hmc_agent_cfg.scramblers_enabled) begin
      drive_lanes(get_scrambler_value()^new_value); // perform scrambling
   end else begin
      drive_lanes(new_value); // no scrambling
   end
   @driver_clk;
   step_scramblers();
endtask : drive_fit


//*******************************************************************************
// drive_fit(input bit[NUM_LANES-1:0] new_value)
//*******************************************************************************
function void hmc_agent_base_driver::step_scramblers();
   if (hmc_agent_cfg.scramblers_enabled) begin
      for (int i = 0; i < NUM_LANES; i++) begin
         lfsr[i] = {lfsr[i][1]^lfsr[i][0], lfsr[i][14:1]};
      end
   end
endfunction : step_scramblers


//*******************************************************************************
// initial_trets() - send TRET FLITs (send tokens)
//*******************************************************************************
task hmc_agent_base_driver::initial_trets();
   hmc_pkt_item tret = hmc_pkt_item::type_id::create("tret");

   tokens_to_send = hmc_agent_cfg.hmc_tokens; // number of tokens to send in TRET

   while(tokens_to_send > 0) begin
      init_tret_randomization : assert (tret.randomize() with {
                                       command == TRET;
                                       poisoned == 0;
                                       crc_error == 0;
                                       return_token_cnt <= tokens_to_send && return_token_cnt > 0;
                                       });
     send_packet(tret);
     `uvm_info("HMC_AGENT_BASE_DRIVER_link_up()",$sformatf("sending tret, (<%0d)", tret.return_token_cnt), UVM_HIGH)
     tokens_to_send = tokens_to_send - tret.return_token_cnt; // next iteration
   end
   next_state = LINK_UP; // initialization and token return is done
endtask : initial_trets


//*******************************************************************************
// send_packet(input hmc_pkt_item pkt)
// calculating some important values of the header and tail depending on 
// the packet command
//*******************************************************************************
task hmc_agent_base_driver::send_packet(input hmc_pkt_item pkt);
   int packet_frp; // forward retry pointer
   bit [31:0] crc;
   int bit_pos;
   int tok_cnt; // token count

   // firstly, save packet in Retry buffer if not (IRTRY, NULL, or PRET)
   // Tokens and Sequence numbers are saved in the retry buffer.
   if (pkt.command == NULL ||
       pkt.command == PRET ||
       pkt.command == IRTRY) begin // call retry_send_packet
      packet_frp = 0;
      retry_send_packet(pkt); // ready to be sent
   end else begin // else of line 270
      pkt.sequence_number = seq_num;
      if (state != INITIAL_TRETS) begin
         if (used_tokens - sent_tokens > 0) begin
            // Always send tokens with TRETs packets
            if (pkt.command == TRET) begin // here we randomize the token count not just put it as ones
               tok_cnd_tret_randomization : assert(std::randomize(tok_cnt) with{
                                                  (pkt.command == TRET && tok_cnt > 0) &&
                                                  tok_cnt < 32 &&
                                                  tok_cnt <= (used_tokens - sent_tokens);
                                                  });
            end else begin // else of line280
               tok_cnt_randomization_succeeds : assert(std::randomize(tok_cnt) with{
                                                      (tok_cnt >= 0) &&
                                                      tok_cnt < 32   &&
                                                      tok_cnt <= (used_tokens - sent_tokens);
                                                      });
            end // end of else in line 282
            pkt.return_token_cnt = tok_cnt;
         end else begin // else of line 278
            pkt.return_token_cnt = 0;
         end // end of else in line 294
      end // end of line 277
      packet_frp = retry_buffer.add_packet(pkt);
      if (packet_frp != -1) begin
         seq_num++;
         if (state != INITIAL_TRETS) begin
            sent_tokens += pkt.return_token_cnt;
         end // end of line301
         `uvm_info("HMC_AGENT_BASE_DRIVER_send_packet()", $sformatf("Sending CDM  %s with TRETS %d", pkt.command.name(), pkt.return_token_cnt), UVM_HIGH)
         retry_send_packet(pkt);
      end // end of line299
   end // end of else in line 275
endtask : send_packet


//*******************************************************************************
// retry_send_packet(input hmc_pkt_item pkt)
// the continuous of send_packet task, as it stores additional values 
// to the packet, also might inject errors before calling drive_tx_packet
//*******************************************************************************
task hmc_agent_base_driver::retry_send_packet(input hmc_pkt_item pkt);
   bit [31:0] crc;
   int bit_pos;
   int bit_errror;
   int error_type;
   int rrp_to_send; // return retry pointer
   int pkt_lng;
   bit [2:0] seq_num;

   // Don't change the stored packet (except to clear the CRC error flag)
   hmc_pkt_item copy = new pkt; // I think this is a way to copy an item

   // Return retry pointers are not saved.
   // Skip some retry pointers
   rrp_to_send_randomization_succeeds : assert (std::randomize(rrp_to_send) with {rrp_to_send >= 0 && rrp_to_send <= frp_queue.size();});
   if (rrp_to_send == 0) begin
      copy.return_retry_ptr = last_rrp;
   end else begin
      for (int i = 0; i < rrp_to_send; i++) begin
         copy.return_retry_ptr = frp_queue.pop_front();
         `uvm_info("HMC_AGENT_BASE_DRIVER_retry_send_packet()",$sformatf("popped %0d for frp in %s", copy.return_retry_ptr, copy.command.name()),UVM_HIGH)
      end
   end
   last_rrp = copy.return_retry_ptr;

   //------ ERROR INJECTION ------

   //-- Sequence Error
   error_type_seq_error_randomization : assert (std::randomize(seq_error_prob) with {seq_error_prob > 0 && seq_error_prob < 1000;});
   if (seq_error_prob < hmc_agent_cfg.seq_error_probability) begin
      randcase
      1: copy.sequence_number = copy.sequence_number + 1; //add one
      1: copy.sequence_number = copy.sequence_number - 1; // subtract one
      1: begin
            random_SEQ_succeeds : assert(
               std::randomize(seq_num) with { seq_num !=copy.sequence_number;});
            copy.sequence_number = seq_num; // total random number
         end
      endcase
      `uvm_info("HMC_AGENT_BASE_DRIVER_retry_send_packet()",$sformatf("injecting SEQ error in CMD %s and FRP %d",copy.command.name(), copy.forward_retry_ptr), UVM_HIGH)
   end

   //-- Length Error
   error_type_lng_error_randomization : assert (std::randomize(lng_error_prob) with {lng_error_prob > 0 && lng_error_prob < 1000;});
   if (lng_error_prob < hmc_agent_cfg.lng_error_probability) begin
      randcase
      1: copy.length = copy.length + 1; //add one
      1: copy.length = copy.length - 1; // subtract one
      1: copy.duplicate_length = copy.duplicate_length + 1; //add one
      1: copy.duplicate_length = copy.duplicate_length - 1; //add one
      1: begin
            random_LNG_succeeds : assert(
               std::randomize(pkt_lng) with {pkt_lng >= 0 && pkt_lng < 16  && pkt_lng !=copy.length;}); 
            copy.length = pkt_lng; // total random number
         end
      1: begin
            random_DLN_succeeds : assert(
               std::randomize(pkt_lng) with {pkt_lng >= 0 && pkt_lng < 16  && pkt_lng !=copy.duplicate_length;}); 
            copy.duplicate_length = pkt_lng; // total random number
         end 
      endcase
   end

   crc = copy.calculate_crc();

   //-- Send Poisoned Packets (flip crc)
   if(copy.poisoned) begin
      `uvm_info("HMC_AGENT_BASE_DRIVER_retry_send_packet()",$sformatf("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX poisoning packet with CRC %0x and CMD %s and TAG %d", ~crc, copy.command.name(), copy.tag),UVM_LOW)
      crc = ~crc;
   end

   //-- CRC Error
   error_type_crc_error_randomization : assert (std::randomize(crc_error_prob) with {crc_error_prob > 0 && crc_error_prob < 1000;});
   if (crc_error_prob < hmc_agent_cfg.crc_error_probability * copy.length) begin
      int clear_crc_error;
      crc_bit_error_randomization_succeeds : assert (std::randomize(bit_pos) with {bit_pos >= 0 && bit_pos < 32;});
      `uvm_info("HMC_AGENT_BASE_DRIVER_retry_send_packet()",$sformatf("inserting crc error at %0x", bit_pos),UVM_LOW)
      crc[bit_pos] = !crc[bit_pos];
      clear_crc_error_randomization_succeeds : assert (std::randomize(clear_crc_error) with {clear_crc_error >= 0 && clear_crc_error < 3;});
      if (clear_crc_error == 1) begin
         pkt.crc_error = 0;
      end
   end
   copy.crc = crc;
   drive_tx_packet(copy); // ready to go
   if ((copy.command & 6'h38) == FLOW_TYPE) begin
      flow_packets_port.write(pkt);
   end
endtask : retry_send_packet


//*******************************************************************************
// drive_tx_packet(input hmc_pkt_item pkt)
// change the packet form into flits form then call drive_flit
//*******************************************************************************
task hmc_agent_base_driver::drive_tx_packet(input hmc_pkt_item pkt);
   bit bitstream [];
   bit [127:0] flits [9]; // Max packet size is 9 flits
   bit [127:0] curr_flit;
   int i;
   int bitcount;
   bitcount = pkt.pack(bitstream);

   for (int i = 0; i < bitcount; i++) begin
      flits[i/128][i%128] = bitstream[i]; // somehow shapes the flits from the packet
   end
   for (int i = 0; i < bitcount/128; i++) begin
      drive_flit(flits[i]); // getting the flits ready for the lanes
   end
   last_packet_timestamp = $time();
endtask : drive_tx_packet


//*******************************************************************************
// drive_flit(input bit [127:0] flit)
//*******************************************************************************
task hmc_agent_base_driver::drive_flit(input bit [127:0] flit);
   int i;
   bit [15:0] fits [16];

   for (int i = 0; i < 128; i++) begin
      fits[i/hmc_agent_cfg.width][i%hmc_agent_cfg.width] = flit[i];
   end
   for (int i = 0; i < 128/hmc_agent_cfg.width; i++) begin
      drive_fit(fits[i]);
   end
endtask : drive_flit


//*******************************************************************************
// link_up()
// getting a packet from the sequence, might send it poisoned, if no packets
// to be sent, send TRET or PRET depending on buffer and tokens if needed
// else it's an empty flit
//*******************************************************************************
task hmc_agent_base_driver::link_up();
   hmc_pkt_item packet;

   get_packets(); // get response packets from the sequence
   if (packet_queue.size() > 0 /*&& token_handler.tokens_available(packet_queue[0].length)*/ && (250-retry_buffer.get_buffer_used()) > packet_queue[0].length) begin
      packet = packet_queue.pop_front();  //-- send the first packet in the queue
      if (next_poisoned < hmc_agent_cfg.poisoned_probability) begin //normal or poisoned?
         send_poisoned(packet);
      end else begin //else of line497
         send_packet(packet);
      end //end of line499
      poisoned_propability_randomisation : assert (std::randomize(next_poisoned) with {next_poisoned > 0 && next_poisoned < 1000;});
   end else if ($time-last_packet_timestamp > hmc_agent_cfg.send_pret_time && frp_queue.size() > 0) begin //else of line495
      `uvm_info("HMC_AGENT_BASE_DRIVER_link_up()",$sformatf("sending pret, frp_queue size = %0d", frp_queue.size()), UVM_HIGH)
      send_pret();
   end else if ($time-last_packet_timestamp > hmc_agent_cfg.send_tret_time && (used_tokens - sent_tokens) > 0 &&(250- retry_buffer.get_buffer_used()) >1) begin //else of line497
      `uvm_info("HMC_AGENT_BASE_DRIVER_link_up()",$sformatf("sending tret, (<%0d)", used_tokens-sent_tokens), UVM_LOW)
      send_tret();
   end else begin //else of line499
      `uvm_info("HMC_AGENT_BASE_DRIVER_link_up()",$sformatf("drive empty filt"),UVM_HIGH)
      drive_flit(128'h0);
   end

   // From here on, there are no packets being driven.  
   // This is just logic to decide the next state.

   //-- Handle error_abort_mode on remote link (hmc_link_status class)
   if(remote_status.get_error_abort_mode() && $time() - start_retry_timestamp > hmc_agent_cfg.retry_timeout_period) begin
      next_state = START_RETRY_INIT;
   end

endtask : link_up


//*******************************************************************************
// get_packets()
// get response packets
//*******************************************************************************
task hmc_agent_base_driver::get_packets();
   hmc_pkt_item pkt;

   // check if the request_queue is empty then send requests to the sequence and return the response
      if( request_queue.size() > 0) begin
         if( packet_queue.size() == 0) begin
            // give the request to the a function to generate response
            pkt = request_queue.pop_front();
            get_response(pkt);
         end     
      end
endtask : get_packets


//*******************************************************************************
// get_response(input hmc_pkt_item request)
// create a response from this request and store it in packet_queue()
//*******************************************************************************
function void hmc_agent_base_driver::get_response(input hmc_pkt_item request);
  hmc_pkt_item response;
  int response_length = 1;
  //int new_timestamp;
  //rand bit error_response;
  bit [127:0] rand_flit;
  bit [127:0] payload_flits [$];

  `uvm_info("HMC_AGENT_BASE_DRIVER_get_response()",$sformatf("Generating response for a %s @%0x",request.command.name(), request.address),UVM_HIGH)
  response = hmc_pkt_item::type_id::create("response");

  //void'(this.randomize(error_response));
  //new_timestamp = delay * 500ps + $time;

  if (request.get_command_type() == READ_TYPE) 
  begin : read
      // know the length
      case (request.command)
        RD16 : response_length = 2;
        RD32 : response_length = 3;
        RD48 : response_length = 4;
        RD64 : response_length = 5;
        RD80 : response_length = 6;
        RD96 : response_length = 7;
        RD112 : response_length = 8;
        RD128 : response_length = 9;
      endcase
      // randomize the packet
      void'(response.randomize() with {command == RD_RS;
                                       address == request.address;
                                       length  == response_length;
                                       tag     == request.tag;
                                      }); // error_status == 0 || error_response;
      // randomize the packet's payload, maybe not needed?
      for (int i = 0; i < response_length-1; i++) begin
        randomize_flit_successful : assert(std::randomize(rand_flit));
        payload_flits.push_front(rand_flit);
      end
      response.payload = payload_flits;
      //response.timestamp = new_timestamp;
      // enqueue the packet, ready to send
      packet_queue.push_back(response);
  end : read

  else if (request.get_command_type() == MODE_READ_TYPE)
   begin : mode_read
      response_length = 2;
      void'(response.randomize() with {command == MD_RD_RS;
                                       address == request.address;
                                       length  == response_length;
                                       tag     == request.tag;
                                      });
      for (int i = 0; i < response_length-1; i++) begin
        rand_flit = 128'h0; // mode read response has zeros in payload
        payload_flits.push_front(rand_flit);
      end
      response.payload = payload_flits;
      packet_queue.push_back(response);
   end : mode_read

  else if ((request.get_command_type() == WRITE_TYPE || request.get_command_type() == MISC_WRITE_TYPE) && request.command != MD_WR) 
  begin : write
      // know the length
      response_length = 1; // there is already a constraint inside the packet
      // randomize the packet
      void'(response.randomize() with {command == WR_RS;
                                       address == request.address; 
                                       tag     == request.tag;
                                      });
      // no payload
      packet_queue.push_back(response);
  end : write
  else if (request.command == MD_WR)
   begin : mode_write
      response_length = 1;
      void'(response.randomize() with {command == MD_WR_RS;
                                       address == request.address;
                                       length  == response_length;
                                       tag     == request.tag;
                                      });
      packet_queue.push_back(response);
   end : mode_write
  else if (request.get_command_type() != POSTED_WRITE_TYPE &&
           request.get_command_type() != POSTED_MISC_WRITE_TYPE) 
  begin : wrong_commands
      // posted write requests gets not responses
      `uvm_fatal("HMC_AGENT_BASE_DRIVER_get_response()",$sformatf("Unsupported command type %s", request.command.name()))
  end : wrong_commands
endfunction : get_response


//*******************************************************************************
// send_poisoned(input hmc_pkt_item pkt)
// send a poisoned packet, save the original to send later
//*******************************************************************************
task hmc_agent_base_driver::send_poisoned(input hmc_pkt_item pkt);
   hmc_pkt_item poisoned = new pkt; //copy

   `uvm_info("HMC_AGENT_BASE_DRIVER_send_poisoned()",$sformatf("Poisoning Packet with command %s and tag %d", poisoned.command.name(), poisoned.tag),UVM_HIGH)
   poisoned.poisoned = 1;
   send_packet(poisoned);
   packet_queue.push_back(pkt); // resend it later
endtask : send_poisoned


//*******************************************************************************
// send_pret()
// send a PRET packet
//*******************************************************************************
task hmc_agent_base_driver::send_pret();
   hmc_pkt_item pret = hmc_pkt_item::type_id::create("pret");

   pret_randomization : assert (pret.randomize() with {command == PRET;});
   send_packet(pret);
endtask : send_pret


//*******************************************************************************
// send_tret()
// send a TRET packet
//*******************************************************************************
task hmc_agent_base_driver::send_tret();
   hmc_pkt_item tret = hmc_pkt_item::type_id::create("tret");

   pret_randomization : assert (tret.randomize() with {command == TRET;});
   send_packet(tret);
endtask : send_tret


//*******************************************************************************
// start_retry_init()
// send start retry IRTRYs, just initiating it and calling the actual task
//*******************************************************************************
task hmc_agent_base_driver::start_retry_init();
   start_retry_timestamp = $time();
   local_retries_signalled = local_retries_signalled + 1;
   `uvm_info("HMC_AGENT_BASE_DRIVER_start_retry_init()",$sformatf("sending start retry packets"), UVM_HIGH)
   // send IRTRY FLITs
   for (int i = 0; i < hmc_agent_cfg.irtry_flit_count_to_send; i++) begin
      send_irtry_start();
   end
   next_state = LINK_UP;
endtask : start_retry_init


//*******************************************************************************
// send_irtry_start()
// call send_irtry but making sure it is a start
//*******************************************************************************
task hmc_agent_base_driver::send_irtry_start();
   send_irtry(1,0); //start = 1, clear = 0
endtask : send_irtry_start


//*******************************************************************************
// send_irtry_clear()
// call send_irtry but making sure it is a clear
//*******************************************************************************
task hmc_agent_base_driver::send_irtry_clear();
   send_irtry(0,1); //start = 0, clear = 1
endtask : send_irtry_clear


//*******************************************************************************
// send_irtry()
// send a IRTRY packet
//*******************************************************************************
task hmc_agent_base_driver::send_irtry(input bit start, input bit clear);
   hmc_pkt_item irtry = hmc_pkt_item::type_id::create("irtry");

   pret_randomization : assert (irtry.randomize() with {command == IRTRY;
                                start_retry == start;
                                clear_error_abort == clear;});
   send_packet(irtry);
endtask : send_irtry


//*******************************************************************************
// clear_retry()
// send clear error abort mode IRTRYs
//*******************************************************************************
task hmc_agent_base_driver::clear_retry();
   local_retries_cleared = local_retries_cleared + 1;
   // send IRTRY FLITs
   for (int i = 0; i < hmc_agent_cfg.irtry_flit_count_to_send; i++) begin
      send_irtry_clear();
   end
   next_state = SEND_RETRY_PACKETS; // exit link retry and resend the packets
endtask : clear_retry


//*******************************************************************************
// send_retry_packets()
// takes the packets from retry buffer and re-send them
//*******************************************************************************
task hmc_agent_base_driver::send_retry_packets();
   hmc_pkt_item packet;
   int spacer_flits; // empty flits till I send the packet

   packet = retry_buffer.get_retry_packet();
   while(packet != null) begin // there is a packet to send
      spacer_flits_randomization_succeeds : assert (std::randomize(spacer_flits) with {spacer_flits >= 0 && spacer_flits < 10;});
      for (int i = 0; i < spacer_flits; i++) begin
         drive_flit(128'h0);
      end
      retry_send_packet(packet); //why not send_packet?
      packet = retry_buffer.get_retry_packet(); // next iteration
   end
   next_state = LINK_UP;
endtask : send_retry_packets


//*******************************************************************************
// reset_lfsr()
// reset lfsr value back to the original scrambler seed
//*******************************************************************************
function void hmc_agent_base_driver::reset_lfsr();
   for (int i = 0; i < NUM_LANES; i++) begin
      if(hmc_agent_cfg.reverse_lanes)
         lfsr[i] = lfsr_seed[NUM_LANES-1-i]; //reverse lane by lane
      else
         lfsr[i] = lfsr_seed[i];
   end
endfunction : reset_lfsr


//*******************************************************************************
// set_init_continue()
// I2C or JTAG would configure the HMC during reset, here we just do it ourselves
//*******************************************************************************
function void hmc_agent_base_driver::set_init_continue();
   tb_respects_tINIT : assert(can_continue); //waiting for this time I guess
   init_continue = 1;
endfunction : set_init_continue