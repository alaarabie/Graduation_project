class rf_driver #(HMC_RF_WWIDTH = 64,
                  HMC_RF_RWIDTH = 64,
                  HMC_RF_AWIDTH = 4) extends  uvm_driver #(rf_item);
  
  `uvm_component_param_utils(rf_driver #(HMC_RF_WWIDTH, HMC_RF_RWIDTH, HMC_RF_AWIDTH))

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
  if(!uvm_config_db #(rf_agent_cfg#(HMC_RF_WWIDTH, HMC_RF_RWIDTH, HMC_RF_AWIDTH))::get(this, "","rf_agent_cfg_t", cfg))
    `uvm_fatal("RF_DRIVER_CONFIG_LOAD", "Failed to get rf_agent_cfg from uvm_config_db")
  vif = cfg.vif;
endfunction : build_phase

task rf_driver::run_phase(uvm_phase phase);

  rf_item   m_item;
  //string item_str;
  string vif_pins;

  forever begin
    seq_item_port.get_next_item(m_item);
    //item_str = m_item.convert2string();
    //`uvm_info("RF_DRIVER",item_str,UVM_MEDIUM)

      if(!vif.res_n) begin
        vif.rf_read_enable = 1'b0;
        vif.rf_write_enable = 1'b0;
        vif.rf_address = 'b0;
        vif.rf_write_data = 'b0;
      end
      wait(vif.res_n)

        @(posedge vif.clk)

        vif.rf_address =  m_item.addr;

        if(m_item.write_flag) begin

          vif.rf_write_data = m_item.data;
          vif.rf_write_enable = 1;

          wait(vif.rf_access_complete);

          vif.rf_write_enable = 0;

        end else begin
          vif.rf_read_enable = 1;

          wait(vif.rf_access_complete);

          m_item.data = vif.rf_read_data;
          vif.rf_read_enable = 0;

        end
          $sformat(vif_pins, "addr\t%0h\n write data\t%0h\n read data\t%0h\n write_flag\t%0b\n access_complete\t%0b\n",vif.rf_address, vif.rf_write_data, vif.rf_read_data, vif.rf_write_enable,vif.rf_access_complete);     
          `uvm_info("RF_DRIVER",{"\nvif pins:\n",vif_pins},UVM_MEDIUM)
    seq_item_port.item_done();
  end
  
endtask : run_phase