class rf_reset_vseq extends vseq_base ;

  `uvm_object_utils(rf_reset_vseq)

  rf_reset_seq rf_reset_seq_h;


  extern function new (string name = "");
  extern task body(); 

endclass : rf_reset_vseq


function rf_reset_vseq::new(string name = "");
  super.new(name);
endfunction : new

task rf_reset_vseq::body();

  rf_reset_seq_h= rf_reset_seq::type_id::create("rf_reset_seq_h");

  seq_set_cfg(rf_reset_seq_h);

  super.body();

  `uvm_info("RF_RESET_VSEQ", "Executing sequence", UVM_MEDIUM)

    // check that all registers reseted correctly
    `uvm_info("RF_RESET_VSEQ", "Executing rf_reset_seq", UVM_MEDIUM)
      rf_reset_seq_h.start(m_rf_seqr);
    `uvm_info("RF_RESET_VSEQ", "rf_reset_seq complete", UVM_MEDIUM)
  
  `uvm_info("RF_RESET_VSEQ", "Sequence complete", UVM_MEDIUM)

  endtask : body



