class rf_control_sleep_seq extends  base_seq;

  `uvm_object_utils(rf_control_sleep_seq)

  extern function new (string name = "");
  extern task body();

endclass : rf_control_sleep_seq


function rf_control_sleep_seq::new(string name = "");
  super.new(name);
endfunction : new

task rf_control_sleep_seq::body();
  time sleep_time = 10us;
  string print_reg;
  super.body();

  rf_rb.m_reg_control.read(status, data, .parent(this));
  rf_rb.m_reg_control.read(status, data, .parent(this));
  print_reg = $sformatf("\n*******************************\n\tCONTROL REGISTER (before sleep)\n*******************************
                       \t p_rst_n=%1b, 
                       \t hmc_init_cont_set=%1b, 
                       \t set_hmc_sleep=%1b, 
                       \t warm_reset=%1b, 
                       \t scrambler_disable=%1b, 
                       \t run_length_enable=%1b, 
                       \t rx_token_count=%0x, 
                       \t irtry_received_threshold=%0x, 
                       \t irtry_to_send=%0x\n**************************************************************\n", 
                       rf_rb.m_reg_control.p_rst_n.get(),
                       rf_rb.m_reg_control.hmc_init_cont_set.get(),
                       rf_rb.m_reg_control.set_hmc_sleep.get(),
                       rf_rb.m_reg_control.warm_reset.get(),
                       rf_rb.m_reg_control.scrambler_disable.get(),
                       rf_rb.m_reg_control.run_length_enable.get(),
                       rf_rb.m_reg_control.rx_token_count.get(),
                       rf_rb.m_reg_control.irtry_received_threshold.get(),
                       rf_rb.m_reg_control.irtry_to_send.get()
                      );
    `uvm_info("SLEEP_SEQ",print_reg,UVM_LOW)

  rf_rb.m_reg_control.set_hmc_sleep.set(1'h1); // <<--
  rf_rb.m_reg_control.update(status);

  rf_rb.m_reg_control.read(status, data, .parent(this));
  rf_rb.m_reg_control.read(status, data, .parent(this));
  print_reg = $sformatf("\n*******************************\n\tCONTROL REGISTER (after sleep)\n*******************************
                       \t p_rst_n=%1b, 
                       \t hmc_init_cont_set=%1b, 
                       \t set_hmc_sleep=%1b, 
                       \t warm_reset=%1b, 
                       \t scrambler_disable=%1b, 
                       \t run_length_enable=%1b, 
                       \t rx_token_count=%0x, 
                       \t irtry_received_threshold=%0x, 
                       \t irtry_to_send=%0x\n**************************************************************\n", 
                       rf_rb.m_reg_control.p_rst_n.get(),
                       rf_rb.m_reg_control.hmc_init_cont_set.get(),
                       rf_rb.m_reg_control.set_hmc_sleep.get(),
                       rf_rb.m_reg_control.warm_reset.get(),
                       rf_rb.m_reg_control.scrambler_disable.get(),
                       rf_rb.m_reg_control.run_length_enable.get(),
                       rf_rb.m_reg_control.rx_token_count.get(),
                       rf_rb.m_reg_control.irtry_received_threshold.get(),
                       rf_rb.m_reg_control.irtry_to_send.get()
                      );
    `uvm_info("SLEEP_SEQ",print_reg,UVM_LOW)

    #1us;
    `uvm_info("SLEEP_SEQ","Checking Sleep mode in status register",UVM_LOW)
    while(!rf_rb.m_reg_status_general.sleep_mode.get()) begin
        rf_rb.m_reg_status_general.read(status, data, .parent(this));
        rf_rb.m_reg_status_general.read(status, data, .parent(this));
        if (rf_rb.m_reg_status_general.sleep_mode.get()) begin
          print_reg = $sformatf("\n*******************************\n\tSTATUS GENERAL REGISTER (during sleep)\n*******************************
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
          `uvm_info("SLEEP_SEQ", print_reg,UVM_LOW)
        end
    end
    //Stay in Sleep for up to 22 us
    sleep_time_rand_succeeds : assert (std::randomize(sleep_time) 
                                       with {sleep_time >= 2us && sleep_time < 22us;}); //-- should be 1ms in real system
    #(sleep_time);
    `uvm_info("SLEEP_SEQ",$sformatf("SLEEP MODE: EXIT"),UVM_LOW)
    //Force openHMC controller to exit sleep mode
    rf_rb.m_reg_control.set_hmc_sleep.set(1'h0); // <<--
    rf_rb.m_reg_control.update(status);
    rf_rb.m_reg_control.read(status, data, .parent(this));
    rf_rb.m_reg_control.read(status, data, .parent(this));
    print_reg = $sformatf("\n*******************************\n\tCONTROL REGISTER (disable sleep)\n*******************************
                       \t p_rst_n=%1b, 
                       \t hmc_init_cont_set=%1b, 
                       \t set_hmc_sleep=%1b, 
                       \t warm_reset=%1b, 
                       \t scrambler_disable=%1b, 
                       \t run_length_enable=%1b, 
                       \t rx_token_count=%0x, 
                       \t irtry_received_threshold=%0x, 
                       \t irtry_to_send=%0x\n**************************************************************\n", 
                       rf_rb.m_reg_control.p_rst_n.get(),
                       rf_rb.m_reg_control.hmc_init_cont_set.get(),
                       rf_rb.m_reg_control.set_hmc_sleep.get(),
                       rf_rb.m_reg_control.warm_reset.get(),
                       rf_rb.m_reg_control.scrambler_disable.get(),
                       rf_rb.m_reg_control.run_length_enable.get(),
                       rf_rb.m_reg_control.rx_token_count.get(),
                       rf_rb.m_reg_control.irtry_received_threshold.get(),
                       rf_rb.m_reg_control.irtry_to_send.get()
                      );
    `uvm_info("SLEEP_SEQ",print_reg,UVM_LOW)
    `uvm_info("SLEEP_SEQ",$sformatf("Waiting for Link is Up"),UVM_LOW)
    rf_rb.m_reg_status_general.read(status, data, .parent(this));
    rf_rb.m_reg_status_general.read(status, data, .parent(this));
    while(!rf_rb.m_reg_status_general.link_up.get()) begin
      rf_rb.m_reg_status_general.read(status, data, .parent(this));
    end
    `uvm_info("SLEEP_SEQ",$sformatf("Link is Up! from sleep"),UVM_LOW)

endtask : body