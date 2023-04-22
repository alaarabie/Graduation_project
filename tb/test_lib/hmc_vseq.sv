class hmc_vseq extends base_seq #(hmc_pkt_item);

  `uvm_object_utils(hmc_vseq)

  bit [1:0] tx_state;
  hmc_pkt_item response_packet ;

  hmc_initialization_seq hmc_initialization_seq ;
  hmc_response_seq hmc_response_seq ;
  hmc_state_seq hmc_state_seq ;

  extern function new (string name = "");
  extern task body();
  extern task TX_FSM();  

endclass : hmc_vseq


function hmc_vseq::new(string name = "");
  super.new(name);
  hmc_initialization_seq=hmc_initialization_seq::type_id::create("hmc_initialization") ;
  hmc_response_seq=hmc_response_seq::type_id::create("hmc_response") ;
  hmc_state_seq=hmc_state_seq::type_id::create("hmc_state_seq") ;  
endfunction : new

task hmc_vseq::body();
  super.body();

  tx_state = rf_rb.m_reg_status_init.status_init_tx_init_state.get();

  hmc_state_seq.start(m_sequencer) ;

  assert(tx_state==2'b11)
            begin
               hmc_initialization_seq.start(m_sequencer) ;
            end
         else
            begin
             assert(hmc_agent_if.phy_data_tx_link2phy[FLIT_SIZE-1:0]=='b0)
              begin  
                hmc_response_seq.start(m_sequencer) ; 
             end
            end  

  endtask : body



