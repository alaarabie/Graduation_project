class reset4_test extends  base_test;
  `uvm_component_utils(reset4_test)
  
 function new(string name, uvm_component parent);
    super.new(name,parent);
 endfunction : new

  task run_phase(uvm_phase phase);

    //vseq_class_name vseq_handle = seq_class_name::type_id::create("vseq_handle");
    reset4_test_vseq m_reset4_test_vseq = reset4_test_vseq::type_id::create("m_reset4_test_vseq");

    set_seqs(m_reset4_test_vseq);

    phase.raise_objection(this);

    super.run_phase(phase); 
    
      `uvm_info("RESET4_TEST","Starting test", UVM_MEDIUM)

      `uvm_info("RESET4_TEST","Executing m_reset_test_vseq", UVM_MEDIUM)      
      m_reset4_test_vseq.start(m_env.m_vseqr);        
      `uvm_info("RESET4_TEST", "m_reset_test_vseq complete", UVM_MEDIUM)

      `uvm_info("RESET4_TEST","Ending test", UVM_MEDIUM)
    
    phase.drop_objection(this);

    
  endtask : run_phase
  

endclass : reset4_test