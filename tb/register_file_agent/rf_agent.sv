class rf_agent#(HMC_RF_WWIDTH = 64,
                HMC_RF_RWIDTH = 64,
                HMC_RF_AWIDTH = 4) extends  uvm_agent;

  `uvm_component_utils(rf_agent #(HMC_RF_WWIDTH, HMC_RF_RWIDTH, HMC_RF_AWIDTH))
  
  rf_agent_cfg #(HMC_RF_WWIDTH, HMC_RF_RWIDTH, HMC_RF_AWIDTH) cfg;

  rf_driver  #(HMC_RF_WWIDTH, HMC_RF_RWIDTH, HMC_RF_AWIDTH) driver;
  rf_monitor #(HMC_RF_WWIDTH, HMC_RF_RWIDTH, HMC_RF_AWIDTH) monitor;
  rf_sequencer   m_sequencer;

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

  if(!uvm_config_db #(rf_agent_cfg#(HMC_RF_WWIDTH, HMC_RF_RWIDTH, HMC_RF_AWIDTH))::get(this, "","rf_agent_cfg", cfg))
    `uvm_fatal("RF_AGENT_CONFIG_LOAD", "Failed to get rf_agent_cfg from uvm_config_db")

  if(cfg.active == UVM_ACTIVE) begin
      driver    = rf_driver#(HMC_RF_WWIDTH, HMC_RF_RWIDTH, HMC_RF_AWIDTH)::type_id::create("driver",this);
      driver.cfg = cfg;
      m_sequencer = rf_sequencer::type_id::create("m_sequencer", this);
  end

  monitor = rf_monitor#(HMC_RF_WWIDTH, HMC_RF_RWIDTH, HMC_RF_AWIDTH)::type_id::create("monitor",this);
  monitor.cfg = cfg;

  rf_ap = new("rf_ap",this);

endfunction : build_phase


function void rf_agent::connect_phase(uvm_phase phase);
  super.connect_phase(phase);

   if (cfg.active == UVM_ACTIVE) begin
    driver.seq_item_port.connect(m_sequencer.seq_item_export);
  end
  monitor.rf_ap.connect(rf_ap);  

endfunction : connect_phase