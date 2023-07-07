class reset3_test_vseq extends vseq_base ;

  `uvm_object_utils(reset3_test_vseq)

  reset3_seq reset3;


  function new(string name = "");
    super.new(name);
  endfunction : new

  task body();

    reset3 = reset3_seq::type_id::create("reset3");
    seq_set_cfg(reset3);

    super.body();
      `uvm_info("reset3_test_vseq", "Executing sequence", UVM_MEDIUM)
        reset3.start(m_rf_seqr);

  endtask : body

endclass : reset3_test_vseq