class hmc_token_handler extends uvm_component;
	
  `uvm_component_utils(hmc_token_handler)

	`uvm_analysis_imp_decl(_tokens)
	uvm_analysis_imp_tokens#(hmc_pkt_item, hmc_token_handler) token_imp;

	int available_tokens;
	

	function new(string name, uvm_component parent);
		super.new(name,parent);
		token_imp = new ("token_imp",this);
		available_tokens = 0;
	endfunction : new


	function void reset();
		available_tokens = 0;
	endfunction : reset


	function void write_tokens(input hmc_pkt_item packet);
		`uvm_info("HMC_TOKEN_HANDLER_write_tokens()", $sformatf("write_tokens received %0d available_tokens = %0d", packet.return_token_cnt, available_tokens), UVM_HIGH)
		available_tokens = available_tokens + packet.return_token_cnt;
	endfunction : write_tokens


	function bit tokens_available(input int request);
		`uvm_info("HMC_TOKEN_HANDLER_tokens_available()", $sformatf("tokens_available called for %0d available_tokens = %0d", request, available_tokens), UVM_HIGH)
		tokens_available = 0;
		if (available_tokens >= request) begin
			available_tokens = available_tokens - request;
			tokens_available = 1;
		end
	endfunction : tokens_available
	
endclass : hmc_token_handler