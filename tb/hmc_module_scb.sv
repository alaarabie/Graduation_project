class hmc_module_scb  extends uvm_scoreboard;
	`uvm_component_utils(hmc_module_scb )

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
	//-- HMC Interface
    `uvm_analysis_imp_decl(_hmc_req)
    uvm_analysis_imp_hmc_req #(hmc_pkt_item, hmc_module_scb) hmc_req_port;
    `uvm_analysis_imp_decl(_hmc_rsp)
    uvm_analysis_imp_hmc_rsp #(hmc_pkt_item, hmc_module_scb) hmc_rsp_port;
	`uvm_analysis_imp_decl(_axi4_hmc_req)
    uvm_analysis_imp_axi4_hmc_req #(hmc_pkt_item, hmc_module_scb) axi4_hmc_req; 
    `uvm_analysis_imp_decl(_axi4_hmc_rsp)
    uvm_analysis_imp_axi4_hmc_rsp #(hmc_pkt_item, hmc_module_scb) axi4_hmc_rsp;

    function new (string name="hmc_module_scb", uvm_component parent);
		super.new(name, parent);
		// Instantiate the analysis port
		axi4_hmc_req = new("axi4_hmc_req",this);
		axi4_hmc_rsp = new("axi4_hmc_rsp",this);
		hmc_req_port = new("hmc_req_port",this);
		hmc_rsp_port = new("hmc_rsp_port",this);
	endfunction : new


	function void write_hmc_rsp(input hmc_pkt_item packet);
		hmc_pkt_item expected;

		if (packet.command != ERROR_RS) begin //TODO cover error response
			hmc_rsp_packet_count++;
			`uvm_info(get_type_name(),$psprintf("hmc_rsp: received packet #%0d %s", hmc_rsp_packet_count, packet.command.name()), UVM_MEDIUM)
			`uvm_info(get_type_name(),$psprintf("hmc_rsp: \n%s", packet.sprint()), UVM_HIGH)
		end else begin
			hmc_error_response_count++;
			`uvm_info(get_type_name(),$psprintf("hmc_error_rsp: received error response #%0d %s", hmc_error_response_count, packet.command.name()), UVM_MEDIUM)
			`uvm_info(get_type_name(),$psprintf("hmc_error_rsp: \n%s", packet.sprint()), UVM_HIGH)
		end

		//-- check this packet later 
		
		//-- the response packet might be delayed due to the packet mon
		//-- check if the response packet is already received on the axi link
		if (axi4_response.size() == 0)
			hmc_response.push_back(packet);
		else begin //-- check the packet
			expected = axi4_response.pop_front();
			response_compare(expected, packet); //TODO

			if (packet.command != ERROR_RS) begin //TODO cover error response
								//-- check if open request with tag is available
				if (used_tags[packet.tag] == 1'b1) begin
					used_tags[packet.tag] =  1'b0;
				end else begin
					`uvm_fatal(get_type_name(),$psprintf("Packet with Tag %0d was not requested", packet.tag))
				end
			end
		end
	endfunction : write_hmc_rsp


	function void write_hmc_req(input hmc_pkt_item packet);
		hmc_pkt_item expected;

		if (packet == null) begin
		  `uvm_fatal(get_type_name(), $psprintf("packet is null"))
		 end
		
		hmc_req_packet_count++;	

		`uvm_info(get_type_name(),$psprintf("hmc_req: received packet #%0d %s@%0x (tok %0d)", hmc_req_packet_count, packet.command.name(), packet.address, packet.return_token_count), UVM_MEDIUM)
		`uvm_info(get_type_name(),$psprintf("hmc_req: \n%s", packet.sprint()), UVM_HIGH)

		//-- expect an request packet on the host (AXI4) request queue
		if (axi4_2_hmc.size() == 0)
			`uvm_fatal(get_type_name(),$psprintf("write_hmc_req: Unexpected packet (the request queue is empty)\n%s",packet.sprint()))
		else
			expected = axi4_2_hmc.pop_front();

		//-- compare and check 2 Request type packets
		request_compare(expected, packet);
		`uvm_info(get_type_name(),$psprintf("hmc_req: checked packet #%0d %s@%0x", hmc_req_packet_count, packet.command.name(), packet.address), UVM_MEDIUM)
	endfunction : write_hmc_req

	function void write_axi4_hmc_rsp(input hmc_packet packet);
	endfunction :write_axi4_hmc_rsp


	function void write_axi4_hmc_req(input hmc_packet packet);
	endfunction :write_axi4_hmc_req

	//-- compare the received response packets and check with the previous sent request packet
	function void response_compare(input hmc_packet expected, input hmc_packet packet);
	endfunction : response_compare

	//-- compare and check 2 Request type packets
	function void request_compare(input hmc_packet expected, hmc_packet packet);
	endfunction : request_compare

	function void check_phase(uvm_phase phase);
		
		if (axi4_rsp_packet_count != hmc_rsp_packet_count)
			`uvm_fatal(get_type_name(),$psprintf("axi4_rsp_packet_count = %0d hmc_rsp_packet_count = %0d!", axi4_rsp_packet_count, hmc_rsp_packet_count))
		if (axi4_req_packet_count != hmc_req_packet_count)
			`uvm_fatal(get_type_name(),$psprintf("axi4_req_packet_count = %0d hmc_req_packet_count = %0d!", axi4_req_packet_count, hmc_req_packet_count))
		
		//-- check for open requests on the host side
		if (axi4_np_requests.size() > 0) begin
			for(int i=0;i<512;i++)begin
				if (axi4_np_requests.exists(i))begin
					`uvm_info(get_type_name(),$psprintf("Unanswered Requests: %0d with tag %0d", axi4_np_requests[i].size(), i), UVM_LOW)
				end
			end
			`uvm_fatal(get_type_name(),$psprintf("axi4_np_requests.size() = %0d, not all requests have been answered!", axi4_np_requests.size()))
		end
		
		//-- check for open tags
		if (used_tags >0) begin
			foreach(used_tags[i]) begin
				if (used_tags[i] == 1'b1)
					`uvm_info(get_type_name(),$psprintf("Tag %0d is in use",  i), UVM_LOW)
			end
			`uvm_fatal(get_type_name(),$psprintf("Open Tags!"))
		end
	endfunction : check_phase

	function void report_phase(uvm_phase phase);
		`uvm_info(get_type_name(),$psprintf("axi4_req_count %0d", axi4_req_packet_count), UVM_LOW)
		`uvm_info(get_type_name(),$psprintf("axi4_rsp_count %0d", axi4_rsp_packet_count), UVM_LOW)
		`uvm_info(get_type_name(),$psprintf("hmc_req_count %0d",  hmc_req_packet_count),  UVM_LOW)
		`uvm_info(get_type_name(),$psprintf("hmc_rsp_count %0d",  hmc_rsp_packet_count),  UVM_LOW)
		`uvm_info(get_type_name(),$psprintf("Error response count %0d", axi4_error_response_count ),  UVM_LOW)
	endfunction : report_phase

endclass : hmc_module_scb