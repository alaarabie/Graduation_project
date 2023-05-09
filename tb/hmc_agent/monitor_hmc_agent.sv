class monitor_hmc_agent#(DWIDTH = 512 , 
						 						NUM_LANES = 8 , 
						 						FPW = 4,
						 						FLIT_SIZE = 128
						 						) extends uvm_monitor ;
	`uvm_component_param_utils(monitor_hmc_agent #(DWIDTH, NUM_LANES, FPW, FLIT_SIZE))

	virtual hmc_agent_if #(DWIDTH, NUM_LANES, FPW, FLIT_SIZE) vif ;
	uvm_analysis_port #(hmc_pkt_item) req_ap ;
	uvm_analysis_port #(hmc_pkt_item) res_ap ;	
	hmc_agent_config #(DWIDTH, NUM_LANES, FPW, FLIT_SIZE) hmc_agent_config_h ;

	function new (string name, uvm_component parent);
		super.new(name,parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		if(!uvm_config_db#(hmc_agent_config#(DWIDTH, NUM_LANES, FPW, FLIT_SIZE))::get(this, "", "hmc_agent_config_t",hmc_agent_config_h))
			`uvm_fatal("monitor_hmc_agent","Failed to get CONFIG") ;
		vif = hmc_agent_config_h.vif ;
		vif.proxy = this ;
		req_ap=new("req_ap",this) ;
		res_ap=new("res_ap",this) ;		 
	endfunction : build_phase

	task run_phase(uvm_phase phase);
		forever begin
			wait(vif.res_n)
			vif.run() ;			
		end
	endtask : run_phase

	function void notify_req_transaction(hmc_pkt_item packet);
		req_ap.write(packet);	
	endfunction : notify_req_transaction

	function void notify_res_transaction(hmc_pkt_item packet);
		res_ap.write(packet);		
	endfunction : notify_res_transaction

endclass : monitor_hmc_agent