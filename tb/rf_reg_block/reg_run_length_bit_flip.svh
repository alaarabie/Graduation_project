class reg_run_length_bit_flip extends  uvm_reg;

  `uvm_object_utils(reg_run_length_bit_flip)

  rand uvm_reg_field  run_length_bit_flip;


function new(string name = "");
  super.new(name,64,UVM_NO_COVERAGE);
endfunction : new

virtual function void build();
  
  // Create object instance for each field
  this.run_length_bit_flip  = uvm_reg_field::type_id::create("run_length_bit_flip");

  // Configure each field (parent, size, lsb_pos, access, volatile, reset, has_reset, is_rand, individually_accessible)
  this.run_length_bit_flip.configure  (this, 32,  0, "RO", 0,  32'h0, 1, 0, 1);

endfunction : build
  

endclass : reg_run_length_bit_flip