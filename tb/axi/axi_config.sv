`ifndef axi_config_sv
`define axi_config_sv

class axi_config extends uvm_object;

uvm_active_passive_enum agent_active = UVM_ACTIVE;

//uvm macros
`uvm_object_utils_begin(axi_config)
`uvm_field_enum(uvm_active_passive_enum, agent_active, UVM_DEFAULT)
`uvm_object_utils_end

//constructor
function new (string name = "axi_config");
super.new(name);
endfunction : new


endclass : axi_config


`endif

