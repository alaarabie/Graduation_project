class hmc_agent#(DWIDTH = 512 , 
                 NUM_LANES = 8 , 
                 FPW = 4,
                FLIT_SIZE = 128
                ) extends uvm_agent ;

	`uvm_component_param_utils(hmc_agent#(DWIDTH, NUM_LANES, FPW, FLIT_SIZE))

  hmc_agent_config#(DWIDTH, NUM_LANES, FPW, FLIT_SIZE) hmc_agent_config_h ;

  uvm_analysis_port #(hmc_pkt_item) mon_req_ap ;
  uvm_analysis_port #(hmc_pkt_item) mon_res_ap ;  

  sequencer_hmc_agent sequencer_hmc_agent_h ;
  driver_hmc_agent#(DWIDTH, NUM_LANES, FPW, FLIT_SIZE) driver_hmc_agent_h ;
  monitor_hmc_agent#(DWIDTH, NUM_LANES, FPW, FLIT_SIZE) monitor_hmc_agent_h ;

  function new (string name, uvm_component parent);
  	super.new(name,parent);
  endfunction : new

  function void build_phase(uvm_phase phase);

  	if(!uvm_config_db#(hmc_agent_config#(DWIDTH, NUM_LANES, FPW, FLIT_SIZE))::get(this,"","config",hmc_agent_config_h))
  		`uvm_fatal("HMC_Agent","Failed to get config object")

  	if(hmc_agent_config_h.active == UVM_ACTIVE) begin
  		sequencer_hmc_agent_h = sequencer_hmc_agent::type_id::create("sequencer_hmc_agent_h", this);
  		driver_hmc_agent_h = driver_hmc_agent#(DWIDTH, NUM_LANES, FPW, FLIT_SIZE)::type_id::create("driver_hmc_agent_h",this);
  	end

  	monitor_hmc_agent_h = monitor_hmc_agent#(DWIDTH, NUM_LANES, FPW, FLIT_SIZE)::type_id::create("monitor_hmc_agent_h",this);

  	mon_req_ap = new("mon_req_ap",this);
    mon_res_ap = new("mon_res_ap",this);    

  endfunction : build_phase

  function void connect_phase(uvm_phase phase);
  	driver_hmc_agent_h.seq_item_port.connect(sequencer_hmc_agent_h.seq_item_export);
  	monitor_hmc_agent_h.req_ap.connect(mon_req_ap);
    monitor_hmc_agent_h.res_ap.connect(mon_res_ap);   
  endfunction : connect_phase

endclass : hmc_agent