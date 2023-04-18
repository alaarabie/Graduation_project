class hmc_response_seq extends base_seq #(hmc_pkt_item) ;
 `uvm_object_utils(hmc_response_seq)

 hmc_pkt_item response_packet ;

 function new (string name = "");
    super.new(name);
 endfunction : new

 task body() ;
   super.body();
   
   start_item(response_packet) ; 
   
   assert(response_packet.new_request==0)
    begin

    end
    
    finish_item(response_packet) ;
 
 endtask : body



endclass : hmc_response_seq