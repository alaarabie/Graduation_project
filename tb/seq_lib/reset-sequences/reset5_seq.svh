class reset5_seq extends  base_seq;

  `uvm_object_utils(reset5_seq)

  function new(string name = "");
    super.new(name);
  endfunction : new

  task body();
    string print_reg;
    time sleep_time = 10us;
    super.body();

    rf_rb.m_reg_control.read(status, data, .parent(this));
    rf_rb.m_reg_control.read(status, data, .parent(this));
    print_reg = $sformatf("\n%s\n\tCONTROL REGISTER (before sleep)\n%s\n\t p_rst_n=%1b, \n\t hmc_init_cont_set=%1b, \n\t set_hmc_sleep=%1b, \n\t warm_reset=%1b, \n\t scrambler_disable=%1b, \n\t run_length_enable=%1b, \n\t rx_token_count=%0x, \n\t irtry_received_threshold=%0x, \n\t irtry_to_send=%0x\n%s\n", 
                       "*******************************",
                       "*******************************",
                       rf_rb.m_reg_control.p_rst_n.get(),
                       rf_rb.m_reg_control.hmc_init_cont_set.get(),
                       rf_rb.m_reg_control.set_hmc_sleep.get(),
                       rf_rb.m_reg_control.warm_reset.get(),
                       rf_rb.m_reg_control.scrambler_disable.get(),
                       rf_rb.m_reg_control.run_length_enable.get(),
                       rf_rb.m_reg_control.rx_token_count.get(),
                       rf_rb.m_reg_control.irtry_received_threshold.get(),
                       rf_rb.m_reg_control.irtry_to_send.get(),
                       "**************************************************************"
                      );
    `uvm_info("RESET5_SEQ",print_reg,UVM_LOW)
    
    rf_rb.m_reg_control.set_hmc_sleep.set(1'h1); // <<--
    rf_rb.m_reg_control.update(status);

    rf_rb.m_reg_control.read(status, data, .parent(this));
    rf_rb.m_reg_control.read(status, data, .parent(this));
    print_reg = $sformatf("\n%s\n\tCONTROL REGISTER (after sleep)\n%s\n\t p_rst_n=%1b, \n\t hmc_init_cont_set=%1b, \n\t set_hmc_sleep=%1b, \n\t warm_reset=%1b, \n\t scrambler_disable=%1b, \n\t run_length_enable=%1b, \n\t rx_token_count=%0x, \n\t irtry_received_threshold=%0x, \n\t irtry_to_send=%0x\n%s\n", 
                         "*******************************",
                         "*******************************",
                         rf_rb.m_reg_control.p_rst_n.get(),
                         rf_rb.m_reg_control.hmc_init_cont_set.get(),
                         rf_rb.m_reg_control.set_hmc_sleep.get(),
                         rf_rb.m_reg_control.warm_reset.get(),
                         rf_rb.m_reg_control.scrambler_disable.get(),
                         rf_rb.m_reg_control.run_length_enable.get(),
                         rf_rb.m_reg_control.rx_token_count.get(),
                         rf_rb.m_reg_control.irtry_received_threshold.get(),
                         rf_rb.m_reg_control.irtry_to_send.get(),
                         "**************************************************************"
                        );
    `uvm_info("RESET5_SEQ",print_reg,UVM_LOW)

    #1us;
    `uvm_info("RESET5_SEQ","Checking Sleep mode in status register",UVM_LOW)
    while(!rf_rb.m_reg_status_general.sleep_mode.get()) begin
        rf_rb.m_reg_status_general.read(status, data, .parent(this));
        rf_rb.m_reg_status_general.read(status, data, .parent(this));
        if (rf_rb.m_reg_status_general.sleep_mode.get()) begin
          print_reg = $sformatf("\n%s\n\tSTATUS GENERAL REGISTER (during sleep)\n%s\n\t link_up=%1b, \n\t link_training=%1b, \n\t sleep_mode=%1b, \n\t FERR_N=%1b, \n\t lanes_reversed=%1b, \n\t phy_tx_ready=%1b, \n\t phy_rx_ready=%1b, \n\t hmc_tokens_remaining=%0x, \n\t rx_tokens_remaining=%0x, \n\t lane_polarity_reversed=%0x\n%s\n", 
                         "*******************************",
                         "*******************************",
                         rf_rb.m_reg_status_general.link_up.get(),
                         rf_rb.m_reg_status_general.link_training.get(),
                         rf_rb.m_reg_status_general.sleep_mode.get(),
                         rf_rb.m_reg_status_general.FERR_N.get(),
                         rf_rb.m_reg_status_general.lanes_reversed.get(),
                         rf_rb.m_reg_status_general.phy_tx_ready.get(),
                         rf_rb.m_reg_status_general.phy_rx_ready.get(),
                         rf_rb.m_reg_status_general.hmc_tokens_remaining.get(),
                         rf_rb.m_reg_status_general.rx_tokens_remaining.get(),
                         rf_rb.m_reg_status_general.lane_polarity_reversed.get(),
                         "**************************************************************"
                        );
          `uvm_info("RESET5_SEQ", print_reg,UVM_LOW)
        end
    end
    //Stay in Sleep for up to 22 us
    sleep_time_rand_succeeds : assert (std::randomize(sleep_time) with {sleep_time >= 2us && sleep_time < 22us;}); //-- should be 1ms in real system
    #(sleep_time);
    // instead of exiting sleep, activate reset
    activate_reset("RESET5_SEQ");
  endtask : body


endclass : reset5_seq