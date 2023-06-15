
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
bit req_pkt[];
bit res_pkt[];
	

// new - constructor	
function new ( string name="axi_monitor", uvm_component parent );
super.new(name, parent);
request = new("request", this);
response = new("response", this);
endfunction : new


// Connect interface to Virtual interface by using get method
function void build_phase(uvm_phase phase);
super.build_phase(phase);
if (!uvm_config_db#(axi_config #(.NUM_DATA_BYTES(NUM_DATA_BYTES), .DWIDTH(DWIDTH)))::get(this, "", "axi_config_t", a_config)) begin
`uvm_fatal(get_type_name(),"Couldn't get handle to vif")
end
vif = a_config.vif;
endfunction: build_phase


// monitor transmitted data
task request_to_monitor();
valid_data #(.DWIDTH(DWIDTH), .NUM_DATA_BYTES(NUM_DATA_BYTES)) vld_data;
forever
begin
	if (vif.res_n !== 1)
	begin
		@(posedge vif.res_n);
	end
	fork
		begin 
			@(negedge vif.res_n);
		end

		forever 
		begin
			@(posedge vif.clk);
			vld_data = new();
			if (vif.t_valid == 1 && vif.t_ready == 1) 
			begin
				vld_data.t_user = vif.t_user;
				vld_data.t_data = vif.t_data;
				req_valid_data_2_hmc_pkt(vld_data);
			end
			if (vif.t_valid == 0) 
			begin
				vld_data.t_user	= 'b0;
				vld_data.t_data	= 'b0;
				req_valid_data_2_hmc_pkt(vld_data);
			end
		end
	join_any
	disable fork;
end
endtask : request_to_monitor


task req_valid_data_2_hmc_pkt(valid_data #(.DWIDTH(DWIDTH), .NUM_DATA_BYTES(NUM_DATA_BYTES)) vld_data);

for (int f=0; f<FPW; f++) 
begin

	if (vld_data.t_user[f+FPW]==1) //header?
	begin 	
		bit [3:0] pkt_length = vld_data.t_data[10:7];
		req_pkt = new[pkt_length*128];
	end 

	if (vld_data.t_user[f]==1) //valid?
		req_pkt={req_pkt, vld_data.t_data[128*(f-1):(128*f)-1]};

	if (vld_data.t_user[f+2*FPW]==1) //tail?
	begin
		hmc_pkt_item hmc_pkt;
		hmc_pkt = hmc_pkt_item::type_id::create("hmc_pkt", this);
		if (hmc_pkt.unpack(req_pkt))
		begin 
			request.write(hmc_pkt);
			req_pkt.delete;
		end else 
			`uvm_error(get_type_name(),"Could not unpack request hmc_packet")	
	end 	
end

endtask : req_valid_data_2_hmc_pkt

// monitor received data
task response_from_memory ();
valid_data #(.DWIDTH(DWIDTH), .NUM_DATA_BYTES(NUM_DATA_BYTES)) rx_data;
forever 
begin
	if (vif.res_n !== 1)
	begin
		@(posedge vif.res_n);
	end
	fork
		begin 
			@(negedge vif.res_n);
		end

		forever 
		begin
			@(posedge vif.clk);
			rx_data = new();
			if (vif.rx_valid == 1) 
			begin
				rx_data.t_user 	= vif.rx_user;
				rx_data.t_data 	= vif.rx_data;
				res_valid_data_2_hmc_pkt(rx_data);
			end
			if (vif.rx_valid == 0) 
			begin
				rx_data.t_user	= 'b0;
				rx_data.t_data	= 'b0;
				res_valid_data_2_hmc_pkt(rx_data);
			end
		end
	join_any
	disable fork;
end
endtask : response_from_memory


task res_valid_data_2_hmc_pkt(valid_data #(.DWIDTH(DWIDTH), .NUM_DATA_BYTES(NUM_DATA_BYTES)) vld_data);

for (int f=0; f<FPW; f++) 
begin

	if (vld_data.t_user[f+FPW]==1) //header?
	begin	
		bit [3:0] pkt_length = vld_data.t_data[10:7];
		res_pkt = new[pkt_length*128];
	end 

	if (vld_data.t_user[f]==1) //valid?
		res_pkt={res_pkt, vld_data.t_data[128*(f-1):(128*f)-1]};

	if (vld_data.t_user[f+2*FPW]==1) //tail?
	begin
		hmc_pkt_item hmc_pkt;
		hmc_pkt = hmc_pkt_item::type_id::create("hmc_pkt", this);
		if (hmc_pkt.unpack(res_pkt))
		begin 
			response.write(hmc_pkt);
			res_pkt.delete;
		end else 
			`uvm_error(get_type_name(),"Could not unpack response hmc_packet")	
	end 	
end

endtask : res_valid_data_2_hmc_pkt


endclass : axi_monitor

