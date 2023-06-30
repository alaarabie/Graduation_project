class reg_counter_reset extends  uvm_reg;

  `uvm_object_utils(reg_counter_reset)

  rand uvm_reg_field  counter_reset;


function new(string name = "");
  super.new(name,64,UVM_NO_COVERAGE);
endfunction : new

virtual function void build();
  
  // Create object instance for each field
  this.counter_reset  = uvm_reg_field::type_id::create("counter_reset");

  // Configure each field (parent, size, lsb_pos, access, volatile, reset, has_reset, is_rand, individually_accessible)
  this.counter_reset.configure  (this, 1,  0, "RW", 0,  1'h0, 1, 0, 1);

endfunction : build
  

endclass : reg_counter_reset