class hmc_response_seq extends uvm_sequence#(hmc_pkt_item);
  `uvm_object_utils(hmc_response_seq) 

  env_cfg m_cfg;

  /*hmc_pkt_item response_queue[$];
  hmc_pkt_item dummy = hmc_pkt_item::type_id::create("dummy");
  hmc_pkt_item my_req;
  hmc_pkt_item my_rsp = hmc_pkt_item::type_id::create("my_rsp");*/
  hmc_pkt_item rsp = hmc_pkt_item::type_id::create("rsp");
  //rand bit error_response;

  function new (string name = "");
    super.new(name);
  endfunction : new

  task body() ;
    if(m_cfg == null) begin
    `uvm_fatal(get_full_name(), "env_config is null")
    end
    
    /*// Get request
    start_item(dummy);
    void'(dummy.randomize());
    finish_item(dummy);

    get_response(my_req);

    // Creating responses and save inside response_queue
    `uvm_info("HMC_RESPONSE_SEQ_body()",$sformatf("create response to request: %s @%0x",my_req.command.name(), my_req.address),UVM_MEDIUM)
    create_response_packet(my_req);

    // Respond:
    // Sending the response packet from queue
    start_item(my_rsp);
 
    my_rsp = response_queue.pop_front();
    `uvm_info("HMC_RESPONSE_SEQ_body()",$sformatf("Sending Response %s @%0x",my_rsp.command.name(), my_rsp.address),UVM_MEDIUM)
    finish_item(my_rsp);*/

    start_item(rsp);
    void'(rsp.randomize() with {command == WR_RS;
                                      address == 34'h264cd7770; 
                                       tag    == 9'd1;
                                      });
    finish_item(rsp);

  endtask : body

  extern task create_response_packet(hmc_pkt_item request);
  extern task enqueue_response_packet(hmc_pkt_item response);

endclass : hmc_response_seq


//*******************************************************************************
// create_response_packet(hmc_pkt_item request)
//*******************************************************************************
task hmc_response_seq::create_response_packet(hmc_pkt_item request);
  hmc_pkt_item response;
  int response_length = 1;
  //int new_timestamp;
  bit [127:0] rand_flit;
  bit [127:0] payload_flits [$];

  `uvm_info("HMC_RESPONSE_SEQ_create_response_packet()",$sformatf("Generating response for a %s @%0x",request.command.name(), request.address),UVM_MEDIUM)
  response = hmc_pkt_item::type_id::create("response");

  //void'(this.randomize(error_response));
  //new_timestamp = delay * 500ps + $time;

  if (request.get_command_type() == READ_TYPE ||
      request.get_command_type() == MODE_READ_TYPE) 
  begin : read
      // know the length
      case (request.command)
        RD16 : response_length = 2;
        RD32 : response_length = 3;
        RD48 : response_length = 4;
        RD64 : response_length = 5;
        RD80 : response_length = 6;
        RD96 : response_length = 7;
        RD112 : response_length = 8;
        RD128 : response_length = 9;
        MD_RD : response_length = 1;
      endcase
      // randomize the packet
      void'(response.randomize() with {command == RD_RS;
                                       address == request.address;
                                       length  == response_length;
                                       tag     == request.tag;
                                      }); // error_status == 0 || error_response;
      // randomize the packet's payload, maybe not needed?
      for (int i = 0; i < response_length-1; i++) begin
        randomize_flit_successful : assert(std::randomize(rand_flit));
        payload_flits.push_front(rand_flit);
      end
      response.payload = payload_flits;
      //response.timestamp = new_timestamp;
      // enqueue the packet, ready to send
      enqueue_response_packet(response);
  end : read
  else if (request.get_command_type() == WRITE_TYPE || 
           request.get_command_type() == MISC_WRITE_TYPE) 
  begin : write
      // know the length
      response_length = 1; // there is already a constraint inside the packet
      // randomize the packet
      void'(response.randomize() with {command == WR_RS;
                                       address == request.address; 
                                       tag     == request.tag;
                                      });
      // no payload
      enqueue_response_packet(response);
  end : write
  else if (request.get_command_type() != POSTED_WRITE_TYPE &&
           request.get_command_type() != POSTED_MISC_WRITE_TYPE) 
  begin : wrong_commands
      // posted write requests gets not responses
      uvm_report_fatal("HMC_RESPONSE_SEQ_create_response_packet()",$sformatf("Unsupported command type %s", request.command.name()));
  end : wrong_commands
endtask : create_response_packet


//*******************************************************************************
// enqueue_response_packet(hmc_pkt_item response)
//*******************************************************************************
task hmc_response_seq::enqueue_response_packet(hmc_pkt_item response);
  // Insert at the end
  response_queue.push_back(response);
endtask : enqueue_response_packet