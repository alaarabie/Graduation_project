class rf_reset_seq extends  base_seq;

  `uvm_object_utils(rf_reset_seq)

  uvm_reg         hmc_regs[$];
  uvm_reg_data_t  ref_data;

  extern function new (string name = "");
  extern task body();

endclass : rf_reset_seq


function rf_reset_seq::new(string name = "");
  super.new(name);
endfunction : new

task rf_reset_seq::body();
  super.body();

  rf_rb.get_registers(hmc_regs);

  // Read back reset values in random order
  hmc_regs.shuffle();
  foreach(hmc_regs[i]) begin
    ref_data = hmc_regs[i].get_reset();
    hmc_regs[i].read(status, data, .parent(this));
    if(ref_data != data) begin
      `uvm_error("RF_RESET_SEQ", $sformatf("Reset read error for %s: Expected: %0h Actual: %0h", hmc_regs[i].get_name(), ref_data, data))
    end
  end

endtask : body