class initialization_seq extends  base_seq;

  bit phy_tx_ready  = 1'b0;
  bit phy_rx_ready  = 1'b0;
  bit link_up     = 1'b0;
  int timeout     = 0;

  `uvm_object_utils(initialization_seq)

  function new(string name = "");
    super.new(name);
  endfunction : new

  task body();
    string print_reg;
    super.body();
    
    `uvm_info("INITIALiZATION_SEQ", $sformatf("HMC_Token Count is: %d", m_cfg.m_hmc_agent_cfg.hmc_tokens), UVM_NONE)
    `uvm_info("INITIALiZATION_SEQ", $sformatf("RX_Token Count is: %d", m_cfg.m_hmc_agent_cfg.rx_tokens), UVM_NONE)

    // setting up the configuration of the OpenHMC
    rf_rb.m_reg_control.read(status, data, .parent(this));

    rf_rb.m_reg_control.hmc_init_cont_set.set(0);
    rf_rb.m_reg_control.set_hmc_sleep.set(0);
    rf_rb.m_reg_control.warm_reset.set(0);
    rf_rb.m_reg_control.scrambler_disable.set(!m_cfg.m_hmc_agent_cfg.scramblers_enabled);
    rf_rb.m_reg_control.run_length_enable.set(!m_cfg.m_hmc_agent_cfg.scramblers_enabled);
    rf_rb.m_reg_control.rx_token_count.set(m_cfg.m_hmc_agent_cfg.rx_tokens);
    rf_rb.m_reg_control.irtry_received_threshold.set(m_cfg.m_hmc_agent_cfg.irtry_flit_count_received_threshold);
    rf_rb.m_reg_control.irtry_to_send.set(m_cfg.m_hmc_agent_cfg.irtry_flit_count_to_send);
    #1us;
    rf_rb.m_reg_control.update(status); //write
    #1us;
    // make sure data is written correctly
    rf_rb.m_reg_control.read(status, data, .parent(this));

    print_reg = $sformatf("\n*******************************\n\tCONTROL REGISTER\n*******************************
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
    `uvm_info("INITIALiZATION_SEQ",print_reg,UVM_LOW)

    //Dummy Read to status init
    rf_rb.m_reg_status_init.read(status, data, .parent(this));

    //Dummy counter reset
    rf_rb.m_reg_counter_reset.counter_reset.set(1);
    rf_rb.m_reg_counter_reset.update(status);  //write

    //-- Wait until the PHY is out of reset
    while (phy_tx_ready == 1'b0) begin
      #1us;
      rf_rb.m_reg_status_general.read(status, data, .parent(this));
      phy_tx_ready = rf_rb.m_reg_status_general.phy_tx_ready.get();
      `uvm_info("INITIALiZATION_SEQ", "Waiting for the PHY TX to get ready", UVM_NONE)
    end
    `uvm_info("INITIALiZATION_SEQ", "Phy TX ready", UVM_NONE)

    //------------------------------------------------------- Set Reset and Init Continue
    rf_rb.m_reg_control.p_rst_n.set(1);
    rf_rb.m_reg_control.update(status);  //write
    #1us;
    rf_rb.m_reg_control.hmc_init_cont_set.set(1);
    rf_rb.m_reg_control.update(status);  //write

    //------------------------------------------------------- Wait for the PHY to get ready
    while (phy_rx_ready == 1'b0) begin
      #1us;
      rf_rb.m_reg_status_general.read(status, data, .parent(this));
      phy_rx_ready = rf_rb.m_reg_status_general.phy_rx_ready.get();
      `uvm_info("INITIALiZATION_SEQ", "Waiting for PHY RX to get ready", UVM_NONE)
    end
    `uvm_info("INITIALiZATION_SEQ", "Phy RX is ready", UVM_NONE)

    //-- Poll on link_up to make sure that it comes up.
    while (link_up == 1'b0) begin
      if (timeout == 8000) //-- Try Resetting it.
        begin
          `uvm_fatal("INITIALiZATION_SEQ", "The link didn't come up...")
        end
      #4ns;
      rf_rb.m_reg_status_general.read(status, data, .parent(this));
      link_up = rf_rb.m_reg_status_general.link_up.get();
      timeout = timeout + 1;
    end
    `uvm_info("INITIALiZATION_SEQ", "Link is UP !", UVM_NONE)

  endtask : body


endclass : initialization_seq