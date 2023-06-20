`define TYPE_MASK 6'h38 // 6'b111_000

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
     hmc_pkt_item retried_response_packet ;
     shortint x ;
     int m[4] ;
     int n ;        
     int p[4] ;        
     int e ;        
     bit [3:0] req_LNG[4] ;
     bit [3:0] expression ; 
     int seq_no ; 
     int irtry_tx_no;
     bit is_irtry_tx ;
     int irtry_rx_no;
     bit is_irtry_rx ;     
     bit [4:0] irtry_to_send ;
     bit h,o ;

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


        // u=3'b1 ;       
        m={0,0,0,0} ; // positions of null flits
        n=0 ; // number of null flits    
        p={0,0,0,0} ; // start position of request
        e=0 ; //number of requests in one round
        req_LNG={4'b0,4'b0,4'b0,4'b0} ; // length of requests
        vif.req_pos={0,0,0,0} ;
        vif.null_pos={0,0,0,0} ;
        seq_no= -1 ;
        h=1'b0 ;
        o=1'b0 ;
        is_irtry_tx=1'b0 ;
        irtry_tx_no=0 ;
        is_irtry_rx=1'b0 ;
        irtry_rx_no=0 ;        

        irtry_to_send=5'b10010 ;

        forever begin : response_loop
        
          if(!vif.res_n)
            begin
             vif.LXTXPS=1'b1 ;
             vif.FERR_N=1'b1 ;
             vif.phy_data_rx_phy2link='b0 ;
             vif.phy_rx_ready=1'b0 ;
             vif.phy_tx_ready=1'b0 ;
             vif.phy_bit_slip='b0 ;
             vif.k=0 ;
             vif.a=0 ;
             x=1 ;                 
            end
            wait(vif.res_n)
     
            if(x==1) begin
            @(posedge vif.clk)
            x=0 ;                
            end


            vif.phy_rx_ready=1'b1 ;   
            vif.phy_tx_ready=1'b1 ;
            vif.req_finish={0,0,0,0} ;            


            for(bit[3:0] l=4'b1; l<=4'b0100; l++)
             begin
                `uvm_info("HMC_AGENT_DRIVER", $sformatf("L=%b",l),UVM_LOW)                  
                //for state sequence
                vif.phy_bit_slip='b0 ;
                
                current_response_packet.delete() ;
                
                if(o==1'b0)
                 begin
                    request_packet=hmc_pkt_item::type_id::create("request_packet") ;
                    response_packet=hmc_pkt_item::type_id::create("response_packet") ;
                    o=1'b1 ;                    
                 end
                
                if((request_packet.init_state==2'b11)&&((request_packet.rx_state==3'b110)||(request_packet.rx_state==3'b111))&&(vif.is_TS1==1'b0))
                 begin
                    
                    if((h==1'b0)||(l==4'b1))
                     begin
                        h=1'b1 ;
                        packing_FLITS() ;   
                     end

                    vif.vif_request_packet=current_request_packet ;   
                    vif.z=1 ;

                    seq_item_port.get_next_item(request_packet) ;
                    seq_item_port.item_done() ;   
                   if(is_irtry_tx==1'b0)
                    begin
                        if(request_packet.crc!=request_packet.calculate_crc())
                         begin
                            response_packet.start_retry=1'b1 ; 
                            is_irtry_tx=1'b1 ;
                            irtry_tx_no=irtry_tx_no+1'b1 ;                               
                         end
                        else if(seq_no==-1)
                         begin
                            seq_no=request_packet.sequence_number ;                        
                         end
                        else if(seq_no!=-1)
                         begin
                            if((request_packet.command!=NULL)&&(request_packet.command!=PRET)&&(request_packet.command!=TRET)&&(request_packet.command!=IRTRY))                            
                             begin
                                if(request_packet.sequence_number!=(seq_no+1'b1))                              
                                 begin
                                    response_packet.start_retry=1'b1 ; 
                                    is_irtry_tx=1'b1 ;
                                    irtry_tx_no=irtry_tx_no+1'b1 ;        
                                 end
                                seq_no=request_packet.sequence_number ;                                      
                             end                      
                         end                        
                    end
                    else if(is_irtry_tx==1'b1)
                     begin
                        if(irtry_tx_no<irtry_to_send)
                         begin
                            response_packet.start_retry=1'b1 ;
                            irtry_tx_no=irtry_tx_no+1'b1 ;       
                         end
                         if(irtry_tx_no==irtry_to_send)
                          begin
                            irtry_tx_no=0 ;
                            is_irtry_tx=1'b0 ;                                     
                          end   
                     end
                    
                    if(((is_irtry_tx==1'b0)&&(request_packet.command==IRTRY))||(is_irtry_rx==1'b1))
                     begin
                        if(irtry_rx_no==0)
                         begin
                            is_irtry_rx=1'b1 ; 
                            irtry_rx_no=irtry_rx_no+1'b1 ;                             
                            retried_response_packet=hmc_pkt_item::type_id::create("retried_response_packet") ;
                            retried_response_packet=response_packet ;
                            retried_response_packet.calculate_crc();
                            retried_response_packet.sequence_number= seq_no ;
                         end
                        else if(irtry_rx_no<irtry_to_send)
                         begin                           
                            irtry_rx_no=irtry_rx_no+1'b1 ;                                                       
                         end
                        if(irtry_rx_no==irtry_to_send)
                         begin
                            irtry_rx_no=irtry_rx_no+1'b1 ;
                            is_irtry_rx=1'b0 ;                               
                         end                                                    
                     end

                    if(irtry_rx_no>irtry_to_send)
                     begin
                        irtry_rx_no=0 ;
                        is_irtry_rx=1'b0 ;
                        response_packet=retried_response_packet ;

                        response_packet.print() ;
                        `uvm_info("HMC_AGENT_DRIVER", $sformatf("current_response_packet=%p",current_response_packet),UVM_LOW)                      
                        assert (response_packet.pack(current_response_packet)); // call do_pack
                        `uvm_info("HMC_AGENT_DRIVER", $sformatf("current_response_packet=%p",current_response_packet),UVM_LOW)                
                        vif.send_to_DUT(current_response_packet,response_packet,l) ;  // to send the response packet to the DUT                                                              
                     end   
                    else
                     begin
                        seq_item_port.get_next_item(response_packet) ;
                        
                        if(((request_packet.command & `TYPE_MASK)!=6'b011000)&&((request_packet.command & `TYPE_MASK)!=6'b100000))
                         begin
                            response_packet.print() ;
                            `uvm_info("HMC_AGENT_DRIVER", $sformatf("current_response_packet=%p",current_response_packet),UVM_LOW)                      
                            assert (response_packet.pack(current_response_packet)); // call do_pack
                            `uvm_info("HMC_AGENT_DRIVER", $sformatf("current_response_packet=%p",current_response_packet),UVM_LOW)                
                            vif.send_to_DUT(current_response_packet,response_packet,l) ;  // to send the response packet to the DUT  
                         end                                             
                        
                        seq_item_port.item_done() ;                        
                     end
                    
                    if(((request_packet.command & `TYPE_MASK)!=6'b011000)&&((request_packet.command & `TYPE_MASK)!=6'b100000))
                     begin
                        response_packet.new_request=1'b1 ;
                        vif.k=1 ;          
                        vif.a=1 ;                     
                     end  
                    else
                     begin
                        response_packet.new_request=1'b1 ;
                        vif.k=0 ;          
                        vif.a=0 ;                           
                     end
                 end
////////////////////////////////////////////////////////////////////////////////////////////                 
                else
                 begin
                   //`uvm_info("HMC_AGENT_DRIVER", $sformatf("Line 111"),UVM_LOW)                     
                    seq_item_port.get_next_item(response_packet);
                    //`uvm_info("HMC_AGENT_DRIVER", $sformatf("Line 113"),UVM_LOW)                      
                    if ((vif.phy_data_tx_link2phy[((FLIT_SIZE*(l-1))+FLIT_SIZE-1)-:FLIT_SIZE])!=128'b0) begin
                        response_packet.new_request=1'b1 ;
                        vif.k=1 ;          
                     end 
                    else begin
                         response_packet.new_request=1'b0;                   
                     end
                     vif.a=1 ;

                    // `uvm_info("hmc_vseq", $sformatf("current_request_packet=%p",current_request_packet) ,UVM_LOW)        
                    // vif.vif_request_packet=current_request_packet ;  
                    // // {<<bit{vif.vif_request_packet}}=current_request_packet ;      
                    // vif.z=1 ;
                    //`uvm_info("HMC_AGENT_DRIVER", $sformatf("Line 127"),UVM_LOW)    
                    seq_item_port.item_done() ; 
                    //`uvm_info("HMC_AGENT_DRIVER", $sformatf("Line 129"),UVM_LOW)    
                    if(l==4'b1)
                     begin
                        packing_FLITS() ;                      
                     end

                    vif.vif_request_packet=current_request_packet ;  
                    // {<<bit{vif.vif_request_packet}}=current_request_packet ;      
                    vif.z=1 ;
     
                    `uvm_info("HMC_AGENT_DRIVER", $sformatf("phy_data_tx_link2phy=%b",vif.phy_data_tx_link2phy) ,UVM_LOW)          
                    `uvm_info("HMC_AGENT_DRIVER", $sformatf("vif.is_TS1=%b",vif.is_TS1),UVM_LOW)  

                    if(((response_packet.init_state!=2'b11)&&(response_packet.init_state!=2'b01)&&(vif.is_TS1==1'b0))||((response_packet.rx_state==3'b110)&&(vif.is_TS1==1'b0)))
                     begin
                        //hmc_initialization sequence(NULL) 
                        seq_item_port.get_next_item(request_packet) ;      
                        request_packet.init_state=response_packet.init_state ;
                        request_packet.rx_state=response_packet.rx_state ;                    
                        seq_item_port.item_done() ; 

                        seq_item_port.get_next_item(response_packet) ;
                        response_packet.print() ;
                        `uvm_info("HMC_AGENT_DRIVER", $sformatf("current_response_packet=%p",current_response_packet),UVM_LOW)                      
                        assert (response_packet.pack(current_response_packet)); // call do_pack
                        `uvm_info("HMC_AGENT_DRIVER", $sformatf("current_response_packet=%p",current_response_packet),UVM_LOW)                
                        //response_packet.pack(current_response_packet) ;
                        vif.send_to_DUT(current_response_packet,response_packet,l) ;  // to send the response packet to the DUT
                        //vif.send_to_DUT(response_packet) ;  // to send the response packet to the DUT
                        seq_item_port.item_done() ; 
                     end                                    
                    else if ((response_packet.init_state==2'b01)&&(vif.is_TS1)) begin
                         //Training Sequence
                         // u=3'b011 ;
                         while(vif.is_TS1)
                          begin 
                             if(u>3'b100)
                              begin
                                u=3'b1 ;            
                              end
                             // if(l==4'b1)
                             //  begin
                             //     for (int w=1; w<=6; w++)
                             //      begin
                             //        @(posedge vif.clk) ;
                             //        if(w==6)
                             //         begin
                             //            break ;    
                             //         end   
                             //      end                         
                             //  end

                             for (bit [3:0] q = 4'b0; q <= 4'b0011; q++) 
                              begin
                                expression=q+((u-1)*4) ;
                                vif.phy_data_rx_phy2link[15+(16*q) -: 16] = {4'b1111,4'b0,4'b0011,expression} ;
                                `uvm_info("HMC_TS1", $sformatf("phy_data_rx_phy2link=%b",vif.phy_data_rx_phy2link),UVM_LOW)                  

                                if(q==4'b0011) begin
                                   break ;                          
                                end

                              end

                             for (int j = 0; j <6 ; j++) 
                              begin
                                
                                for (bit [3:0] q = 4'b0; q <= 4'b0011; q++) 
                                 begin
                                    expression=q+((u-1)*4) ;
                                    vif.phy_data_rx_phy2link [79+(16*q)+(64*j) -: 16] = {4'b1111,4'b0,4'b0101,expression} ;  
                                    
                                    if(q==4'b0011) begin
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
                                expression=q+((u-1)*4) ;
                                vif.phy_data_rx_phy2link[463+(16*q) -: 16] = {4'b1111,4'b0,4'b1100,expression} ;
                                
                                if(q==4'b0011) begin
                                    break ;                          
                                end                      
                              end

                             u=u+1'b1 ;
                             @(posedge vif.clk) ;
                             packing_FLITS() ;                              
                             // if(l<4'b0100)
                             //  begin
                             //    @(posedge vif.clk) ;                          
                             //  end                         
                          end
            
                     end
                        
                 end

             end

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
                    if(req_LNG[i-2]>=4'b1)
                     begin
                        d=req_LNG[i-2]-1 ;                          
                     end 
                 end
                else if(d>4'b0)
                 begin
                    d=d-4'b1 ;  
                 end
                `uvm_info("Packing_FLITS", $sformatf("d=%b",d),UVM_LOW)  
                if((req_LNG[i-1]==4'b0)||(i!=1))
                 begin                  
                    if(d<=4'b0)
                     begin
                        `uvm_info("Packing_FLITS", $sformatf("vif.phy_data_tx_link2phy[%d:%d]=%b",((FLIT_SIZE*(i-1))+FLIT_SIZE-1),((i-1)*FLIT_SIZE),vif.phy_data_tx_link2phy[((FLIT_SIZE*(i-1))+FLIT_SIZE-1)-:FLIT_SIZE]),UVM_LOW)
                        LNG = vif.phy_data_tx_link2phy[(10+FLIT_SIZE*(i-1))-:4] ;     
                        if(LNG>=4'b1)
                         begin
                           req_LNG[i-1]=LNG ;
                           p[i-1]=i ;
                           `uvm_info("Packing_FLITS", $sformatf("p[%d]=%d",i-1,p[i-1]),UVM_LOW)                              
                           vif.req_pos[i-1]=i ;
                           e=e+1 ;
                         end
                        else if((vif.phy_data_tx_link2phy[((FLIT_SIZE*(i-1))+FLIT_SIZE-1)-:FLIT_SIZE])=='b0)
                         begin
                            n=n+1 ;  
                            m[i-1]=i ;
                            `uvm_info("Packing_FLITS", $sformatf("m[%d]=%d",i-1,m[i-1]),UVM_LOW)  
                            vif.null_pos[i-1]=i ;
                         end 
                   
                     end

                 end
                 `uvm_info("Packing_FLITS", $sformatf("req_LNG[%d]=%b",i,req_LNG[i-1]),UVM_LOW)               
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
                 {<<bit{current_null_FLITS[i-1]}}=128'b0 ;
                 vif.vif_null_FLITS[i-1]=current_null_FLITS[i-1] ;                 
                 vif.is_TS1=1'b0 ;
                 m[i-1]=0 ;
                 n=n-1 ;
              end 
             else if((p[i-1]==0)&&(m[i-1]==0))
              begin
                // if(i>4)
                //  begin            
                //     i=1 ;
                //  end            
                  vif.is_TS1=1'b1 ;          
              end

             end

endtask : packing_FLITS


endclass : driver_hmc_agent
