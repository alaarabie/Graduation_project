class reg_poisoned_packets extends  uvm_reg;

  `uvm_object_utils(reg_poisoned_packets)

  rand uvm_reg_field  poisoned_packets;


function new(string name = "");
  super.new(name,64,UVM_NO_COVERAGE);
endfunction : new

virtual function void build();
  
  // Create object instance for each field
  this.poisoned_packets  = uvm_reg_field::type_id::create("poisoned_packets");

  // Configure each field (parent, size, lsb_pos, access, volatile, reset, has_reset, is_rand, individually_accessible)
  this.poisoned_packets.configure  (this, 64,  0, "RO", 0,  64'h0, 1, 0, 1);

endfunction : build
  

endclass : reg_poisoned_packets