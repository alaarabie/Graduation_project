class rf_agent_cfg extends uvm_object;

  `uvm_object_utils(rf_agent_cfg)

   virtual rf_if vif;
   uvm_active_passive_enum     active = UVM_ACTIVE;
   bit has_functional_coverage = 0;

  function new(string name = "");
    super.new(name);
  endfunction : new

endclass : rf_agent_cfg

