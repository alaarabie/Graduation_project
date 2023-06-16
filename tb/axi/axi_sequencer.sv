
class axi_sequencer #(NUM_DATA_BYTES = 64, DWIDTH = 512)  extends  uvm_sequencer #(valid_data #(.NUM_DATA_BYTES(NUM_DATA_BYTES), .DWIDTH(DWIDTH)));

`uvm_component_param_utils (axi_sequencer #(.NUM_DATA_BYTES(NUM_DATA_BYTES), .DWIDTH(DWIDTH)))

function new (string name = "axi_sequencer" , uvm_component parent);
super.new(name,parent);
endfunction 

endclass : axi_sequencer
