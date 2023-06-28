class rf_check_vseq extends vseq_base ;

  `uvm_object_utils(rf_check_vseq)

  rf_control_read_seq rf_control_read_seq_h;
  rf_status_general_seq rf_status_general_seq_h;
  rf_status_init_mirror_seq rf_status_init_mirror_seq_h;
  rf_counters_seq rf_counters_seq_h;


  extern function new (string name = "");
  extern task body(); 

endclass : rf_check_vseq


function rf_check_vseq::new(string name = "");
  super.new(name);
endfunction : new

task rf_check_vseq::body();

  rf_control_read_seq_h      = rf_control_read_seq::type_id::create("rf_control_read_seq_h");
  rf_status_general_seq_h    = rf_status_general_seq::type_id::create("rf_status_general_seq_h");
  rf_status_init_mirror_seq_h= rf_status_init_mirror_seq::type_id::create("rf_status_init_mirror_seq_h");
  rf_counters_seq_h= rf_counters_seq::type_id::create("rf_counters_seq_h");
  seq_set_cfg(rf_control_read_seq_h);
  seq_set_cfg(rf_status_general_seq_h);
  seq_set_cfg(rf_status_init_mirror_seq_h);
  seq_set_cfg(rf_counters_seq_h);

  super.body();

  `uvm_info("rf_check_vseq", "Executing sequence", UVM_MEDIUM)

      rf_status_general_seq_h.start(m_rf_seqr);
      //rf_status_init_mirror_seq_h.start(m_rf_seqr);
      //rf_control_read_seq_h.start(m_rf_seqr);
      //rf_counters_seq_h.start(m_rf_seqr);
  
  `uvm_info("rf_check_vseq", "Sequence complete", UVM_MEDIUM)

  endtask : body