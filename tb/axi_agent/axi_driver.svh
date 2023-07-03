
class axi_driver #(NUM_DATA_BYTES = 64, DWIDTH = 512) extends uvm_driver #(valid_data #(.NUM_DATA_BYTES(NUM_DATA_BYTES), .DWIDTH(DWIDTH)));

// Declare the virtual interface
virtual axi_interface #(NUM_DATA_BYTES,DWIDTH) vif;

axi_config  #(.NUM_DATA_BYTES(NUM_DATA_BYTES), .DWIDTH(DWIDTH))  a_config;

`uvm_component_param_utils(axi_driver #(.NUM_DATA_BYTES(NUM_DATA_BYTES), .DWIDTH(DWIDTH)))


// constructor
function new (string name = "axi_driver" , uvm_component parent);
super.new(name,parent);
endfunction 


// build_phase
function void build_phase(uvm_phase phase);
super.build_phase(phase);

// Get the interface handle

if (!uvm_config_db#(axi_config #(.NUM_DATA_BYTES(NUM_DATA_BYTES), .DWIDTH(DWIDTH)))::get(this, "", "axi_config_t", a_config)) begin
`uvm_fatal(get_type_name(),"Couldn't get handle to vif")
end
vif = a_config.vif;


endfunction : build_phase


// run phase
task run_phase(uvm_phase phase);
	//super.run_phase(phase);
	forever begin
		// check reset	
		if(vif.res_n == 0) begin
			vif.t_valid <= 0;
			vif.t_data <= 0;
			vif.t_user <= 0;
			vif.rx_ready <= 0;
			`uvm_info(get_type_name(),$psprintf("during reset"), UVM_HIGH)
			@(posedge vif.res_n);
			`uvm_info(get_type_name(),$psprintf("coming out of reset"), UVM_HIGH)
		end

		fork 
			begin 
				@(negedge vif.res_n);
			end

			begin 
				drive_data();
			end

			forever begin
				@(posedge vif.clk);
				if (vif.rx_valid)
						randcase
							3 : vif.rx_ready <= 1;
							1 : vif.rx_ready <= 0;
						endcase
				else 
						randcase
							1 : vif.rx_ready <= 1;
							1 : vif.rx_ready <= 0;
							1 : begin		//-- hold tready at least until tvalid is set
										vif.rx_ready <= 0;
										while (vif.rx_valid == 0)
											@(posedge vif.clk);
									end
						endcase
			end

		join_any
		disable fork; 	
	end
endtask : run_phase


task drive_data();
@(posedge vif.clk);
forever begin
valid_data #(.DWIDTH(DWIDTH), .NUM_DATA_BYTES(NUM_DATA_BYTES)) vld_data;
// get next data item from sequencer
seq_item_port.try_next_item(vld_data);
if (vld_data != null) // Got a valid item from the sequencer, execute it 
begin 	
`uvm_info(get_type_name(),$sformatf("data is ready to be sent"), UVM_HIGH)
`uvm_info(get_type_name(),$sformatf("send %0x %0x", vld_data.t_user, vld_data.t_data), UVM_HIGH)

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

`uvm_info(get_type_name(),$sformatf("data is sent"), UVM_HIGH)
seq_item_port.item_done();
end	
else @(posedge vif.clk);

end
endtask :drive_data

endclass : axi_driver
