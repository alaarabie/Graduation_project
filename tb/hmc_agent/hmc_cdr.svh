class hmc_cdr #(NUM_LANES = 16) extends uvm_component;
	
	`uvm_component_param_utils(hmc_cdr #(NUM_LANES))

	// Interface and Config handles
	virtual hmc_agent_if #(NUM_LANES) vif;
	hmc_agent_config #(NUM_LANES) hmc_agent_cfg;
	
	event int_clk;
	link_type_t link_type = REQUESTER;
	
	function new (string name, uvm_component parent);
		super.new(name, parent);
	endfunction : new
	
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if(!uvm_config_db#(hmc_agent_config#(NUM_LANES))::get(this, "", "hmc_agent_config_t",hmc_agent_cfg))
			`uvm_fatal("HMC_CDR_build_phase()","Failed to get CONFIG");
		vif = hmc_agent_cfg.vif;
	endfunction : build_phase
	
	
	task run_phase(uvm_phase phase);
		bit timeout = 0;
		time timeout_length;
		time wait_time;
		
		super.run_phase(phase);
		forever begin
			@(posedge vif.P_RST_N); //-- wait for leaving reset state
			fork 
				// THREAD A1
				begin 
					@(negedge vif.P_RST_N);	//-- entering reset state
				end
				// THREAD A2
				begin
					timeout_length = link_config.bit_time;
					forever begin
						fork
							// THREAD B1
							begin 
								if(link_type == REQUESTER)
									@(vif.RXP);
								else
									@(vif.TXP);
							end
							// THREAD B2
							begin 
								#(timeout_length + 1ps);
								timeout = 1;
							end
						join_any
						disable fork;
						
						case (hmc_agent_cfg.bit_time)
							100ps	: wait_time = 50ps;
							80ps	: wait_time = 40ps;
							66ps	: wait_time = 30ps;
						endcase
						
						timeout_length = wait_time;
						
						if(timeout == 1)
							wait_time -= 1ps;
						
						#(wait_time);
						
						-> int_clk;
						
						timeout = 0;
					end
				end
			join_any;
			disable fork;
		end
	endtask : run_phase

endclass : hmc_cdr