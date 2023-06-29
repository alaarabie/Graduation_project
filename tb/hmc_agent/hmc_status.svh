class hmc_status#(NUM_LANES = 16) extends uvm_component;
	
  `uvm_component_param_utils(hmc_status#(NUM_LANES))

	hmc_link_status#(NUM_LANES) Requester_link_status;
	hmc_link_status#(NUM_LANES) Responder_link_status;
	
	function new (string name, uvm_component parent);
		super.new(name, parent);
		Requester_link_status = hmc_link_status#(NUM_LANES)::type_id::create("Requester_link_status", this);
		Responder_link_status = hmc_link_status#(NUM_LANES)::type_id::create("Responder_link_status", this);
	endfunction : new

endclass : hmc_status