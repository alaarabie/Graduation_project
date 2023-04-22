class hmc_agent_config#(DWIDTH = 512 , 
						 						NUM_LANES = 8 , 
						 						FPW = 4,
						 						FLIT_SIZE = 128
						 						) extends uvm_object;

  `uvm_object_param_utils(hmc_agent_config #(DWIDTH, NUM_LANES, FPW, FLIT_SIZE))
   
   //localparam string s_my_config_id = "hmc_agent_config";
   //localparam string s_no_config_id = "no config";
   //localparam string s_my_config_type_error_id = "config type error";

   virtual hmc_agent_if #(DWIDTH, NUM_LANES, FPW, FLIT_SIZE) vif;
   
   uvm_active_passive_enum     active = UVM_ACTIVE;


   //extern static function hmc_agent_config get_config( uvm_component c);
   extern function new(string name = "");

endclass : hmc_agent_config

function hmc_agent_config::new(string name = "");
  super.new(name);
endfunction : new