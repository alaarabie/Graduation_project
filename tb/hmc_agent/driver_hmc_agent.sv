class driver_hmc_agent #(DWIDTH = 512 , 
                        NUM_LANES = 8 , 
                        FPW = 4,
                        FLIT_SIZE = 128
                        ) extends uvm_driver #(hmc_pkt_item);

     `uvm_component_param_utils(driver_hmc_agent#(DWIDTH, NUM_LANES, FPW, FLIT_SIZE))


     bit current_request_packet[FPW][] ;
     bit current_null_FLITS[FPW][] ;
     bit current_response_packet[] ;    
     bit [3:0] LNG ;
     hmc_pkt_item request_packet ;
     // shortint q ;
     // shortint i ;
     bit [2:0] u ;
     int k ;
     hmc_pkt_item response_packet;
     bit x ;
     int m[4] ;
     int n ;        
     int p[4] ;        
     int e ;        
     bit [3:0] req_LNG[4] ; 


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

        `uvm_info("HMC_DRIVER", "Line 46", UVM_MEDIUM)
        // u=3'b1 ;       
        m={0,0,0,0} ; // positions of null flits
        n=0 ; // number of null flits    
        p={0,0,0,0} ; // start position of request
        e=0 ; //number of requests in one round
        req_LNG={4'b0,4'b0,4'b0,4'b0} ; // length of requests
        vif.req_pos={0,0,0,0} ;
        vif.null_pos={0,0,0,0} ;


        forever begin : response_loop
        `uvm_info("HMC_DRIVER", "Line 58", UVM_MEDIUM)
          if(!vif.res_n)
            begin
             vif.LXTXPS=1'b1 ;
             vif.FERR_N=1'b1 ;
             vif.phy_data_rx_phy2link='b0 ;
             vif.phy_rx_ready=1'b0 ;
             vif.phy_tx_ready=1'b0 ;
             vif.k=0 ;
             vif.a=0 ;
             x=1 ;                 
            end
            wait(vif.res_n)
          `uvm_info("HMC_DRIVER", "Line 71", UVM_MEDIUM)
            if(x==1) begin
            @(posedge vif.clk)
            x=0 ;                
            end
`uvm_info("HMC_DRIVER", "Line 76", UVM_MEDIUM)

            vif.phy_rx_ready=1'b1 ;   
            vif.phy_tx_ready=1'b1 ;
            vif.req_finish={0,0,0,0} ;            
      
`uvm_info("HMC_DRIVER", "Line 82", UVM_MEDIUM)
        // rf_request_item state_item ;

        // bit [HMC_RF_WWIDTH-1:0] rf_read_data;

        // bit [1:0] tx_init_state ;

        // seq_item_port.get_next_item(state_item) ; 
        // hmc_agent_if.send_rf(state_item,rf_read_data) ; // rf_read_data is an output of task send_rf in the if
        // tx_init_state = rf_read_data[HMC_RF_WWIDTH-11:HMC_RF_WWIDTH-12] ;
        // seq_item_port.item_done() ;

            packing_FLITS() ;
      `uvm_info("HMC_DRIVER", "Line 95", UVM_MEDIUM)
            for(bit[3:0] l=4'b1; l<=4'b0100; l++)
             begin
              `uvm_info("HMC_DRIVER", "Line 98", UVM_MEDIUM)
                //for state sequence
                request_packet=hmc_pkt_item::type_id::create("request_packet") ;
                response_packet=hmc_pkt_item::type_id::create("response_packet") ;
                `uvm_info("HMC_DRIVER", "Line 102", UVM_MEDIUM)
                seq_item_port.get_next_item(response_packet);
                  `uvm_info("HMC_DRIVER", "Line 104", UVM_MEDIUM)
                if ((vif.phy_data_tx_link2phy[((FLIT_SIZE*(l-1))+FLIT_SIZE-1)-:FLIT_SIZE])!=128'b0) begin
                    response_packet.new_request=1'b1 ;
                    vif.k=1 ;          
                 end 
                else begin
                     response_packet.new_request=1'b0;                   
                 end
                 vif.a=1 ;
                `uvm_info("hmc_vseq", $sformatf("current_request_packet=%p",current_request_packet) ,UVM_LOW)      
                  
                vif.vif_request_packet=current_request_packet ;  
                // {<<bit{vif.vif_request_packet}}=current_request_packet ;      
                vif.z=1 ;

                seq_item_port.item_done() ; 

 
                `uvm_info("HMC_AGENT_DRIVER", $sformatf("phy_data_tx_link2phy=%b",vif.phy_data_tx_link2phy) ,UVM_LOW)          
                `uvm_info("HMC_AGENT_DRIVER", $sformatf("vif.is_TS1=%b",vif.is_TS1),UVM_LOW)  

                if((response_packet.init_state!=2'b11)&&(response_packet.init_state!=2'b01))
                 begin
                    //hmc_initialization sequence(NULL) 
                    seq_item_port.get_next_item(request_packet) ;      
                    request_packet.init_state=response_packet.init_state ;
                    seq_item_port.item_done() ; 

                    seq_item_port.get_next_item(response_packet) ;
                    assert (response_packet.pack(current_response_packet)); // call do_pack
                    //response_packet.pack(current_response_packet) ;
                    vif.send_to_DUT(current_response_packet,response_packet,l) ;  // to send the response packet to the DUT
                    //vif.send_to_DUT(response_packet) ;  // to send the response packet to the DUT
                    seq_item_port.item_done() ; 
                 end                                    
                else if ((response_packet.init_state==2'b01)&&(vif.is_TS1)) begin
                     //Training Sequence

                     // if(u>3'b100)
                     //  begin
                     //    u=3'b1 ;            
                     //  end

                     for (bit [3:0] q = 4'b0; q <= 4'b0011; q++) 
                      begin
                        vif.phy_data_rx_phy2link[15+(16*q) -: 16] = {4'b1111,4'b0,4'b0011,q+((l-1)*4)} ;
                        `uvm_info("HMC_TS1", $sformatf("phy_data_rx_phy2link=%b",vif.phy_data_rx_phy2link),UVM_LOW)                  

                        if(q>4'b0011) begin
                           break ;                          
                        end

                      end

                     for (int j = 0; j <6 ; j++) 
                      begin
                        
                        for (bit [3:0] q = 4'b0; q <= 4'b0011; q++) 
                         begin
                            vif.phy_data_rx_phy2link [79+(16*q)+(64*j) -: 16] = {4'b1111,4'b0,4'b0101,q+((l-1)*4)} ;  
                            
                            if(q>4'b0011) begin
                                break ;                          
                            end                         
                         end 
                        if(j>=6) begin
                            break ;                          
                        end                 
                        //vif.phy_data_rx_phy2link[127+(j*64):64+(j*64)] = {48'b0,4'b1111,4'b0,4'b0101,i} ;               
                     end
                     
                     for (bit [3:0] q = 4'b0; q <= 4'b0011; q++) 
                      begin
                        vif.phy_data_rx_phy2link[463+(16*q) -: 16] = {4'b1111,4'b0,4'b1100,q+((l-1)*4)} ;
                        
                        if(q>4'b0011) begin
                            break ;                          
                        end                      
                      end

                     // u=u+1'b1 ;
                     if(l<4'b0100)
                      begin
                        @(posedge vif.clk) ;                          
                      end
                            
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
     
     // for (i=0 ;i<=15 ;i++)
     //   @(posedge vif.clk) ;
     //   current_FLIT[(7+8*i):8*i] = vif.in_lanes ;  //to get the Header fields separately at first
     // end

        // int m[4]={0,0,0,0} ; // positions of null flits
        // int n=0 ; // number of null flits    
        // int p[4]={0,0,0,0} ; // start position of request
        // int e=0 ; //number of requests in one round
        // bit [3:0] req_LNG[4]={4'b0,4'b0,4'b0,4'b0} ; // length of requests
        
        bit [3:0] d=4'b0 ;

            for (int i=1; i<=4; i++)
             begin
                if((i!=1)&&(d<=4'b0))
                 begin
                    d=req_LNG[i-2]-1 ;   
                 end
                else if(d>4'b0)
                 begin
                    d=d-4'b1 ;  
                 end

                if(((req_LNG[i-1]==4'b0)||(i!=1)))
                 begin
                    if(d<=4'b0)
                     begin
                        LNG = vif.phy_data_tx_link2phy[(10+FLIT_SIZE*(i-1))-:4] ;     
                        if(LNG>=4'b1)
                         begin
                           req_LNG[i-1]=LNG ;
                           p[i-1]=i ;   
                           vif.req_pos[i-1]=i ;
                           e=e+1 ;
                         end
                        else if((vif.phy_data_tx_link2phy[((FLIT_SIZE*(i-1))+FLIT_SIZE-1)-:FLIT_SIZE])==128'b0)
                         begin
                            n=n+1 ;  
                            m[i-1]=i ;
                            vif.null_pos[i-1]=i ;
                         end 
                   
                     end

                 end
             
             end

             LNG=4'b0 ;
             // current_request_packet = new[(e*(req_LNG.sum())+n)*FLIT_SIZE] ;
             // vif.vif_request_packet = new[(e*(req_LNG.sum())+n)*FLIT_SIZE] ;

             for(int i=1; i<=4; i++)
              begin            
                current_request_packet[i-1].delete() ;  
                vif.vif_request_packet[i-1].delete() ;                    
                if(p[i-1]!=0)
                 begin
                     int f ;
                     f=0 ;                     
                     vif.is_TS1=1'b0 ;
                     current_request_packet[i-1] = new[req_LNG[i-1]*FLIT_SIZE] ;
                     vif.vif_request_packet[i-1] = new[req_LNG[i-1]*FLIT_SIZE] ;
                    // {>>{current_request_packet [FLIT_SIZE-1:0]}} = vif.phy_data_tx_link2phy[((FLIT_SIZE*(i-1))+FLIT_SIZE-1)-:FLIT_SIZE] ; //to get the Header fields separately at first     
                     //current_request_packet [FLIT_SIZE-1:0] = vif.phy_data_tx_link2phy[FLIT_SIZE-1:0]  ;  
                     // current_FLIT = vif.phy_data_tx_link2phy[127:0] ;
                     
                     while(req_LNG[i-1]>4'b0)  
                      begin

                        if (req_LNG[i-1]<=4'b0)
                        begin
                            e=e-1 ;
                            p[i-1]=0 ;
                            vif.req_finish[i-1]=1'b1 ;                            
                            break ;
                        end
                        
                        if (p[i-1]+f>4)
                        begin
                            req_LNG[1]=req_LNG[i-1] ;
                            req_LNG[i-1]=0 ;
                            f=0 ;
                            e=0 ;
                            p[i-1]=1 ;
                            break ;    
                        end


                        // if(vif.phy_data_tx_link2phy[FLIT_SIZE-1+(FLIT_SIZE*i) -: (FLIT_SIZE-1)]!='b0)
                        //   begin


                             // @(posedge vif.clk) ;

                //             current_request_packet [FLIT_SIZE-1+(FLIT_SIZE*i):(FLIT_SIZE*i)] = vif.phy_data_tx_link2phy[FLIT_SIZE-1+(FLIT_SIZE*i):(FLIT_SIZE*i)]  ;  //to get the Header fields separately at first    
                             {>>{current_request_packet[i-1][FLIT_SIZE-1+(FLIT_SIZE*(p[i-1]+f-1)) -: (FLIT_SIZE)]}} = vif.phy_data_tx_link2phy[FLIT_SIZE-1+(FLIT_SIZE*(p[i-1]+f-1)) -: (FLIT_SIZE)]  ;  //to get the Header fields separately at first
                             // current_request_packet [FLIT_SIZE-1+(FLIT_SIZE*i) -: (FLIT_SIZE-1)] = vif.phy_data_tx_link2phy[FLIT_SIZE-1+(FLIT_SIZE*i) -: (FLIT_SIZE-1)]  ;  //to get the Header fields separately at first      

                             req_LNG[i-1] = req_LNG[i-1]-4'b1 ;
                             f=f+1 ;

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
                     
                          // end
                      end
                     if (req_LNG[i-1]<=4'b0)
                      begin
                            e=e-1 ;
                            p[i-1]=0 ;
                            vif.req_finish[i-1]=1'b1 ;
                      end                      
                 end
              end 

             for (int i=1; i<=4; i++)
             begin
             current_null_FLITS[i-1].delete() ;  
             vif.vif_null_FLITS[i-1].delete() ;                  
             if(m[i-1]!=0)
              begin
                 current_null_FLITS[i-1] = new[FLIT_SIZE] ;
                 vif.vif_null_FLITS[i-1] = new[FLIT_SIZE] ;
                 {>>{current_null_FLITS[i-1]}}='b0 ;
                 vif.vif_null_FLITS[i-1]=current_null_FLITS[i-1] ;                 
                 vif.is_TS1=1'b0 ;
                 m[i-1]=0 ;
                 n=n-1 ;
              end 
             else if(p[i-1]==0)
              begin
                if(i>4)
                 begin            
                    i=1 ;
                 end            
                  vif.is_TS1=1'b1 ;          
              end

             end

endtask : packing_FLITS


endclass : driver_hmc_agent
