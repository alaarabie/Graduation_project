class hmc_retry_test_vseq extends vseq_base ;

  `uvm_object_utils(hmc_retry_test_vseq)

  axi_base_seq axi_seq_h ;

  initialization_seq init;


  function new(string name = "");
    super.new(name);
  endfunction : new

  task body();

    axi_seq_h=axi_base_seq::type_id::create("axi_seq_h") ;
    seq_set_cfg(axi_seq_h);
    init = initialization_seq::type_id::create("init");
    seq_set_cfg(init);

    super.body();
      `uvm_info("hmc_retry_test_vseq", "Executing sequence", UVM_MEDIUM)
        init.start(m_rf_seqr);
        #2us;
        `uvm_info("hmc_retry_test_vseq", "Executing AXI sequence", UVM_MEDIUM)
        axi_seq_h.randomize();
        axi_seq_h.start(m_axi_sqr);
        repeat(3) begin
          #200ns;
          `uvm_info("hmc_retry_test_vseq", "Executing AXI sequence", UVM_MEDIUM)
          axi_seq_h.randomize();
          axi_seq_h.start(m_axi_sqr); 
        end
      `uvm_info("hmc_retry_test_vseq", "Sequence complete", UVM_MEDIUM)

  endtask : body

endclass : hmc_retry_test_vseq