class reset2_test_vseq extends vseq_base ;

  `uvm_object_utils(reset2_test_vseq)

  reset2_seq reset2;


  function new(string name = "");
    super.new(name);
  endfunction : new

  task body();

    reset2 = reset2_seq::type_id::create("reset2");
    seq_set_cfg(reset2);

    super.body();
      `uvm_info("reset2_test_vseq", "Executing sequence", UVM_MEDIUM)
        reset2.start(m_rf_seqr);

  endtask : body

endclass : reset2_test_vseq