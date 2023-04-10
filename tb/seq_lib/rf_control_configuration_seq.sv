class rf_control_configuration_seq extends  base_seq;

  `uvm_object_utils(rf_control_configuration_seq)

  extern function new (string name = "");
  extern task body();

endclass : rf_control_configuration_seq


function rf_control_configuration_seq::new(string name = "");
  super.new(name);
endfunction : new

task rf_control_configuration_seq::body();
  super.body();

  rf_rb.m_reg_control.scrambler_disable.set(1'h1);
  rf_rb.m_reg_control.hmc_init_cont_set.set(1'h1);
  rf_rb.m_reg_control.update(status, .path(UVM_FRONTDOOR), .parent(this));

endtask : body