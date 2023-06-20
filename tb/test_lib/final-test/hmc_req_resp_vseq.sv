class hmc_req_resp_vseq extends vseq_base ;

  `uvm_object_utils(hmc_req_resp_vseq)

  axi_seq axi_seq_h ;
  hmc_response_seq hmc_response_seq_h ;

  extern function new (string name = "");
  extern task body(); 

endclass : hmc_req_resp_vseq


function hmc_req_resp_vseq::new(string name = "");
  super.new(name);
endfunction : new

task hmc_req_resp_vseq::body();

  axi_seq_h=axi_seq::type_id::create("axi_seq_h") ;
  hmc_response_seq_h=hmc_response_seq::type_id::create("hmc_response_seq_h") ;

  seq_set_cfg(axi_seq_h);
  seq_set_cfg(hmc_response_seq_h);

  super.body();
    `uvm_info("hmc_req_resp_vseq", "Executing sequence", UVM_MEDIUM)

    repeat(10000) begin
      fork 
        begin                   // Thread 1 \\
          `uvm_info("hmc_req_resp_vseq", "Executing axi_seq", UVM_MEDIUM)      
          axi_seq_h.start(m_axi_sqr);      
          `uvm_info("hmc_req_resp_vseq", "axi_seq complete", UVM_MEDIUM)        
        end

        begin                  // Thread 2 \\
          `uvm_info("hmc_req_resp_vseq", "Executing hmc_response_seq", UVM_MEDIUM)
          hmc_response_seq_h.start(m_seqr_hmc_agent) ;
          `uvm_info("hmc_req_resp_vseq", "hmc_response_seq complete", UVM_MEDIUM)          
        end

      join
      
    end

`uvm_info("hmc_req_resp_vseq", "Sequence complete", UVM_MEDIUM)

endtask : body