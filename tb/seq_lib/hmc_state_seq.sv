class hmc_state_seq extends base_seq ;
  `uvm_object_utils(hmc_state_seq)

  bit [1:0] tx_state;
  bit [2:0] rx_state ;
  hmc_pkt_item response_packet ;
  
  extern function new (string name = "");
  extern task body();

endclass : hmc_state_seq

  function hmc_state_seq:: new (string name = "");
    super.new(name);
  endfunction : new

  task hmc_state_seq:: body();
    super.body();

   response_packet=hmc_pkt_item::type_id::create("response_packet") ;

    start_item(response_packet) ;
    tx_state = rf_rb.m_reg_status_init.status_init_tx_init_state.get();
    rx_state = rf_rb.m_reg_status_init.status_init_rx_init_state.get();    
    response_packet.init_state = tx_state ;
    response_packet.rx_state = rx_state ;    
    finish_item(response_packet) ;    
  endtask : body