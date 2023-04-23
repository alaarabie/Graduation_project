interface hmc_agent_if #(DWIDTH = 512 , 
						 NUM_LANES = 8 , 
						 FPW = 4,
						 FLIT_SIZE = 128
						 )
						(
	                  	input clk, 
                  		input res_n
						);

logic  [DWIDTH-1:0]           phy_data_tx_link2phy;// input  //Connect!
logic  [DWIDTH-1:0]           phy_data_rx_phy2link;// output //Connect!
logic  [NUM_LANES-1:0]        phy_bit_slip;        // input //Must be connected if DETECT_LANE_POLARITY==1 AND CTRL_LANE_POLARITY=0
logic  [NUM_LANES-1:0]        phy_lane_polarity ;  // input //All 0 if CTRL_LANE_POLARITY=1
logic                         phy_tx_ready ;       // output //Optional information to RF
logic                         phy_rx_ready ;       // output //Release RX descrambler reset when PHY ready
logic                         phy_init_cont_set ;  // input //Can be used to release transceiver reset if used
logic                         P_RST_N ;			   // input
logic                         LXRXPS ;			   // input
logic                         LXTXPS ;			   // output
logic                         FERR_N ;			   // output

monitor_hmc_agent proxy ;
hmc_pkt_item response_packet ;
bit vif_request_packet[] ;
bit [3:0] LNG ;
shortint j,k,z ;

task send_to_DUT(hmc_pkt_item packet);
    response_packet = packet ;
	LNG = response_packet[10:7] ;
	j=1 ;
	if(LNG<=FPW)
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

task run();
	always @(posedge clk)
	 begin
	 	if (j==1) begin
	        proxy.notify_res_transaction(response_packet) ;	
	        j=0 ;
	 	end
	 	
	 	else if ((k==1)&&(z==1)) begin
            proxy.notify_req_transaction(vif_request_packet) ;
            k=0 ;
            z=0 ;	
	 	end
	 
	 end
endtask : run

endinterface : hmc_agent_if