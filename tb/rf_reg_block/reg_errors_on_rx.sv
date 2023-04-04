class reg_errors_on_rx extends  uvm_reg;

  `uvm_object_utils(reg_errors_on_rx)

  rand uvm_reg_field  errors_on_rx;


function new(string name = "");
  super.new(name,64,UVM_NO_COVERAGE);
endfunction : new

virtual function void build();
  
  // Create object instance for each field
  this.errors_on_rx  = uvm_reg_field::type_id::create("errors_on_rx");

  // Configure each field (parent, size, lsb_pos, access, volatile, reset, has_reset, is_rand, individually_accessible)
  this.errors_on_rx.configure  (this, 32,  0, "RO", 0,  32'h0, 1, 0, 1);

endfunction : build
  

endclass : reg_errors_on_rx