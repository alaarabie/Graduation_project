class reg_status_general extends  uvm_reg;

  `uvm_object_utils(reg_status_general)

  rand uvm_reg_field  link_up;
  rand uvm_reg_field  link_training;
  rand uvm_reg_field  sleep_mode;
  rand uvm_reg_field  FERR_N;
  rand uvm_reg_field  lanes_reversed;
  rand uvm_reg_field  phy_tx_ready;
  rand uvm_reg_field  phy_rx_ready;
  rand uvm_reg_field  hmc_tokens_remaining;
  rand uvm_reg_field  rx_tokens_remaining;
  rand uvm_reg_field  lane_polarity_reversed;


function new(string name = "");
  super.new(name,64,UVM_NO_COVERAGE);
endfunction : new

virtual function void build();
  
  // Create object instance for each field
  this.link_up                = uvm_reg_field::type_id::create("link_up");
  this.link_training          = uvm_reg_field::type_id::create("link_training");
  this.sleep_mode             = uvm_reg_field::type_id::create("sleep_mode");
  this.FERR_N                 = uvm_reg_field::type_id::create("FERR_N");
  this.lanes_reversed         = uvm_reg_field::type_id::create("lanes_reversed");
  this.phy_tx_ready           = uvm_reg_field::type_id::create("phy_tx_ready");
  this.phy_rx_ready           = uvm_reg_field::type_id::create("phy_rx_ready");
  this.hmc_tokens_remaining   = uvm_reg_field::type_id::create("hmc_tokens_remaining");
  this.rx_tokens_remaining    = uvm_reg_field::type_id::create("rx_tokens_remaining");
  this.lane_polarity_reversed = uvm_reg_field::type_id::create("lane_polarity_reversed");

  // Configure each field (parent, size, lsb_pos, access, volatile, reset, has_reset, is_rand, individually_accessible)
  this.link_up.configure                (this, 1, 0, "RO", 0, 1'h0, 1, 0, 1);
  this.link_training.configure          (this, 1, 1, "RO", 0, 1'h1, 1, 0, 1);
  this.sleep_mode.configure             (this, 1, 2, "RO", 0, 1'h0, 1, 0, 1);
  this.FERR_N.configure                 (this, 1, 3, "RO", 0, 1'h0, 1, 0, 1);
  this.lanes_reversed.configure         (this, 1, 4, "RO", 0, 1'h0, 1, 0, 1);
  this.phy_tx_ready.configure           (this, 1, 8, "RO", 0, 1'h0, 1, 0, 1);
  this.phy_rx_ready.configure           (this, 1, 9, "RO", 0, 1'h0, 1, 0, 1);
  this.hmc_tokens_remaining.configure   (this, 10, 16, "RO", 0, 10'h0, 1, 0, 1);
  this.rx_tokens_remaining.configure    (this, 8,  32, "RO", 0, {8{1'b1}}, 1, 0, 1);
  this.lane_polarity_reversed.configure (this, 8,  48, "RO", 0, 8'h0, 1, 0, 1);
  
endfunction : build
  

endclass : reg_status_general