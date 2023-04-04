class vsequencer extends  uvm_sequencer;
  
  `uvm_component_utils(vsequencer)

  rf_sequencer  m_rf_seqr;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new
  
endclass : vsequencer