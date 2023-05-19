
class axi_agent #(NUM_DATA_BYTES = 64, DWIDTH = 512) extends uvm_agent;

// uvm macro file
`uvm_component_param_utils(axi_agent #(.NUM_DATA_BYTES(NUM_DATA_BYTES), .DWIDTH(DWIDTH)))

// declaring agent component
axi_config #(.NUM_DATA_BYTES(NUM_DATA_BYTES), .DWIDTH(DWIDTH)) a_config;
axi_driver  #(.NUM_DATA_BYTES(NUM_DATA_BYTES), .DWIDTH(DWIDTH))  a_driver;
axi_monitor  #(.NUM_DATA_BYTES(NUM_DATA_BYTES), .DWIDTH(DWIDTH))  a_monitor;
axi_sequencer #(.NUM_DATA_BYTES(NUM_DATA_BYTES), .DWIDTH(DWIDTH)) a_sequencer;

  uvm_analysis_port #(valid_data #(.DWIDTH(DWIDTH), .NUM_DATA_BYTES(NUM_DATA_BYTES))) mon_request ;
  uvm_analysis_port #(valid_data #(.DWIDTH(DWIDTH), .NUM_DATA_BYTES(NUM_DATA_BYTES))) mon_response ;  



// constructor
function new (string name , uvm_component parent);
super.new(name,parent);
endfunction 

// build_phase
function void build_phase(uvm_phase phase);
super.build_phase(phase);

if (!uvm_config_db#(axi_config #(.NUM_DATA_BYTES(NUM_DATA_BYTES), .DWIDTH(DWIDTH)))::get(this, "", "axi_config_t", a_config)) begin
`uvm_fatal("axi_agent","Failed to get config object")
end 
/*else begin
uvm_config_db#(axi_config)::set(this, "a_driver"	, "a_config", a_config);
end
*/

if(a_config.agent_active == UVM_ACTIVE) begin
//uvm_config_db#(axi_config)::set(this, "a_driver", "a_config", a_config);	
a_driver = axi_driver #(.NUM_DATA_BYTES(NUM_DATA_BYTES), .DWIDTH(DWIDTH))::type_id::create("a_driver", this);
a_sequencer = axi_sequencer #(.NUM_DATA_BYTES(NUM_DATA_BYTES), .DWIDTH(DWIDTH))::type_id::create("a_sequencer", this);
end

  	a_monitor = axi_monitor#(.NUM_DATA_BYTES(NUM_DATA_BYTES), .DWIDTH(DWIDTH))::type_id::create("a_monitor",this);

  	mon_request = new("mon_request",this);
    mon_response = new("mon_response",this);    

endfunction : build_phase


// connect_phase
function void connect_phase(uvm_phase phase);
super.connect_phase(phase);
if(a_config.agent_active  == UVM_ACTIVE) begin
a_driver.seq_item_port.connect(a_sequencer.seq_item_export);
  	a_monitor.request.connect(mon_request);
    a_monitor.response.connect(mon_response); 
end
endfunction : connect_phase

endclass : axi_agent


