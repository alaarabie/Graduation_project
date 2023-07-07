class hmc_retry_test extends  base_test;
  `uvm_component_utils(hmc_retry_test)
  
 function new(string name, uvm_component parent);
    super.new(name,parent);
 endfunction : new


  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
      
    m_hmc_cfg.seq_error_probability = 2;
    m_hmc_cfg.lng_error_probability = 5;
    m_hmc_cfg.crc_error_probability = 1;

  endfunction : build_phase


  task run_phase(uvm_phase phase);

    //vseq_class_name vseq_handle = seq_class_name::type_id::create("vseq_handle");
    rf_check_vseq m_rf_check_vseq = rf_check_vseq::type_id::create("m_rf_check_vseq");
    hmc_retry_test_vseq m_hmc_retry_test_vseq = hmc_retry_test_vseq::type_id::create("m_hmc_retry_test_vseq");
    set_seqs(m_hmc_retry_test_vseq);
    set_seqs(m_rf_check_vseq);
     
    phase.raise_objection(this);
    
      `uvm_info("HMC_RETRY_TEST","Starting test", UVM_MEDIUM)

      `uvm_info("HMC_RETRY_TEST","Executing hmc_retry_test_vseq", UVM_MEDIUM)      
      m_hmc_retry_test_vseq.start(m_env.m_vseqr) ;        
      `uvm_info("HMC_RETRY_TEST", "hmc_retry_test_vseq complete", UVM_MEDIUM)
      #1us
      `uvm_info("HMC_RETRY_TEST","Executing rf_check_vseq", UVM_MEDIUM)
      m_rf_check_vseq.start(m_env.m_vseqr);
      `uvm_info("HMC_RETRY_TEST", "rf_check_vseq complete", UVM_MEDIUM)
      #500ns
      
      `uvm_info("HMC_RETRY_TEST","Ending test", UVM_MEDIUM)
    
    phase.drop_objection(this);
    
  endtask : run_phase
  

endclass : hmc_retry_test