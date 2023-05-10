class driver_hmc_agent #(DWIDTH = 512 , 
                        NUM_LANES = 8 , 
                        FPW = 4,
                        FLIT_SIZE = 128
                        ) extends uvm_driver #(hmc_pkt_item);

     `uvm_component_param_utils(driver_hmc_agent#(DWIDTH, NUM_LANES, FPW, FLIT_SIZE))


     bit current_request_packet[] ;
     bit current_response_packet[] ;    
     bit [3:0] LNG ;
     hmc_pkt_item request_packet ;
     bit [3:0] i ;


     virtual hmc_agent_if #(DWIDTH, NUM_LANES, FPW, FLIT_SIZE) vif ;
     hmc_agent_config #(DWIDTH, NUM_LANES, FPW, FLIT_SIZE) hmc_agent_config_h;


     
     function new (string name, uvm_component parent);
     	super.new(name,parent);
     endfunction : new


     function void build_phase(uvm_phase phase);
     	if(!uvm_config_db #(hmc_agent_config#(DWIDTH, NUM_LANES, FPW, FLIT_SIZE))::get(this, "","hmc_agent_config_t", hmc_agent_config_h))
     		`uvm_fatal("HMC_AGENT_DRIVER","Failed to get vif")
        vif = hmc_agent_config_h.vif ;
     endfunction : build_phase

     task run_phase(uvm_phase phase);

        hmc_pkt_item response_packet;
        
        
        forever begin : response_loop
        
          if(!vif.res_n)
            begin
             vif.LXTXPS=1'b1 ;
             vif.FERR_N=1'b1 ;
             vif.phy_data_rx_phy2link='b0 ;
             vif.phy_rx_ready=1'b0 ;
             vif.phy_tx_ready=1'b0 ;                 
            end
            wait(vif.res_n)

            @(posedge vif.clk)

            vif.phy_rx_ready=1'b1 ;   
            vif.phy_tx_ready=1'b1 ;
      

        // rf_request_item state_item ;

        // bit [HMC_RF_WWIDTH-1:0] rf_read_data;

        // bit [1:0] tx_init_state ;

        // seq_item_port.get_next_item(state_item) ; 
        // hmc_agent_if.send_rf(state_item,rf_read_data) ; // rf_read_data is an output of task send_rf in the if
        // tx_init_state = rf_read_data[HMC_RF_WWIDTH-11:HMC_RF_WWIDTH-12] ;
        // seq_item_port.item_done() ;

                           

            current_request_packet.delete() ;  
            vif.vif_request_packet.delete() ;             
     
            //for state sequence
            request_packet=hmc_pkt_item::type_id::create("request_packet") ;
            response_packet=hmc_pkt_item::type_id::create("response_packet") ;


                  seq_item_port.get_next_item(response_packet);
                  
                  if (vif.phy_data_tx_link2phy[FLIT_SIZE-1:0]!='b0) begin
                     response_packet.new_request=1'b1 ;
                     vif.k=1 ;          
                  end 
                  else begin
                    response_packet.new_request=1'b0; 
                  end 

                  packing_FLITS() ;
                  `uvm_info("hmc_vseq", $sformatf("current_request_packet=%p",current_request_packet) ,UVM_HIGH)      
                  vif.vif_request_packet=current_request_packet ;  
                  // {<<bit{vif.vif_request_packet}}=current_request_packet ;      
                  vif.z=1 ;

                  seq_item_port.item_done() ; 

                  if((response_packet.init_state!=2'b11)&&(response_packet.init_state!=2'b01))
                  begin
            //hmc_initialization sequence(NULL) 
                    seq_item_port.get_next_item(request_packet) ;      
                    request_packet.init_state=response_packet.init_state ;
                    seq_item_port.item_done() ; 

                    seq_item_port.get_next_item(response_packet) ;
                    assert (response_packet.pack(current_response_packet)); // call do_pack
            //      response_packet.pack(current_response_packet) ;
                    vif.send_to_DUT(current_response_packet,response_packet) ;  // to send the response packet to the DUT
                    //vif.send_to_DUT(response_packet) ;  // to send the response packet to the DUT
                    seq_item_port.item_done() ; 
                  end  
                  else if (response_packet.init_state==2'b01) begin
            //Training Sequence        
                     for (i = 4'b0; i <= 4'b0111; i++) begin
                        vif.phy_data_rx_phy2link[63:0] = {48'b0,4'b1111,4'b0,4'b0011,i} ;
                        for (int j = 0; j <6 ; j++) begin
                        vif.phy_data_rx_phy2link [127+(j*64) -: 63] = {48'b0,4'b1111,4'b0,4'b0101,i} ;                  
                        //vif.phy_data_rx_phy2link[127+(j*64):64+(j*64)] = {48'b0,4'b1111,4'b0,4'b0101,i} ;               
                        end
                        vif.phy_data_rx_phy2link[511:448] = {48'b0,4'b1111,4'b0,4'b1100,i} ;
                        @(posedge vif.clk) ;
                     end           
                  end
                  //else begin
            //hmc_response sequence 
                    // seq_item_port.get_next_item(request_packet) ;
                    // request_packet.unpack(current_request_packet) ;              
                    // seq_item_port.item_done() ; 

                    // seq_item_port.get_next_item(response_packet) ;
                    // response_packet.pack(current_response_packet) ;        
                    // vif.send_to_DUT(current_response_packet) ;  // to send the response packet to the DUT
                    // seq_item_port.item_done() ; 
                  //end


                     // assert(tx_init_state==2'b11)
                     //    begin
                     //       TX_FSM() ;
                     //    end
                     // else
                     //    begin
                     //     assert(vif.phy_data_tx_link2phy[FLIT_SIZE-1:0]=='b0)
                     //      begin  
                     //        packing_FLITS(response_packet) ;
                     //        response_packet.unpack(current_request_packet) ;
                     //        seq_item_port.get_next_item(response_packet) ;
                     //        response_packet.pack(current_response_packet) ;
                     //        vif.send_hmc(response_packet) ;  // to send the response packet to the DUT
                     //        seq_item_port.item_done() ;  
                     //     end
                     //    end
       
        end: response_loop
     endtask : run_phase 

 task packing_FLITS();
     
     shortint i ;

     // for (i=0 ;i<=15 ;i++)
     //   @(posedge vif.clk) ;
     //   current_FLIT[(7+8*i):8*i] = vif.in_lanes ;  //to get the Header fields separately at first
     // end
     
     LNG = vif.phy_data_tx_link2phy[10:7] ;     

     current_request_packet = new[LNG*FLIT_SIZE] ;
     vif.vif_request_packet = new[LNG*FLIT_SIZE] ;     

    {>>{current_request_packet [FLIT_SIZE-1:0]}} = vif.phy_data_tx_link2phy[FLIT_SIZE-1:0] ; //to get the Header fields separately at first     
     //current_request_packet [FLIT_SIZE-1:0] = vif.phy_data_tx_link2phy[FLIT_SIZE-1:0]  ;  


     LNG = LNG-1 ;

     // current_FLIT = vif.phy_data_tx_link2phy[127:0] ;

     i=1 ;     
     
     while(LNG>4'b0)  
      begin

        if(i>3)
          begin
           @(posedge vif.clk) ;
           i=1 ;  
          end

        if(vif.phy_data_tx_link2phy[FLIT_SIZE-1+(FLIT_SIZE*i) -: (FLIT_SIZE-1)]!='b0)
          begin


             // @(posedge vif.clk) ;

//             current_request_packet [FLIT_SIZE-1+(FLIT_SIZE*i):(FLIT_SIZE*i)] = vif.phy_data_tx_link2phy[FLIT_SIZE-1+(FLIT_SIZE*i):(FLIT_SIZE*i)]  ;  //to get the Header fields separately at first    
             {>>{current_request_packet [FLIT_SIZE-1+(FLIT_SIZE*i) -: (FLIT_SIZE-1)]}} = vif.phy_data_tx_link2phy[FLIT_SIZE-1+(FLIT_SIZE*i) -: (FLIT_SIZE-1)]  ;  //to get the Header fields separately at first
             // current_request_packet [FLIT_SIZE-1+(FLIT_SIZE*i) -: (FLIT_SIZE-1)] = vif.phy_data_tx_link2phy[FLIT_SIZE-1+(FLIT_SIZE*i) -: (FLIT_SIZE-1)]  ;  //to get the Header fields separately at first      

             LNG=LNG-4'b1 ;
             i=i+1 ;

             // response_packet.do_unpack(current_request_packet) ; //FLIT number 1 in the packet in the request item 
             // for (j=1 ;j<LNG; j++)
             //    begin
             //       @(posedge vif.clk) ;
             //       for (i=0 ;i<=3 ;i++)
             //          begin
             //             // @(posedge vif.clk) ;
             //             current_request_packet.push_front(vif.phy_data_tx_link2phy[127+(128*i):(128*i)])  ; //to get the input bits on each lane from the if to the driver and pack them in FLIT
             //          end
             //       response_packet.packet[j]= current_FLIT ;
             //    end
     
          end
      end
endtask : packing_FLITS


endclass : driver_hmc_agent
