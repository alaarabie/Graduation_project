class base_test extends  uvm_test;
  
  `uvm_component_utils(base_test)

  virtual system_if sys_if;
  
  axi_config_t m_axi_cfg;
  virtual axi_interface_t m_axi_if;

  hmc_agent_config_t m_hmc_cfg;
  virtual hmc_agent_if_t m_hmc_if;  
  
  rf_agent_cfg m_rf_cfg;
  virtual rf_if m_rf_if;
  rf_reg_block rf_rb;

  env_cfg m_env_cfg;
  env m_env;
  

  function new(string name, uvm_component parent);
    super.new(name,parent);
  endfunction : new


  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    m_env_cfg = env_cfg::type_id::create ("m_env_cfg");
    m_hmc_cfg = hmc_agent_config_t::type_id::create("m_hmc_cfg") ;
    m_axi_cfg = axi_config_t::type_id::create("m_axi_cfg") ;
    rf_rb = rf_reg_block::type_id::create("rf_rb") ; 
    rf_rb.build() ;
    m_rf_cfg = rf_agent_cfg::type_id::create("m_rf_cfg") ;  

    if(!uvm_config_db #(hmc_agent_if_t)::get(this, "","vif",  m_hmc_cfg.vif))
    `uvm_fatal("TEST", "Failed to get hmc_if")
    if(!uvm_config_db #(hmc_agent_if_t)::get(this, "","int_vif",  m_hmc_cfg.int_vif))
    `uvm_fatal("TEST", "Failed to get int_vif")
    if(!uvm_config_db #(axi_interface_t)::get(this, "","AXI_IF",  m_axi_cfg.vif))
    `uvm_fatal("TEST", "Failed to get axi_if")
    if(!uvm_config_db #(virtual rf_if)::get(this, "","rf_if", m_rf_cfg.vif))
    `uvm_fatal("TEST", "Failed to get rf_if")

    if(!uvm_config_db #(virtual system_if)::get(this, "","system_if", sys_if))
    `uvm_fatal("TEST", "Failed to get system_if")

    m_hmc_cfg.active=UVM_ACTIVE ;

    m_rf_cfg.active=UVM_ACTIVE ;

    m_axi_cfg.agent_active=UVM_ACTIVE ;

    m_env_cfg.rf_rb=rf_rb ;
    m_env_cfg.m_hmc_agent_cfg=m_hmc_cfg ;
    m_env_cfg.m_rf_agent_cfg=m_rf_cfg ;
    m_env_cfg.m_axi_cfg=m_axi_cfg;

    uvm_config_db #(env_cfg)::set(this, "*", "m_env_cfg", m_env_cfg);

    m_env = env::type_id::create("m_env",this);
  endfunction : build_phase

  task run_phase(uvm_phase phase);
    sys_if.res_n  <= 1'b0;
    #500ns;
    @(posedge sys_if.clk) 
    sys_if.res_n <= 1'b1;    
  endtask : run_phase


  function void set_seqs(vseq_base seq);
    seq.m_cfg = m_env_cfg;
    seq.sys_if = sys_if;
  endfunction

  // Print Testbench structure and factory contents
  function void start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    if (uvm_report_enabled(UVM_MEDIUM)) begin
      this.print();
      factory.print();
      `uvm_info("BASE_TEST_end_of_elaboration_phase()", $sformatf("Printing hmc_config: %s",m_hmc_cfg.sprint()), UVM_NONE)
    end
  endfunction : start_of_simulation_phase


endclass : base_test