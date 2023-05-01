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

		import uvm_pkg::*;
	`include "uvm_macros.svh"
    import cmd_pkg::*;
    import hmc_agent_pkg::* ;
    import rf_reg_block_pkg::* ;    
    import rf_agent_pkg::* ;
    import tb_params_pkg::* ;
    import tb_pkg::*;

monitor_hmc_agent proxy ;
hmc_pkt_item  response_item;
bit response_packet[] ;
hmc_pkt_item  request_pkt_item;
bit vif_request_packet[] ;
bit [3:0] LNG ;
bit [(9*FLIT_SIZE)-1:0] packed_response ;
int LNG_int ; 
shortint j,k,z ;

task send_to_DUT(bit current_response_packet[],hmc_pkt_item response_pkt_item);
    //bit [LNG-1:0] packed_response ;   
    {<<bit{response_packet}} = current_response_packet;
    LNG = response_pkt_item.length;
    packed_response = 'b0 ;
    // LNG_int = int'(LNG);
    // bit [LNG-1:0] packed_response ; 
    packed_response = { << { response_packet }}; 
	
	//LNG = response_pkt_item.length;
	//assert (response_pkt_item.pack(response_packet)); // call do_pack
    
    //response_packet = packet ;
	//LNG = response_packet[10:7];

	j=1 ;
	
	// if(LNG==4'b1)
	//  begin
	     //phy_data_rx_phy2link = {response_packet,((LNG-FPW)*FLIT_SIZE)'b0} ;	
	     
	phy_data_rx_phy2link = packed_response[DWIDTH-1:0] ;	

	//  end

	// if(LNG==4'b10)
	//  begin
	//      //phy_data_rx_phy2link = {response_packet,((LNG-FPW)*FLIT_SIZE)'b0} ;	
	//      phy_data_rx_phy2link = {packed_response,{((FPW-2)*FLIT_SIZE){1'b0}}} ;	     
	//  end

	// if(LNG==4'b11)
	//  begin
	//      //phy_data_rx_phy2link = {response_packet,((LNG-FPW)*FLIT_SIZE)'b0} ;	
	//      phy_data_rx_phy2link = {packed_response,{((FPW-3)*FLIT_SIZE){1'b0}}} ;	     
	//  end

	// if(LNG==4'b100)
	//  begin
	//      //phy_data_rx_phy2link = {response_packet,((LNG-FPW)*FLIT_SIZE)'b0} ;	
	//      phy_data_rx_phy2link = packed_response ;	     
	//  end

	 if(LNG>FPW)
	  begin
	     shortint i ;
	     for(i=$ceil(LNG/FPW) ; i>=0;i--)
	      begin
	        @(posedge clk) ;
	        phy_data_rx_phy2link = packed_response[(DWIDTH*i) +: DWIDTH] ; 
	        //:(DWIDTH-1)+(DWIDTH*i)] ;
	      end
	     //@(posedge clk) ;	      
	     //phy_data_rx_phy2link = {response_packet[(DWIDTH*i):(DWIDTH-1)+(DWIDTH*i)],((FPW-(LNG%FPW))*FLIT_SIZE)'b0} ;
	     //phy_data_rx_phy2link = {packed_response[(DWIDTH*i):(DWIDTH-1)+(DWIDTH*i)],{((FPW-(LNG%FPW))*FLIT_SIZE){1'b0}}} ;

	  end

endtask : send_to_DUT

task run();
	@(posedge clk)
	 	if (j==1) begin
	 		assert (response_item.unpack(response_packet));
	        proxy.notify_res_transaction(response_item) ;	
	        j=0 ;
	 	end
	 	
	 	else if ((k==1)&&(z==1)) begin
	 		assert (request_pkt_item.unpack(vif_request_packet));
            proxy.notify_req_transaction(request_pkt_item) ;
            k=0 ;
            z=0 ;	
	 	end
endtask : run


endinterface : hmc_agent_if