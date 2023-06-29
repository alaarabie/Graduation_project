class hmc_tag_mon extends uvm_component;

	`uvm_component_utils(hmc_tag_mon)

	int tags_in_use[int];
	int current_tag;
	int transaction_count;
	int max_tags_in_use;
	
	int max_tags_available = 512;
	
	
	/*covergroup tags_cg;
		option.per_instance = 1;
		TAGS_IN_USE : coverpoint tags_in_use.size(){
			bins low_usage[]	= {[1:20]};
			bins medium_usage[]	= {[21:250]};
			bins high_usage[]	= {[251:511]};
			bins no_tags_available = {512};
		}
		
		USED_TAGS	: coverpoint current_tag{
			bins TAGS[] = {[1:511]};
		}
	endgroup*/


	function new (string name, uvm_component parent);
		super.new(name, parent);
		tags_in_use.delete();
		max_tags_in_use = 0;
		transaction_count = 0;
		//tags_cg = new();
	endfunction : new

	function void reset();
		tags_in_use.delete();
	endfunction : reset

	function void use_tag(input bit [8:0] tag);
		int tmp[];
		
		if (tag > max_tags_available-1)
			`uvm_fatal("HMC_TAG_MON_use_tag()", $sformatf("use_tag: tag (%0d) out of range!", tag))
		
		 if(!tags_in_use.exists(tag) ) begin
			tags_in_use[tag] = tag;
			current_tag = tag;
			//tags_cg.sample();
		end
	
	endfunction : use_tag

	function void release_tag(input bit [8:0] tag);
		if (tags_in_use.exists(tag))
			tags_in_use.delete(tag);
		else
			`uvm_fatal("HMC_TAG_MON_release_tag()", $sformatf("release_tag: tag (%0d) not in use!", tag))

		transaction_count++;
	endfunction : release_tag

	function bit idle_check();
		idle_check = 1;
		if (tags_in_use.size() > 0) begin
			foreach (tags_in_use[i])
				`uvm_info("HMC_TAG_MON_idle_check()", $sformatf("%0d tags still in use, Tag %0d is in use!", tags_in_use.size(), i),UVM_LOW)
			idle_check = 0;
		end
	endfunction : idle_check

	function void check_phase(uvm_phase phase);
		if (!idle_check())
			`uvm_fatal("HMC_TAG_MON_check_phase()", $sformatf("Tags are still in use"))
	endfunction : check_phase

	function void report_phase(uvm_phase phase);
		`uvm_info("HMC_TAG_MON_report_phase()", $sformatf("max_tags_in_use %0d, transaction_count %0d", max_tags_in_use, transaction_count), UVM_LOW)
	endfunction : report_phase

endclass : hmc_tag_mon