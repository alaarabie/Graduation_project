class hmc_final_test extends  base_test;
  `uvm_component_utils(hmc_final_test)
  
 function new(string name, uvm_component parent);
    super.new(name,parent);
 endfunction : new

  task run_phase(uvm_phase phase);

    //vseq_class_name vseq_handle = seq_class_name::type_id::create("vseq_handle");
    hmc_init_vseq m_hmc_init_vseq = hmc_init_vseq::type_id::create("m_hmc_init_vseq");
    hmc_req_resp_vseq m_hmc_req_resp_vseq = hmc_req_resp_vseq::type_id::create("hmc_req_resp_vseq") ;     
    set_seqs(m_hmc_init_vseq);
    set_seqs(m_hmc_req_resp_vseq);
     
    phase.raise_objection(this);
    
       `uvm_info("HMC_FINAL_TEST","Starting test", UVM_MEDIUM)

         //vseq_handle.start(m_env.m_vseqr);

       `uvm_info("HMC_FINAL_TEST","Executing hmc_init_vseq", UVM_MEDIUM)         
         m_hmc_init_vseq.start(m_env.m_vseqr) ;
       `uvm_info("HMC_FINAL_TEST", "hmc_init_vseq complete", UVM_MEDIUM)          

       `uvm_info("HMC_FINAL_TEST","Executing hmc_req_resp_vseq", UVM_MEDIUM)      
         m_hmc_req_resp_vseq.start(m_env.m_vseqr) ;        
       `uvm_info("HMC_FINAL_TEST", "hmc_req_resp_vseq complete", UVM_MEDIUM)          

       `uvm_info("HMC_FINAL_TEST","Ending test", UVM_MEDIUM)
    
    phase.drop_objection(this);
    
  endtask : run_phase
  

endclass : hmc_final_test