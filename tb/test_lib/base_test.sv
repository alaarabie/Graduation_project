class base_test extends  uvm_test;
  `uvm_component_utils(base_test)
  
  // handles
  env m_env;
  
  virtual rf_if_t m_rf_if;
  env_cfg cfg;

  extern function new(string name, uvm_component parent);
  extern function void build_phase(uvm_phase phase);
  extern function void start_of_simulation_phase(uvm_phase phase);
  
endclass : base_test


// Constructor
function base_test::new(string name, uvm_component parent);
  super.new(name,parent);
endfunction : new


// Build Phase
function void base_test::build_phase(uvm_phase phase);
  super.build_phase(phase);


  if(!uvm_config_db #(virtual rf_if_t)::get(this, "","m_rf_if", m_rf_if))
  `uvm_fatal("TEST", "Failed to get rf_if")

  cfg = new("cfg");
      
  uvm_config_db #(env_cfg)::set(this, "m_env*", "cfg", cfg);

  m_env = env::type_id::create("m_env",this);
endfunction : build_phase


// Print Testbench structure and factory contents
function void base_test::start_of_simulation_phase(uvm_phase phase);
  
  super.start_of_simulation_phase(phase);

  if (uvm_report_enabled(UVM_MEDIUM)) begin
    this.print();
    factory.print();
  end

endfunction : start_of_simulation_phase