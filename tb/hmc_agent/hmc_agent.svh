class hmc_agent#(NUM_LANES = 16) extends uvm_agent;

	`uvm_component_param_utils(hmc_agent#(NUM_LANES))

  hmc_agent_config#(NUM_LANES) m_cfg ;

  uvm_analysis_port #(hmc_pkt_item) hmc_req_ap ;
  uvm_analysis_port #(hmc_pkt_item) hmc_rsp_ap ;  

  hmc_agent_sequencer m_sqr ;
  driver_hmc_agent#(NUM_LANES) m_driver ;
  hmc_agent_monitor#(NUM_LANES) m_req_monitor ;
  hmc_agent_monitor#(NUM_LANES) m_rsp_monitor ;

  // Additional classes
  hmc_status          h_status;
  hmc_token_handler   token_handler;
  hmc_retry_buffer    retry_buffer;
  hmc_transaction_mon req_transaction_mon;


  function new (string name, uvm_component parent);
  	super.new(name,parent);
  endfunction : new


  function void build_phase(uvm_phase phase);

  	if(!uvm_config_db#(hmc_agent_config#(NUM_LANES))::get(this,"","hmc_agent_config_t",m_cfg))
  		`uvm_fatal("HMC_Agent","Failed to get config object")

  	if(m_cfg.active == UVM_ACTIVE) begin
  		m_sqr = hmc_agent_sequencer::type_id::create("m_sqr", this);

      token_handler = hmc_token_handler::type_id::create("token_handler",this);
      retry_buffer  = hmc_retry_buffer::type_id::create("retry_buffer",this);
      
      m_driver = driver_hmc_agent#(NUM_LANES)::type_id::create("m_driver",this);
      m_driver.hmc_agent_cfg = m_cfg;
      m_driver.token_handler = token_handler;
      m_driver.retry_buffer  = retry_buffer;
  	end

  	m_req_monitor = hmc_agent_monitor#(NUM_LANES)::type_id::create("m_req_monitor",this);
    m_req_monitor.hmc_agent_cfg = m_cfg;
    m_req_monitor.requester_flag = 1;

    m_rsp_monitor = hmc_agent_monitor#(NUM_LANES)::type_id::create("m_req_monitor",this);
    m_rsp_monitor.hmc_agent_cfg = m_cfg;
    m_rsp_monitor.requester_flag = 0;

  	hmc_req_ap = new("hmc_req_ap",this);
    hmc_rsp_ap = new("hmc_rsp_ap",this);    

  endfunction : build_phase

  function void connect_phase(uvm_phase phase);
    if (m_cfg.active == UVM_ACTIVE) begin
      m_driver.seq_item_port.connect(m_sqr.seq_item_export);

      m_driver.remote_status = m_rsp_monitor.remote_link_status;
      driver.start_clear_retry_event = m_rsp_monitor.start_clear_retry_event;
      //req_transaction_mon.transaction_finished_port.connect(sequencer.hmc_req_port);
      m_rsp_monitor.frp_port.connect(m_driver.hmc_frp_port);
      m_rsp_monitor.return_token_port.connect(token_handler.token_imp);
      m_rsp_monitor.rrp_port.connect(retry_buffer.return_pointer_imp);
    end
  	m_req_monitor.item_collected_port.connect(hmc_req_ap);
    m_rsp_monitor.item_collected_port.connect(hmc_rsp_ap);   
  endfunction : connect_phase

endclass : hmc_agent