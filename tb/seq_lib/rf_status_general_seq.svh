class rf_status_general_seq extends  base_seq;

  `uvm_object_utils(rf_status_general_seq)

  extern function new (string name = "");
  extern task body();

endclass : rf_status_general_seq


function rf_status_general_seq::new(string name = "");
  super.new(name);
endfunction : new

task rf_status_general_seq::body();
  string print_reg;
  super.body();

  rf_rb.m_reg_status_general.read(status, data, .parent(this));

  print_reg = $sformatf("\n*******************************\n\tSTATUS GENERAL REGISTER\n*******************************
                         \t link_up=%1b, 
                         \t link_training=%1b, 
                         \t sleep_mode=%1b, 
                         \t FERR_N=%1b, 
                         \t lanes_reversed=%1b, 
                         \t phy_tx_ready=%1b, 
                         \t phy_rx_ready=%1b, 
                         \t hmc_tokens_remaining=%0x, 
                         \t rx_tokens_remaining=%0x, 
                         \t lane_polarity_reversed=%0x\n**************************************************************\n", 
                         rf_rb.m_reg_status_general.link_up.get(),
                         rf_rb.m_reg_status_general.link_training.get(),
                         rf_rb.m_reg_status_general.sleep_mode.get(),
                         rf_rb.m_reg_status_general.FERR_N.get(),
                         rf_rb.m_reg_status_general.lanes_reversed.get(),
                         rf_rb.m_reg_status_general.phy_tx_ready.get(),
                         rf_rb.m_reg_status_general.phy_rx_ready.get(),
                         rf_rb.m_reg_status_general.hmc_tokens_remaining.get(),
                         rf_rb.m_reg_status_general.rx_tokens_remaining.get(),
                         rf_rb.m_reg_status_general.lane_polarity_reversed.get()
                        );

  `uvm_info("rf_status_general_seq", print_reg,UVM_LOW)

endtask : body