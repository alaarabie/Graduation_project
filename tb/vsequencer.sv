class vsequencer extends  uvm_sequencer;
  
  `uvm_component_utils(vsequencer)

  rf_sequencer  m_rf_seqr;
  sequencer_hmc_agent m_seqr_hmc_agent;
  env_cfg cfg ;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    if(!uvm_config_db #(env_cfg)::get(this, "","m_env_cfg", cfg))
       `uvm_fatal("ENV_CONFIG_LOAD", "Failed to get env_cfg from uvm_config_db")
  endfunction : new
  
endclass : vsequencer