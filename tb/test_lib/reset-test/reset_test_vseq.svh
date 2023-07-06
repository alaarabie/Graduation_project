class reset_test_vseq extends vseq_base ;

  `uvm_object_utils(reset_test_vseq)

  reset_seq random_resets;


  function new(string name = "");
    super.new(name);
  endfunction : new

  task body();

    random_resets = reset_seq::type_id::create("random_resets");
    seq_set_cfg(random_resets);

    super.body();
      `uvm_info("reset_test_vseq", "Executing sequence", UVM_MEDIUM)
        random_resets.start(m_rf_seqr);

  endtask : body

endclass : reset_test_vseq