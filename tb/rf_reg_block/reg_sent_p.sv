class reg_sent_p extends  uvm_reg;

  `uvm_object_utils(reg_sent_p)

  rand uvm_reg_field  sent_p;


function new(string name = "");
  super.new(name,64,UVM_NO_COVERAGE);
endfunction : new

virtual function void build();
  
  // Create object instance for each field
  this.sent_p  = uvm_reg_field::type_id::create("sent_p");

  // Configure each field (parent, size, lsb_pos, access, volatile, reset, has_reset, is_rand, individually_accessible)
  this.sent_p.configure  (this, 64,  0, "RO", 0,  64'h0, 1, 0, 1);

endfunction : build
  

endclass : reg_sent_p