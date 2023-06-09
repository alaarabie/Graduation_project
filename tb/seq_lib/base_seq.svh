class base_seq extends  uvm_sequence #(uvm_sequence_item);

  `uvm_object_utils(base_seq)

  rf_reg_block rf_rb;

  env_cfg m_cfg;

  virtual system_if sys_if;

  // Properties used by the various register access methods:
  rand uvm_reg_data_t data;  // For passing data
  uvm_status_e status;       // Returning access status

  function new(string name = "");
    super.new(name);
  endfunction : new

  task body();
    if(m_cfg == null) begin
      `uvm_fatal(get_full_name(), "env_config is null")
    end
    rf_rb = m_cfg.rf_rb;

  endtask : body

  task activate_reset(string parent);
    `uvm_info(parent, "ENTER RESET MODE", UVM_MEDIUM)
      sys_if.res_n  <= 1'b0;
      #500ns;
      @(posedge sys_if.clk) 
      sys_if.res_n <= 1'b1;
    `uvm_info(parent, "EXIT RESET MODE", UVM_MEDIUM)
  endtask : activate_reset

endclass : base_seq


