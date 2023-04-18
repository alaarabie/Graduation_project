class monitor_hmc_agent extends uvm_component ;
	`uvm_component_utils(monitor_hmc_agent)

	virtual hmc_agent_if interface ;
	uvm_analysis_port #(hmc_pkt_item) ap ;
	hmc_agent_config hmc_agent_config_h ;

	function new (string name, uvm_component parent);
		super.new(name,parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		if(!uvm_config_db#(hmc_agent_config)::get(this, "", "config",hmc_agent_config_h))
			`uvm_fatal("monitor_hmc_agent","Failed to get CONFIG");
		hmc_agent_config_h.interface.monitor_hmc_agent = this ;
		ap=new("ap",this) ; 
	endfunction : build_phase

	function void write_to_monitor(hmc_pkt_item packet);
		ap.write(packet);
	endfunction : write_to_monitor

endclass : monitor_hmc_agent