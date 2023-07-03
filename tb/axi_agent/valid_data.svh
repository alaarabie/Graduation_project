
class valid_data #(parameter NUM_DATA_BYTES = 64, parameter DWIDTH = 512) extends  uvm_sequence_item;

rand  bit [DWIDTH-1 : 0]    t_data;
rand  bit [NUM_DATA_BYTES-1 : 0]  t_user;
rand  int unsigned delay = 0;

`uvm_object_param_utils_begin(valid_data #(.DWIDTH(DWIDTH), .NUM_DATA_BYTES(NUM_DATA_BYTES)))
`uvm_field_int(t_data, UVM_ALL_ON | UVM_NOPACK | UVM_HEX)
`uvm_field_int(t_user, UVM_ALL_ON | UVM_NOPACK | UVM_HEX)
`uvm_field_int(delay, UVM_ALL_ON | UVM_NOPACK | UVM_HEX)
`uvm_object_utils_end	


//constructor
function new (string name = "valid_data");
super.new(name);
endfunction 


endclass : valid_data


