class hmc_agent_config#(NUM_LANES = 16) extends uvm_object;

  `uvm_object_param_utils(hmc_agent_config #(NUM_LANES))

   virtual hmc_agent_if #(NUM_LANES) vif;
   
   uvm_active_passive_enum     active = UVM_ACTIVE;

  // Full = 16, Half = 8
  int width = NUM_LANES;

  // scramber enable flag
  bit scramblers_enabled = 0;

  // lanes polarity and lanes reversal
  bit [NUM_LANES-1:0] reverse_polarity = 0;
  bit reverse_lanes = 0;

  int irtry_flit_count_to_send = 24;  // hexa = 18
  int irtry_flit_count_received_threshold = 16; // hexa = 10

  // Error Porbabilities
  int poisoned_probability = 0;
  int lng_error_probability = 0;
  int seq_error_probability = 0;
  int crc_error_probability = 0;
  int bitflip_error_probability = 0;

  // Timing
  int send_tret_time = 0;
  int send_pret_time = 0;
  int retry_timeout_period = 614.4ns; // 10Gbps


  function new(string name = "");
    super.new(name);
  endfunction : new

endclass : hmc_agent_config