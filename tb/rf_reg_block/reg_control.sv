class reg_control #(LOG_MAX_RX_TOKENS = 8) extends  uvm_reg;

  `uvm_object_param_utils(reg_control #(LOG_MAX_RX_TOKENS))
  
  rand uvm_reg_field  p_rst_n;
  rand uvm_reg_field  hmc_init_cont_set;
  rand uvm_reg_field  set_hmc_sleep;
  rand uvm_reg_field  scrambler_disable;
  rand uvm_reg_field  run_length_enable;
  rand uvm_reg_field  first_cube_ID;
  rand uvm_reg_field  debug_dont_send_tret;
  rand uvm_reg_field  debug_halt_on_error_abort;
  rand uvm_reg_field  debug_halt_on_tx_retry;
  rand uvm_reg_field  rx_token_count;
  rand uvm_reg_field  irtry_received_threshold;
  rand uvm_reg_field  irtry_to_send;


function new(string name = "");
  super.new(name,64,UVM_NO_COVERAGE);
endfunction : new

virtual function void build();
  
  // Create object instance for each field
  this.p_rst_n                   = uvm_reg_field::type_id::create("p_rst_n");
  this.hmc_init_cont_set         = uvm_reg_field::type_id::create("hmc_init_cont_set");
  this.set_hmc_sleep             = uvm_reg_field::type_id::create("set_hmc_sleep");
  this.scrambler_disable         = uvm_reg_field::type_id::create("scrambler_disable");
  this.run_length_enable         = uvm_reg_field::type_id::create("run_length_enable");
  this.first_cube_ID             = uvm_reg_field::type_id::create("first_cube_ID");
  this.debug_dont_send_tret      = uvm_reg_field::type_id::create("debug_dont_send_tret");
  this.debug_halt_on_error_abort = uvm_reg_field::type_id::create("debug_halt_on_error_abort");
  this.debug_halt_on_tx_retry    = uvm_reg_field::type_id::create("debug_halt_on_tx_retry");
  this.rx_token_count            = uvm_reg_field::type_id::create("rx_token_count");
  this.irtry_received_threshold  = uvm_reg_field::type_id::create("irtry_received_threshold");
  this.irtry_to_send             = uvm_reg_field::type_id::create("irtry_to_send");

  // Configure each field (parent, size, lsb_pos, access, volatile, reset, has_reset, is_rand, individually_accessible)
  this.p_rst_n.configure                   (this, 1, 0, "RW", 0, 1'h0, 1, 0, 1);
  this.hmc_init_cont_set.configure         (this, 1, 1, "RW", 0, 1'h0, 1, 0, 1);
  this.set_hmc_sleep.configure             (this, 1, 2, "RW", 0, 1'h0, 1, 0, 1);
  this.scrambler_disable.configure         (this, 1, 3, "RW", 0, 1'h0, 1, 0, 1);
  this.run_length_enable.configure         (this, 1, 4, "RW", 0, 1'h0, 1, 0, 1);
  this.first_cube_ID.configure             (this, 3, 5, "RW", 0, 3'h0, 1, 0, 1);
  this.debug_halt_on_error_abort.configure (this, 1, 8, "RW", 0, 1'h0, 1, 0, 1);
  this.debug_halt_on_tx_retry.configure    (this, 1, 9, "RW", 0, 1'h0, 1, 0, 1);
  this.rx_token_count.configure            (this, LOG_MAX_RX_TOKENS, 16, "RW", 0, {LOG_MAX_RX_TOKENS{1'b1}}, 1, 0, 1);
  this.irtry_received_threshold.configure  (this, 5, 32, "RW", 0, 5'h10, 1, 0, 1);
  this.irtry_to_send.configure             (this, 5, 40, "RW", 0, 5'h18, 1, 0, 1);
  
endfunction : build
  

endclass : reg_control