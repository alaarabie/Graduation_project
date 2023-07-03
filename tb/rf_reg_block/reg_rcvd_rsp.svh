class reg_rcvd_rsp extends  uvm_reg;

  `uvm_object_utils(reg_rcvd_rsp)

  rand uvm_reg_field  rcvd_rsp;


function new(string name = "");
  super.new(name,64,UVM_NO_COVERAGE);
endfunction : new

virtual function void build();
  
  // Create object instance for each field
  this.rcvd_rsp  = uvm_reg_field::type_id::create("rcvd_rsp");

  // Configure each field (parent, size, lsb_pos, access, volatile, reset, has_reset, is_rand, individually_accessible)
  this.rcvd_rsp.configure  (this, 64,  0, "RO", 0,  64'h0, 1, 0, 1);

endfunction : build;
  

endclass : reg_rcvd_rsp