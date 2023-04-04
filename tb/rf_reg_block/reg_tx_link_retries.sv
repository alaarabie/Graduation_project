class reg_tx_link_retries extends  uvm_reg;

  `uvm_object_utils(reg_tx_link_retries)

  rand uvm_reg_field  tx_link_retries;


function new(string name = "");
  super.new(name,64,UVM_NO_COVERAGE);
endfunction : new

virtual function void build();
  
  // Create object instance for each field
  this.tx_link_retries  = uvm_reg_field::type_id::create("tx_link_retries");

  // Configure each field (parent, size, lsb_pos, access, volatile, reset, has_reset, is_rand, individually_accessible)
  this.tx_link_retries.configure  (this, 32,  0, "RO", 0,  32'h0, 1, 0, 1);

endfunction : build
  

endclass : reg_tx_link_retries


