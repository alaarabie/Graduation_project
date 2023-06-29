class hmc_transaction_mon extends uvm_monitor;

	`uvm_component_utils(hmc_transaction_mon)

	uvm_active_passive_enum enable_tag_checking = UVM_PASSIVE;

	hmc_pkt_item	hmc_buffer[$];
	bit [7:0]	last_rrp = 0;
	bit [2:0]	next_sequence_num;
	hmc_tag_mon tag_mon;

	`uvm_analysis_imp_decl(_hmc_pkt)
	uvm_analysis_imp_hmc_pkt #(hmc_pkt_item, hmc_transaction_mon) pkt_import; //input
	`uvm_analysis_imp_decl(_hmc_rrp)
	uvm_analysis_imp_hmc_rrp #(int, hmc_transaction_mon) rrp_import; //input

	uvm_analysis_port #(hmc_pkt_item) transaction_finished_port; // output, might not be used
	

	function new (string name, uvm_component parent);
		super.new(name, parent);
		pkt_import = new("pkt_import",this);
		rrp_import = new("rrp_import",this);
		transaction_finished_port = new("transaction_finished_port", this);
		next_sequence_num = 3'b1;
		hmc_buffer = {};	
	endfunction : new
	

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
	endfunction : build_phase


	function void write_hmc_pkt(input hmc_pkt_item collected_packet);
		if (collected_packet.command 	!= NULL 
			&& collected_packet.command	!= IRTRY
			&& collected_packet.command != PRET
		) 
		begin
			`uvm_info("HMC_TRANSACTION_MON_write_hmc_pkt()",$sformatf("got packet with command %s and frp %d", collected_packet.command.name(),collected_packet.forward_retry_ptr), UVM_HIGH)
			hmc_buffer.push_back(collected_packet);
		end	
	endfunction : write_hmc_pkt


	function void write_hmc_rrp(int rrp);
		if (rrp != last_rrp) begin
			hmc_pkt_item current_packet;
			`uvm_info("HMC_TRANSACTION_MON_write_hmc_rrp()",$sformatf("searching packet with FRP %d", rrp),UVM_HIGH)
			if (hmc_buffer.size()>0) begin
				do begin
					if (hmc_buffer.size()>0) begin
						current_packet = hmc_buffer.pop_front();

							if ((current_packet.command != TRET) ) begin
								`uvm_info("HMC_TRANSACTION_MON_write_hmc_rrp()",$sformatf("send packet with command %s and frp %d", current_packet.command.name(),current_packet.forward_retry_ptr), UVM_HIGH)
								if (current_packet.poisoned)
									`uvm_info("HMC_TRANSACTION_MON_write_hmc_rrp()",$sformatf("Packet was poisoned"), UVM_NONE)
								else begin
									if(enable_tag_checking == UVM_ACTIVE)
										tag_handling(current_packet);
									transaction_finished_port.write(current_packet);
								end
							end 
					end
					else 
						`uvm_fatal("HMC_TRANSACTION_MON_write_hmc_rrp()",$sformatf("Cant find RRP %d in retry buffer", rrp))
				end while (current_packet.forward_retry_pointer != rrp);
			end else 
			`uvm_info("HMC_TRANSACTION_MON_write_hmc_rrp()",$sformatf("retry buffer is empty, can not find matching rrp (%0d)", rrp), UVM_HIGH)
			last_rrp = rrp;
		end
	endfunction : write_hmc_rrp


	function void check_phase(uvm_phase phase);
		hmc_pkt_item pkt;
		
		if (hmc_buffer.size() >0) begin
			`uvm_info("HMC_TRANSACTION_MON_check_phase()",$sformatf("retry buffer is not empty!"),UVM_NONE)
			while(hmc_buffer.size()>0) begin
				pkt = hmc_buffer.pop_front();
				`uvm_info("HMC_TRANSACTION_MON_check_phase()",$sformatf("Open FRP: %d", pkt.forward_retry_ptr), UVM_NONE)
			end
			//-- print packet
			`uvm_fatal("HMC_TRANSACTION_MON_check_phase()",$sformatf("retry buffer is not empty!"))
		end		
	endfunction : check_phase
	
	extern function void tag_handling(hmc_pkt_item packet);
	extern function bit idle_check();
	
endclass : hmc_transaction_mon


//*******************************************************************************
// tag_handling(hmc_pkt_item packet)
//*******************************************************************************
function void hmc_transaction_mon::tag_handling(hmc_pkt_item packet);
	if (packet.get_command_type() == WRITE_TYPE 		||
		packet.get_command_type() == MISC_WRITE_TYPE	||
		packet.get_command_type() == MODE_READ_TYPE	||
		packet.get_command_type() == READ_TYPE) 
	begin
		tag_mon.use_tag(packet.tag);
	end
	
	if (packet.get_command_type() 	== RESPONSE_TYPE &&
					 packet.command != ERROR_RESPONSE &&
					!packet.poisoned)
	begin
		tag_mon.release_tag(packet.tag);
	end
endfunction : tag_handling


//*******************************************************************************
// idle_check()
//*******************************************************************************
function bit hmc_transaction_mon::idle_check();
	if (enable_tag_checking == UVM_ACTIVE)
		return hmc_buffer.size()==0 && tag_mon.idle_check();
	else
		return hmc_buffer.size()==0;
endfunction : idle_check	