
class axi_config #(parameter T_DATA_BIT = 128, parameter T_USER_WIDTH = 16) extends uvm_object;

uvm_active_passive_enum agent_active = UVM_ACTIVE;

virtual axi_interface  #(.T_DATA_BIT(T_DATA_BIT),.T_USER_WIDTH(T_USER_WIDTH)) vif;

//uvm macros
`uvm_object_utils_begin(axi_config)
`uvm_field_enum(uvm_active_passive_enum, agent_active, UVM_DEFAULT)
`uvm_object_utils_end

//constructor
function new (string name = "axi_config");
super.new(name);
endfunction : new


endclass : axi_config


