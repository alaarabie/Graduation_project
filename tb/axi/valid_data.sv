`ifndef valid_data_sv
`define valid_data_sv


class valid_data #(parameter t_user_width = 16, parameter t_data_bit = 128) extends  uvm_sequence_item;

rand  bti [t_data_bit-1 : 0]    t_data;
rand  bti [t_user_width-1 : 0]  t_user;

`uvm_object_param_utils_begin(valid_data #(.t_data_bit(t_data_bit), .t_user_width(t_user_width)))
`uvm_field_int(t_data, UVM_ALL_ON | UVM_NOPACK | UVM_HEX)
`uvm_field_int(t_user, UVM_ALL_ON | UVM_NOPACK | UVM_HEX)
`uvm_object_utils_end	


//constructor
function new (string name = "valid_data" , uvm_component parent);
super.new(name,parent)
endfunction 


endclass : valid_data

`endif
