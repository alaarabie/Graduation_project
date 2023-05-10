class rf_status_init_mirror_seq extends  base_seq;

  `uvm_object_utils(rf_status_init_mirror_seq)

  extern function new (string name = "");
  extern task body();

endclass : rf_status_init_mirror_seq


function rf_status_init_mirror_seq::new(string name = "");
  super.new(name);
endfunction : new

task rf_status_init_mirror_seq::body();
  super.body();

  // will continuously perform read operations to mirror the hardware into the register model
  //rf_rb.m_reg_status_init.mirror(status, .path(UVM_FRONTDOOR), .parent(this));

  rf_rb.m_reg_status_init.read(status, data, .parent(this));

endtask : body