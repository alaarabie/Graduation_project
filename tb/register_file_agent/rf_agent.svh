class rf_agent extends  uvm_agent;

  `uvm_component_param_utils(rf_agent )
  
  rf_agent_cfg  cfg;

  rf_driver   driver;
  rf_monitor  monitor;
  rf_sequencer   m_seqr;

  uvm_analysis_port #(rf_item) rf_ap;

  extern function new(string name, uvm_component parent);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);


endclass : rf_agent


function rf_agent::new(string name, uvm_component parent);
  super.new(name,parent);
endfunction : new


function void rf_agent::build_phase(uvm_phase phase);
  super.build_phase(phase);

  if(!uvm_config_db #(rf_agent_cfg)::get(this, "","rf_agent_cfg_t", cfg))
    `uvm_fatal("RF_AGENT_CONFIG_LOAD", "Failed to get rf_agent_cfg from uvm_config_db")

  if(cfg.active == UVM_ACTIVE) begin
      driver    = rf_driver::type_id::create("driver",this);
      driver.cfg = cfg;
      m_seqr = rf_sequencer::type_id::create("m_seqr", this);
  end

  monitor = rf_monitor::type_id::create("monitor",this);
  monitor.cfg = cfg;

  rf_ap = new("rf_ap",this);

endfunction : build_phase


function void rf_agent::connect_phase(uvm_phase phase);
  super.connect_phase(phase);

   if (cfg.active == UVM_ACTIVE) begin
    driver.seq_item_port.connect(m_seqr.seq_item_export);
  end
  monitor.rf_ap.connect(rf_ap);  

endfunction : connect_phase