class axi_test extends base_test;
  `uvm_component_utils(axi_test)
  
 function new(string name, uvm_component parent);
    super.new(name,parent);
 endfunction : new

  task run_phase(uvm_phase phase);

    //vseq_class_name vseq_handle = seq_class_name::type_id::create("vseq_handle");
    axi_vseq m_axi_vseq = axi_vseq::type_id::create("m_axi_vseq");
    set_seqs(m_axi_vseq);
     
    phase.raise_objection(this);
    
       `uvm_info("axi_test","Starting test", UVM_MEDIUM)

        //vseq_handle.start(m_env.m_vseqr);
        m_axi_vseq.start(m_env.m_vseqr) ;

       `uvm_info("axi_test","Ending test", UVM_MEDIUM)
    
    phase.drop_objection(this);
    
  endtask : run_phase
  

endclass : axi_test