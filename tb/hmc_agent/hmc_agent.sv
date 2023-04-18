class hmc_agent extends uvm_agent ;
	`uvm_component_utils(hmc_agent)

  hmc_agent_config hmc_agent_config_h ;

  uvm_analysis_port #(hmc_pkt_item) mon_ap ;

  sequencer_hmc_agent sequencer_hmc_agent_h ;
  driver_hmc_agent driver_hmc_agent_h ;
  monitor_hmc_agent monitor_hmc_agent_h ;

  function new (string name, uvm_component parent);
  	super.new(name,parent);
  endfunction : new

  function void build_phase(uvm_phase phase);

  	if(!uvm_config_db#(hmc_agent_config)::get(this,"","config",hmc_agent_config_h))
  		`uvm_fatal("HMC_Agent","Failed to get config object");

  	is_active = hmc_agent_config_h.get_is_active() ;

  	if(get_is_active() == UVM_ACTIVE) begin : make stimulus
  		sequencer_hmc_agent_h = new("sequencer_hmc_agent_h",this);
  		driver_hmc_agent_h = driver_hmc_agent::type_id::create("driver_hmc_agent_h",this);
  	end

  	monitor_hmc_agent_h = monitor_hmc_agent::type_id::create("monitor_hmc_agent_h",this);

  	mon_ap = new("mon_ap",this);

  endfunction : build_phase

  function void connect_phase(uvm_phase phase);
  	driver_hmc_agent_h.seq_item_port.connect(sequencer_hmc_agent_h.seq_item_export);
  	monitor_hmc_agent_h.ap.connect(ap);
  endfunction : connect_phase

endclass : hmc_agent