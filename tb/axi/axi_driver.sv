
class axi_driver #(parameter t_user_width = 16, parameter t_data_bit = 128) extends uvm_driver #(valid_data #(.t_user_width(t_user_width), .t_user_width(t_user_width)));

// Declare the virtual interface
virtual interface axi_if #(.t_user_width(t_user_width), .t_data_bit(t_data_bit)) vif;
valid_data #(.t_data_bit(t_data_bit), .t_user_width(t_user_width)) vld_data;
axi_config    a_config;

`uvm_component_param_utils_begin(axi_driver #(.t_user_width(t_user_width), .t_data_bit(t_data_bit)))
`uvm_field_object(a_config, UVM_DEFAULT)
`uvm_component_utils_end

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
drive_data();
end
join_any
disable fork; 	
end
endtask : run_phase


task drive_data();
@(posedge vif.clk);
forever begin
valid_data #(.t_data_bit(t_data_bit), .t_user_width(t_user_width)) vld_data;
// get next data item from sequencer
seq_item_port.try_next_item(vld_data);
if (vld_data != null) // Got a valid item from the sequencer, execute it 
begin 	
`uvm_info(get_type_name(),$psprintf("data is ready to be sent"), UVM_HIGH)
`uvm_info(get_type_name(),$psprintf("send %0x %0x", vld_data.t_user, vld_data.t_data), UVM_HIGH)

// wait until delay
repeat(vld_data.delay)
@(posedge vif.clk);
				
//send AXI cycle
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
seq_item_port.item_done();
end	
else @(posedge vif.clk);

end
endtask :drive_data

endclass : axi_driver
