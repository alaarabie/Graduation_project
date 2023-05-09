`ifndef axi_env_sv
`define axi_env_sv

class axi_env #(parameter t_user_width = 16, parameter t_data_bit = 128) extends uvm_env;

//declaring env component
virtual interface axi_if #(.t_user_width(t_user_width), .t_data_bit(t_data_bit)) vif;
axi_agent #(.t_user_width(t_user_width), .t_data_bit(t_data_bit)) a_agent;
axi_monitor #(.t_user_width(t_user_width), .t_data_bit(t_data_bit)) a_monitor;
axi_config a_config;

//uvm macros
`uvm_object_param_utils_begin(axi_env #(.t_user_width(t_user_width), .t_data_bit(t_data_bit)))
`uvm_field_object(vif, UVM_ALL_ON)
`uvm_field_object(a_agent, UVM_ALL_ON)
`uvm_field_object(a_monitor, UVM_ALL_ON)
`uvm_field_object(a_config, UVM_ALL_ON)
`uvm_object_utils_end

//constructor
function new (string name = "axi_env" , uvm_component parent);
super.new(name,parent);
endfunction : new


//build phase
function void build_phase(uvm_phase phase);
super.build_phase(phase);
if(uvm_config_db#(axi_if #(.t_user_width(t_user_width), .t_data_bit(t_data_bit)))::get(this, "", "vif", vif))
begin
uvm_config_db#(axi_if #(.t_user_width(t_user_width), .t_data_bit(t_data_bit)))::set(this, "a_agent", "vif", vif);
uvm_config_db#(axi_if #(.t_user_width(t_user_width), .t_data_bit(t_data_bit)))::set(this, "a_monitor", "vif", vif);
end
else 
begin
`uvm_fatal(get_type_name(),"vif is not set")		
end	
if(uvm_config_db#(axi_config)::get(this, "", "a_config", a_config))
begin
uvm_config_db#(axi_config)::set(this, "a_agent", "a_config", a_config);
end
else 
begin
`uvm_fatal(get_type_name(),"a_config is not set")	
end


//create
a_agent = axi_agent#(.t_user_width(t_user_width), .t_data_bit(t_data_bit))::type_id::create("a_agent", this);
a_monitor = axi_monitor#(.t_user_width(t_user_width), .t_data_bit(t_data_bit))::type_id::create("a_monitor", this);
	
endfunction : build_phase


//connect phase
function void connect_phase(uvm_phase phase);
super.connect_phase(phase);
endfunction : connect_phase


endclass : axi_env


`endif

