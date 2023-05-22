class axi_vseq extends vseq_base;

  `uvm_object_utils(axi_vseq)

  axi_seq axi_sequence_h;
 

  extern function new (string name = "");
  extern task body(); 

endclass : axi_vseq


function axi_vseq::new(string name = "");
  super.new(name);
endfunction : new

task axi_vseq::body();

  axi_sequence_h= axi_seq ::type_id::create("axi_sequence_h");
 
  seq_set_cfg(axi_sequence_h);

 
  super.body();
 
  `uvm_info("axi_vseq", "Executing sequence", UVM_MEDIUM)
    // check that all registers reseted correctly
    `uvm_info("axi_vseq", "Executing axi_sequence", UVM_MEDIUM)
      axi_sequence_h.start(m_axi_sqr);
    `uvm_info("axi_vseq", "axi_sequence complete", UVM_MEDIUM)
    `uvm_info("axi_vseq", "Sequence complete", UVM_MEDIUM)

  endtask : body



