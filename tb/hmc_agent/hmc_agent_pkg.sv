package hmc_agent_pkg ;
	import uvm_pkg::*;
	`include "uvm_macros.svh"
import cmd_pkg::*;

typedef enum {
	RESET,
	POWER_DOWN,
	INIT,
	PRBS,
	NULL_FLITS,
	TS1,
	NULL_FLITS_2,
	INITIAL_TRETS,
	LINK_UP,
	START_RETRY_INIT,
	CLEAR_RETRY,
	SEND_RETRY_PACKETS
} init_state_t;

typedef enum {
	REQUESTER,
	RESPONDER
} link_type_t;

	`include "hmc_agent_config.svh"
	`include "hmc_link_status.svh"
	`include "hmc_status.svh"
	`include "hmc_cdr.svh"
	`include "hmc_retry_buffer.svh"
	`include "hmc_token_handler.svh"

	`include "hmc_agent_base_driver.svh"
	`include "hmc_agent_driver.svh"
	`include "hmc_agent_monitor.svh"
	`include "hmc_agent_sequencer.svh"	
	`include "hmc_agent.svh"	


endpackage : hmc_agent_pkg