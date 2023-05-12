
class axi_monitor  #(parameter T_USER_WIDTH = 16, parameter T_DATA_BIT = 128) extends uvm_monitor;

// add to factory 
`uvm_component_param_utils(axi_monitor #(.T_DATA_BIT(T_DATA_BIT), .T_USER_WIDTH(T_USER_WIDTH)))


// Virtual Interface	
virtual interface axi_if #(.T_DATA_BIT(T_DATA_BIT), .T_USER_WIDTH(T_USER_WIDTH)) vif;


// Declare analysis port
uvm_analysis_port   #(valid_data #(.T_DATA_BIT(T_DATA_BIT), .T_USER_WIDTH(T_USER_WIDTH))) 	request;
uvm_analysis_port   #(valid_data #(.T_DATA_BIT(T_DATA_BIT), .T_USER_WIDTH(T_USER_WIDTH))) 	response;

	
// new - constructor	
function new ( string name="axi_monitor", uvm_component parent );
super.new(name, parent);
request = new("request", this);
response = new("response", this);
endfunction : new


// Connect interface to Virtual interface by using get method
function void build_phase(uvm_phase phase);
super.build_phase(phase);
if(!uvm_config_db#(virtual interface axi_if #(.T_DATA_BIT(T_DATA_BIT), .T_USER_WIDTH(T_USER_WIDTH)))::get(this, "", "vif", vif))begin
`uvm_fatal("NOVIF",{"virtual interface must be set for: ",get_full_name(),".vif"});
end else begin
this.vif = vif;
end
endfunction: build_phase


// monitor transmitted data
virtual task request_to_monitor(uvm_phase phase);
valid_data #(.T_DATA_BIT(T_DATA_BIT), .T_USER_WIDTH(T_USER_WIDTH)) vld_data;
forever begin
if (vif.rst_n !== 1)
begin
@(posedge vif.rst_n);
end
fork
begin 
@(negedge vif.rst_n);
end
forever begin
@(posedge vif.ACLK);
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
valid_data #(.T_DATA_BIT(T_DATA_BIT), .T_USER_WIDTH(T_USER_WIDTH)) rx_data;
forever begin
if (vif.rst_n !== 1)
begin
@(posedge vif.rst_n);
end
fork
begin 
@(negedge vif.rst_n);
end
forever begin
@(posedge vif.ACLK);
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

