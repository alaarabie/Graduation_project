class rf_driver #(HMC_RF_WWIDTH = 64,
                  HMC_RF_RWIDTH = 64,
                  HMC_RF_AWIDTH = 4) extends  uvm_driver #(rf_item);
  
  `uvm_object_param_utils(rf_driver #(HMC_RF_WWIDTH, HMC_RF_RWIDTH, HMC_RF_AWIDTH))

  virtual rf_if #(HMC_RF_WWIDTH, HMC_RF_RWIDTH, HMC_RF_AWIDTH) vif;
  rf_agent_cfg #(HMC_RF_WWIDTH, HMC_RF_RWIDTH, HMC_RF_AWIDTH) cfg;

  extern function new(string name, uvm_component parent);
  extern function void build_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);

endclass : rf_driver

function rf_driver::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new

function void rf_driver::build_phase(uvm_phase phase);
  super.build_phase(phase);
  if(!uvm_config_db #(rf_agent_cfg#(HMC_RF_WWIDTH, HMC_RF_RWIDTH, HMC_RF_AWIDTH))::get(this, "","rf_agent_cfg", cfg))
    `uvm_fatal("RF_DRIVER_CONFIG_LOAD", "Failed to get rf_agent_cfg from uvm_config_db")
  vif = cfg.vif;
endfunction : build_phase

task rf_driver::run_phase(uvm_phase phase);

  rf_item   m_item;

  forever begin
    seq_item_port.get_next_item(m_item);

      if(vif.res_n) begin

        @(posedge vif.clk)

        vif.rf_address <=  m_item.addr;

        if(m_item.write_flag) begin

          vif.rf_write_data <= m_item.data;
          vif.rf_write_enable <= 1;

          wait(vif.rf_access_complete);

          vif.rf_write_enable <= 0;

        end else begin
          vif.rf_read_enable <= 1;

          wait(vif.rf_access_complete);

          m_item.data = vif.rf_read_data;
          vif.rf_read_enable <= 0;

        end
      end

    seq_item_port.item_done();
  end
  
endtask : run_phase