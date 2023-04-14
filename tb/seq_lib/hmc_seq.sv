class hmc_seq extends  base_seq;

  bit [1:0] tx_state;

  `uvm_object_utils(hmc_seq)

  extern function new (string name = "");
  extern task body();

endclass : hmc_seq


function hmc_seq::new(string name = "");
  super.new(name);
endfunction : new

task hmc_seq::body();
  super.body();

  tx_state = rf_rb.m_reg_status_init.status_init_tx_init_state.get();

  

endtask : body