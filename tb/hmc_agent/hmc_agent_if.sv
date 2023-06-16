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
hmc_pkt_item null_FLIT_item;
bit vif_request_packet[FPW][] ;
bit vif_null_FLITS[FPW][] ;
bit [3:0] LNG ;
bit [DWIDTH-1:0] null_packed_response ;
bit [(9*FLIT_SIZE)-1:0] req_packed_response ;
int LNG_int ; 
bit j,k,z,y,a ; // y is a signal to know that all of the response is sent @ y=1
bit is_TS1 ;
int req_pos[4] ;
int null_pos[4] ;
bit req_finish[4] ;

task send_to_DUT(bit current_response_packet[],hmc_pkt_item response_pkt_item,bit[3:0] l);
    //bit [LNG-1:0] packed_response ;   
    {<<bit{response_packet}} = current_response_packet;
    LNG = response_pkt_item.length;
    if(l==4'b1)
     begin
        null_packed_response ='b0 ;
        req_packed_response='b0 ;    	
     end
    // LNG_int = int'(LNG);
    // bit [LNG-1:0] packed_response ;

	j=1 ;

	if(LNG==4'b0)
	 begin
	    null_packed_response[((FLIT_SIZE*(l-1))+FLIT_SIZE-1)-:FLIT_SIZE] = { << { response_packet }}; 
	    phy_data_rx_phy2link[((FLIT_SIZE*(l-1))+FLIT_SIZE-1)-:FLIT_SIZE] = null_packed_response[((FLIT_SIZE*(l-1))+FLIT_SIZE-1)-:FLIT_SIZE] ;
	 end		
		//LNG = response_pkt_item.length;
		//assert (response_pkt_item.pack(response_packet)); // call do_pack
	    //response_packet = packet ;
		//LNG = response_packet[10:7];
		// if(LNG==4'b1)
		//  begin
		     //phy_data_rx_phy2link = {response_packet,((LNG-FPW)*FLIT_SIZE)'b0} ;	

	     
     else if(LNG!=0)
      begin
        int b ;
        int s ;
        s=1 ; 
        y=0 ;
	    for(bit [3:0] m=1; m<=LNG-1; m++)
	     begin
	        req_packed_response[((FLIT_SIZE*(m-1))+FLIT_SIZE-1)-:FLIT_SIZE]= { << { response_packet }}; 		
	     end
         
        for(b=0; b<=4-l; b++)
         begin
            phy_data_rx_phy2link[FLIT_SIZE-1+(FLIT_SIZE*(l+b)) -: (FLIT_SIZE)] = req_packed_response[FLIT_SIZE-1+(FLIT_SIZE*(s-1)) -: (FLIT_SIZE)];
            LNG = LNG-4'b1 ;
            s=s+1 ;
            if (LNG<=4'b0)
             begin
                y=1 ;                           
                break ;
             end                                   	
         end
        @(posedge clk) ;
        b=0 ;
        while(LNG>4'b0)  
         begin
            if (LNG<=4'b0)
             begin
                y=1 ;                           
                break ;
             end
                        
            if (l+b>4)
             begin
                b=0 ;
                @(posedge clk) ;    
             end
            phy_data_rx_phy2link[FLIT_SIZE-1+(FLIT_SIZE*b) -: (FLIT_SIZE)] = req_packed_response[FLIT_SIZE-1+(FLIT_SIZE*(s-1)) -: (FLIT_SIZE)];
            LNG = LNG-4'b1 ;
            b=b+1 ;
            s=s+1 ;
         end

         if (LNG<=4'b0)
          begin
            y=1 ;            
          end                      
      end        

	    //  if((l+LNG-1)<=(FPW-1))
	    //   begin
	    //     phy_data_rx_phy2link[(l+LNG)*(FLIT_SIZE)-1-:(LNG*FLIT_SIZE)] = req_packed_response[(LNG*FLIT_SIZE)-1 -:(LNG*FLIT_SIZE)];      			
	    //     y=1 ;
	    //   end
	    //   else if((l+LNG-1)>(FPW-1))
	    //    begin
	    //     phy_data_rx_phy2link[(FPW*FLIT_SIZE)-1-:((FPW-l)*(FLIT_SIZE))] = req_packed_response[((FPW-l)*(FLIT_SIZE))-1-:((FPW-l)*(FLIT_SIZE))];
	    //     y=0 ;
	    //     @(posedge clk) ;
        //     for(int i=0 ; i<=$floor(LNG/FPW)-1;i++)
	    //      begin
		//       	if(i>$floor(LNG/FPW)-1)
		//       	 begin
		//       		break ;
		//       	 end
        //         else if((i==$floor(LNG/FPW)-1)&&((LNG%FPW)!=0))
        //          begin
        //             phy_data_rx_phy2link[((LNG%FPW)*(FLIT_SIZE))-1-:((LNG%FPW)*(FLIT_SIZE))] = req_packed_response[((LNG%FPW)*(FLIT_SIZE))+((FPW-l)*(FLIT_SIZE))+i*(FPW*FLIT_SIZE)-1 -:((LNG%FPW)*(FLIT_SIZE))];                   	
        //             y=1 ;
        //          end
        //         else if((i==$floor(LNG/FPW)-1)&&((LNG%FPW)==0))
        //          begin
        //             phy_data_rx_phy2link = req_packed_response[((FPW-l)*(FLIT_SIZE))+(i+1)*(FPW*FLIT_SIZE)-1-:(FPW*FLIT_SIZE)];                   	
        //             y=1 ;
        //          end                 
        //         else if (i<$floor(LNG/FPW)-1)
        //          begin
        //             phy_data_rx_phy2link = req_packed_response[((FPW-l)*(FLIT_SIZE))+(i+1)*(FPW*FLIT_SIZE)-1-:(FPW*FLIT_SIZE)];
        //             @(posedge clk) ;
        //          end   
	    //   	 end	          			
	    //    end     		

            // [((LNG%FPW)*(FLIT_SIZE))+((FPW-l)*(FLIT_SIZE))+i*(FPW*FLIT_SIZE)-1:((FPW-l)*(FLIT_SIZE))+i*(FPW*FLIT_SIZE)]


endtask : send_to_DUT

task run();
   `uvm_info("HMC_IF", "Line 166", UVM_MEDIUM)
	 @(posedge clk)
	 	if (j==1) begin
	 		response_item=hmc_pkt_item::type_id::create("response_item") ;
	 		assert (response_item.unpack(response_packet));
	        proxy.notify_res_transaction(response_item) ;	
	        j=0 ;
               `uvm_info("HMC_IF", "Line 174", UVM_MEDIUM)
	 	end
	 	else if ((k==1)&&(z==1)&&(is_TS1==1'b0)) begin
	 		for(int i=1; i<=4; i++)
	 		 begin
	 		 	if(req_finish[i-1]==1)
	 		 	 begin
			 		request_pkt_item=hmc_pkt_item::type_id::create("request_pkt_item") ;	 		
			 		assert (request_pkt_item.unpack(vif_request_packet[i-1]));
		            proxy.notify_req_transaction(request_pkt_item) ;
		            k=0 ;
		            z=0 ;			 		 		
	 		 	 end 			
	 		 end
                `uvm_info("HMC_IF", "Line 188", UVM_MEDIUM)
	 	end

	 	else if ((k==0)&&(is_TS1==1'b0)&&(a==1))
	 	 begin
	 	 	for(int i=1; i<=4; i++)
	 	 	 begin
	 	 	 	if(null_pos[i-1]==1)
	 	 	 	 begin
				 	null_FLIT_item=hmc_pkt_item::type_id::create("null_FLIT_item") ;	 		
			 		assert (null_FLIT_item.unpack(vif_null_FLITS[i-1]));
		            proxy.notify_req_transaction(null_FLIT_item) ;	 	 	 		
	 	 	 	 end	 	 		
	 	 	 end 	     	
	 	 end
       `uvm_info("HMC_IF", "Line 202", UVM_MEDIUM)
endtask : run


endinterface : hmc_agent_if