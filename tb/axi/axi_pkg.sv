`include "axi_interface.sv"
 


package axi_pkg;
`include "uvm_macros.svh"
import uvm_pkg::*;

`include "axi_monitor.sv"
`include "valid_data.sv"
`include "axi_sequencer.sv"
`include "axi_monitor.sv"
`include "axi_env.sv"
`include "axi_driver.sv"
`include "axi_config.sv"
`include "axi_agent.sv" 

endpackage : axi_pkg
