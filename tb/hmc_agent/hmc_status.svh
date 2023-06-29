class hmc_status extends uvm_component;
	
  `uvm_component_utils(hmc_status)

	hmc_link_status Requester_link_status;
	hmc_link_status Responder_link_status;
	
	function new (string name, uvm_component parent);
		super.new(name, parent);
		Requester_link_status = hmc_link_status::type_id::create("Requester_link_status", this);
		Responder_link_status = hmc_link_status::type_id::create("Responder_link_status", this);
	endfunction : new

endclass : hmc_status