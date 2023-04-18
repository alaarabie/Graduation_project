class env_cfg extends uvm_object;

  `uvm_object_utils(env_cfg)

  localparam string s_my_config_id = "env_cfg";
  localparam string s_no_config_id = "no config";
  localparam string s_my_config_type_error_id = "config type error";

  // Whether env analysis components are used:
  bit has_functional_coverage = 0;
  bit has_rf_functional_coverage = 0;
  bit has_reg_scoreboard = 0;
  bit has_rf_scoreboard = 0;

  // Configurations for the sub_components
  rf_agent_cfg_t m_rf_agent_cfg;

  //Register block
  rf_reg_block rf_rb;

  //HMC_agent interface
  virtual hmc_agent_if hmc_agent_if ;

  //extern static function env_cfg get_config( uvm_component c);
  extern function new(string name = "",virtual hmc_agent_if hmc_agent_if);
 
endclass : env_cfg

function env_cfg::new(string name = "",virtual hmc_agent_if hmc_agent_if);
  super.new(name);
  this.hmc_agent_if = hmc_agent_if ;
endfunction : new
/*
function env_cfg env_cfg::get_config( uvm_component c );
  env_cfg t;

  if (!uvm_config_db #(env_cfg)::get(c, "", s_my_config_id, t) )
    `uvm_fatal("ENV_CFG_CONFIG_LOAD", $sformatf("Cannot get() configuration %s from uvm_config_db. Have you set() it?", s_my_config_id))

  return t;
endfunction : get_config
*/