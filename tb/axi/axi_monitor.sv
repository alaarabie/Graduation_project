
class axi_monitor #(NUM_DATA_BYTES = 64, DWIDTH = 512) extends uvm_monitor;

// add to factory 
`uvm_component_param_utils(axi_monitor #(.DWIDTH(DWIDTH), .NUM_DATA_BYTES(NUM_DATA_BYTES)))


// Virtual Interface and config	
virtual axi_interface #(.DWIDTH(DWIDTH), .NUM_DATA_BYTES(NUM_DATA_BYTES)) vif;
axi_config  #(.NUM_DATA_BYTES(NUM_DATA_BYTES), .DWIDTH(DWIDTH)) a_config;


// Declare analysis port
uvm_analysis_port #(hmc_pkt_item) request;
uvm_analysis_port #(hmc_pkt_item) response;


// Parameters
localparam FPW=4;
int HEADERS =FPW;
int TAILS =2*FPW;
int VALIDS=0 ;
typedef bit [127:0] flit_t;


// new - constructor	
function new ( string name="axi_monitor", uvm_component parent );
super.new(name, parent);
endfunction : new


// Connect interface to Virtual interface by using get method
function void build_phase(uvm_phase phase);
super.build_phase(phase);
if (!uvm_config_db#(axi_config #(.NUM_DATA_BYTES(NUM_DATA_BYTES), .DWIDTH(DWIDTH)))::get(this, "", "axi_config_t", a_config)) begin
`uvm_fatal(get_type_name(),"Couldn't get handle to vif")
end
vif = a_config.vif;
request = new("request", this);
response = new("response", this);
endfunction: build_phase


task run_phase(uvm_phase phase);
forever begin
	wait(vif.res_n)
	//vif.run();		
		@(posedge vif.clk);

	// write request 
	if (vif.t_valid == 1 && vif.t_ready == 1) 
	begin
		valid_data #(.DWIDTH(DWIDTH), .NUM_DATA_BYTES(NUM_DATA_BYTES)) vld_data;
		vld_data = new();
		vld_data.t_user = vif.t_user;
		vld_data.t_data = vif.t_data;
		write_req(vld_data);
	end

	// write response
	if (vif.rx_valid == 1) 
	begin
		valid_data #(.DWIDTH(DWIDTH), .NUM_DATA_BYTES(NUM_DATA_BYTES)) vld_data_rx;	
		vld_data_rx = new();
		vld_data_rx.t_user 	= vif.rx_user;
		vld_data_rx.t_data 	= vif.rx_data;
		write_res(vld_data_rx);
	end		
end
endtask : run_phase

////////////////////////////////////////////////////////////////////////////
// writing request
flit_t req_flit_queue[$];
hmc_pkt_item req_packet_queue[$];	
int req_headers_seen = 0;
int req_tails_seen = 0;

function void write_req (input valid_data #(.DWIDTH(DWIDTH), .NUM_DATA_BYTES(NUM_DATA_BYTES)) vld_data);
	hmc_pkt_item packet;
	collect_req_flits(vld_data);

	// convert flits to hmc_packets
	while (req_tails_seen>0) begin
			collect_req_packet();		
	end

	while (req_packet_queue.size()>0) begin
		packet = req_packet_queue.pop_front();
		request.write(packet);
		`uvm_info("AXI4 to HMC Monitor",$psprintf("\n%s", packet.sprint()), UVM_MEDIUM)
	end

endfunction : write_req


function void collect_req_flits(input valid_data #(.DWIDTH(DWIDTH), .NUM_DATA_BYTES(NUM_DATA_BYTES)) vld_data);
	flit_t tmp_flit;
	for (int i = 0; i<FPW; i++) begin // loop on flits 
		if (vld_data.t_user[VALIDS+i] == 1) // check valid ? -> write to flit queue
		begin
			for (int b=0; b<128; b++)
				tmp_flit[b] = vld_data.t_data[128*i+b];

			req_flit_queue.push_back(tmp_flit);

			if (vld_data.t_user[HEADERS+i] == 1) // check header ?
			begin 
				req_headers_seen++; 
			end

			if (vld_data.t_user[TAILS+i] == 1) // check tail ?
			begin
				req_tails_seen++; 
			end
		end
	end

endfunction : collect_req_flits


function void collect_req_packet();
	//flit_queue_empty : assert (req_flit_queue.size() > 0);
	hmc_pkt_item packet;
	flit_t current_flit;
	bit bitstream[];
	int req_pkt_lng;
	//-- First flit is always header
	current_flit = req_flit_queue.pop_front();
	req_pkt_lng = current_flit[10:7];
	`uvm_info(get_type_name(),$psprintf("packet length %0d ", req_pkt_lng), UVM_MEDIUM)
	`uvm_info(get_type_name(),$psprintf("queue size %0d ", req_flit_queue.size()+1), UVM_MEDIUM)
	flit_queue_lost : assert (req_flit_queue.size() >= req_pkt_lng - 1);		

	bitstream = new[req_pkt_lng*128];
	// Pack first flit
	for (int i=0; i<128; i=i+1)
		bitstream[i] = current_flit[i];
	// Pack the remaining flits
	for (int flit=1; flit < req_pkt_lng; flit ++) 
	begin
		current_flit = req_flit_queue.pop_front();
		for (int i=0; i<128; i=i+1) 
			bitstream[flit*128+i] = current_flit[i];
	end

	
	packet = hmc_pkt_item::type_id::create("packet", this);
	void'(packet.unpack(bitstream));

	if (packet == null) begin
	  `uvm_fatal(get_type_name(), $psprintf("packet is null"))
	end
	req_headers_seen--;
	req_tails_seen--; 
	req_packet_queue.push_back(packet);

endfunction : collect_req_packet

////////////////////////////////////////////////////////////////////////////
// writing response
flit_t res_flit_queue[$];
hmc_pkt_item res_packet_queue[$];	
int res_headers_seen = 0;
int res_tails_seen = 0;

function void write_res (input valid_data #(.DWIDTH(DWIDTH), .NUM_DATA_BYTES(NUM_DATA_BYTES)) vld_data);
	hmc_pkt_item packet;
	collect_res_flits(vld_data);

	// convert flits to hmc_packets
	while (res_tails_seen>0) begin
			collect_res_packet();		
	end

	while (res_packet_queue.size()>0) begin
		packet = res_packet_queue.pop_front();
		response.write(packet);
		`uvm_info("AXI4 to HMC Monitor",$psprintf("\n%s", packet.sprint()), UVM_MEDIUM)
	end

endfunction : write_res


function void collect_res_flits(input valid_data #(.DWIDTH(DWIDTH), .NUM_DATA_BYTES(NUM_DATA_BYTES)) vld_data);
	flit_t tmp_flit;
	for (int i = 0; i<FPW; i++) begin // loop on flits 
		if (vld_data.t_user[VALIDS+i] == 1) // check valid ? -> write to flit queue
		begin
			for (int b=0; b<128; b++)
				tmp_flit[b] = vld_data.t_data[128*i+b];

			res_flit_queue.push_back(tmp_flit);

			if (vld_data.t_user[HEADERS+i] == 1) // check header ?
			begin 
				res_headers_seen++; 
			end

			if (vld_data.t_user[TAILS+i] == 1) // check tail ?
			begin
				res_tails_seen++; 
			end
		end
	end

endfunction : collect_res_flits


function void collect_res_packet();
	//flit_queue_empty : assert (res_flit_queue.size() > 0);
	hmc_pkt_item packet;
	flit_t current_flit;
	bit bitstream[];
	int res_pkt_lng;
	//-- First flit is always header
	current_flit = res_flit_queue.pop_front();
	res_pkt_lng = current_flit[10:7];
	`uvm_info(get_type_name(),$psprintf("packet length %0d ", res_pkt_lng), UVM_MEDIUM)
	`uvm_info(get_type_name(),$psprintf("queue size %0d ", res_flit_queue.size()+1), UVM_MEDIUM)
	flit_queue_lost : assert (res_flit_queue.size() >= res_pkt_lng - 1);		

	bitstream = new[res_pkt_lng*128];
	// Pack first flit
	for (int i=0; i<128; i=i+1)
		bitstream[i] = current_flit[i];
	// Pack the remaining flits
	for (int flit=1; flit < res_pkt_lng; flit ++) 
	begin
		current_flit = res_flit_queue.pop_front();
		for (int i=0; i<128; i=i+1) 
			bitstream[flit*128+i] = current_flit[i];
	end

	
	packet = hmc_pkt_item::type_id::create("packet", this);
	void'(packet.unpack(bitstream));

	if (packet == null) begin
	  `uvm_fatal(get_type_name(), $psprintf("packet is null"))
	end
	res_headers_seen--;
	res_tails_seen--; 
	res_packet_queue.push_back(packet);

endfunction : collect_res_packet

endclass : axi_monitor

