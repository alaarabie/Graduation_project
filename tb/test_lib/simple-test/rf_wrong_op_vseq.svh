class rf_wrong_op_vseq extends vseq_base ;

  `uvm_object_utils(rf_wrong_op_vseq)

  rf_wrong_op_seq rf_wrong_op_seq_h;

  extern function new (string name = "");
  extern task body(); 

endclass : rf_wrong_op_vseq


function rf_wrong_op_vseq::new(string name = "");
  super.new(name);
endfunction : new

task rf_wrong_op_vseq::body();

  rf_wrong_op_seq_h = rf_wrong_op_seq::type_id::create("rf_wrong_op_seq_h");
  seq_set_cfg(rf_wrong_op_seq_h);

  super.body();

  `uvm_info("rf_wrong_op_vseq", "Executing sequence", UVM_MEDIUM)

      rf_wrong_op_seq_h.start(m_rf_seqr);
  
  `uvm_info("rf_wrong_op_vseq", "Sequence complete", UVM_MEDIUM)

  endtask : body