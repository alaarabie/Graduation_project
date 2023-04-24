class hmc_vseq extends vseq_base ;

  `uvm_object_utils(hmc_vseq)

  bit [1:0] tx_state;
  hmc_pkt_item response_packet ;

  hmc_initialization_seq hmc_initialization_seq_h ;
  hmc_response_seq hmc_response_seq_h ;
  hmc_state_seq hmc_state_seq_h ;

  extern function new (string name = "");
  extern task body();
  extern task TX_FSM();  

endclass : hmc_vseq


function hmc_vseq::new(string name = "");
  super.new(name);
endfunction : new

task hmc_vseq::body();
  super.body();

  hmc_initialization_seq_h=hmc_initialization_seq::type_id::create("hmc_initialization") ;
  hmc_response_seq_h=hmc_response_seq::type_id::create("hmc_response") ;
  hmc_state_seq_h=hmc_state_seq::type_id::create("hmc_state_seq") ;  

  tx_state = rf_rb.m_reg_status_init.status_init_tx_init_state.get();

  hmc_state_seq_h.start(m_seqr_hmc_agent) ;

  if(tx_state!=2'b11)
            begin
               hmc_initialization_seq_h.start(m_seqr_hmc_agent) ;
            end
         // else
         //    begin
         //        hmc_response_seq_h.start(m_seqr_hmc_agent) ;
         //    end  

  endtask : body



