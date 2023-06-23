class hmc_initialization_seq extends base_seq  ;

 `uvm_object_utils(hmc_initialization_seq)

 hmc_pkt_item response_packet ;
 hmc_pkt_item request_packet ;
 bit [3:0] i ; 

 function new (string name = "");
    super.new(name);
 endfunction : new

 task body() ;
   super.body();

    response_packet=hmc_pkt_item::type_id::create("response_packet") ;
    request_packet=hmc_pkt_item::type_id::create("request_packet")  ;

   start_item(request_packet) ;
   finish_item(request_packet) ;
   `uvm_info("HMC_Initialization_seq", $sformatf("Line 21"),UVM_LOW)
   start_item(response_packet) ;     
   TX_FSM() ;
   finish_item(response_packet) ; 

 endtask : body

  task TX_FSM();
        
        if(request_packet.init_state==2'b0)
         begin //INIT_TX_NULL_1
            assert(response_packet.randomize() with {command==NULL;is_ts1==1'b0;}) ;
            response_packet.crc=response_packet.calculate_crc() ;
         end
        else if((request_packet.init_state==2'b10)||(request_packet.rx_state==3'b110))
         begin //INIT_TX_NULL_2        
            assert(response_packet.randomize() with {command==NULL;is_ts1==1'b0;}) ;    
            response_packet.crc=response_packet.calculate_crc() ;                              
         end 
         // tx_state

endtask : TX_FSM

endclass : hmc_initialization_seq
