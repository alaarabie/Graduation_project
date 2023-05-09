
class axi_sequencer #(parameter t_user_width = 16, parameter t_data_bit = 128) extends  uvm_sequencer #(valid_data #(.t_user_width(t_user_width), .t_data_bit(t_data_bit)));

`uvm_component_utils (axi_sequencer #(.t_user_width(t_user_width), .t_data_bit(t_data_bit)))

function new (string name = "axi_sequencer" , uvm_component parent);
super.new(name,parent)
endfunction 

endclass : axi_sequencer
