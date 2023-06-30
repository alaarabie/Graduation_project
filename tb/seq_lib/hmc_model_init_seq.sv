class hmc_model_init_seq extends base_seq;

  function new (string name = "");
    super.new(name);
  endfunction : new

  `uvm_object_utils(hmc_model_init_seq)

  task body() ;
    super.body();

    `uvm_info(get_type_name(), $sformatf("HMC_Token Count is: %d", m_cfg.m_hmc_agent_cfg.hmc_tokens), UVM_NONE)
    `uvm_info(get_type_name(), $sformatf("RX_Token Count is: %d", m_cfg.m_hmc_agent_cfg.rx_tokens), UVM_NONE)
  endtask : body

endclass : hmc_model_init_seq