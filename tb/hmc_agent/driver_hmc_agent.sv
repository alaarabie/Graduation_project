class driver_hmc_agent extends uvm_driver #(rf_request_item, hmc_pkt_item, init_item);
     `uvm_component_utils(driver_hmc_agent)


    bit current_request_packet[$] ;
    bit [FPW*128:0] current_response_packet[$] ;    
    bit [3:0] LNG ;


     virtual hmc_agent_if hmc_agent_if ;
     

     
     function new (string name, uvm_component parent);
     	super.new(name,parent);
     endfunction : new


     function void build_phase(uvm_phase phase);
     	if(!uvm_config_db #(virtual hmc_agent_if)::get(null, "*","hmc_agent_if", hmc_agent_if))
     		uvm_fatal("HMC_AGENT_DRIVER","Failed to get hmc_agent_if")
     endfunction : build_phase

     task run_phase(uvm_phase phase);
        hmc_pkt_item response_packet ;
        

        forever begin : response_loop
        
        rf_request_item state_item ;

        bit [HMC_RF_WWIDTH-1:0] rf_read_data;
        bit [1:0] tx_init_state ;

        seq_item_port.get_next_item(state_item) ; 
        hmc_agent_if.send_rf(state_item,rf_read_data) ; // rf_read_data is an output of task send_rf in the if
        tx_init_state = rf_read_data[HMC_RF_WWIDTH-11:HMC_RF_WWIDTH-12] ;
        seq_item_port.item_done() ;        

         assert(tx_init_state==2'b11)
            begin
               TX_FSM() ;
            end
         else
            begin
             assert(hmc_agent_if.phy_data_tx_link2phy[127:0]==128'b0)
              begin  
                packing_FLITS(response_packet) ;
                response_packet.unpack(current_request_packet) ;
                seq_item_port.get_next_item(response_packet) ;
                response_packet.pack(current_response_packet) ;
                hmc_agent_if.send_hmc(response_packet) ;  // to send the response packet to the DUT
                seq_item_port.item_done() ;  
             end
            end
        end: response_loop
     endtask : run_phase

     task TX_FSM ();
        bit init_end ;         // A flag to check that initialization is complete 
        
        case(tx_init_state)
         
         init_end = 1'b0 ;
         
         2'b00 : begin

                 init_item INIT_TX_NULL_1 ;
                 seq_item_port.get_next_item(INIT_TX_NULL_1) ;
                 hmc_agent_if.send_hmc(INIT_TX_NULL_1) ;
                 seq_item_port.item_done() ;

                 end : 2'b00 :d

         2'b01 : begin
                 
                 init_item INIT_TX_TS1 ;
                 seq_item_port.get_next_item(INIT_TX_TS1) ;
                 hmc_agent_if.send_hmc(INIT_TX_TS1) ;
                 seq_item_port.item_done() ;
                 
                 end : 2'b01 :d

         2'b10 : begin
                 
                 init_item INIT_TX_NULL_2 ;
                 seq_item_port.get_next_item(INIT_TX_NULL_2) ;
                 hmc_agent_if.send_hmc(INIT_TX_NULL_2) ;
                 seq_item_port.item_done() ;
                 
                 end : 2'b10 :d

         2'b11 : begin
                 
                 init_item INIT_DONE ;
                 seq_item_port.get_next_item(INIT_DONE) ;
                 hmc_agent_if.send_hmc(INIT_DONE) ;
                 seq_item_port.item_done() ;  

                 init_end = 1'b1 ;
                 
                 end : 2'b11 :d

        default : begin
                   init_end = 1'b0 ;
                  end : default

        endcase // tx_init_state

     endtask : TX_FSM

task packing_FLITS(hmc_pkt_item response_packet);
     
     shortint i ;

     // for (i=0 ;i<=15 ;i++)
     //   @(posedge hmc_agent_if.clk) ;
     //   current_FLIT[(7+8*i):8*i] = hmc_agent_if.in_lanes ;  //to get the Header fields separately at first
     // end
     
     current_request_packet.push_front(hmc_agent_if.phy_data_tx_link2phy[127:0])  ;  //to get the Header fields separately at first     
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

        assert(hmc_agent_if.phy_data_tx_link2phy[127+(128*i):(128*i)]==128'b0)
          begin


             // @(posedge hmc_agent_if.clk) ;

             current_request_packet.push_front(hmc_agent_if.phy_data_tx_link2phy[127+(128*i):(128*i)])  ;  //to get the Header fields separately at first     

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
