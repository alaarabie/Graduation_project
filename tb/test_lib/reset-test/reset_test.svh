class reset_test extends  base_test;
  `uvm_component_utils(reset_test)
  
 function new(string name, uvm_component parent);
    super.new(name,parent);
 endfunction : new

  task run_phase(uvm_phase phase);

    //vseq_class_name vseq_handle = seq_class_name::type_id::create("vseq_handle");
    reset_test_vseq m_reset_test_vseq = reset_test_vseq::type_id::create("m_reset_test_vseq");

    set_seqs(m_reset_test_vseq);

    phase.raise_objection(this);

    super.run_phase(phase); 
    
      `uvm_info("RESET_TEST","Starting test", UVM_MEDIUM)

      `uvm_info("RESET_TEST","Executing m_reset_test_vseq", UVM_MEDIUM)      
      m_reset_test_vseq.start(m_env.m_vseqr);        
      `uvm_info("RESET_TEST", "m_reset_test_vseq complete", UVM_MEDIUM)

      #1us;

      `uvm_info("RESET_TEST","Ending test", UVM_MEDIUM)
    
    phase.drop_objection(this);
    
  endtask : run_phase
  

endclass : reset_test