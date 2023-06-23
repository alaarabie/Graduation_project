class random_test extends  base_test;
  `uvm_component_utils(random_test)
  
 function new(string name, uvm_component parent);
    super.new(name,parent);
 endfunction : new

  task run_phase(uvm_phase phase);

    hmc_vseq m_hmc_vseq = hmc_vseq::type_id::create("m_hmc_vseq");
    set_seqs(m_hmc_vseq);
    
    //vseq_class_name vseq_handle = seq_class_name::type_id::create("vseq_handle");
     
    phase.raise_objection(this);
    
       `uvm_info("random_test run","Starting test", UVM_MEDIUM)

      //vseq_handle.start(m_env.m_vseqr);
       m_hmc_vseq.start(m_env.m_vseqr) ;

       `uvm_info("random_test run","Ending test", UVM_MEDIUM)
    
    phase.drop_objection(this);
    
  endtask : run_phase
  

endclass : random_test