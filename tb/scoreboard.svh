class scoreboard  extends uvm_scoreboard;
	`uvm_component_utils(scoreboard )

	protected int hmc_rsp_packet_count = 0;
	protected int hmc_req_packet_count = 0;
	protected int hmc_error_response_count = 0;
	protected int axi4_rsp_packet_count = 0;
	protected int axi4_req_packet_count = 0;
	protected int axi4_error_response_count = 0;

	typedef hmc_pkt_item hmc_request_queue[$];
	typedef bit [127:0] flit_t;
	hmc_request_queue axi4_np_requests[*];
	hmc_pkt_item axi4_2_hmc[$];
	hmc_pkt_item hmc_response[$];
	hmc_pkt_item axi4_response[$];
	
	//--check tags
	int tag_count = 512;
	bit [512:0]used_tags;
	
	//-- analysis imports
  `uvm_analysis_imp_decl(_hmc_req)
  uvm_analysis_imp_hmc_req #(hmc_pkt_item, scoreboard) hmc_req_import;
  `uvm_analysis_imp_decl(_hmc_rsp)
  uvm_analysis_imp_hmc_rsp #(hmc_pkt_item, scoreboard) hmc_rsp_import;
  `uvm_analysis_imp_decl(_axi4_req)
  uvm_analysis_imp_axi4_req #(hmc_pkt_item, scoreboard) axi4_req_import; 
  `uvm_analysis_imp_decl(_axi4_rsp)
  uvm_analysis_imp_axi4_rsp #(hmc_pkt_item, scoreboard) axi4_rsp_import;

    function new (string name="scoreboard", uvm_component parent);
		super.new(name, parent);
		// Instantiate the analysis port
		axi4_req_import = new("axi4_req_import",this);
		axi4_rsp_import = new("axi4_rsp_import",this);
		hmc_req_import = new("hmc_req_import",this);
		hmc_rsp_import = new("hmc_rsp_import",this);
	endfunction : new


//*******************************************************************************
// write_hmc_rsp(): hmc agent writes the responses (driven by testbench)
//*******************************************************************************
	function void write_hmc_rsp(input hmc_pkt_item packet);
		hmc_pkt_item expected;

		if (packet == null) begin
		  `uvm_info("SCOREBOARD", $sformatf("packet is null"),UVM_HIGH)
		 end else begin
			 	if (packet.command != ERROR_RS) begin //TODO cover error response
				hmc_rsp_packet_count++;
				`uvm_info(get_type_name(),$sformatf("hmc_rsp: received packet #%0d %s", hmc_rsp_packet_count, packet.command.name()), UVM_MEDIUM)
				`uvm_info(get_type_name(),$sformatf("hmc_rsp: \n%s", packet.sprint()), UVM_HIGH)
			end else begin
				hmc_error_response_count++;
				`uvm_info(get_type_name(),$sformatf("hmc_error_rsp: received error response #%0d %s", hmc_error_response_count, packet.command.name()), UVM_MEDIUM)
				`uvm_info(get_type_name(),$sformatf("hmc_error_rsp: \n%s", packet.sprint()), UVM_HIGH)
			end

			//-- check this packet later 
			
			//-- the response packet might be delayed due to the packet mon
			//-- check if the response packet is already received on the axi link
			if (axi4_response.size() == 0)//no expected
				hmc_response.push_back(packet);
			else begin //-- check the packet
				expected = axi4_response.pop_front();
				response_compare(expected, packet); //TODO

				if (packet.command != ERROR_RS) begin //TODO cover error response
									//-- check if open request with tag is available
					if (used_tags[packet.tag] == 1'b1) begin
						used_tags[packet.tag] =  1'b0;
					end else begin
						`uvm_info("SCOREBOARD",$sformatf("Packet with Tag %0d was not requested", packet.tag),UVM_MEDIUM)
					end
				end
			end
		 end
	endfunction : write_hmc_rsp


//*******************************************************************************
// write_hmc_req(): hmc agent writes the requests (driven by DUT)
//*******************************************************************************
	function void write_hmc_req(input hmc_pkt_item packet);
		hmc_pkt_item expected;

		if (packet == null) begin
		  `uvm_info("SCOREBOARD", $sformatf("packet is null"),UVM_HIGH)
		 end else begin
			 	hmc_req_packet_count++;	

			`uvm_info(get_type_name(),$sformatf("hmc_req: received packet #%0d %s@%0x (tok %0d)", hmc_req_packet_count, packet.command.name(), packet.address, packet.return_token_cnt), UVM_MEDIUM)
			`uvm_info(get_type_name(),$sformatf("hmc_req: \n%s", packet.sprint()), UVM_HIGH)

			//-- expect an request packet on the host (AXI4) request queue
			if (axi4_2_hmc.size() == 0)
				`uvm_info("SCOREBOARD",$sformatf("write_hmc_req: Unexpected packet (the request queue is empty)\n%s",packet.sprint()),UVM_MEDIUM)
			else
				expected = axi4_2_hmc.pop_front();

			//-- compare and check 2 Request type packets
			request_compare(expected, packet);
			`uvm_info(get_type_name(),$sformatf("hmc_req: checked packet #%0d %s@%0x", hmc_req_packet_count, packet.command.name(), packet.address), UVM_MEDIUM)
		 end
	endfunction : write_hmc_req


//*******************************************************************************
// write_axi4_rsp(): axi agent writes the responses (driven by DUT)
//*******************************************************************************
	function void write_axi4_rsp(input hmc_pkt_item packet);
		 hmc_pkt_item expected;

		 if (packet == null) begin
		  `uvm_info("SCOREBOARD", $sformatf("packet is null"),UVM_HIGH)
		 end else begin
			 	if (packet.command != ERROR_RS) begin //TODO cover error response
				axi4_rsp_packet_count++;
				`uvm_info(get_type_name(),$sformatf("axi4_rsp: received packet #%0d %s", axi4_rsp_packet_count, packet.command.name()), UVM_MEDIUM)
				`uvm_info(get_type_name(),$sformatf("axi4_rsp: \n%s", packet.sprint()), UVM_HIGH)
			end else begin
				axi4_error_response_count++;
				`uvm_info(get_type_name(),$sformatf("axi4_error_rsp: received error response #%0d %s", axi4_error_response_count, packet.command.name()), UVM_MEDIUM)
				`uvm_info(get_type_name(),$sformatf("axi4_error_rsp: \n%s", packet.sprint()), UVM_HIGH)
			end

			//-- the response packet might be delayed due to the transmission mon. 
			//-- due to this the compare must be executed later
			
			//-- compare with previous on the HMC side received response packet
			
			if (hmc_response.size()== 0) 
				axi4_response.push_back(packet);
			else begin //-- check
				expected = hmc_response.pop_front();
				response_compare(expected, packet); //TODO

				if (packet.command != ERROR_RS) begin //TODO cover error response
					//-- check if open request with tag is available
					if (used_tags[packet.tag] == 1'b1) begin
						used_tags[packet.tag] =  1'b0;
					end else begin
						`uvm_info("SCOREBOARD",$sformatf("Packet with Tag %0d was not requested", packet.tag),UVM_MEDIUM)
					end
				end
			end
		 end
	endfunction : write_axi4_rsp


//*******************************************************************************
// write_axi4_req(): axi agent writes the requests (driven by testbench)
//*******************************************************************************
	function void write_axi4_req(input hmc_pkt_item packet);
		if (packet == null) begin
		  `uvm_info("SCOREBOARD", $sformatf("packet is null"),UVM_MEDIUM)
		end else begin
			`uvm_info(get_type_name(),$sformatf("collected a packet %s", packet.command.name()), UVM_HIGH)
			`uvm_info(get_type_name(),$sformatf("\n%s", packet.sprint()), UVM_HIGH)
			
			//-- check packet later
			axi4_req_packet_count++;
			axi4_2_hmc.push_back(packet);
			
			//-- check if tag checking is necessary
			if (packet.get_command_type() == WRITE_TYPE 
					|| packet.get_command_type() == MISC_WRITE_TYPE 
					|| packet.get_command_type() == READ_TYPE 
					|| packet.get_command_type() == MODE_READ_TYPE)
			begin
				//-- store this packet to check corresponding response packet later
				if (!axi4_np_requests.exists(packet.tag)) begin
					axi4_np_requests[packet.tag] = {};
				end 
				else begin
					`uvm_info(get_type_name(),$sformatf("There is already an outstanding axi4 request with tag %0x!", packet.tag), UVM_MEDIUM)
				end
				axi4_np_requests[packet.tag].push_back(packet);
					
				if (used_tags[packet.tag] == 1'b0) begin
					used_tags[packet.tag] =  1'b1;
				end else begin
					`uvm_info("SCOREBOARD", $sformatf("tag %0d is already in use", packet.tag),UVM_MEDIUM)
				
				end
			end
				
			`uvm_info(get_type_name(),$sformatf("axi4_req: received packet #%0d %s@%0x", axi4_req_packet_count, packet.command.name(), packet.address), UVM_MEDIUM)
			`uvm_info(get_type_name(),$sformatf("axi4_req: \n%s", packet.sprint()), UVM_HIGH)
		end
	endfunction :write_axi4_req


//*******************************************************************************
// response_compare(): compare the received response packets and check with the previous sent request packet
//*******************************************************************************
	function void response_compare(input hmc_pkt_item expected, input hmc_pkt_item packet);
				int i;
		hmc_pkt_item request;
		
		if (packet.command != ERROR_RS) begin //-- ERROR_RS has no label
			//-- Check the packet against the request stored in the axi4_np_requests map
			label : assert (axi4_np_requests.exists(packet.tag))
				else `uvm_info("SCOREBOARD",$sformatf("response_compare: Unexpected Response with tag %0x \n%s", packet.tag, packet.sprint()),UVM_MEDIUM);
			
			//-- delete the previous sent request packet
			request = axi4_np_requests[packet.tag].pop_front();
			if (axi4_np_requests[packet.tag].size() == 0)
				axi4_np_requests.delete(packet.tag);
		end
		//-- check the hmc_pkt_item
		//check write response
		if (packet.command == WR_RS && request.get_command_type() != WRITE_TYPE && request.get_command_type() != MISC_WRITE_TYPE)
			`uvm_info("SCOREBOARD",$sformatf("response_compare: Write Response received with tag %0x for request %s\n%s", packet.tag, request.command.name(), packet.sprint()),UVM_MEDIUM)
//check Read response

		if (packet.command == RD_RS && request.get_command_type() != READ_TYPE && request.get_command_type() != MODE_READ_TYPE )
			`uvm_info("SCOREBOARD",$sformatf("response_compare: Read Response received with tag %0x for request %s\n%s", packet.tag, request.command.name(), packet.sprint()),UVM_MEDIUM)
//++++++++++++++++++++++++++++
		if (packet.command == RD_RS) begin
			int expected_payload; //store payload =length-1
			case (request.command)
				MD_RD:  expected_payload = 1;
				RD16:   expected_payload = 1;
				RD32:   expected_payload = 2;
				RD48:   expected_payload = 3;
				RD64:   expected_payload = 4;
				RD80:   expected_payload = 5;
				RD96:   expected_payload = 6;
				RD112:  expected_payload = 7;
				RD128:  expected_payload = 8;
				default:expected_payload = 0;
			endcase
			if (expected_payload != packet.payload.size())
				`uvm_info("SCOREBOARD",$sformatf("response_compare: Read Response received with tag %0x and wrong size req=%0s rsp payload size=%0x\n", packet.tag, request.command.name(), packet.payload.size()),UVM_MEDIUM)
		end

		//-- Check that the HMC command matches the HTOC item
		if (packet.get_command_type() != RESPONSE_TYPE)
			`uvm_info("SCOREBOARD",$sformatf("response_compare: Unexpected Packet \n%s", packet.sprint()),UVM_MEDIUM)

		if (expected.command != packet.command)
			`uvm_info("SCOREBOARD",$sformatf("response_compare: Expected %s, got %s", expected.command.name(), packet.command.name()),UVM_MEDIUM)

		if (expected.tag != packet.tag) begin
			`uvm_info(get_type_name(), $sformatf("Expected: %s. got: %s", expected.sprint(), packet.sprint() ), UVM_LOW)	
			`uvm_info("SCOREBOARD",$sformatf("response_compare: Packet tag mismatch %0d != %0d ", expected.tag, packet.tag),UVM_MEDIUM)
		end	

		if (expected.length != packet.length) begin
			`uvm_info(get_type_name(), $sformatf("Expected: %s. got: %s", expected.sprint(), packet.sprint() ), UVM_LOW)	
			`uvm_info("SCOREBOARD",$sformatf("response_compare: Packet length mismatch %0d != %0d ", expected.length, packet.length),UVM_MEDIUM)
		end
		
		if (expected.payload.size() != packet.payload.size())
			`uvm_info("SCOREBOARD",$sformatf("response_compare: Payload size mismatch %0d != %0d", expected.payload.size(), packet.payload.size()),UVM_MEDIUM)

		for (int i=0; i<packet.payload.size(); i++) begin
			if (packet.payload[i] != expected.payload[i])
				`uvm_info("SCOREBOARD",$sformatf("response_compare: Payload mismatch at %0d %0x != %0x", i, packet.payload[i], expected.payload[i]),UVM_MEDIUM)
		end
	endfunction : response_compare


//*******************************************************************************
// request_compare(): compare and check 2 Request type packets
//*******************************************************************************
	function void request_compare(input hmc_pkt_item expected, hmc_pkt_item packet);
		cmd_type_e packet_type = packet.get_command_type();
		if (packet_type == FLOW_TYPE || packet_type == RESPONSE_TYPE)
			`uvm_info("SCOREBOARD",$sformatf("request_compare: Unexpected Packet \n%s", packet.sprint()),UVM_MEDIUM)

		if (expected.command != packet.command) begin
			`uvm_info(get_type_name(), $sformatf("Expected: %s. got: %s", expected.sprint(), packet.sprint() ), UVM_LOW)	
			`uvm_info("SCOREBOARD",$sformatf("request_compare: Expected %s, got %s", expected.command.name(), packet.command.name()),UVM_MEDIUM)
		end

		if (expected.cube_ID != packet.cube_ID)
			`uvm_info("SCOREBOARD",$sformatf("request_compare: cube_ID mismatch %0d != %0d", expected.cube_ID, packet.cube_ID),UVM_MEDIUM)

		if (expected.address != packet.address)
			`uvm_info("SCOREBOARD",$sformatf("request_compare: Address mismatch %0d != %0d", expected.address, packet.address),UVM_MEDIUM)

		if (expected.length != packet.length)
			`uvm_info("SCOREBOARD",$sformatf("request_compare: Packet length mismatch %0d != %0d", expected.length, packet.length),UVM_MEDIUM)

		if (expected.tag != packet.tag) begin
			`uvm_info(get_type_name(), $sformatf("Expected: %s. got: %s", expected.sprint(), packet.sprint() ), UVM_LOW)	
			`uvm_info("SCOREBOARD",$sformatf("request_compare: Packet tag mismatch %0d != %0d ", expected.tag, packet.tag),UVM_MEDIUM)
		end	
		
		if (expected.payload.size() != packet.payload.size())
			`uvm_info("SCOREBOARD",$sformatf("request_compare: Payload size mismatch %0d != %0d", expected.payload.size(), packet.payload.size()),UVM_MEDIUM)

		for (int i=0;i<expected.payload.size();i = i+1) begin
			if (expected.payload[i] != packet.payload[i])
				`uvm_info("SCOREBOARD",$sformatf("request_compare: Payload mismatch at %0d %0x != %0x", i, expected.payload[i], packet.payload[i]),UVM_MEDIUM)
		end
	endfunction : request_compare


//*******************************************************************************
// check_phase(): after run phase is finished
//*******************************************************************************
	function void check_phase(uvm_phase phase);
		
		if (axi4_rsp_packet_count != hmc_rsp_packet_count)
			`uvm_info("SCOREBOARD",$sformatf("axi4_rsp_packet_count = %0d hmc_rsp_packet_count = %0d!", axi4_rsp_packet_count, hmc_rsp_packet_count),UVM_MEDIUM)
		if (axi4_req_packet_count != hmc_req_packet_count)
			`uvm_info("SCOREBOARD",$sformatf("axi4_req_packet_count = %0d hmc_req_packet_count = %0d!", axi4_req_packet_count, hmc_req_packet_count),UVM_MEDIUM)
		
		//-- check for open requests on the host side
		if (axi4_np_requests.size() > 0) begin
			for(int i=0;i<512;i++)begin
				if (axi4_np_requests.exists(i))begin
					`uvm_info("SCOREBOARD",$sformatf("Unanswered Requests: %0d with tag %0d", axi4_np_requests[i].size(), i), UVM_LOW)
				end
			end
			`uvm_info("SCOREBOARD",$sformatf("axi4_np_requests.size() = %0d, not all requests have been answered!", axi4_np_requests.size()),UVM_MEDIUM)
		end
		
		//-- check for open tags
		if (used_tags >0) begin
			foreach(used_tags[i]) begin
				if (used_tags[i] == 1'b1)
					`uvm_info("SCOREBOARD",$sformatf("Tag %0d is in use",  i), UVM_LOW)
			end
			`uvm_info("SCOREBOARD",$sformatf("Open Tags!"),UVM_MEDIUM)
		end
	endfunction : check_phase


//*******************************************************************************
// report_phase()
//*******************************************************************************
	/*function void report_phase(uvm_phase phase);
		`uvm_info(get_type_name(),$sformatf("axi4_req_count %0d", axi4_req_packet_count), UVM_LOW)
		`uvm_info(get_type_name(),$sformatf("axi4_rsp_count %0d", axi4_rsp_packet_count), UVM_LOW)
		`uvm_info(get_type_name(),$sformatf("hmc_req_count %0d",  hmc_req_packet_count),  UVM_LOW)
		`uvm_info(get_type_name(),$sformatf("hmc_rsp_count %0d",  hmc_rsp_packet_count),  UVM_LOW)
		`uvm_info(get_type_name(),$sformatf("Error response count %0d", axi4_error_response_count ),  UVM_LOW)
	endfunction : report_phase*/

endclass : scoreboard