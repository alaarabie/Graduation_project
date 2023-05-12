
class axi_sequencer #(parameter T_USER_WIDTH = 16, parameter T_DATA_BIT = 128) extends  uvm_sequencer #(valid_data #(.T_USER_WIDTH(T_USER_WIDTH), .T_DATA_BIT(T_DATA_BIT)));

`uvm_component_utils (axi_sequencer #(.T_USER_WIDTH(T_USER_WIDTH), .T_DATA_BIT(T_DATA_BIT)))

function new (string name = "axi_sequencer" , uvm_component parent);
super.new(name,parent);
endfunction 

endclass : axi_sequencer
