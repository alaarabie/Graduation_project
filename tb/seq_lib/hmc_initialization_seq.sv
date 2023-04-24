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

   TX_FSM() ;

 endtask : body

  task TX_FSM();
        bit init_end ;         // A flag to check that initialization is complete 
        
        case(request_packet.init_state)

         2'b00 : begin //INIT_TX_NULL_1

                 start_item(response_packet) ;
                 assert(response_packet.randomize() with {command==NULL;}) ;
                 finish_item(response_packet) ;

                 end

         2'b10 : begin //INIT_TX_NULL_2
                 
                 start_item(response_packet) ;
                 assert(response_packet.randomize() with {command==NULL;}) ;                 
                 finish_item(response_packet) ;
                 
                 end 

        endcase // tx_state

endtask : TX_FSM

endclass : hmc_initialization_seq
