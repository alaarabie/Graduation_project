package hmc_agent_pkg ;
	import uvm_pkg::*;
	`include "uvm_macros.svh"
import cmd_pkg::*;


	`include "hmc_agent_config.sv"
	`include "driver_hmc_agent.sv"
	`include "monitor_hmc_agent.sv"
	`include "sequencer_hmc_agent.sv"	
	`include "hmc_agent.sv"	


endpackage : hmc_agent_pkg