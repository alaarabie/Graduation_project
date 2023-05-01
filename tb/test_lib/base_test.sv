class base_test extends  uvm_test;
  `uvm_component_utils(base_test)
  
  // handles
  env m_env;

  virtual hmc_agent_if_t m_hmc_if ;  
  virtual rf_if_t m_rf_if;
  env_cfg m_env_cfg;
  hmc_agent_config_t m_hmc_cfg ;
  rf_agent_cfg_t m_rf_cfg ;
  rf_reg_block rf_rb ;


  extern function new(string name, uvm_component parent);
  extern function void build_phase(uvm_phase phase);
  extern function void start_of_simulation_phase(uvm_phase phase);

  function void set_seqs(vseq_base seq);
  seq.m_cfg = m_env_cfg;

//  seq.apb = m_env.m_apb_agent.m_sequencer;
//  seq.spi = m_env.m_spi_agent.m_sequencer;
endfunction
  
endclass : base_test


// Constructor
function base_test::new(string name, uvm_component parent);
  super.new(name,parent);
endfunction : new


// Build Phase
function void base_test::build_phase(uvm_phase phase);
  super.build_phase(phase);

  m_env_cfg = env_cfg::type_id::create ("m_env_cfg");
  m_hmc_cfg = hmc_agent_config_t::type_id::create("m_hmc_cfg") ;
  rf_rb = rf_reg_block::type_id::create("rf_rb") ; 
  rf_rb.build() ;
  m_rf_cfg = rf_agent_cfg_t::type_id::create("m_rf_cfg") ;  

  if(!uvm_config_db #(hmc_agent_if_t)::get(this, "","HMC_IF",  m_hmc_cfg.vif))
  `uvm_fatal("TEST", "Failed to get hmc_if")
  if(!uvm_config_db #(rf_if_t)::get(this, "","RF", m_rf_cfg.vif))
  `uvm_fatal("TEST", "Failed to get rf_if")

  m_hmc_cfg.active=UVM_ACTIVE ;
  m_rf_cfg.active=UVM_ACTIVE ;

  m_env_cfg.rf_rb=rf_rb ;
  m_env_cfg.m_hmc_agent_cfg=m_hmc_cfg ;
  m_env_cfg.m_rf_agent_cfg=m_rf_cfg ;

  uvm_config_db #(env_cfg)::set(this, "*", "m_env_cfg", m_env_cfg);

  m_env = env::type_id::create("m_env",this);
endfunction : build_phase


// Print Testbench structure and factory contents
function void base_test::start_of_simulation_phase(uvm_phase phase);
  
  super.start_of_simulation_phase(phase);

  if (uvm_report_enabled(UVM_MEDIUM)) begin
    this.print();
    factory.print();
  end

endfunction : start_of_simulation_phase