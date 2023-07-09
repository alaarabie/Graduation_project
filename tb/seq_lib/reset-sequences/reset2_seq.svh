class reset2_seq extends  base_seq;

  typedef enum bit [2:0] {
    HMC_DOWN           = 3'b000, 
    HMC_WAIT_FOR_NULL  = 3'b001, 
    HMC_NULL           = 3'b010,
    HMC_TS1_PART_ALIGN = 3'b011,
    HMC_TS1_FIND_REF   = 3'b100, //cover this
    HMC_TS1_ALIGN      = 3'b101,
    HMC_NULL_NEXT      = 3'b110,
    HMC_UP             = 3'b111  //cover this
  } status_init_rx_e;

  typedef enum bit [1:0] {
    INIT_TX_NULL_1 = 2'b00,
    INIT_TX_TS1    = 2'b01,
    INIT_TX_NULL_2 = 2'b10,
    INIT_DONE      = 2'b11
  } status_init_tx_e;

  `uvm_object_utils(reset2_seq)

  function new(string name = "");
    super.new(name);
  endfunction : new

  task body();
    string print_reg;
    super.body();

    setup_control();

    while(rf_rb.m_reg_status_init.status_init_rx_init_state.get() != HMC_UP) begin
      rf_rb.m_reg_status_init.read(status, data, .parent(this));
      print_reg = $sformatf("\n%s\n\tSTATUS INIT REGISTER\n%s\n\t status_init_rx_init_state=%3b,\n\t status_init_tx_init_state=%2b\n%s\n", 
                           "*******************************","*******************************",
                           rf_rb.m_reg_status_init.status_init_rx_init_state.get(),rf_rb.m_reg_status_init.status_init_tx_init_state.get()
                           ,"**************************************************************");
      `uvm_info("RESET2_SEQ", print_reg,UVM_LOW)
      if (rf_rb.m_reg_status_init.status_init_rx_init_state.get() == HMC_UP) begin
        activate_reset("RESET2_SEQ");
      end
    end

    setup_control();

    while(rf_rb.m_reg_status_init.status_init_rx_init_state.get() != HMC_TS1_FIND_REF) begin
      rf_rb.m_reg_status_init.read(status, data, .parent(this));
      print_reg = $sformatf("\n%s\n\tSTATUS INIT REGISTER\n%s\n\t status_init_rx_init_state=%3b,\n\t status_init_tx_init_state=%2b\n%s\n", 
                           "*******************************","*******************************",
                           rf_rb.m_reg_status_init.status_init_rx_init_state.get(),rf_rb.m_reg_status_init.status_init_tx_init_state.get()
                           ,"**************************************************************");
      `uvm_info("RESET2_SEQ", print_reg,UVM_LOW)
      if (rf_rb.m_reg_status_init.status_init_rx_init_state.get() == HMC_TS1_FIND_REF) begin
        activate_reset("RESET2_SEQ");
      end
    end
    
  endtask : body


  task setup_control();
    bit phy_tx_ready  = 1'b0;
    bit phy_rx_ready  = 1'b0;
    bit link_up     = 1'b0;
    int timeout     = 0;
    string print_reg;
    
    // setting up the configuration of the OpenHMC
    rf_rb.m_reg_control.read(status, data, .parent(this));
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

    print_reg = $sformatf("\n%s\n\tCONTROL REGISTER\n%s\n\t p_rst_n=%1b, \n\t hmc_init_cont_set=%1b, \n\t set_hmc_sleep=%1b, \n\t warm_reset=%1b, \n\t scrambler_disable=%1b, \n\t run_length_enable=%1b, \n\t rx_token_count=%0x, \n\t irtry_received_threshold=%0x, \n\t irtry_to_send=%0x\n%s\n", 
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
    `uvm_info("RESET2_SEQ",print_reg,UVM_LOW)
    //Dummy Read to status init
    rf_rb.m_reg_status_init.read(status, data, .parent(this));
    rf_rb.m_reg_status_init.read(status, data, .parent(this));
    //Dummy counter reset
    rf_rb.m_reg_counter_reset.counter_reset.set(1);
    rf_rb.m_reg_counter_reset.update(status);  //write
    //-- Wait until the PHY is out of reset
    while (phy_tx_ready == 1'b0) begin
      #1us;
      rf_rb.m_reg_status_general.read(status, data, .parent(this));
      phy_tx_ready = rf_rb.m_reg_status_general.phy_tx_ready.get();
      `uvm_info("RESET2_SEQ", "Waiting for the PHY TX to get ready", UVM_NONE)
    end
    `uvm_info("RESET2_SEQ", "Phy TX ready", UVM_NONE)
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
      `uvm_info("RESET2_SEQ", "Waiting for PHY RX to get ready", UVM_NONE)
    end
    `uvm_info("RESET2_SEQ", "Phy RX is ready", UVM_NONE)
  endtask : setup_control


endclass : reset2_seq