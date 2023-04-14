class rf_monitor #(HMC_RF_WWIDTH = 64,
                  HMC_RF_RWIDTH = 64,
                  HMC_RF_AWIDTH = 4) extends uvm_component;
  
  `uvm_component_param_utils(rf_monitor #(HMC_RF_WWIDTH, HMC_RF_RWIDTH, HMC_RF_AWIDTH))

  virtual rf_bfm #(HMC_RF_WWIDTH, HMC_RF_RWIDTH, HMC_RF_AWIDTH) vif;
  rf_agent_cfg #(HMC_RF_WWIDTH, HMC_RF_RWIDTH, HMC_RF_AWIDTH) cfg;
  uvm_analysis_port #(rf_item) rf_ap;

  extern function new(string name, uvm_component parent);
  extern function void build_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);

endclass : rf_monitor


function rf_monitor::new(string name, uvm_component parent);
  super.new(name,parent);
endfunction : new


function void rf_monitor::build_phase(uvm_phase phase);
  super.build_phase(phase);
  if(!uvm_config_db #(rf_agent_cfg#(HMC_RF_WWIDTH, HMC_RF_RWIDTH, HMC_RF_AWIDTH))::get(this, "","rf_agent_cfg", cfg))
    `uvm_fatal("RF_MONITOR_CONFIG_LOAD", "Failed to get rf_agent_cfg from uvm_config_db")
  vif = cfg.vif;

  rf_ap = new("rf_ap",this);
  
endfunction : build_phase

task rf_monitor::run_phase(uvm_phase phase);
    rf_item m_item;

    forever begin
      @(posedge vif.clk);

      if(vif.res_n & (vif.rf_read_enable | vif.rf_write_enable)) begin

        m_item = rf_item::type_id::create("m_item");

        m_item.addr = vif.rf_address;
        m_item.write_flag = vif.rf_write_enable;

        wait(vif.rf_access_complete);

        if(vif.rf_write_enable)
          m_item.data = vif.rf_write_data;
        else
          m_item.data = vif.rf_read_data;
      end
      rf_ap.write(m_item);
    end

endtask: run_phase
