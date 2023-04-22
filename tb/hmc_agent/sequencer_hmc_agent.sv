class sequencer_hmc_agent extends  uvm_sequencer #(hmc_pkt_item);

  `uvm_component_utils(sequencer_hmc_agent)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

endclass : sequencer_hmc_agent

