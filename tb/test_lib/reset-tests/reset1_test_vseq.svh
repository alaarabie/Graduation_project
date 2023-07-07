class reset1_test_vseq extends vseq_base ;

  `uvm_object_utils(reset1_test_vseq)

  reset1_seq reset1;


  function new(string name = "");
    super.new(name);
  endfunction : new

  task body();

    reset1 = reset1_seq::type_id::create("reset1");
    seq_set_cfg(reset1);

    super.body();
      `uvm_info("reset_test_vseq", "Executing sequence", UVM_MEDIUM)
        reset1.start(m_rf_seqr);

  endtask : body

endclass : reset1_test_vseq