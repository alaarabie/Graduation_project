class reset4_test_vseq extends vseq_base ;

  `uvm_object_utils(reset4_test_vseq)

  reset4_seq reset4;


  function new(string name = "");
    super.new(name);
  endfunction : new

  task body();

    reset4 = reset4_seq::type_id::create("reset4");
    seq_set_cfg(reset4);

    super.body();
      `uvm_info("reset4_test_vseq", "Executing sequence", UVM_MEDIUM)
        reset4.start(m_rf_seqr);

  endtask : body

endclass : reset4_test_vseq