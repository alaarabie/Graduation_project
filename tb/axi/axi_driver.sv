`ifndef axi_driver_sv
`define axi_driver_sv

class axi_driver #(parameter t_user_width = 16, parameter t_data_bit = 128) extends uvm_driver #(valid_data #(.t_user_width(t_user_width), .t_user_width(t_user_width)));;

`uvm_component_param_utils_begin(axi_driver)
`uvm_field_object(a_config, UVM_DEFAULT)
`uvm_component_utils_end

// Declare the virtual interface
virtual interface axi_if #(.t_user_width(t_user_width), .t_data_bit(t_data_bit)) vif;
valid_data #(.t_data_bit(t_data_bit), .t_user_width(t_user_width)) vld_data;
axi_config    a_config;


// constructor
function new (string name = "axi_driver" , uvm_component parent);
super.new(name,parent)
endfunction 


// build_phase
function void build_phase(uvm_phase phase);
super.build_phase(phase);

// Get the interface handle
if(!uvm_config_db#(virtual interface axi_if #(.t_user_width(t_user_width), .t_data_bit(t_data_bit)))::get(this,"", "vif", vif )) begin
`uvm_fatal(get_type_name(),"Couldn't get handle to virtual interface")
end
endfunction : build_phase


// run phase
task run_phase(uvm_phase phase);
super.run_phase(phase);
forever begin
// check reset	
if(vif.rst_n !== 1) begin
vif.TVALID <= 0;
`uvm_info(get_type_name(),$psprintf("during reset"), UVM_HIGH)
@(posedge vif.rst_n);
`uvm_info(get_type_name(),$psprintf("coming out of reset"), UVM_HIGH)
end
fork 
begin 
@(negedge vif.rst_n);
end
begin 
// get next data item from sequencer
seq_item_port.try_next_item(vld_data);
if (vld_data == null) begin // No data item to execute, send an idle transaction
vif.t_data  <= 0;
vif.t_user  <= 0;
vif.t_valid <= 0;	
end 
else begin 					// Got a valid item from the sequencer, execute it
// execute the item
drive_data(vld_data);
seq_item_port.item_done();
end		
end
join_any
disable fork; 	
end
endtask : run_phase


task drive_data(input valid_data #(.t_data_bit(t_data_bit), .t_user_width(t_user_width)) vld_data);
if(vld_data != null) begin
`uvm_info(get_type_name(),$psprintf("data is ready to be sent"), UVM_HIGH)
`uvm_info(get_type_name(),$psprintf("send %0x %0x", vld_data.t_user, vld_data.t_data), UVM_HIGH)
end
vif.t_data  <= vld_data.t_data;
vif.t_user  <= vld_data.t_user;
vif.t_valid <= 1;
@(posedge vif.clk);
while(vif.t_ready == 0)
@(posedge vif.clk);
vif.t_data  <= 0;
vif.t_user  <= 0;
vif.t_valid <= 0;
`uvm_info(get_type_name(),$psprintf("data is sent"), UVM_HIGH)
endtask :drive_data

endclass : axi_driver
`endif
