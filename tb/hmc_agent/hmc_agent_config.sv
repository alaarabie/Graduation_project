class hmc_agent_config ;

	virtual hmc_agent_if interface ;
	protected uvm_active_passive_enum is_active;

	function new (virtual hmc_agent_if interface, uvm_active_passive_enum is_active) ;
		this.interface = interface ;
		this.is_active = is_active ;
	endfunction : new

	function uvm_active_passive_enum get_is_active();
		return is_active ;
	endfunction : get_is_active 

endclass : hmc_agent_config