class reg_error_abort_not_cleared extends  uvm_reg;

  `uvm_object_utils(reg_error_abort_not_cleared)

  rand uvm_reg_field  error_abort_not_cleared;


function new(string name = "");
  super.new(name,64,UVM_NO_COVERAGE);
endfunction : new

virtual function void build();
  
  // Create object instance for each field
  this.error_abort_not_cleared  = uvm_reg_field::type_id::create("error_abort_not_cleared");

  // Configure each field (parent, size, lsb_pos, access, volatile, reset, has_reset, is_rand, individually_accessible)
  this.error_abort_not_cleared.configure  (this, 32,  0, "RO", 0,  32'h0, 1, 0, 1);

endfunction : build
  

endclass : reg_error_abort_not_cleared