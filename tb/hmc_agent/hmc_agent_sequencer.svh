class hmc_agent_sequencer extends  uvm_sequencer #(hmc_pkt_item);

  `uvm_component_utils(hmc_agent_sequencer)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

endclass : hmc_agent_sequencer

