class vseq_base extends  uvm_sequence;

  `uvm_object_utils(vseq_base)
  `uvm_declare_p_sequencer(vsequencer)

  // Virtual sequencer handles
  rf_sequencer m_rf_seqr;


  function new(string name = "");
    super.new(name);
  endfunction : new


  virtual task body();
    // assign all sequencers to their handle in vsequencer
    m_rf_seqr = p_sequencer.m_rf_seqr;

  endtask : body

endclass : vseq_base