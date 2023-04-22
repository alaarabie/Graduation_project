class monitor_hmc_agent#(DWIDTH = 512 , 
						 						NUM_LANES = 8 , 
						 						FPW = 4,
						 						FLIT_SIZE = 128
						 						) extends uvm_monitor ;
	`uvm_component_param_utils(monitor_hmc_agent #(DWIDTH, NUM_LANES, FPW, FLIT_SIZE))

	virtual hmc_agent_if #(DWIDTH, NUM_LANES, FPW, FLIT_SIZE) vif ;
	uvm_analysis_port #(hmc_pkt_item) ap ;
	hmc_agent_config #(DWIDTH, NUM_LANES, FPW, FLIT_SIZE) hmc_agent_config_h ;

	function new (string name, uvm_component parent);
		super.new(name,parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		if(!uvm_config_db#(hmc_agent_config#(DWIDTH, NUM_LANES, FPW, FLIT_SIZE))::get(this, "", "config",hmc_agent_config_h))
			`uvm_fatal("monitor_hmc_agent","Failed to get CONFIG");
		ap=new("ap",this) ; 
	endfunction : build_phase

	//function void write_to_monitor(hmc_pkt_item packet);
	//	ap.write(packet);
	//endfunction : write_to_monitor

endclass : monitor_hmc_agent