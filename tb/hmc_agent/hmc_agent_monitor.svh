class hmc_agent_monitor#(NUM_LANES = 16) extends uvm_monitor;

	`uvm_component_param_utils(hmc_agent_monitor #(NUM_LANES))

	// Interface and Config handles
	virtual hmc_agent_if #(NUM_LANES) vif;
	hmc_agent_config #(NUM_LANES) hmc_agent_cfg;
	// to configure the monitor, either monitor incoming requests or outcoming responses
	bit requester_flag; 

	// Some Classes needed for calculations
	hmc_status			status;
	hmc_link_status link_status;
	hmc_link_status remote_link_status;
	hmc_transaction_mon 			  transaction_mon;
	hmc_cdr #(NUM_LANES) 				cdr;

	// Analysis Ports
	uvm_analysis_port #(hmc_pkt_item) item_collected_port; // should be the main port?
	uvm_analysis_port #(hmc_pkt_item) return_token_port;
	uvm_analysis_port #(hmc_pkt_item) frp_port; // forward retry pointer
	uvm_analysis_port #(int) rrp_port; // return retry pointer

	// Events to trigger stuff
	uvm_event start_clear_retry_event;
	event lane_queue_event;			//-- triggers after write to any lane queue
	event flit_queue_event;		//-- triggers after write to the collected_flits queue

	// Partial flits from each lane
	typedef bit [14:0] lsfr_t;
	typedef bit [15:0]	partial_flit_t; // 16 lanes
	typedef bit [127:0] flit_t; // the 128 bit flit
	// Queue of unassembled flits (per lane)
	typedef partial_flit_t			partial_flit_queue_t[$];
	partial_flit_queue_t			lane_queues[];

	//
	bit [2:0]	next_sequence_num;
	bit lane_reversal_set = 0;

	// lane -> flit -> bitstream -> packet
	bit [127:0]	collected_flits[$];
	bit bitstream[$];
	hmc_pkt_item		collected_packet;

	//-- reporting counter
	int lng_error = 0;
	int crc_error = 0;
	int seq_error = 0;
	int poisoned_pkt = 0;
	typedef enum {
		LENGTH_ERROR,
		CRC_ERROR,
		SEQ_ERROR,	
		POISON,
		INVALID_TS1
	}error_class_e;
	error_class_e current_error;
	int packets_after_Link_up 	= 0;
	int start_retry_count 		  = 0;
	int clear_error_abort_count	= 0;
	int null_flits_after_TS1   	= 0;
	int null_flits_between_pkts	= 0;

	function new (string name, uvm_component parent);
		super.new(name,parent);
		lane_queues 				= new[NUM_LANES] (lane_queues);
		item_collected_port = new("item_collected_port", this);
		return_token_port 	= new("return_token_port", this);
		frp_port 			  		= new("frp_port", this);
		rrp_port 						= new("rrp_port", this);
		next_sequence_num 	= 3'b1;
	endfunction : new

	function void build_phase(uvm_phase phase);
		if(!uvm_config_db#(hmc_agent_config#(NUM_LANES))::get(this, "", "hmc_agent_config_t",hmc_agent_cfg))
			`uvm_fatal("HMC_AGENT_MONITOR_build_phase()","Failed to get CONFIG") ;
		vif = hmc_agent_cfg.vif ;
		start_clear_retry_event = new("start_retry_event");
		if (requester_flag) begin
			link_status = status.Requester_link_status;
			remote_link_status = status.Responder_link_status;
			cdr = hmc_cdr#(.NUM_LANES(NUM_LANES))::type_id::create("req_cdr", this);
			cdr.link_type = REQUESTER;
		end else begin
			link_status = status.Responder_link_status;
			remote_link_status = status.Requester_link_status;
			cdr = hmc_cdr#(.NUM_LANES(NUM_LANES))::type_id::create("rsp_cdr", this);
			cdr.link_type = RESPONDER;
		end
		//if (!link_config.responder.active) begin
		link_status.set_relaxed_token_handling(1); //TODO : check this later
	endfunction : build_phase

	task run_phase(uvm_phase phase);
		//forever begin
			run();
		//end
	endtask : run_phase

	function void report_phase(uvm_phase phase);
		`uvm_info("HMC_AGENT_MONITOR_report_phase()",$sformatf("LNG error count  %0d", lng_error), UVM_NONE)
		`uvm_info("HMC_AGENT_MONITOR_report_phase()",$sformatf("CRC error count  %0d", crc_error), UVM_NONE)
		`uvm_info("HMC_AGENT_MONITOR_report_phase()",$sformatf("SEQ error count  %0d", seq_error),	UVM_NONE)
		`uvm_info("HMC_AGENT_MONITOR_report_phase()",$sformatf("poisoned packets %0d", poisoned_pkt), UVM_NONE)
	endfunction : report_phase

	function void check_phase(uvm_phase phase);
		if (!idle_check()) begin
			`uvm_fatal("HMC_AGENT_MONITOR_check_phase()",$sformatf("Link is not IDLE"))
		end
	endfunction : check_phase

	extern function logic get_bit(input bit Requester, input int lane); // just getting the value of a bit of a given lane from vif
	extern function bit check_lane_queues_not_empty(); // returns a zero flag if lanes_queue is empty
	extern task check_clock(); // checks if clock periods are valid and correct
	extern task monitor_power_pins(); // checks when power up or down
	extern task descramble(input int lane);
	extern function void reset_link(); // during power down or reset
	extern task collect_flits(); // forming flits from lanes
	extern function bit check_seq_number(hmc_pkt_item packet);
	extern function void token_handling(hmc_pkt_item packet);
	extern function void handle_start_retry(hmc_pkt_item packet);
	extern function void handle_error_abort_mode(hmc_pkt_item packet);
	extern task collect_packets(); // forming a full packet from flits then send it on the port
	extern task link_states(); // fills the link_status field with current status in the FSM 
	extern task run();
	extern function bit flit_available(); // checks if all lanes have values
	extern function bit idle_check();

endclass : hmc_agent_monitor


//*******************************************************************************
// run()
//*******************************************************************************
task hmc_agent_monitor::run();
	#1;
	for (int i=0; i<NUM_LANES; i++)
	begin
		automatic int lane = i;
		fork
			`uvm_info("HMC_AGENT_MONITOR_run()",$sformatf("starting descrambler for Requester lane %0d", lane), UVM_HIGH)
			descramble(lane);
		join_none
	end //end of for loop
	fork
		check_clock(); 
		monitor_power_pins();
		collect_flits();
		collect_packets();
		link_states();
	join_none
	wait fork;
endtask : run


//*******************************************************************************
// descramble(input int lane)
//*******************************************************************************
task hmc_agent_monitor::descramble(input int lane);
	partial_flit_t	partial_flit;
	lsfr_t	lfsr;
	lsfr_t	calculated_lfsr;
	bit		last_bit;
	bit		alligned = 0;
	int		run_length_count = 0;

	`uvm_info("HMC_AGENT_MONITOR_descramble()",$sformatf("%s lane %0d descrambler started", requester_flag?"Requester":"Responder", lane), UVM_HIGH)
	forever begin //forever loop
		if (link_status.current_state == RESET || link_status.current_state == POWER_DOWN) begin //-RESET-/
			logic test;
			@(link_status.current_state);
			`uvm_info("HMC_AGENT_MONITOR_descramble()", "Waiting for valid bit", UVM_HIGH)
			test = requester_flag?vif.RXP[lane]:vif.TXP[lane];
			while (test === 1'bz) begin
				@(cdr.int_clk)
				test = requester_flag?vif.RXP[lane]:vif.TXP[lane];
			end // end of while (test === 1'bz) 
		// end of if(link_status.current_state == RESET || link_status.current_state == POWER_DOWN)
		end else if (!link_status.get_locked(lane)) begin //-LOCK SCRAMBLER-/
			lfsr = calculated_lfsr;
			//-- Guess that the top bit is 0 to lock when scrambling is turned off
			calculated_lfsr[14] = (hmc_agent_cfg.scramblers_enabled? 1'b1 : 1'b0);
			for (int i = 0; i < 14; i++) begin
				calculated_lfsr[i] = get_bit(requester_flag,lane) ^ last_bit;
				last_bit = get_bit(requester_flag,lane);
				@(cdr.int_clk);
				lfsr = {lfsr[1]^lfsr[0], lfsr[14:1]}; // step the LFSR
			end // end of for (int i = 0; i < 14; i++)
			if (lane == 0)
				`uvm_info("HMC_AGENT_MONITOR_descramble()",$sformatf("%s lane 0 calculated_lfsr=%0x lfsr=%0x", requester_flag?"Requester":"Responder", calculated_lfsr, lfsr), UVM_HIGH)
			if (lfsr == calculated_lfsr) begin //-Inversion check-/
				if (get_bit(requester_flag,lane) ^ lfsr[0]) begin
					link_status.set_inverted(lane);
					`uvm_info("HMC_AGENT_MONITOR_descramble()",$sformatf("%s lane %0d is inverted", requester_flag?"Requester":"Responder", lane),UVM_LOW)
				// end of if (get_bit(requester_flag,lane) ^ lfsr[0])
				end
				Requester_locks_before_Responder : assert (requester_flag || status.Requester_link_status.get_all_lanes_locked());
				link_status.set_locked(lane);
			// end of if (lfsr == calculated_lfsr)
			end 
		// end of if(!link_status.get_locked(lane))
		end else if (!link_status.get_nonzero(lane)) begin //-WAIT FOR POSSIBLE TS1 (non-zero)-/
			`uvm_info("HMC_AGENT_MONITOR_descramble()",$sformatf("locked on %s lane %0d inverted = %0x lfsr=%0x", requester_flag?"Requester":"Responder", lane,link_status.get_inverted(lane), lfsr), UVM_HIGH)
			while (get_bit(requester_flag,lane) ^ lfsr[0] ^ link_status.get_inverted(lane) == 0) begin
				lfsr = {lfsr[1]^lfsr[0], lfsr[14:1]}; //-- Every clock after lock, step the LFSR
				@(cdr.int_clk);
			// end of while (get_bit(0,lane) ^ lfsr[0] ^ link_status.get_inverted(lane) == 0)
			end
			link_status.set_nonzero(lane);
		// end of if (!link_status.get_nonzero(lane))
		end else if (!link_status.get_aligned(lane)) begin //-ALIGN WITH TS1-/
			`uvm_info("HMC_AGENT_MONITOR_descramble()",$sformatf("looking for TS1 on %s lane %0d", requester_flag?"Requester":"Responder", lane), UVM_HIGH)
			partial_flit[7:0] = 8'hff;
			while (!link_status.get_aligned(lane)) begin
				//-- shift until a possible TS1 sequence is detected
				partial_flit = partial_flit >> 1;
				partial_flit[7] = get_bit(requester_flag,lane) ^ lfsr[0] ^ link_status.get_inverted(lane);
				lfsr = {lfsr[1]^lfsr[0], lfsr[14:1]}; //-- Every clock after lock, step the LFSR
				@(cdr.int_clk);
				if (partial_flit[7:0] == 8'hf0) begin //-- found potential TS1 sequence
					//-- check next partial flits
					alligned = 1;
					for (int i = 0; i < hmc_agent_cfg.TS1_Messages; i++) begin // certain number of TS1 Messages
						//-- read next partial flit
						for (int i = 0; i < 16; i++) begin
							partial_flit[i] = get_bit(requester_flag,lane) ^ lfsr[0] ^ link_status.get_inverted(lane);
							lfsr = {lfsr[1]^lfsr[0], lfsr[14:1]}; // Every clock after lock, step the LFSR
							@(cdr.int_clk);
						end
						`uvm_info("HMC_AGENT_MONITOR_descramble()",$sformatf("partial_flit=%0x", partial_flit), UVM_HIGH)
						if (partial_flit[15:8] != 8'hf0) begin
							`uvm_info("HMC_AGENT_MONITOR_descramble()",$sformatf("Alignment Error, retry"), UVM_HIGH)
							alligned = 0;
							continue;//-- retry
						end
						if (alligned) begin
							link_status.set_aligned(lane);
							`uvm_info("HMC_AGENT_MONITOR_descramble()",$sformatf("%s lane %0x aligned", requester_flag?"Requester":"Responder", lane), UVM_HIGH)
						end
					//end of for (int i = 0; i < 6; i++)
					end
				// end of if (partial_flit[7:0] == 8'hf0)
				end
			// end of while (!link_status.get_aligned(lane))
			end
			run_length_count = 0;
		// end of if (!link_status.get_aligned(lane))
		end else begin //-NORMAL OPERATION-/
			for (int i = 0; i < 16; i++) begin
				// Check Run current_packet_length limit
				if (last_bit == get_bit(requester_flag,lane)) begin
					run_length_count = run_length_count + 1;
					if ((run_length_count >= hmc_agent_cfg.run_length_limit) && hmc_agent_cfg.scramblers_enabled)
						`uvm_fatal("HMC_AGENT_MONITOR_descramble()",$sformatf("last_bit=%0x repeated %0d times on %s lane %0d"
							, last_bit, run_length_count, requester_flag?"Requester":"Responder", lane));
				// end of if (last_bit == get_bit(0,lane))
				end else begin
						run_length_count = 0;
						last_bit = !last_bit;
					end
				partial_flit[i] = get_bit(requester_flag,lane) ^ lfsr[0] ^ link_status.get_inverted(lane);
				lfsr = {lfsr[1]^lfsr[0], lfsr[14:1]}; // Every clock after lock, step the LFSR
				@(cdr.int_clk);
			// end of for (int i = 0; i < 16; i++)
			end
			lane_queues[lane].push_back(partial_flit);
			//-- lane_queue_event only after all partial flits present
			if(check_lane_queues_not_empty())
				-> lane_queue_event;
		end
	end //forever loop
endtask : descramble


//*******************************************************************************
// check_clock()
//*******************************************************************************
task hmc_agent_monitor::check_clock();
	int start_time = 0;
	int clock_period = 0;
	int expected_period = 0;

	`uvm_info("HMC_AGENT_MONITOR_check_clock()",$sformatf("started clock check %0d", $time), UVM_HIGH)
	forever begin
		if (vif.P_RST_N !== 1) begin // Reset
			@(posedge vif.P_RST_N); // exit reset
			// Sample REFCLK_BOOT pins
			case (vif.REFCLK_BOOT)
				2'b00:expected_period = 8ns; // 125 MHz
				2'b01: expected_period = 6.4ns; // 156.25 MHz
				2'b10: expected_period = 6ns; // 166.66 MHz
				2'b11: `uvm_fatal("HMC_AGENT_MONITOR_check_clock()",$sformatf("REFCLK_BOOT setting %0d invalid!", vif.REFCLK_BOOT))
			endcase
			// Sample REFCLKP
			@(posedge vif.REFCLKP);
			start_time = $time;
			for (int i = 0; i < 100; i++) begin
				@(posedge vif.REFCLKP);
			end
			clock_period = ($time-start_time)/100;
			`uvm_info("HMC_AGENT_MONITOR_check_clock()",$sformatf("clock_period = %0d expected = %0d", clock_period, expected_period), UVM_HIGH)
			if (clock_period != expected_period)
				`uvm_fatal("HMC_AGENT_MONITOR_check_clock()",$sformatf("clock_period %0d (p) != expected %0d!", clock_period, expected_period));
			// Sample REFCLKN
			@(posedge vif.REFCLKN);
			start_time = $time;
			for (int i = 0; i < 100; i++) begin
				@(posedge vif.REFCLKN);
			end
			clock_period = ($time-start_time)/100;
			`uvm_info("HMC_AGENT_MONITOR_check_clock()",$sformatf("clock_period (n) = %0d expected = %0d", clock_period, expected_period), UVM_HIGH)
			if (clock_period != expected_period)
				`uvm_fatal("HMC_AGENT_MONITOR_check_clock()",$sformatf("clock_period (n) %0d (p) != expected %0d!", clock_period, expected_period));
		// end of if (vif.P_RST_N !== 1)
		end
		@(negedge vif.P_RST_N);
	end // end of forever loop
endtask : check_clock


//*******************************************************************************
// monitor_power_pins()
//*******************************************************************************
task hmc_agent_monitor::monitor_power_pins();
	if (requester_flag) begin
		link_status.signal_power_state(vif.RXPS);
		forever begin
			@(vif.RXPS)
			if (vif.RXPS == 1'b0) begin
				CHK_IDLE_BEFORE_REQUESTER_POWERDOWN: assert (idle_check()); //-- check if Link is IDLE
			end else begin
			//	`uvm_fatal("HMC_AGENT_MONITOR_monitor_power_pins()",$sformatf("%s link is not IDLE",requester_flag?"Requester":"Responder"))
			end
			link_status.signal_power_state(vif.RXPS);
		end
	end else begin
		link_status.signal_power_state(vif.TXPS);
		forever begin
			@(vif.TXPS)
			if (vif.TXPS == 1'b0) begin
				CHK_IDLE_BEFORE_RESPONDER_POWERDOWN: assert (idle_check());	//-- check if Link is IDLE
			end else begin
			//	`uvm_fatal("HMC_AGENT_MONITOR_monitor_power_pins()",$sformatf("%s link is not IDLE",requester_flag?"Requester":"Responder"))
			end
			link_status.signal_power_state(vif.TXPS);
		end
	end
endtask : monitor_power_pins


//*******************************************************************************
// collect_flits()
//*******************************************************************************
task hmc_agent_monitor::collect_flits();
	flit_t current_flit;
	partial_flit_t lane_flit;

	`uvm_info("HMC_AGENT_MONITOR_collect_flits()",$sformatf("starting collect_flits %s", requester_flag?"Requester":"Responder"), UVM_HIGH)
	forever begin
		if (link_status.current_state == RESET) begin // Reset
			reset_link();
		end
		//-- check if partial flits available
		if (!flit_available()) begin // enter if not available
			@(lane_queue_event);//-- wait for any change at the lane queues and recheck flit available before reading the lane queues
		end
		//-- check TS1 sequences
		if (link_status.current_state == TS1) begin
			foreach (lane_queues[i]) begin
				lane_flit = lane_queues[i].pop_front();
				if (lane_flit != 16'b0) begin //-- while TS1 Sequence
					case (i)
									0 : begin
												case (lane_flit[7:4])
													4'h3 : link_status.lane_reversed = 0;
													4'hc : link_status.lane_reversed = 1;
													default : if (hmc_agent_cfg.lane_errors_enabled) begin
																			`uvm_info("HMC_AGENT_MONITOR_collect_flits()",$sformatf("Detected invalid TS1 sequence on Lane %0d %s", i, requester_flag?"Requester":"Responder"), UVM_HIGH)
																			//-- cover invalid TS1 sequence error
																			current_error = INVALID_TS1;
																			collected_packet = hmc_pkt_item::type_id::create("collected_packet");
																			void'(collected_packet.randomize() with{command == NULL;});
																		end else begin
																			`uvm_fatal("HMC_AGENT_MONITOR_collect_flits()",$sformatf("Detected invalid TS1 sequence on Lane %0d %s", i, requester_flag?"Requester":"Responder"))
																		end
												endcase // case (lane_flit[7:4])
												if(!lane_reversal_set) begin
													`uvm_info("HMC_AGENT_MONITOR_collect_flits()",$sformatf("%s Link is %s"
														, requester_flag?"Requester":"Responder"
														, link_status.lane_reversed?"reversed":"not reversed"
													), UVM_NONE)
												end // if(!lane_reversal_set)
												lane_reversal_set = 1;
											end
				NUM_LANES-1 : begin
												case (lane_flit[7:4])
													4'h3 : link_status.lane_reversed = 1;
													4'hc : link_status.lane_reversed = 0;
													default : if (hmc_agent_cfg.lane_errors_enabled) begin
																			`uvm_info("HMC_AGENT_MONITOR_collect_flits()",$sformatf("Detected invalid TS1 sequence on Lane %0d %s", i, requester_flag?"Requester":"Responder"), UVM_HIGH)
																			//-- cover invalid TS1 sequence error
																			current_error = INVALID_TS1;
																		end else begin
																			`uvm_fatal("HMC_AGENT_MONITOR_collect_flits()",$sformatf("Detected invalid TS1 sequence on Lane %0d %s", i, requester_flag?"Requester":"Responder"))
																		end
												endcase // case (lane_flit[7:4])
											end
						default : begin
												if (hmc_agent_cfg.lane_errors_enabled) begin
													if (lane_flit[7:4] != 4'h5) begin
														`uvm_info("HMC_AGENT_MONITOR_collect_flits()",$sformatf("Detected invalid TS1 sequence on Lane %0d %s", i, requester_flag?"Requester":"Responder"), UVM_HIGH)
													end
												end else begin
													CHK_TS1_ID: assert (lane_flit[7:4] == 4'h5); // a valid TS1 sequence
												end
											end
					endcase // case (i)
					if (hmc_agent_cfg.lane_errors_enabled) begin
						if (lane_flit[15:8] != 8'hf0) begin
							`uvm_info("HMC_AGENT_MONITOR_collect_flits()",$sformatf("Detected invalid TS1 sequence on Lane %0d %s", i, requester_flag?"Requester":"Responder"), UVM_HIGH)			
						end
					end else begin
						CHK_UPPER_TS1: assert (lane_flit[15:8] == 8'hf0); // a valid TS1 sequence
					end
				// end of if (lane_flit != 16'b0)
				end else begin
					//hmc_link_cg.sample();
					link_status.first_null_detected = 1;
					null_flits_after_TS1 = NUM_LANES/8; //-- add 1 or 2 NULL2 Flits depending on NUM_LANES
				end
			end
		end else begin
			for (int j = 0; j < 16; j++) begin //for each bit position in partial flit
				for (int lane = 0; lane < NUM_LANES; lane++) begin //-- for each lane
					bitstream.push_back(lane_queues[link_status.lane_reversed?NUM_LANES-lane-1:lane][0][j]);
				end
			end
			for (int j = 0; j < 16; j++) begin
				if (check_lane_queues_not_empty()) begin
					void'(lane_queues[j].pop_front());
				end
			end
			while(bitstream.size()>=128) begin //-- at least 1 flit in bitstream
				for (int k = 0; k < 128; k++) begin
					current_flit[k]= bitstream.pop_front();
				end
				if (link_status.current_state == NULL_FLITS_2) begin
					link_status.null_after_ts1_seen = 0;
					if (current_flit == 128'h0) begin
						null_flits_after_TS1++;
						if (null_flits_after_TS1 >= 32) begin
							link_status.set_null_after_ts1();
						end
						`uvm_info("HMC_AGENT_MONITOR_collect_flits()",$sformatf("null flit #%0d on %s Link",null_flits_after_TS1, requester_flag?"Requester":"Responder"), UVM_HIGH)
					end else begin
						if (null_flits_after_TS1 != 0)
							if (hmc_agent_cfg.lane_errors_enabled) begin
								`uvm_info("HMC_AGENT_MONITOR_collect_flits()",$sformatf("received only %d consecutive NULL Flits after TS1 sequences, got %h",null_flits_after_TS1,current_flit), UVM_NONE)
								null_flits_after_TS1++;
							end else begin
								`uvm_fatal("HMC_AGENT_MONITOR_collect_flits()",$sformatf("received only %d consecutive NULL Flits after TS1 sequences, got %h",null_flits_after_TS1,current_flit))
							end
					end
				end else if (link_status.current_state == LINK_UP) begin
				collected_flits.push_back(current_flit);
				-> flit_queue_event;
				end
			end
		end
	end // end of forever
endtask : collect_flits

//*******************************************************************************
// collect_packets()
//*******************************************************************************
task hmc_agent_monitor::collect_packets();
	bit 				  bitstream[];
	flit_t        current_flit;
	flit_t			  header_flit;
	bit [31:0]		packet_crc;
	bit [31:0]		calculated_crc;
	int unsigned	current_packet_length;
	int unsigned	last_packet_length;

	`uvm_info("HMC_AGENT_MONITOR_collect_packets()",$sformatf("starting collect_packets "), UVM_HIGH)
	forever begin
		if (link_status.current_state == RESET) begin //-- reset handling
			next_sequence_num = 3'b1; //-- reset sequence number 
			packets_after_Link_up = 0;//-- reset packet counter
			@(link_status.current_state);
		// if (link_status.current_state == RESET)
		end else begin
			if (collected_flits.size() == 0) begin //-- wait until at least one flit is available
				@(flit_queue_event);
			end
			current_flit = collected_flits.pop_front();	//-- header flit
			if (current_flit[5:0] == NULL) begin //-- do not forward null packets "CMD[5:0]"
				null_flits_between_pkts++;
				if (link_status.irtry_StartRetry_packet_count > 0) begin
					`uvm_info("HMC_AGENT_MONITOR_collect_packets()",$sformatf("clearing Start Retry Counter due to a NULL Packet after %0d consecutive StartRetry IRTRYs", link_status.get_StartRetry_packet_count()),UVM_HIGH)
					link_status.irtry_StartRetry_packet_count = 0;
				end
				continue;
			end else begin 
			//-- if first packet after NULL2
			if (packets_after_Link_up == 0) begin
				//null2_cg.sample();
			end
			packets_after_Link_up++;
		end

		//-- check length miss-match "DLN[14:11]" "LNG[10:7]" //-- TODO: include CMD in length check
		if (current_flit[14:11] != current_flit[10:7] || current_flit[14:11] == 0) begin // Length mismatch or invalid current_packet_length
			`uvm_info("HMC_AGENT_MONITOR_collect_packets()",$sformatf("%s: current_packet_length mismatch %0x len=%0d, dln = %0d", requester_flag?"Requester":"Responder", current_flit, current_flit[10:7], current_flit[14:11]),UVM_NONE)
			lng_error ++;
			current_error = LENGTH_ERROR;
			collected_packet = hmc_pkt_item::type_id::create("collected_packet", this);
			if (hmc_agent_cfg.lane_errors_enabled) begin
				void'(collected_packet.randomize() with{command == NULL;}); // maybe assert?
			end else begin // if lane_errors_enabled=0 then it is un-intentional error
				void'(collected_packet.randomize() with{command == cmd_encoding_e'(current_flit[5:0]);}); // maybe assert?
			end
			//hmc_pkt_error_cg.sample();
			link_status.set_error_abort_mode();
			link_status.irtry_ClearErrorAbort_packet_count = 0; //-- reset clear error abort count
			//-- ignore packet fragments until first IRTRY
			while ((cmd_encoding_e'(current_flit[5:0]) != IRTRY)
							|| (current_flit[10:7] != current_flit[14:11])
							|| (current_flit[10:7] !=1) ) 
			begin
				if (collected_flits.size() ==0) begin
					@(flit_queue_event);
				end
				current_flit = collected_flits.pop_front(); // throw out
			end
		end

		current_packet_length = current_flit[10:7]; // correct length
		`uvm_info("HMC_AGENT_MONITOR_collect_packets()",$sformatf("%s: current_flit=%0x current_packet_length=%0d", requester_flag?"Requester":"Responder", current_flit,current_packet_length), UVM_HIGH)
		bitstream = new[current_packet_length*128];
		// pack first flit
		header_flit = current_flit;
		for (int i = 0; i < 128; i++) begin
			bitstream[i] = current_flit[i];
		end
		// get and pack the remaining flits
		for (int j = 0; j < current_packet_length; j++) begin
			if (collected_flits.size() == 0) begin
				@(collected_flits.size());
			end
			current_flit = collected_flits.pop_front(); // extract the flits
			for (int i = 0; i < 128; i++) begin
				bitstream[j*128+i] = current_flit[i];
			end
		end
		// get crc and compare, either poisoned or wrong
		for (int i = 0; i < 32; i++) begin
			packet_crc[i] = bitstream[bitstream.size()-32 +i];
		end
		calculated_crc = collected_packet.calc_crc(bitstream); // calculate crc of the array
		if (calculated_crc!=packet_crc && !(packet_crc == ~calculated_crc)) begin
			`uvm_info("HMC_AGENT_MONITOR_collect_packets()",$sformatf("got a CRC error in hmc_packet %x", header_flit), UVM_NONE)
			crc_error++;
			current_error = CRC_ERROR;
			collected_packet = hmc_pkt_item::type_id::create("collected_packet", this);
			if (hmc_agent_cfg.lane_errors_enabled) begin
				void'(collected_packet.randomize() with{command == NULL;}); // maybe assert?
			end else begin // if lane_errors_enabled=0 then it is un-intentional error
				void'(collected_packet.unpack(bitstream)); // maybe assert?
			end
			//hmc_pkt_error_cg.sample();
			link_status.set_error_abort_mode();
			link_status.irtry_ClearErrorAbort_packet_count = 0; //-- reset clear error abort count
			continue;
		end

		// No LNG or CRC Errors
		collected_packet = hmc_pkt_item::type_id::create("collected_packet", this);
		void'(collected_packet.unpack(bitstream));
		if (collected_packet.command != IRTRY) begin
			`uvm_info("HMC_AGENT_MONITOR_collect_packets()",$sformatf("collected_packet CMD: %s FRP: %d",
				collected_packet.command.name(), collected_packet.forward_retry_ptr), UVM_HIGH)
		end
		handle_start_retry(collected_packet);
		if (link_status.get_error_abort_mode) begin
			if (collected_packet.command == IRTRY) begin
				void'(check_seq_number(collected_packet));
			end
			handle_error_abort_mode(collected_packet);
		end else begin
			//--check the sequence number
			if(check_seq_number(collected_packet)) begin
				continue;
			end

			//-- at this point each packet should be clean
			token_handling(collected_packet);
			//-- commit the collected packet
			 //hmc_packets_cg.sample();
		 	null_flits_between_pkts = 0;
		 	if (!link_status.get_error_abort_mode()) begin
		 		rrp_port.write(collected_packet.return_retry_ptr);
		 	end
		 	if (collected_packet.command != PRET) begin
		 		if (collected_packet.command != IRTRY) begin
		 			frp_port.write(collected_packet);
		 			link_status.last_successfull_frp = collected_packet.forward_retry_ptr;
		 			if (collected_packet.poisoned) begin
		 				`uvm_info("HMC_AGENT_MONITOR_collect_packets()",$sformatf("received a poisoned %s", collected_packet.command.name()), UVM_NONE)
		 				poisoned_pkt++;
		 				current_error = POISON;
		 				//hmc_pkt_error_cg.sample();
		 				continue;
		 			end
		 			if (collected_packet.command != TRET
		 					&& !collected_packet.poisoned
		 					&& collected_packet.command != IRTRY) begin 
		 				//-- send only Transaction packets (not flow or errored)
		 				item_collected_port.write(collected_packet);
		 			end
		 		  end
		 		end
		 	end
		end
	end // end of forever 
endtask : collect_packets


//*******************************************************************************
// link_states()
//*******************************************************************************
task hmc_agent_monitor::link_states();
	forever begin
		@({vif.P_RST_N
			,link_status.power_state
			,link_status.all_lanes_locked
			,link_status.all_lanes_alligned
			,link_status.first_null_detected
			,link_status.null_after_ts1_seen}
		);
		// casex considers x and z as don't care
		casex ({vif.P_RST_N
					,link_status.power_state
					,link_status.all_lanes_locked
					,link_status.all_lanes_alligned
					,link_status.first_null_detected
					,link_status.null_after_ts1_seen}
					)
			6'b0xxxxx :	link_status.current_state = RESET;
			6'b10xxxx :	link_status.current_state = POWER_DOWN;		//-- sleep mode 
			6'b110xxx :	link_status.current_state = PRBS;		//-- scrambler waits for null flits
			6'b1110xx :	link_status.current_state = NULL_FLITS;	//-- scrambler has detected a null flit
			6'b11110x :	link_status.current_state = TS1;			//-- scrambler has detected a TS1 sequence and is in flit sync
			6'b111110 :	link_status.current_state = NULL_FLITS_2;//-- detected first NULL flits after TS1
			6'b111111 :	link_status.current_state = LINK_UP;		//-- Link is UP
		endcase
		`uvm_info("HMC_AGENT_MONITOR_link_states()",$sformatf("%s Link current State: %s \t vector: %b",
			requester_flag?"Requester":"Responder", link_status.current_state.name(),
			{	vif.P_RST_N,
			link_status.power_state, 
			link_status.all_lanes_locked, 
			link_status.all_lanes_alligned,
			link_status.first_null_detected, 
			link_status.null_after_ts1_seen
			}),UVM_LOW)
		if (link_status.current_state == POWER_DOWN || RESET) begin
			reset_link();
		end
	end
endtask : link_states


//*******************************************************************************
// reset_link()
//*******************************************************************************
function void  hmc_agent_monitor::reset_link();
	lane_reversal_set = 0;
	link_status.lane_reversed = 0;
	link_status.num_lanes = NUM_LANES;
	// clears everything
	link_status.reset();
	bitstream = {};
	collected_flits = {};
	for (int i=0; i < NUM_LANES; i++) begin
		lane_queues[i] = {};
	end
endfunction : reset_link


//*******************************************************************************
// get_bit(input bit Requester, input int lane)
//*******************************************************************************
function logic hmc_agent_monitor::get_bit(input bit Requester, input int lane);
	if (Requester) begin
		get_bit = vif.RXP[lane];
	end else begin
		get_bit = vif.TXP[lane];
	end
endfunction : get_bit


//*******************************************************************************
// check_lane_queues_not_empty()
//*******************************************************************************
function bit hmc_agent_monitor::check_lane_queues_not_empty();
	bit full = 1;
	foreach (lane_queues[i]) begin
		if (lane_queues[i].size()==0)
			full = 0;
	end
	return full;
endfunction : check_lane_queues_not_empty


//*******************************************************************************
// idle_check()
//*******************************************************************************
function bit hmc_agent_monitor::idle_check();
	return transaction_mon.idle_check()
		&& (link_status.token_count == requester_flag?hmc_agent_cfg.rx_tokens:hmc_agent_cfg.hmc_tokens);
endfunction : idle_check


//*******************************************************************************
// flit_available()
//*******************************************************************************
function bit hmc_agent_monitor::flit_available();
	bit  rval = 1'b1;
	// There is only a flit available if all lane_queues are ready
	for (int i = 0; i < NUM_LANES; i++) begin
		rval = rval && lane_queues[i].size()>0; // this checks if all lanes have values
	end
	return rval;
endfunction : flit_available


//*******************************************************************************
// check_seq_number(hmc_pkt_item packet)
//*******************************************************************************
function bit hmc_agent_monitor::check_seq_number(hmc_pkt_item packet);
	check_seq_number = 0;
	if (packet.command != PRET && packet.command != IRTRY) begin // No sequence numbers to check in PRET
		if (packet.sequence_number != next_sequence_num) begin // Sequence error
			`uvm_info("HMC_AGENT_MONITOR_check_seq_number()",$sformatf("%s: expected sequence number %0d, got %0d! in packet with cmd %0s, frp %0d and rrp %0d",
						requester_flag?"Requester":"Responder",next_sequence_num, packet.sequence_number,
						packet.command.name(),packet.forward_retry_ptr, packet.return_retry_ptr),
						UVM_LOW)
			seq_error++;
			current_error = SEQ_ERROR;
			//hmc_pkt_error_cg.sample();
			link_status.set_error_abort_mode();
			link_status.clear_irtry_packet_counts();
			check_seq_number = 1;
		end else begin
			`uvm_info("HMC_AGENT_MONITOR_check_seq_number()",$sformatf("CMD %s with current seq_nr: %d",packet.command.name(),packet.sequence_number), UVM_HIGH)
			next_sequence_num = packet.sequence_number + 1;
		end
	end else begin // PRET & IRTRY
		if (packet.sequence_number != 0) begin // Sequence error
			`uvm_info("HMC_AGENT_MONITOR_check_seq_number()",$sformatf("%s: expected sequence number %0d, got %0d! in packet with cmd %0s, frp %0d and rrp %0d",
						requester_flag?"Requester":"Responder",next_sequence_num, packet.sequence_number,
						packet.command.name(),packet.forward_retry_ptr, packet.return_retry_ptr),
						UVM_LOW)
			seq_error++;
			current_error = SEQ_ERROR;
			//hmc_pkt_error_cg.sample();
			link_status.set_error_abort_mode();
			link_status.clear_irtry_packet_counts();
			check_seq_number = 1;
		end
	end
endfunction : check_seq_number


//*******************************************************************************
// token_handling(hmc_pkt_item packet)
//*******************************************************************************
function void hmc_agent_monitor::token_handling(hmc_pkt_item packet);
	if (!remote_link_status.relaxed_token_handling) begin
		remote_link_status.token_count += packet.return_token_cnt; //-- add available token to the remote link
		return_token_port.write(collected_packet);
		if (requester_flag && packet.return_token_cnt >0) begin
			`uvm_info("HMC_AGENT_MONITOR_token_handling()",$sformatf("Command %s adds %0d tokens to remote, new token count = %0d",
				packet.command.name(), packet.return_token_cnt,remote_link_status.token_count ),
				UVM_HIGH)
		end
	end
	if (!link_status.relaxed_token_handling) begin
		if (packet.get_command_type() != FLOW_TYPE) begin // && !packet.poisoned) // Flow packets do not use tokens.
			if (!requester_flag) begin
				`uvm_info("HMC_AGENT_MONITOR_token_handling()",$sformatf("Tokens available: %d, used tokens: %d, new token count: %d",link_status.token_count,packet.length, link_status.token_count - packet.length), UVM_HIGH)
			end
			if (link_status.token_count < packet.length) begin //--token underflow must not occur due to the token based flow control
				`uvm_fatal("HMC_AGENT_MONITOR_token_handling()",$sformatf("send_to_validate: no room to push %s token_count = %0d!", packet.command.name(), link_status.token_count))
			end
			`uvm_info(get_type_name(), $psprintf("send_to_validate: push %s (length %0d) frp %0d token_count %0d new token count %0d.",
				packet.command.name(), packet.length, packet.forward_retry_ptr, link_status.token_count,
				link_status.token_count - packet.length ),UVM_HIGH)

			link_status.token_count -= packet.length;
			//tokens_cg.sample();
		end
	end
endfunction : token_handling


//*******************************************************************************
// handle_start_retry(hmc_pkt_item packet)
//*******************************************************************************
function void hmc_agent_monitor::handle_start_retry(hmc_pkt_item packet);
	if (packet.command == IRTRY && packet.start_retry) begin
		`uvm_info("HMC_AGENT_MONITOR_handle_start_retry()",$sformatf("received %d start retry IRTRYs for FRP %d",
			link_status.get_StartRetry_packet_count(), packet.return_retry_ptr), UVM_HIGH)
		if (link_status.increment_StartRetry_packet_count() >= hmc_agent_cfg.irtry_flit_count_received_threshold) begin
			UNEXPECTED_RETRY : assert (remote_link_status.error_abort_mode);
			`uvm_info("HMC_AGENT_MONITOR_handle_start_retry()",$sformatf("Start Retry Threshold Reached for RRP %d", packet.return_retry_ptr),UVM_NONE)
			if (link_status.get_error_abort_mode()
					&& link_status.irtry_StartRetry_packet_count == hmc_agent_cfg.irtry_flit_count_received_threshold) begin
				if (remote_link_status.last_successfull_frp != packet.return_retry_ptr) begin
					`uvm_fatal("HMC_AGENT_MONITOR_handle_start_retry()",$sformatf("expecting RRP %0d, got %0d",
						remote_link_status.last_successfull_frp, packet.return_retry_ptr))
				end
				rrp_port.write(packet.return_retry_ptr);
			end
			start_clear_retry_event.trigger();
		end
	end else begin //-- clear start_retry counter
		if (link_status.irtry_StartRetry_packet_count > 0) begin
			`uvm_info("HMC_AGENT_MONITOR_handle_start_retry()",$sformatf("clearing Start Retry Counter due to a CMD %s after %0d consecutive StartRetry IRTRYs",
				packet.command.name(), link_status.get_StartRetry_packet_count()),UVM_HIGH)
			link_status.irtry_StartRetry_packet_count = 0;
		end
	end
endfunction : handle_start_retry


//*******************************************************************************
// handle_error_abort_mode(hmc_pkt_item packet)
//*******************************************************************************
function void hmc_agent_monitor::handle_error_abort_mode(hmc_pkt_item packet);
	if (packet.clear_error_abort) begin
		`uvm_info("HMC_AGENT_MONITOR_handle_error_abort_mode()",$sformatf("Clear Error Abort Mode: %0d",link_status.irtry_ClearErrorAbort_packet_count), UVM_HIGH)
		if (link_status.increment_ClearErrorAbort_packet_count() == hmc_agent_cfg.irtry_flit_count_received_threshold) begin
			link_status.error_abort_mode = 0;
			`uvm_info("HMC_AGENT_MONITOR_handle_error_abort_mode()",$sformatf("Clearing Error Abort Mode" ), UVM_NONE)
			rrp_port.write(packet.return_retry_ptr); //--commit last valid RRP
		end
	end else begin
		if (!packet.start_retry) begin
			`uvm_info("HMC_AGENT_MONITOR_handle_error_abort_mode()",$sformatf("clearing Start Retry and Error Abort Counter due to a CMD %s", packet.command.name()),UVM_HIGH)
			link_status.clear_irtry_packet_counts(); //-- reset counter
		end
	end
endfunction : handle_error_abort_mode