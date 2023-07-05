class simple_test_vseq extends vseq_base ;

  `uvm_object_utils(simple_test_vseq)

  axi_base_seq axi_seq_h ;

  initialization_seq init;

  rf_control_sleep_seq sleep;


  function new(string name = "");
    super.new(name);
  endfunction : new

  task body();

    axi_seq_h=axi_base_seq::type_id::create("axi_seq_h") ;
    seq_set_cfg(axi_seq_h);
    init = initialization_seq::type_id::create("init");
    seq_set_cfg(init);
    sleep = rf_control_sleep_seq::type_id::create("sleep");
    seq_set_cfg(sleep);

    super.body();
      `uvm_info("simple_test_vseq", "Executing sequence", UVM_MEDIUM)
        init.start(m_rf_seqr);
        #2us;
        repeat(6) begin
          `uvm_info("simple_test_vseq", "Executing AXI sequence", UVM_MEDIUM)
          axi_seq_h.randomize();
          axi_seq_h.start(m_axi_sqr);
          `uvm_info("simple_test_vseq", "AXI sequence complete", UVM_MEDIUM)
          #5us;
          `uvm_info("simple_test_vseq", "START TRIAL - SET OpenHMC to Sleep then Re-Init", UVM_MEDIUM)
          sleep.start(m_rf_seqr);
          `uvm_info("simple_test_vseq", "END TRIAL - SET OpenHMC to Sleep then Re-Init", UVM_MEDIUM)
          #1us;
        end

  endtask : body

endclass : simple_test_vseq