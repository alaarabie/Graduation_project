class hmc_link_status extends uvm_component;

	`uvm_component_utils(hmc_link_status)

	init_state_t current_state;

	int num_lanes = 8;

	// status bits
	bit first_null_detected = 0;	//-- first NULL Flit detected after TS1 sequence
	bit null_after_ts1_seen = 0;	//-- recceived the mimimum amount of NULL Flits to enter Link UP

	// Lane status signals
	bit lanes_locked []	;
	bit lanes_aligned[];
	bit [15:0]lanes_polarity;
	bit lanes_nonzero[];
	bit lane_reversed;
	
	bit all_lanes_locked;
	bit all_lanes_alligned;

	int token_count;
	int num_lanes_locked;
	
	bit power_state;
	bit first_tret_received=1'b0;

	bit error_abort_mode=1'b0;
	int irtry_StartRetry_packet_count=0;
	int irtry_ClearErrorAbort_packet_count=0;
	
	
	int last_successfull_frp;
	int last_sequence_number;

	bit relaxed_token_handling=1'b0;

	function new ( string name="hmc_link_status", uvm_component parent );
		super.new(name, parent);
	endfunction : new

	function void reset();//--TODO power down reset?
		lanes_locked	= new[num_lanes];
		lanes_aligned	= new[num_lanes];
		lanes_polarity	= {16{1'b0}};
		lanes_nonzero	= new[num_lanes];
		
		for (int i=0; i < num_lanes; i++) begin
			lanes_locked[i]		= 0;
			lanes_aligned[i]	= 0;
			lanes_polarity[i] 	= 0;
			lanes_nonzero[i] 	= 0;	
		end

		num_lanes_locked 	= 0;
		lane_reversed 		= 0;
		first_null_detected = 0;
		null_after_ts1_seen = 0;
		error_abort_mode 	= 0;
		irtry_StartRetry_packet_count 		= 0;
		irtry_ClearErrorAbort_packet_count 	= 0;
		first_tret_received = 0;
		last_sequence_number= 0;
		
		void'(get_all_lanes_locked());
		void'(get_all_lanes_aligned());
		
	endfunction : reset

	function void set_relaxed_token_handling(input bit relaxed);
		relaxed_token_handling = relaxed;
	endfunction : set_relaxed_token_handling

	function void set_locked(input int lane);
		lanes_locked[lane] = 1'b1;
		num_lanes_locked = num_lanes_locked + 1;
		void'(get_all_lanes_locked());
	endfunction : set_locked

	function bit get_locked(input int lane);
		return lanes_locked[lane];
	endfunction : get_locked

	function int get_next_sequence_number();
		return last_sequence_number + 1;
	endfunction : get_next_sequence_number

	function bit get_all_lanes_locked();
		all_lanes_locked = num_lanes_locked == num_lanes;
		return num_lanes_locked == num_lanes;
	endfunction : get_all_lanes_locked

	function void set_aligned(input int lane);
		lanes_aligned[lane] = 1'b1;
		all_lanes_alligned = lanes_aligned == lanes_locked;
	endfunction : set_aligned

	function bit get_aligned(input int lane);
		return lanes_aligned[lane];
	endfunction : get_aligned

	function bit get_all_lanes_aligned();
		bit aligned_lanes;
		aligned_lanes = 1;
		for (int i = 0; i < num_lanes; i++) begin
			if (lanes_aligned[i] != 1'b1) begin
				aligned_lanes = 0;
			end
		end
		all_lanes_alligned = (lanes_aligned == lanes_locked) && aligned_lanes;
		return all_lanes_alligned;
	endfunction : get_all_lanes_aligned

	function void set_inverted(input int lane);
		lanes_polarity[lane] = 1'b1;
	endfunction : set_inverted

	function bit get_inverted(input int lane);
		return lanes_polarity[lane];
	endfunction : get_inverted

	function void set_nonzero(input int lane);
		lanes_nonzero[lane] = 1'b1;
		void'(get_all_nonzero()); 
	endfunction : set_nonzero

	function bit get_nonzero(input int lane);
		return lanes_nonzero[lane];
	endfunction : get_nonzero

	function bit get_all_nonzero();
		return lanes_nonzero == lanes_locked;
	endfunction : get_all_nonzero

	function void set_null_after_ts1();
		null_after_ts1_seen = 1;
	endfunction : set_null_after_ts1

	function bit get_null_after_ts1();
		return null_after_ts1_seen;
	endfunction : get_null_after_ts1

	function bit get_first_tret_received();
		return first_tret_received;
	endfunction : get_first_tret_received

	function void set_error_abort_mode();
		error_abort_mode = 1;
	endfunction : set_error_abort_mode

	function bit get_error_abort_mode();
		return error_abort_mode;
	endfunction : get_error_abort_mode

	function void clear_irtry_packet_counts();
		`uvm_info("HMC_LINK_STATUS_clear_irtry_packet_counts()",$sformatf("clear IRTRY counter"), UVM_HIGH)
		irtry_StartRetry_packet_count = 0;
		irtry_ClearErrorAbort_packet_count = 0;
	endfunction : clear_irtry_packet_counts

	function int get_StartRetry_packet_count();
		return irtry_StartRetry_packet_count;
	endfunction : get_StartRetry_packet_count

	function int get_ClearErrorAbort_packet_count();
		return irtry_ClearErrorAbort_packet_count;
	endfunction : get_ClearErrorAbort_packet_count

	function int increment_StartRetry_packet_count();
		irtry_StartRetry_packet_count = irtry_StartRetry_packet_count + 1;
		return irtry_StartRetry_packet_count;
	endfunction : increment_StartRetry_packet_count

	function int increment_ClearErrorAbort_packet_count();
		irtry_ClearErrorAbort_packet_count = irtry_ClearErrorAbort_packet_count + 1;
		return irtry_ClearErrorAbort_packet_count;
	endfunction : increment_ClearErrorAbort_packet_count

	function void signal_power_state(input bit ps);
		power_state = ps;
	endfunction : signal_power_state

	function void report_phase(uvm_phase phase);
		`uvm_info("HMC_LINK_STATUS_report_phase()",$sformatf("Token_count %0d", token_count), UVM_LOW)
	endfunction : report_phase

endclass : hmc_link_status