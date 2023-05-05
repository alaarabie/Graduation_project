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
  string vif_pins;

  forever begin
    seq_item_port.get_next_item(m_item);
      if(!vif.res_n) begin
        vif.rf_read_enable = 1'b0;
        vif.rf_write_enable = 1'b0;
        vif.rf_address = 'b0;
        vif.rf_write_data = 'b0;
      end
      wait(vif.res_n)

        @(posedge vif.clk)

        if(m_item.write_flag) begin
          vif.rf_address =  m_item.addr;
          vif.rf_write_data = m_item.data;
          vif.rf_write_enable = 1;

          @(posedge vif.clk)
          wait(vif.rf_access_complete);
          
          $sformat(vif_pins, "addr\t%0h\n write data\t%0h\n read data\t%0h\n write enable\t%0b\n access_complete\t%0b\n",
                   vif.rf_address, vif.rf_write_data, vif.rf_read_data, vif.rf_write_enable,vif.rf_access_complete);     
          `uvm_info("RF_DRIVER",{"\nvif pins:\n",vif_pins},UVM_HIGH)

          vif.rf_write_enable = 0;
          #1; // next clock -> next sequence

        end else begin
          vif.rf_address =  m_item.addr;      
          vif.rf_read_enable = 1;

          @(posedge vif.clk)  
          wait(vif.rf_access_complete);

          m_item.data = vif.rf_read_data;
          $sformat(vif_pins, "addr\t%0h\n write data\t%0h\n read data\t%0h\n Read enable\t%0b\n access_complete\t%0b\n",
                   vif.rf_address, vif.rf_write_data, vif.rf_read_data, vif.rf_read_enable,vif.rf_access_complete);     
          `uvm_info("RF_DRIVER",{"\nvif pins:\n",vif_pins},UVM_HIGH)

          vif.rf_read_enable = 0;
          #1; // next clock -> next sequence

        end

    seq_item_port.item_done();
  end
  
endtask : run_phase