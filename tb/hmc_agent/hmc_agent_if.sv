interface hmc_agent_if

import hmc_agent_pkg::* ;

logic  [DWIDTH-1:0]           phy_data_tx_link2phy; //Connect!
logic  [DWIDTH-1:0]           phy_data_rx_phy2link; //Connect!
logic  [NUM_LANES-1:0]        phy_bit_slip;        //Must be connected if DETECT_LANE_POLARITY==1 AND CTRL_LANE_POLARITY=0
logic  [NUM_LANES-1:0]        phy_lane_polarity ;  //All 0 if CTRL_LANE_POLARITY=1
logic                         phy_tx_ready ;       //Optional information to RF
logic                         phy_rx_ready ;       //Release RX descrambler reset when PHY ready
logic                         phy_init_cont_set ;  //Can be used to release transceiver reset if used
logic                         P_RST_N ;
logic                         LXRXPS ;
logic                         LXTXPS ;
logic                         FERR_N ;
bit                           clk ;

task send_to_DUT(hmc_pkt_item response_packet);
    bit [3:0] LNG ;
	LNG = response_packet[10:7] ;
	assert(LNG>FPW)
	 begin
	     phy_data_rx_phy2link = {response_packet[0:$],((LNG-FPW)*FLIT_SIZE)'b0} ;	
	 end

	 else
	  begin
	     shortint i ;
	     for(i=0 ; i<($floor(LNG/FPW));i++)
	      begin
	        @(posedge clk) ;
	        phy_data_rx_phy2link = response_packet[(DWIDTH*i):(DWIDTH-1)+(DWIDTH*i)] ;
	      end
	     @(posedge clk) ;	      
	     phy_data_rx_phy2link = {response_packet[(DWIDTH*i):(DWIDTH-1)+(DWIDTH*i)],((FPW-(LNG%FPW))*FLIT_SIZE)'b0} ;
	  end

endtask : send_to_DUT

initial begin
	clk = 0;
	fork 
		forever begin
			#(CLK_PERIOD/2) ;
			clk=~clk ;
		end
	join_none
end

endinterface : hmc_agent_if