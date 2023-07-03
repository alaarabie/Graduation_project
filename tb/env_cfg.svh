class env_cfg extends uvm_object;

  `uvm_object_utils(env_cfg)

  // Whether env analysis components are used:
  //bit has_functional_coverage = 0;
  //bit has_rf_functional_coverage = 0;
  //bit has_scoreboard = 0;
  //bit has_rf_scoreboard = 0;

  // Configurations for the sub_components
  rf_agent_cfg m_rf_agent_cfg;
  hmc_agent_config_t m_hmc_agent_cfg;
  axi_config_t  m_axi_cfg;
  
  //Register block
  rf_reg_block rf_rb;

  function new(string name = "");
    super.new(name);
  endfunction : new
 
endclass : env_cfg

