class hmc_state_seq extends base_seq ;
  `uvm_object_utils(hmc_state_seq)

  bit [1:0] tx_state;
  hmc_pkt_item response_packet ;
  
  extern function new (string name = "");
  extern task body();

endclass : hmc_state_seq

  function hmc_state_seq:: new (string name = "");
    super.new(name);
  endfunction : new

  task hmc_state_seq:: body();
    super.body();
   
    start_item(response_packet) ;
    tx_state = rf_rb.m_reg_status_init.status_init_tx_init_state.get();
    response_packet.init_state = tx_state ;
    finish_item(response_packet) ;    
  endtask : body