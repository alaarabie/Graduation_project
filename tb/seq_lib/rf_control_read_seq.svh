class rf_control_read_seq extends  base_seq;

  `uvm_object_utils(rf_control_read_seq)

  extern function new (string name = "");
  extern task body();

endclass : rf_control_read_seq


function rf_control_read_seq::new(string name = "");
  super.new(name);
endfunction : new

task rf_control_read_seq::body();
  string print_reg;
  super.body();

  rf_rb.m_reg_control.read(status, data, .parent(this));
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

  `uvm_info("rf_control_read_seq", print_reg,UVM_LOW)

endtask : body