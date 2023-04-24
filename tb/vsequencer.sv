class vsequencer extends  uvm_sequencer;
  
  `uvm_component_utils(vsequencer)

  rf_sequencer  m_rf_seqr;
  sequencer_hmc_agent m_seqr_hmc_agent;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new
  
endclass : vsequencer