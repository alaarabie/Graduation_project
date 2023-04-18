package hmc_agent_pkg ;
	import uvm_pkg::*;
	`include "uvm_macros.svh"

	`include "hmc_pkt_item.sv"

    typedef uvm_sequencer #(hmc_pkt_item) sequencer_hmc_agent ;

	`include "hmc_agent_config.sv"
	`include "driver_hmc_agent.sv"
	`include "hmc_agent_if.sv"
	`include "monitor_hmc_agent.sv"
	`include "hmc_agent.sv"	

	`include "base_seq.sv"			
	`include "hmc_vseq.sv"
	`include "hmc_state_seq.sv"	
	`include "hmc_initialization_seq.sv"
	`include "hmc_response_seq.sv"



endpackage : hmc_agent_pkg