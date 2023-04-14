class reg_status_init extends  uvm_reg;

  `uvm_object_utils(reg_status_init)

  rand uvm_reg_field  lane_descramblers_locked;
  rand uvm_reg_field  descrambler_part_alligned;
  rand uvm_reg_field  descrambler_alligned;
  rand uvm_reg_field  all_descramblers_alligned;
  rand uvm_reg_field  status_init_rx_init_state;
  rand uvm_reg_field  status_init_tx_init_state;


function new(string name = "");
  super.new(name,64,UVM_NO_COVERAGE);
endfunction : new

virtual function void build();
  
  // Create object instance for each field
  this.lane_descramblers_locked  = uvm_reg_field::type_id::create("lane_descramblers_locked");
  this.descrambler_part_alligned = uvm_reg_field::type_id::create("descrambler_part_alligned");
  this.descrambler_alligned      = uvm_reg_field::type_id::create("descrambler_alligned");
  this.all_descramblers_alligned = uvm_reg_field::type_id::create("all_descramblers_alligned");
  this.status_init_rx_init_state = uvm_reg_field::type_id::create("status_init_rx_init_state");
  this.status_init_tx_init_state = uvm_reg_field::type_id::create("status_init_tx_init_state");

  // Configure each field (parent, size, lsb_pos, access, volatile, reset, has_reset, is_rand, individually_accessible)
  this.lane_descramblers_locked.configure  (this, 8,  0, "RO", 0,  8'h0, 1, 0, 1);
  this.descrambler_part_alligned.configure (this, 8, 16, "RO", 0,  8'h0, 1, 0, 1);
  this.descrambler_alligned.configure      (this, 8, 32, "RO", 0,  8'h0, 1, 0, 1);
  this.all_descramblers_alligned.configure (this, 1, 48, "RO", 0,  'h0, 1, 0, 1);
  this.status_init_rx_init_state.configure (this, 3, 49, "RO", 0, 3'h0, 1, 0, 1);
  this.status_init_tx_init_state.configure (this, 2, 53, "RO", 0, 2'h0, 1, 0, 1);
  
endfunction : build

endclass : reg_status_init