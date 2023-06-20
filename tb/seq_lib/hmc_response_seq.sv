class hmc_response_seq extends base_seq  ;
 `uvm_object_utils(hmc_response_seq)

 hmc_pkt_item response_packet ;
 hmc_pkt_item request_packet ; 


 function new (string name = "");
    super.new(name);
 endfunction : new

 task body() ;
   super.body();
     
   request_packet=hmc_pkt_item::type_id::create("request_packet") ;
   response_packet=hmc_pkt_item::type_id::create("response_packet") ;
   
    start_item(request_packet) ;
    finish_item(request_packet) ;
   
   start_item(response_packet) ; 

    if(response_packet.start_retry==1'b1)
     begin
      assert(response_packet.randomize() with {command==IRTRY;is_ts1==1'b0;clear_error_abort==1'b0;
                                               start_retry==1'b1;
                                               return_retry_ptr==request_packet.forward_retry_ptr;}) ;  
      response_packet.crc=response_packet.calculate_crc() ;        
     end
    else
     begin
       case(request_packet.command)
        // Flow
        NULL: begin
                assert(response_packet.randomize() with {command==NULL;is_ts1==1'b0;}) ;            
                response_packet.crc=response_packet.calculate_crc() ;             
              end
        PRET: begin
                assert(response_packet.randomize() with {command==PRET;is_ts1==1'b0;
                                                         return_retry_ptr==request_packet.forward_retry_ptr;}) ;
                response_packet.crc=response_packet.calculate_crc() ;             
              end
        TRET: begin
                assert(response_packet.randomize() with {command==TRET;is_ts1==1'b0;return_token_cnt==5'b11111;
                                                          sequence_number==request_packet.sequence_number;
                                                          forward_retry_ptr==8'b0; 
                                                          return_retry_ptr==request_packet.forward_retry_ptr;}) ;
                response_packet.crc=response_packet.calculate_crc() ;             
              end 
        IRTRY: begin
                assert(response_packet.randomize() with {command==IRTRY;is_ts1==1'b0;clear_error_abort==1'b1;
                                                         start_retry==1'b0;
                                                         return_retry_ptr==request_packet.return_retry_ptr;}) ;  
                response_packet.crc=response_packet.calculate_crc() ;             
              end
        // Write Requests      
        WR16: begin
                assert(response_packet.randomize() with {command==WR_RS;is_ts1==1'b0;tag==request_packet.tag;
                                                         return_token_cnt==5'b11111;
                                                         sequence_number==request_packet.sequence_number;
                                                         forward_retry_ptr==8'b0; 
                                                         return_retry_ptr==request_packet.forward_retry_ptr;}) ;
                response_packet.crc=response_packet.calculate_crc() ;         
              end
        WR32: begin
                assert(response_packet.randomize() with {command==WR_RS;is_ts1==1'b0;tag==request_packet.tag;
                                                         return_token_cnt==5'b11111;
                                                         sequence_number==request_packet.sequence_number;
                                                         forward_retry_ptr==8'b0; 
                                                         return_retry_ptr==request_packet.forward_retry_ptr;}) ;
                response_packet.crc=response_packet.calculate_crc() ;         
              end
        WR48: begin
                assert(response_packet.randomize() with {command==WR_RS;is_ts1==1'b0;tag==request_packet.tag;
                                                         return_token_cnt==5'b11111;
                                                         sequence_number==request_packet.sequence_number;
                                                         forward_retry_ptr==8'b0; 
                                                         return_retry_ptr==request_packet.forward_retry_ptr;}) ;
                response_packet.crc=response_packet.calculate_crc() ;             
              end
        WR64: begin
                assert(response_packet.randomize() with {command==WR_RS;is_ts1==1'b0;tag==request_packet.tag;
                                                         return_token_cnt==5'b11111;
                                                         sequence_number==request_packet.sequence_number;
                                                         forward_retry_ptr==8'b0; 
                                                         return_retry_ptr==request_packet.forward_retry_ptr;}) ;
                response_packet.crc=response_packet.calculate_crc() ;              
              end
        WR80: begin
                assert(response_packet.randomize() with {command==WR_RS;is_ts1==1'b0;tag==request_packet.tag;
                                                         return_token_cnt==5'b11111;
                                                         sequence_number==request_packet.sequence_number;
                                                         forward_retry_ptr==8'b0; 
                                                         return_retry_ptr==request_packet.forward_retry_ptr;}) ;
                response_packet.crc=response_packet.calculate_crc() ;             
              end
        WR96: begin
                assert(response_packet.randomize() with {command==WR_RS;is_ts1==1'b0;tag==request_packet.tag;
                                                         return_token_cnt==5'b11111;
                                                         sequence_number==request_packet.sequence_number;
                                                         forward_retry_ptr==8'b0; 
                                                         return_retry_ptr==request_packet.forward_retry_ptr;}) ;
                response_packet.crc=response_packet.calculate_crc() ;   
              end
        WR112: begin
                assert(response_packet.randomize() with {command==WR_RS;is_ts1==1'b0;tag==request_packet.tag;
                                                         return_token_cnt==5'b11111;
                                                         sequence_number==request_packet.sequence_number;
                                                         forward_retry_ptr==8'b0; 
                                                         return_retry_ptr==request_packet.forward_retry_ptr;}) ;
                response_packet.crc=response_packet.calculate_crc() ;   
              end
        WR128: begin
                assert(response_packet.randomize() with {command==WR_RS;is_ts1==1'b0;tag==request_packet.tag;
                                                         return_token_cnt==5'b11111;
                                                         sequence_number==request_packet.sequence_number;
                                                         forward_retry_ptr==8'b0; 
                                                         return_retry_ptr==request_packet.forward_retry_ptr;}) ;
                response_packet.crc=response_packet.calculate_crc() ;           
              end
        //  Misc Write Requests
        MD_WR: begin
                assert(response_packet.randomize() with {command==MD_WR_RS;is_ts1==1'b0;tag==request_packet.tag;
                                                         return_token_cnt==5'b11111;
                                                         sequence_number==request_packet.sequence_number;
                                                         forward_retry_ptr==8'b0; 
                                                         return_retry_ptr==request_packet.forward_retry_ptr;}) ;
                response_packet.crc=response_packet.calculate_crc() ;             
              end
        BWR: begin
                assert(response_packet.randomize() with {command==WR_RS;is_ts1==1'b0;tag==request_packet.tag;
                                                         return_token_cnt==5'b11111;
                                                         sequence_number==request_packet.sequence_number;
                                                         forward_retry_ptr==8'b0; 
                                                         return_retry_ptr==request_packet.forward_retry_ptr;}) ;
                response_packet.crc=response_packet.calculate_crc() ;                        
              end
        DUAL_2ADD8: begin
                assert(response_packet.randomize() with {command==WR_RS;is_ts1==1'b0;tag==request_packet.tag;
                                                         return_token_cnt==5'b11111;
                                                         sequence_number==request_packet.sequence_number;
                                                         forward_retry_ptr==8'b0; 
                                                         return_retry_ptr==request_packet.forward_retry_ptr;}) ;
                response_packet.crc=response_packet.calculate_crc() ;   
              end
        SINGLE_ADD16: begin
                assert(response_packet.randomize() with {command==WR_RS;is_ts1==1'b0;tag==request_packet.tag;
                                                         return_token_cnt==5'b11111;
                                                         sequence_number==request_packet.sequence_number;
                                                         forward_retry_ptr==8'b0; 
                                                         return_retry_ptr==request_packet.forward_retry_ptr;}) ;
                response_packet.crc=response_packet.calculate_crc() ;                
              end
        // Posted Write Requests
        P_WR16: begin           
                end
        P_WR32: begin            
                end
        P_WR48: begin         
                end
        P_WR64: begin         
                end
        P_WR80: begin          
                end
        P_WR96: begin           
                end
        P_WR112: begin         
                 end
        P_WR128: begin           
                 end
        // Posted Misc Write Requests
        P_BWR: begin             
               end
        P_DUAL_2ADD8: begin           
                      end
        P_SINGLE_ADD16: begin           
                        end
        // Mode Read Request
        MD_RD: begin
                assert(response_packet.randomize() with {command==MD_RD_RS;is_ts1==1'b0;tag==request_packet.tag;
                                                         length==4'b10; return_token_cnt==5'b11111;
                                                         sequence_number==request_packet.sequence_number;
                                                         forward_retry_ptr==8'b0; 
                                                         return_retry_ptr==request_packet.forward_retry_ptr;}) ;
                response_packet.crc=response_packet.calculate_crc() ;                
              end
        // Read Requests
        RD16: begin
                assert(response_packet.randomize() with {command==RD_RS;is_ts1==1'b0;tag==request_packet.tag;
                                                         length==4'b10; return_token_cnt==5'b11111;
                                                         sequence_number==request_packet.sequence_number;
                                                         forward_retry_ptr==8'b0; 
                                                         return_retry_ptr==request_packet.forward_retry_ptr;}) ;
                response_packet.crc=response_packet.calculate_crc() ;          
              end
        RD32: begin
                assert(response_packet.randomize() with {command==RD_RS;is_ts1==1'b0;tag==request_packet.tag;
                                                         length==4'b11; return_token_cnt==5'b11111;
                                                         sequence_number==request_packet.sequence_number;
                                                         forward_retry_ptr==8'b0; 
                                                         return_retry_ptr==request_packet.forward_retry_ptr;}) ;
                response_packet.crc=response_packet.calculate_crc() ;            
              end
        RD48: begin
                assert(response_packet.randomize() with {command==RD_RS;is_ts1==1'b0;tag==request_packet.tag;
                                                         length==4'b100; return_token_cnt==5'b11111;
                                                         sequence_number==request_packet.sequence_number;
                                                         forward_retry_ptr==8'b0; 
                                                         return_retry_ptr==request_packet.forward_retry_ptr;}) ;
                response_packet.crc=response_packet.calculate_crc() ;             
              end
        RD64: begin
                assert(response_packet.randomize() with {command==RD_RS;is_ts1==1'b0;tag==request_packet.tag;
                                                         length==4'b101; return_token_cnt==5'b11111;
                                                         sequence_number==request_packet.sequence_number;
                                                         forward_retry_ptr==8'b0; 
                                                         return_retry_ptr==request_packet.forward_retry_ptr;}) ;
                response_packet.crc=response_packet.calculate_crc() ;              
              end
        RD80: begin
                assert(response_packet.randomize() with {command==RD_RS;is_ts1==1'b0;tag==request_packet.tag;
                                                         length==4'b110; return_token_cnt==5'b11111;
                                                         sequence_number==request_packet.sequence_number;
                                                         forward_retry_ptr==8'b0; 
                                                         return_retry_ptr==request_packet.forward_retry_ptr;}) ;
                response_packet.crc=response_packet.calculate_crc() ;            
              end
        RD96: begin
                assert(response_packet.randomize() with {command==RD_RS;is_ts1==1'b0;tag==request_packet.tag;
                                                         length==4'b111; return_token_cnt==5'b11111;
                                                         sequence_number==request_packet.sequence_number;
                                                         forward_retry_ptr==8'b0; 
                                                         return_retry_ptr==request_packet.forward_retry_ptr;}) ;
                response_packet.crc=response_packet.calculate_crc() ;            
              end
        RD112: begin
                assert(response_packet.randomize() with {command==RD_RS;is_ts1==1'b0;tag==request_packet.tag;
                                                         length==4'b1000; return_token_cnt==5'b11111;
                                                         sequence_number==request_packet.sequence_number;
                                                         forward_retry_ptr==8'b0; 
                                                         return_retry_ptr==request_packet.forward_retry_ptr;}) ;
                response_packet.crc=response_packet.calculate_crc() ;              
              end
        RD128: begin
                assert(response_packet.randomize() with {command==RD_RS;is_ts1==1'b0;tag==request_packet.tag;
                                                         length==4'b1001; return_token_cnt==5'b11111;
                                                         sequence_number==request_packet.sequence_number;
                                                         forward_retry_ptr==8'b0; 
                                                         return_retry_ptr==request_packet.forward_retry_ptr;}) ;
                response_packet.crc=response_packet.calculate_crc() ;            
              end  
        default : `uvm_fatal(get_type_name(), $psprintf("command of request hmc_pkt_item is illegal='h%0h!", request_packet.command))

        endcase // request_packet.command       
     end
    
    finish_item(response_packet) ;
 
 endtask : body


endclass : hmc_response_seq