class rf_reg_block extends  uvm_reg_block;

  `uvm_object_utils(rf_reg_block)

  rand reg_status_general             m_reg_status_general;
  rand reg_status_init                m_reg_status_init;
  rand reg_control                    m_reg_control;
  rand reg_sent_p                     m_reg_sent_p;
  rand reg_sent_np                    m_reg_sent_np;
  rand reg_sent_r                     m_reg_sent_r;
  rand reg_poisoned_packets           m_reg_poisoned_packets;
  rand reg_rcvd_rsp                   m_reg_rcvd_rsp;
  rand reg_counter_reset              m_reg_counter_reset;
  rand reg_tx_link_retries            m_reg_tx_link_retries;
  rand reg_errors_on_rx               m_reg_errors_on_rx;
  rand reg_run_length_bit_flip        m_reg_run_length_bit_flip;
  rand reg_error_abort_not_cleared    m_reg_error_abort_not_cleared;

  uvm_reg_map rf_map; // Block map

function new(string name = "");
  super.new(name, UVM_NO_COVERAGE);
endfunction : new

virtual function void build();
  
  // Create an instance for every register
  m_reg_status_general          = reg_status_general::type_id::create("m_reg_status_general");
  m_reg_status_init             = reg_status_init::type_id::create("m_reg_status_init");
  m_reg_control                 = reg_control::type_id::create("m_reg_control");
  m_reg_sent_p                  = reg_sent_p::type_id::create("m_reg_sent_p");
  m_reg_sent_np                 = reg_sent_np::type_id::create("m_reg_sent_np");
  m_reg_sent_r                  = reg_sent_r::type_id::create("m_reg_sent_r");
  m_reg_poisoned_packets        = reg_poisoned_packets::type_id::create("m_reg_poisoned_packets");
  m_reg_rcvd_rsp                = reg_rcvd_rsp::type_id::create("m_reg_rcvd_rsp");
  m_reg_counter_reset           = reg_counter_reset::type_id::create("m_reg_counter_reset");
  m_reg_tx_link_retries         = reg_tx_link_retries::type_id::create("m_reg_tx_link_retries");
  m_reg_errors_on_rx            = reg_errors_on_rx::type_id::create("m_reg_errors_on_rx");
  m_reg_run_length_bit_flip     = reg_run_length_bit_flip::type_id::create("m_reg_run_length_bit_flip");
  m_reg_error_abort_not_cleared = reg_error_abort_not_cleared::type_id::create("m_reg_error_abort_not_cleared");

  // Configure every register instance
  m_reg_status_general.configure(this, null, "");
  m_reg_status_init.configure(this, null, "");
  m_reg_control.configure(this, null, "");
  m_reg_sent_p.configure(this, null, "");
  m_reg_sent_np.configure(this, null, "");
  m_reg_sent_r.configure(this, null, "");
  m_reg_poisoned_packets.configure(this, null, "");
  m_reg_rcvd_rsp.configure(this, null, "");
  m_reg_counter_reset.configure(this, null, "");
  m_reg_tx_link_retries.configure(this, null, "");
  m_reg_errors_on_rx.configure(this, null, "");
  m_reg_run_length_bit_flip.configure(this, null, "");
  m_reg_error_abort_not_cleared.configure(this, null, "");

  // Call the build() to build all register fields
  m_reg_status_general.build();
  m_reg_status_init.build();
  m_reg_control.build();
  m_reg_sent_p.build();
  m_reg_sent_np.build();
  m_reg_sent_r.build();
  m_reg_poisoned_packets.build();
  m_reg_rcvd_rsp.build();
  m_reg_counter_reset.build();
  m_reg_tx_link_retries.build();
  m_reg_errors_on_rx.build();
  m_reg_run_length_bit_flip.build();
  m_reg_error_abort_not_cleared.build();

// Map name, Offset, Number of bytes, Endianess)
 rf_map = create_map("rf_map", 'h0, 8, UVM_LITTLE_ENDIAN, 0);

 // Add these registers to the default map
 rf_map.add_reg(m_reg_status_general,          4'h0, "RO");
 rf_map.add_reg(m_reg_status_init,             4'h1, "RO");
 rf_map.add_reg(m_reg_control,                 4'h2, "RW");
 rf_map.add_reg(m_reg_sent_p,                  4'h3, "RO");
 rf_map.add_reg(m_reg_sent_np,                 4'h4, "RO");
 rf_map.add_reg(m_reg_sent_r,                  4'h5, "RO");
 rf_map.add_reg(m_reg_poisoned_packets,        4'h6, "RO");
 rf_map.add_reg(m_reg_rcvd_rsp,                4'h7, "RO");
 rf_map.add_reg(m_reg_counter_reset,           4'h8, "RO");
 rf_map.add_reg(m_reg_tx_link_retries,         4'h9, "RO");
 rf_map.add_reg(m_reg_errors_on_rx,            4'hA, "RO");
 rf_map.add_reg(m_reg_run_length_bit_flip,     4'hB, "RO");
 rf_map.add_reg(m_reg_error_abort_not_cleared, 4'hC, "RO");

 lock_model();

endfunction : build
  

endclass : rf_reg_block


