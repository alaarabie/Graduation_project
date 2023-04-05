class rf_sequencer extends  uvm_sequencer #(rf_item);

  `uvm_component_utils(rf_sequencer)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

endclass : rf_sequencer

