class rf_agent_cfg#(HMC_RF_WWIDTH = 64,
                    HMC_RF_RWIDTH = 64,
                    HMC_RF_AWIDTH = 4) extends uvm_object;

  `uvm_object_param_utils(rf_agent_cfg #(HMC_RF_WWIDTH, HMC_RF_RWIDTH, HMC_RF_AWIDTH))
   
   localparam string s_my_config_id = "rf_agent_cfg";
   localparam string s_no_config_id = "no config";
   localparam string s_my_config_type_error_id = "config type error";

   virtual rf_if #(HMC_RF_WWIDTH, HMC_RF_RWIDTH, HMC_RF_AWIDTH) vif;
   uvm_active_passive_enum     active = UVM_ACTIVE;
   bit has_functional_coverage = 0;

   //extern static function rf_agent_cfg get_config( uvm_component c);
   extern function new(string name = "");

endclass : rf_agent_cfg

function rf_agent_cfg::new(string name = "");
  super.new(name);
endfunction : new
/*
function rf_agent_cfg rf_agent_cfg::get_config( uvm_component c );
  rf_agent_cfg t;

  if (!uvm_config_db #(rf_agent_cfg#(HMC_RF_WWIDTH, HMC_RF_RWIDTH, HMC_RF_AWIDTH))::get(c, "", s_my_config_id, t) )
     `uvm_fatal("RF_AGENT_CONFIG_LOAD", $sformatf("Cannot get() configuration %s from uvm_config_db. Have you set() it?", s_my_config_id))

  return t;
endfunction : get_config
*/
