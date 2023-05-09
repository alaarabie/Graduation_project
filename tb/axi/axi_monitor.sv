`ifndef axi_monitor_SV
`define axi_monitor_SV


class axi_monitor  #(parameter t_user_width = 16, parameter t_data_bit = 128) extends  uvm_monitor;

// add to factory 
`uvm_component_param_utils(axi_monitor #(.t_data_bit(t_data_bit), .t_user_width(t_user_width)))


// Virtual Interface	
virtual interface axi_if #(.t_data_bit(t_data_bit), .t_user_width(t_user_width)) vif;


// Declare analysis port
uvm_analysis_port   #(valid_data #(.t_data_bit(t_data_bit), .t_user_width(t_user_width))) 	request;
uvm_analysis_port   #(valid_data #(.t_data_bit(t_data_bit), .t_user_width(t_user_width))) 	response;

	
// new - constructor	
function new ( string name="axi_monitor", uvm_component parent );
super.new(name, parent);
request = new("request", this);
response = new("response", this);
endfunction : new


// Connect interface to Virtual interface by using get method
function void build_phase(uvm_phase phase);
super.build_phase(phase);
if(!uvm_config_db#(virtual interface axi_if #(.t_data_bit(t_data_bit), .t_user_width(t_user_width)))::get(this, "", "vif", vif))begin
`uvm_fatal("NOVIF",{"virtual interface must be set for: ",get_full_name(),".vif"});
end else begin
this.vif = vif;
end
endfunction: build_phase


// monitor transmitted data
virtual task request_to_monitor(uvm_phase phase);
valid_data #(.t_data_bit(t_data_bit), .t_user_width(t_user_width)) vld_data;
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
vld_data.t_user	= {t_user_width{'b0}};
vld_data.t_data	= {t_data_bit{'b0}};
request.write(vld_data);
end
end
join_any
disable fork;
end
endtask : request_to_monitor


// monitor received data
virtual task response_from_memory (uvm_phase phase);
valid_data #(.t_data_bit(t_data_bit), .t_user_width(t_user_width)) rx_data;
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
rx_data.t_user	= {t_user_width{'b0}};
rx_data.t_data	= {t_data_bit{'b0}};
response.write(rx_data);
end
end
join_any
disable fork;
end
endtask : response_from_memory

endclass : axi_monitor
`endif
