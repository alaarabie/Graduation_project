class simple_test_vseq extends vseq_base ;

  `uvm_object_utils(simple_test_vseq)

  axi_seq axi_seq_h ;

  rf_status_general_seq rf_status_general_seq_h;
  initialization_seq init;


  function new(string name = "");
    super.new(name);
  endfunction : new

  task body();

    axi_seq_h=axi_seq::type_id::create("axi_seq_h") ;
    seq_set_cfg(axi_seq_h);
    rf_status_general_seq_h = rf_status_general_seq::type_id::create("rf_status_general_seq_h");
    seq_set_cfg(rf_status_general_seq_h);
    init = initialization_seq::type_id::create("init");
    seq_set_cfg(init);

    super.body();
      `uvm_info("simple_test_vseq", "Executing sequence", UVM_MEDIUM)
        init.start(m_rf_seqr);
        #2us;
        `uvm_info("simple_test_vseq", "Executing AXI sequence", UVM_MEDIUM)
        axi_seq_h.start(m_axi_sqr);
        repeat(5) begin
          #200ns;
          `uvm_info("simple_test_vseq", "Executing AXI sequence", UVM_MEDIUM)
          axi_seq_h.start(m_axi_sqr); 
          rf_status_general_seq_h.start(m_rf_seqr);
        end
        #5000ns;
      `uvm_info("simple_test_vseq", "Sequence complete", UVM_MEDIUM)

  endtask : body

endclass : simple_test_vseq