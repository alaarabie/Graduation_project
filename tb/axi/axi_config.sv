
class axi_config #(NUM_DATA_BYTES = 64, DWIDTH = 512) extends uvm_object;

//uvm macros
`uvm_object_param_utils(axi_config #(.DWIDTH(DWIDTH),.NUM_DATA_BYTES(NUM_DATA_BYTES)))

uvm_active_passive_enum agent_active = UVM_ACTIVE;

virtual axi_interface  #(.NUM_DATA_BYTES(NUM_DATA_BYTES), .DWIDTH(DWIDTH)) vif;


//constructor
function new (string name = "");
super.new(name);
endfunction : new


endclass : axi_config


