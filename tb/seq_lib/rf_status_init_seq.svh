class rf_status_init_seq extends  base_seq;

  `uvm_object_utils(rf_status_init_seq)

  extern function new (string name = "");
  extern task body();

endclass : rf_status_init_seq


function rf_status_init_seq::new(string name = "");
  super.new(name);
endfunction : new

task rf_status_init_seq::body();
  string print_reg;
  super.body();

  rf_rb.m_reg_status_init.read(status, data, .parent(this));

  print_reg = $sformatf("\n*******************************\n\tSTATUS INIT REGISTER\n*******************************
                         \t lane_descramblers_locked=%0x, 
                         \t descrambler_part_alligned=%0x, 
                         \t descrambler_alligned=%0x, 
                         \t all_descramblers_alligned=%1b, 
                         \t status_init_rx_init_state=%0x, 
                         \t status_init_tx_init_state=%0x\n**************************************************************\n", 
                         rf_rb.m_reg_status_init.lane_descramblers_locked.get(),
                         rf_rb.m_reg_status_init.descrambler_part_alligned.get(),
                         rf_rb.m_reg_status_init.descrambler_alligned.get(),
                         rf_rb.m_reg_status_init.all_descramblers_alligned.get(),
                         rf_rb.m_reg_status_init.status_init_rx_init_state.get(),
                         rf_rb.m_reg_status_init.status_init_tx_init_state.get()
                        );

  `uvm_info("rf_control_read_seq", print_reg,UVM_LOW)

endtask : body