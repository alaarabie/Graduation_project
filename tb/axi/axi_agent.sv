
class axi_agent  #(parameter T_USER_WIDTH = 16, parameter T_DATA_BIT = 128) extends uvm_agent;


// declaring agent component
axi_driver  #(.T_USER_WIDTH(T_USER_WIDTH), .T_DATA_BIT(T_DATA_BIT))  a_driver;
axi_monitor  #(.T_USER_WIDTH(T_USER_WIDTH), .T_DATA_BIT(T_DATA_BIT))  a_monitor;
axi_sequencer #(.T_USER_WIDTH(T_USER_WIDTH), .T_DATA_BIT(T_DATA_BIT)) a_sequencer;
axi_config    a_config;

  uvm_analysis_port #(valid_data #(.T_DATA_BIT(T_DATA_BIT), .T_USER_WIDTH(T_USER_WIDTH))) mon_request ;
  uvm_analysis_port #(valid_data #(.T_DATA_BIT(T_DATA_BIT), .T_USER_WIDTH(T_USER_WIDTH))) mon_response ;  


// uvm macro file
`uvm_component_param_utils_begin(axi_agent #(.T_USER_WIDTH(T_USER_WIDTH), .T_DATA_BIT(T_DATA_BIT)))
`uvm_field_object(a_config, UVM_DEFAULT)
`uvm_field_object(a_driver,          UVM_DEFAULT)
`uvm_field_object(a_monitor,          UVM_DEFAULT)
`uvm_field_object(a_sequencer,       UVM_DEFAULT)
`uvm_component_utils_end

// constructor
function new (string name = "axi_agent" , uvm_component parent);
super.new(name,parent);
endfunction 

// build_phase
function void build_phase(uvm_phase phase);
super.build_phase(phase);

if (!uvm_config_db#(axi_config)::get(this, "", "a_config", a_config)) begin
uvm_report_fatal(get_type_name(), $psprintf("a_config is not set"));
end else begin
uvm_config_db#(axi_config)::set(this, "a_driver"	, "a_config", a_config);
end

if(a_config.agent_active == UVM_ACTIVE) begin
uvm_config_db#(axi_config)::set(this, "a_driver", "a_config", a_config);	
a_driver = axi_driver #(.T_USER_WIDTH(T_USER_WIDTH), .T_DATA_BIT(T_DATA_BIT))::type_id::create("a_driver", this);
a_sequencer = axi_sequencer #(.T_USER_WIDTH(T_USER_WIDTH), .T_DATA_BIT(T_DATA_BIT))::type_id::create("a_sequencer", this);
end

  	a_monitor = axi_monitor#(.T_USER_WIDTH(T_USER_WIDTH), .T_DATA_BIT(T_DATA_BIT))::type_id::create("a_monitor",this);

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


