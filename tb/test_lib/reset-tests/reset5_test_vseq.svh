class reset5_test_vseq extends vseq_base ;

  `uvm_object_utils(reset5_test_vseq)

  reset5_seq reset_during_sleep;
  initialization_seq init;
  axi_write_seq axi_tx;

  function new(string name = "");
    super.new(name);
  endfunction : new

  task body();
    reset_during_sleep = reset5_seq::type_id::create("reset_during_sleep");
    seq_set_cfg(reset_during_sleep);
    init = initialization_seq::type_id::create("init");
    seq_set_cfg(init);
    axi_tx = axi_write_seq::type_id::create("axi_tx");
    seq_set_cfg(axi_tx);

    super.body();
    `uvm_info("reset5_test_vseq", "Executing sequence", UVM_MEDIUM)
    init.start(m_rf_seqr);
    #2us;
    reset_during_sleep.start(m_rf_seqr);

    init.start(m_rf_seqr);
    #2us;
    repeat(5) begin
      activate_reset("reset5_test_vseq");
      init.start(m_rf_seqr);
      #200ns;
      axi_tx.randomize();
      axi_tx.start(m_axi_sqr);
    end   
  endtask : body

  

endclass : reset5_test_vseq