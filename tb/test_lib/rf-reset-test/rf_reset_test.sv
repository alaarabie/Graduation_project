class rf_reset_test extends  base_test;
  `uvm_component_utils(rf_reset_test)
  
 function new(string name, uvm_component parent);
    super.new(name,parent);
 endfunction : new

  task run_phase(uvm_phase phase);

    //vseq_class_name vseq_handle = seq_class_name::type_id::create("vseq_handle");
    rf_reset_vseq m_rf_reset_vseq = rf_reset_vseq::type_id::create("m_rf_reset_vseq");
    set_seqs(m_rf_reset_vseq);
     
    phase.raise_objection(this);
    
       `uvm_info("RF_RESET_TEST","Starting test", UVM_MEDIUM)

        //vseq_handle.start(m_env.m_vseqr);
        m_rf_reset_vseq.start(m_env.m_vseqr) ;

       `uvm_info("RF_RESET_TEST","Ending test", UVM_MEDIUM)
    
    phase.drop_objection(this);
    
  endtask : run_phase
  

endclass : rf_reset_test