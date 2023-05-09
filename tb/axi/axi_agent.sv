`ifndef axi_agent_sv
`define axi_agent_sv

class axi_agent  #(parameter t_user_width = 16, parameter t_data_bit = 128) extends uvm_agent;


// declaring agent component
axi_driver  #(.t_user_width(t_user_width), .t_data_bit(t_data_bit))  a_driver;
axi_monitor  #(.t_user_width(t_user_width), .t_data_bit(t_data_bit))  a_monitor;
axi_sequencer  #(valid_data #(.t_user_width(t_user_width), .t_data_bit(t_data_bit))) a_sequencer;
axi_config    a_config;
virtual interface axi_if #(.t_user_width(t_user_width), .t_data_bit(t_data_bit)) vif;

// uvm macro file
`uvm_component_param_utils_begin(axi_agent #(.t_user_width(t_user_width), .t_data_bit(t_data_bit)))
`uvm_field_object(a_config, UVM_DEFAULT)
`uvm_field_object(a_driver,          UVM_DEFAULT)
`uvm_field_object(a_monitor,          UVM_DEFAULT)
`uvm_field_object(a_sequencer,       UVM_DEFAULT)
`uvm_component_utils_end

// constructor
function new (string name = "axi_agent" , uvm_component parent);
super.new(name,parent)
endfunction 

// build_phase
function void build_phase(uvm_phase phase);
super.build_phase(phase);

// check that vif is set correctly
if(uvm_config_db#(virtual interface axi_if #(.t_user_width(t_user_width), .t_data_bit(t_data_bit))::get(this, "", "vif",vif) ) begin
uvm_config_db#(virtual interface axi_if #(.t_user_width(t_user_width), .t_data_bit(t_data_bit))::set(this, "a_driver","vif",vif);
end else begin
`uvm_fatal(get_type_name(),"didn't get handle to virtual interface")
end

if (!uvm_config_db#(axi_config)::get(this, "", "a_config", a_config)) begin
uvm_report_fatal(get_type_name(), $psprintf("a_config is not set"));
end else begin
uvm_config_db#(axi_config)::set(this, "a_driver"	, "a_config", a_config);
end

if(a_config.agent_active == UVM_ACTIVE) begin
uvm_config_db#(axi_config)::set(this, "a_driver", "a_config", a_config);	
a_driver = axi_driver #(.t_user_width(t_user_width), .t_data_bit(t_data_bit))::type_id::create("a_driver", this);
a_sequencer = axi_sequencer #(valid_data #(.t_user_width(t_user_width), .t_data_bit(t_data_bit)))::type_id::create("a_sequencer", this);
end
endfunction : build_phase


// connect_phase
function void connect_phase(uvm_phase phase);
super.connect_phase(phase);
if(a_config.agent_active  == UVM_ACTIVE) begin
a_driver.seq_item_port.connect(a_sequencer.seq_item_export);
end
endfunction : connect_phase

endclass : axi_agent

`endif
