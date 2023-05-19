
class axi_monitor #(NUM_DATA_BYTES = 64, DWIDTH = 512)  extends uvm_monitor;

// add to factory 
`uvm_component_param_utils(axi_monitor #(.DWIDTH(DWIDTH), .NUM_DATA_BYTES(NUM_DATA_BYTES)))


// Virtual Interface and config	
virtual axi_interface #(.DWIDTH(DWIDTH), .NUM_DATA_BYTES(NUM_DATA_BYTES)) vif;
axi_config  #(.NUM_DATA_BYTES(NUM_DATA_BYTES), .DWIDTH(DWIDTH))  a_config;


// Declare analysis port
uvm_analysis_port   #(valid_data #(.DWIDTH(DWIDTH), .NUM_DATA_BYTES(NUM_DATA_BYTES))) 	request;
uvm_analysis_port   #(valid_data #(.DWIDTH(DWIDTH), .NUM_DATA_BYTES(NUM_DATA_BYTES))) 	response;

	
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
vif = a_config.vif;
end
endfunction: build_phase


// monitor transmitted data
virtual task request_to_monitor(uvm_phase phase);
valid_data #(.DWIDTH(DWIDTH), .NUM_DATA_BYTES(NUM_DATA_BYTES)) vld_data;
forever begin
if (vif.res_n !== 1)
begin
@(posedge vif.res_n);
end
fork
begin 
@(negedge vif.res_n);
end
forever begin
@(posedge vif.clk);
vld_data = new();
if (vif.t_valid == 1 && vif.t_ready == 1) begin
vld_data.t_user 	= vif.t_user;
vld_data.t_data 	= vif.t_data;
request.write(vld_data);
end
if (vif.t_valid == 0) begin
vld_data.t_user	= 'b0;
vld_data.t_data	= 'b0;
request.write(vld_data);
end
end
join_any
disable fork;
end
endtask : request_to_monitor


// monitor received data
virtual task response_from_memory (uvm_phase phase);
valid_data #(.DWIDTH(DWIDTH), .NUM_DATA_BYTES(NUM_DATA_BYTES)) rx_data;
forever begin
if (vif.res_n !== 1)
begin
@(posedge vif.res_n);
end
fork
begin 
@(negedge vif.res_n);
end
forever begin
@(posedge vif.clk);
rx_data = new();
if (vif.rx_valid == 1) begin
rx_data.t_user 	= vif.rx_user;
rx_data.t_data 	= vif.rx_data;
response.write(rx_data);
end
if (vif.rx_valid == 0) begin
rx_data.t_user	= 'b0;
rx_data.t_data	= 'b0;
response.write(rx_data);
end
end
join_any
disable fork;
end
endtask : response_from_memory

endclass : axi_monitor

