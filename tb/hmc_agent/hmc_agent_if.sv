interface hmc_agent_if #(NUM_LANES = 8)	();

	logic REFCLKP; // Link Reference clock input
	logic REFCLKN;

	logic [1:0] REFCLK_BOOT; // 00 -> 125 MHz, 01 -> 156.25 MHz, 10 -> 166.67 MHz

	logic P_RST_N; // input

	//-- Differential pairs
	logic [NUM_LANES - 1 : 0]	RXP; // input
	logic [NUM_LANES - 1 : 0]	RXN; // input

	logic [NUM_LANES - 1 : 0]	TXP; // output
	logic [NUM_LANES - 1 : 0]	TXN; // output

	logic RXPS; // Power-reduction input
	logic TXPS; // Power-reduction output

	logic FERR_N; // Fatal error indicator, output

endinterface : hmc_agent_if