class driver_hmc_agent #(parameter FPW=4,FLIT_SIZE=128) extends uvm_driver #(hmc_pkt_item);
     `uvm_component_param_utils(driver_hmc_agent) #(parameter FPW=4,FLIT_SIZE=128)


    bit current_request_packet[$] ;
    bit [(FPW*FLIT_SIZE)-1:0] current_response_packet[$] ;    
    bit [3:0] LNG ;


     virtual hmc_agent_if hmc_agent_if ;
     

     
     function new (string name, uvm_component parent);
     	super.new(name,parent);
     endfunction : new


     function void build_phase(uvm_phase phase);
        hmc_agent_config hmc_agent_config_h ;
     	if(!uvm_config_db #(hmc_agent_config)::get(this, "","config", hmc_agent_config_h))
     		uvm_fatal("HMC_AGENT_DRIVER","Failed to get hmc_agent_if") ;
        hmc_agent_if = hmc_agent_config_h.interface ;
     endfunction : build_phase

     task run_phase(uvm_phase phase);

        hmc_pkt_item response_packet ;
        
        
        forever begin : response_loop
        
        // rf_request_item state_item ;

        // bit [HMC_RF_WWIDTH-1:0] rf_read_data;

        // bit [1:0] tx_init_state ;

        // seq_item_port.get_next_item(state_item) ; 
        // hmc_agent_if.send_rf(state_item,rf_read_data) ; // rf_read_data is an output of task send_rf in the if
        // tx_init_state = rf_read_data[HMC_RF_WWIDTH-11:HMC_RF_WWIDTH-12] ;
        // seq_item_port.item_done() ;

    current_request_packet = {} ;            

    NULL_FLIT_at_the_hmc_interface:
      assert(hmc_agent_if.phy_data_tx_link2phy[FLIT_SIZE-1:0]=='b0);
      response_packet.new_request=1'b0 ;      
      else response_packet.new_request=1'b1 ;        
      
      packing_FLITS(response_packet) ;
      response_packet.unpack(current_request_packet) ;
      seq_item_port.get_next_item(response_packet) ;
      response_packet.pack(current_response_packet) ;
      hmc_agent_if.send_to_DUT(response_packet) ;  // to send the response packet to the DUT
      seq_item_port.item_done() ; 

         // assert(tx_init_state==2'b11)
         //    begin
         //       TX_FSM() ;
         //    end
         // else
         //    begin
         //     assert(hmc_agent_if.phy_data_tx_link2phy[FLIT_SIZE-1:0]=='b0)
         //      begin  
         //        packing_FLITS(response_packet) ;
         //        response_packet.unpack(current_request_packet) ;
         //        seq_item_port.get_next_item(response_packet) ;
         //        response_packet.pack(current_response_packet) ;
         //        hmc_agent_if.send_hmc(response_packet) ;  // to send the response packet to the DUT
         //        seq_item_port.item_done() ;  
         //     end
         //    end
        end: response_loop
     endtask : run_phase 

 task packing_FLITS(hmc_pkt_item response_packet);
     
     shortint i ;

     // for (i=0 ;i<=15 ;i++)
     //   @(posedge hmc_agent_if.clk) ;
     //   current_FLIT[(7+8*i):8*i] = hmc_agent_if.in_lanes ;  //to get the Header fields separately at first
     // end
     
     current_request_packet.push_front(hmc_agent_if.phy_data_tx_link2phy[FLIT_SIZE-1:0])  ;  //to get the Header fields separately at first     
     LNG = current_request_packet[10:7] ;
     LNG = LNG-1 ;

     // current_FLIT = hmc_agent_if.phy_data_tx_link2phy[127:0] ;

     i=1 ;     
     
     while(LNG>4'b0)  
      begin

        assert(i<=3)
          begin
           @(posedge hmc_agent_if.clk) ;
           i=1 ;  
          end

        assert(hmc_agent_if.phy_data_tx_link2phy[FLIT_SIZE-1+(FLIT_SIZE*i):(FLIT_SIZE*i)]=='b0)
          begin


             // @(posedge hmc_agent_if.clk) ;

             current_request_packet.push_front(hmc_agent_if.phy_data_tx_link2phy[FLIT_SIZE-1+(FLIT_SIZE*i):(FLIT_SIZE*i)])  ;  //to get the Header fields separately at first     

             LNG=LNG-1'b1 ;
             i=i+1 ;

             // response_packet.do_unpack(current_request_packet) ; //FLIT number 1 in the packet in the request item 
             // for (j=1 ;j<LNG; j++)
             //    begin
             //       @(posedge hmc_agent_if.clk) ;
             //       for (i=0 ;i<=3 ;i++)
             //          begin
             //             // @(posedge hmc_agent_if.clk) ;
             //             current_request_packet.push_front(hmc_agent_if.phy_data_tx_link2phy[127+(128*i):(128*i)])  ; //to get the input bits on each lane from the if to the driver and pack them in FLIT
             //          end
             //       response_packet.packet[j]= current_FLIT ;
             //    end
     
          end
      end
endtask : packing_FLITS


endclass : driver_hmc_agent
