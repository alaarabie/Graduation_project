class base_seq extends  uvm_sequence #(uvm_sequence_item);

  `uvm_object_utils(base_seq)

  rf_reg_block rf_rb;

  env_cfg m_cfg;

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

endclass : base_seq


