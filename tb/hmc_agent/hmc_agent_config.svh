class hmc_agent_config#(NUM_LANES = 16) extends uvm_object;

  

   virtual hmc_agent_if #(NUM_LANES) vif;
   
   uvm_active_passive_enum active = UVM_ACTIVE;
   uvm_active_passive_enum enable_tag_checking = UVM_PASSIVE;

  // Full = 16, Half = 8
  int width = NUM_LANES;

  // scramber enable flag
  bit scramblers_enabled = 0;

  // lanes polarity and lanes reversal
  bit [NUM_LANES-1:0] reverse_polarity = 0;
  bit reverse_lanes = 0;
  int run_length_limit = 85;
  int   TS1_Messages = 4;

  int irtry_flit_count_to_send = 24;  // hexa = 18
  int irtry_flit_count_received_threshold = 16; // hexa = 10

  int hmc_tokens = 163;
  int rx_tokens = 117;

  // Error Porbabilities
  bit lane_errors_enabled = 0;
  int poisoned_probability = 0;
  int lng_error_probability = 0;
  int seq_error_probability = 0;
  int crc_error_probability = 0;
  int bitflip_error_probability = 0;

  // Timing
  int send_tret_time = 0;
  int send_pret_time = 0;
  int retry_timeout_period = 614.4ns; // 10Gbps
  int bit_time = 100ps; // 10Gbit;
  time t_PST = 80ns;
  time t_SS =  500ns;
  time t_SME = 600ns;
  int tINIT = 1us;// 20ms in the spec, but that would take too long in simulation
  int tRESP1 = 1us; // 1us or 1.2ms with DFE
  int tRESP2 = 1us; // 1us
 
  `uvm_object_param_utils_begin(hmc_agent_config #(NUM_LANES))
    `uvm_field_int(width, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(scramblers_enabled, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(reverse_polarity, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(reverse_lanes, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(run_length_limit, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(TS1_Messages, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(irtry_flit_count_to_send, UVM_DEFAULT | UVM_HEX)
    `uvm_field_int(irtry_flit_count_received_threshold, UVM_DEFAULT | UVM_HEX)
    `uvm_field_int(hmc_tokens, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(rx_tokens, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(lane_errors_enabled, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(poisoned_probability, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(lng_error_probability, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(seq_error_probability, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(crc_error_probability, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(bitflip_error_probability, UVM_DEFAULT | UVM_DEC)
  `uvm_object_utils_end

  function new(string name = "");
    super.new(name);
  endfunction : new

endclass : hmc_agent_config