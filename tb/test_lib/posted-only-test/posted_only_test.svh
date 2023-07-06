class posted_only_test extends  base_test;
  `uvm_component_utils(posted_only_test)
  
 function new(string name, uvm_component parent);
    super.new(name,parent);
 endfunction : new

  task run_phase(uvm_phase phase);

    //vseq_class_name vseq_handle = seq_class_name::type_id::create("vseq_handle");
    rf_check_vseq m_rf_check_vseq = rf_check_vseq::type_id::create("m_rf_check_vseq");
    posted_only_test_vseq m_posted_only_test_vseq = posted_only_test_vseq::type_id::create("m_posted_only_test_vseq");
    set_seqs(m_posted_only_test_vseq);
    set_seqs(m_rf_check_vseq);
     
    phase.raise_objection(this);

    super.run_phase(phase); 
    
      `uvm_info("POSTED_ONLY_TEST","Starting test", UVM_MEDIUM)

      `uvm_info("POSTED_ONLY_TEST","Executing posted_only_test_vseq", UVM_MEDIUM)      
      m_posted_only_test_vseq.start(m_env.m_vseqr) ;        
      `uvm_info("POSTED_ONLY_TEST", "posted_only_test_vseq complete", UVM_MEDIUM)
      #200ns
      `uvm_info("POSTED_ONLY_TEST","Executing rf_check_vseq", UVM_MEDIUM)
      m_rf_check_vseq.start(m_env.m_vseqr);
      `uvm_info("POSTED_ONLY_TEST", "rf_check_vseq complete", UVM_MEDIUM)  
      #5000ns

      `uvm_info("POSTED_ONLY_TEST","Ending test", UVM_MEDIUM)
    
    phase.drop_objection(this);
    
  endtask : run_phase
  

endclass : posted_only_test