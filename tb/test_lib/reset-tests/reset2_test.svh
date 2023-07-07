class reset2_test extends  base_test;
  `uvm_component_utils(reset2_test)
  
 function new(string name, uvm_component parent);
    super.new(name,parent);
 endfunction : new

  task run_phase(uvm_phase phase);

    //vseq_class_name vseq_handle = seq_class_name::type_id::create("vseq_handle");
    reset2_test_vseq m_reset2_test_vseq = reset2_test_vseq::type_id::create("m_reset2_test_vseq");

    set_seqs(m_reset2_test_vseq);

    phase.raise_objection(this);

    super.run_phase(phase); 
    
      `uvm_info("RESET2_TEST","Starting test", UVM_MEDIUM)

      `uvm_info("RESET2_TEST","Executing m_reset_test_vseq", UVM_MEDIUM)      
      m_reset2_test_vseq.start(m_env.m_vseqr);        
      `uvm_info("RESET2_TEST", "m_reset_test_vseq complete", UVM_MEDIUM)

      `uvm_info("RESET2_TEST","Ending test", UVM_MEDIUM)
    
    phase.drop_objection(this);

    
  endtask : run_phase
  

endclass : reset2_test