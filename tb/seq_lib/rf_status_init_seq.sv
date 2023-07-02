class rf_status_init_seq extends  base_seq;

  `uvm_object_utils(rf_status_init_seq)

  extern function new (string name = "");
  extern task body();

endclass : rf_status_init_seq


function rf_status_init_seq::new(string name = "");
  super.new(name);
endfunction : new

task rf_status_init_seq::body();
  super.body();
  rf_rb.m_reg_status_init.read(status, data, .parent(this));

endtask : body