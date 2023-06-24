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
bit response_packet[FPW][] ;
hmc_pkt_item  request_pkt_item;
hmc_pkt_item null_FLIT_item;
bit vif_request_packet[FPW][] ;
bit vif_null_FLITS[FPW][] ;
bit [3:0] LNG ;
bit [DWIDTH-1:0] null_packed_response ;
bit [(9*FLIT_SIZE)-1:0] req_packed_response ;
int LNG_int ; 
shortint y ; // y is a signal to know that all of the response is sent @ y=1
bit j[4],k[4],z[4],a[4] ;
bit [3:0] c ;
bit is_TS1 ;
int req_pos[4] ;
int null_pos[4] ;
bit req_finish[4] ;
bit p_TRET[4] ;
int null_before_TRET_count ;

task send_to_DUT(bit current_response_packet[],hmc_pkt_item response_pkt_item,bit[3:0] l);
    response_packet[l-1] = current_response_packet; 
	 `uvm_info("HMC_IF", $sformatf("response_packet array =%p",response_packet[l-1]),UVM_MEDIUM)    
    // {<<bit{response_packet}} = current_response_packet;
    LNG = response_pkt_item.length;
	 `uvm_info("HMC_IF", $sformatf("at L=%b ,LNG=%d",l,LNG),UVM_LOW)    
    c=l ;
    if(l==4'b1)
     begin
        null_packed_response ='b0 ;
        req_packed_response='b0 ;    	
     end
    // LNG_int = int'(LNG);
    // bit [LNG-1:0] packed_response ;

	`uvm_info("HMC_IF", $sformatf("p_TRET[%d]=%d",l-1,p_TRET[l-1]),UVM_LOW) 
	if(p_TRET[l-1]==1'b1)
	 begin
	 	if(null_before_TRET_count<4)
	 	 begin
	 	   `uvm_info("HMC_IF", $sformatf("null_before_TRET_count=%d",null_before_TRET_count),UVM_LOW) 	 	 	
	 	   phy_data_rx_phy2link[((FLIT_SIZE*(l-1))+FLIT_SIZE-1)-:FLIT_SIZE]= { << { response_packet[l-1] }}; 	
	 	   null_before_TRET_count=null_before_TRET_count+1 ;
	 	 end
	 	else if(l==4'b1)
	 	 begin
		   // phy_data_rx_phy2link[((FLIT_SIZE*(l-1))+FLIT_SIZE-1)-:FLIT_SIZE]= { << { response_packet[l-1] }}; 	   	
		   phy_data_rx_phy2link[((FLIT_SIZE*(l-1))+FLIT_SIZE-1)-:FLIT_SIZE]=128'h0 ;	 		
	 	 end
	 	else if(l==4'b10)
	 	 begin
		   // phy_data_rx_phy2link[((FLIT_SIZE*(l-1))+FLIT_SIZE-1)-:FLIT_SIZE]= { << { response_packet[l-1] }}; 	   	
		   phy_data_rx_phy2link[((FLIT_SIZE*(l-1))+FLIT_SIZE-1)-:FLIT_SIZE]=128'hffffffffffffffff ;	 		
	 	 end
	 	else if(l==4'b11)
	 	 begin
		   // phy_data_rx_phy2link[((FLIT_SIZE*(l-1))+FLIT_SIZE-1)-:FLIT_SIZE]= { << { response_packet[l-1] }}; 	   	
		   phy_data_rx_phy2link[((FLIT_SIZE*(l-1))+FLIT_SIZE-1)-:FLIT_SIZE]=128'hffffffffffffffffffffffffffffffff ;	 		
	 	 end	
	 	else if(l==4'b100)
	 	 begin
		   // phy_data_rx_phy2link[((FLIT_SIZE*(l-1))+FLIT_SIZE-1)-:FLIT_SIZE]= { << { response_packet[l-1] }}; 	   	
		   phy_data_rx_phy2link[((FLIT_SIZE*(l-1))+FLIT_SIZE-1)-:FLIT_SIZE]=128'h0 ;	 		
	 	 end		 	  	 
		j[l-1]=1'b1 ;
	 	`uvm_info("HMC_IF", $sformatf("phy_data_rx_phy2link=%h",phy_data_rx_phy2link),UVM_LOW)		
	 end

	else if(LNG==4'b0)
	 begin
	 	// if(p_TRET[l-1]==1'b0)
	 	//  begin
	   	null_packed_response[((FLIT_SIZE*(l-1))+FLIT_SIZE-1)-:FLIT_SIZE] = { << { response_packet[l-1] }}; 
	    	phy_data_rx_phy2link[((FLIT_SIZE*(l-1))+FLIT_SIZE-1)-:FLIT_SIZE] = null_packed_response[((FLIT_SIZE*(l-1))+FLIT_SIZE-1)-:FLIT_SIZE] ;
			j[l-1]=1'b1 ;
	 	 // end
	 end		

	     
     else if(LNG!=0)
      begin
        int b ;
        int s ;
        s=1 ; 
        y=0 ;
	    for(bit [3:0] m=4'b0; m<=LNG-4'b1; m++)
	     begin
	        req_packed_response[((FLIT_SIZE*m)+FLIT_SIZE-1)-:FLIT_SIZE]= { << { response_packet[l-1] }}; 		
	     end

    	 `uvm_info("HMC_IF", $sformatf("at L=%b ,req_packed_response=%b",l,req_packed_response),UVM_LOW)
         
        for(b=0; b<=4-l; b++)
         begin
            phy_data_rx_phy2link[FLIT_SIZE-1+(FLIT_SIZE*(l+b-1)) -: (FLIT_SIZE)] = req_packed_response[FLIT_SIZE-1+(FLIT_SIZE*(s-1)) -: (FLIT_SIZE)];
    	      `uvm_info("HMC_IF", $sformatf("at b=%d ,phy_data_rx_phy2link[%d:%d]=%b",b,FLIT_SIZE-1+(FLIT_SIZE*(l+b-1)),FLIT_SIZE*(l+b-1),phy_data_rx_phy2link[FLIT_SIZE-1+(FLIT_SIZE*(l+b-1)) -: (FLIT_SIZE)]),UVM_LOW)
            LNG = LNG-4'b1 ;
            s=s+1 ;
            if (LNG<=4'b0)
             begin
                y=1 ;                           
	         	 j[l-1]=1'b1 ;
                break ;
             end                                   	
         end

        if(LNG>4'b0)
         begin
        		@(posedge clk) ;
        		b=0 ;        			
         end

        while(LNG>4'b0)  
         begin            
            if (LNG<=4'b0)
             begin
                y=1 ;                           
                break ;
             end
                        
            if (b>4)
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
				j[l-1]=1'b1 ;
          end                      
      end        

     if(l==4'b100)
      begin
     	   @(posedge clk) ;
      end


endtask : send_to_DUT

task run();

	   @(posedge clk) ;

	 	for(int i=1; i<=4; i++)
	 	 begin
		 	if ((j[i-1]==1'b1)||(p_TRET[i-1]==1'b1)) 
		 	 begin
		 		response_item=hmc_pkt_item::type_id::create("response_item") ;		 	
			 	`uvm_info("HMC_IF", $sformatf("response_packet[%d] array =%p",i-1,response_packet[i-1]),UVM_LOW)
			 	assert (response_item.unpack(response_packet[i-1]));
			   proxy.notify_res_transaction(response_item) ;	
		   	j[i-1]=1'b0 ;
		    end

	 		else if ((k[i-1]==1'b1)&&(z[i-1]==1'b1)&&(is_TS1==1'b0)) 
	 		 begin
	 		   if(req_finish[i-1]==1'b1)
	 		 	 begin
			 		request_pkt_item=hmc_pkt_item::type_id::create("request_pkt_item") ;	 	
	 		      `uvm_info("HMC_IF", $sformatf("request_packet array length=%d",vif_request_packet[i-1].size()),UVM_LOW)			 			
			 		assert (request_pkt_item.unpack(vif_request_packet[i-1]));
		         proxy.notify_req_transaction(request_pkt_item) ;
		         k[i-1]=1'b0 ;
		         z[i-1]=1'b0 ;			 		 		
	 		 	 end 			
	 		 end

	 		else if ((k[i-1]==1'b0)&&(is_TS1==1'b0)&&(a[i-1]==1'b1))
	 	 	 begin
	 	 	 	if(null_pos[i-1]==1)
	 	 	 	 begin
				 	null_FLIT_item=hmc_pkt_item::type_id::create("null_FLIT_item") ; 		
				 	`uvm_info("HMC_IF", $sformatf("vif_null_FLITS array length=%d",vif_null_FLITS[i-1].size()),UVM_LOW)			 			
			 		assert (null_FLIT_item.unpack(vif_null_FLITS[i-1]));
		         proxy.notify_req_transaction(null_FLIT_item) ;	 	 	 		
	 	 	 	 end	 	 			     	
	 	    end

	 	 end
	 
endtask : run


endinterface : hmc_agent_if