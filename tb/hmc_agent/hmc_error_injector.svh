class hmc_error_injector#(NUM_LANES = 16) extends uvm_component;
	
	`uvm_component_param_utils(hmc_error_injector#(.NUM_LANES(NUM_LANES)))

	virtual hmc_agent_if#(.NUM_LANES(NUM_LANES)) ext_vif;
	virtual hmc_agent_if#(.NUM_LANES(NUM_LANES)) int_vif;
	
	hmc_agent_config #(NUM_LANES) hmc_agent_cfg;

	hmc_cdr #(.NUM_LANES(NUM_LANES)) cdr;
	hmc_link_status link_status;
	bit requester_flag;
	
	logic [NUM_LANES - 1 : 0] current_value;
	int num_bitflips;
	int inserted_bitflips[];


	function new ( string name, uvm_component parent );
		super.new(name, parent);
	endfunction : new


	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if(!uvm_config_db#(hmc_agent_config#(NUM_LANES))::get(this, "", "hmc_agent_config_t",hmc_agent_cfg))
			`uvm_fatal("hmc_error_injector_build_phase()","Failed to get CONFIG");

			uvm_config_db#(hmc_agent_config#(NUM_LANES))::set(this, "cdr","hmc_agent_config_t",hmc_agent_cfg);
		
			this.ext_vif = hmc_agent_cfg.vif;
			this.int_vif = hmc_agent_cfg.int_vif;
		
		if (requester_flag) begin
			cdr = hmc_cdr#(.NUM_LANES(NUM_LANES))::type_id::create("req_cdr", this);
			cdr.link_type = REQUESTER;
			cdr.vif = ext_vif;
		end else begin
			cdr = hmc_cdr#(.NUM_LANES(NUM_LANES))::type_id::create("rsp_cdr", this);
			cdr.link_type = RESPONDER;
			cdr.vif = int_vif;
		end
	endfunction : build_phase

	function void connect_phase(uvm_phase phase);
	endfunction : connect_phase


	task run_phase(uvm_phase phase);
		#1ps;
		read();
		write();
		forever begin
			@(cdr.int_clk)
			read();
			if (hmc_agent_cfg.lane_errors_enabled && link_status.current_state >= LINK_UP)
				inject_error();
			write();
		end
	endtask : run_phase
	

	function void read();
		if (requester_flag) begin
			current_value =  ext_vif.RXP;
		end else begin
			current_value =  int_vif.TXP; //responder driver will give this value
		end
	endfunction

	function void write();
		logic [NUM_LANES - 1 : 0] inv_value;

		foreach(current_value[i]) begin
			if (!(current_value[i] === 1'bz))
				inv_value[i] = ~current_value[i];
			else begin
				inv_value[i] = 1'bz;
			end
		end

		if (requester_flag) begin
			int_vif.RXP = current_value; //hmc input
			int_vif.RXN = inv_value;
		end else begin
			ext_vif.TXP = current_value; // hmc output
			ext_vif.TXN = inv_value;
		end
	endfunction : write

	function void inject_error();
		int error_probability;
		error_prob_rand_succeeds : assert (std::randomize(error_probability) 
									with {error_probability >= 0 && error_probability < 10000;});
		if (error_probability < hmc_agent_cfg.bitflip_error_probability) begin
			num_error_rand_succeeds : assert(std::randomize(num_bitflips)
										with {num_bitflips>0 && num_bitflips<NUM_LANES;});
			`uvm_info(get_type_name(), $psprintf("Inserting %0d Bitflips in %s Link",num_bitflips, requester_flag?"requester":"responder"), UVM_HIGH)
			bitflip(num_bitflips);
		end
	endfunction : inject_error
	
	function void bitflip(int bits);
		int pos = -1;
		int last_pos[int];
		for (int i= 0; i < bits; i++) begin
			while (last_pos[pos] == 1 || pos == -1)begin //-- inject bitflip only once per lane
				pos_randomization_succeeds : assert (std::randomize(pos) with {pos >= 0 && pos < NUM_LANES;});
			end
			last_pos[pos] = 1;
			current_value[pos] = ~current_value[pos];
			`uvm_info(get_type_name(), $psprintf("Inserting Bitflip at %d in %s Link", pos, requester_flag?"requester":"responder"), UVM_HIGH)
		end
	endfunction : bitflip

endclass : hmc_error_injector