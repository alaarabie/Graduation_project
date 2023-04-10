class rf_control_sleep_seq extends  base_seq;

  `uvm_object_utils(rf_control_sleep_seq)

  extern function new (string name = "");
  extern task body();

endclass : rf_control_sleep_seq


function rf_control_sleep_seq::new(string name = "");
  super.new(name);
endfunction : new

task rf_control_sleep_seq::body();
  super.body();

  rf_rb.m_reg_control.set_hmc_sleep.set(1'h1);
  rf_rb.m_reg_control.update(status, .path(UVM_FRONTDOOR), .parent(this));

endtask : body