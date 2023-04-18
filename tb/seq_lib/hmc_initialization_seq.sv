class hmc_initialization_seq extends base_seq #(hmc_pkt_item) ;

 `uvm_object_utils(hmc_initialization_seq)

 hmc_pkt_item response_packet ;

 function new (string name = "");
    super.new(name);
 endfunction : new

 task body() ;
   super.body();

   TX_FSM() ;

 endtask : body

  task TX_FSM();
        bit init_end ;         // A flag to check that initialization is complete 
        
        case(response_packet.tx_state)
         init_end = 1'b0 ;

         2'b00 : begin //INIT_TX_NULL_1

                 start_item(response_packet) ;
                 
                 finish_item(response_packet) ;

                 end : 2'b00 :d

         2'b01 : begin //INIT_TX_TS1
                 
                 start_item(response_packet) ;
                 
                 finish_item(response_packet) ;
                 
                 end : 2'b01 :d

         2'b10 : begin //INIT_TX_NULL_2
                 
                 start_item(response_packet) ;
                 
                 finish_item(response_packet) ;
                 
                 end : 2'b10 :d

        default : begin
                   init_end = 1'b0 ;
                  end : default

        endcase // tx_state

endtask : TX_FSM

endclass : hmc_initialization_seq
