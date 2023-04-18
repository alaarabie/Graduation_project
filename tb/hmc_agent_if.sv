interface hmc_agent_if

import hmc_pkg::* ;

wire  [DWIDTH-1:0]           phy_data_tx_link2phy,//Connect!
wire  [DWIDTH-1:0]           phy_data_rx_phy2link,//Connect!
wire  [NUM_LANES-1:0]        phy_bit_slip,       //Must be connected if DETECT_LANE_POLARITY==1 AND CTRL_LANE_POLARITY=0
wire  [NUM_LANES-1:0]        phy_lane_polarity,  //All 0 if CTRL_LANE_POLARITY=1
wire                         phy_tx_ready,       //Optional information to RF
wire                         phy_rx_ready,       //Release RX descrambler reset when PHY ready
wire                         phy_init_cont_set,  //Can be used to release transceiver reset if used
wire                         P_RST_N,
wire                         LXRXPS,
wire                         LXTXPS,
wire                         FERR_N,

initial begin
	clk = 0;
	fork 
		forever begin
			#4.27 ;
			clk=~clk ;
		end
	join_none
end

endinterface : hmc_agent_if