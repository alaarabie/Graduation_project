class rf_wrong_op_seq extends  base_seq;


  `uvm_object_utils(rf_wrong_op_seq)
  extern function new (string name = "");
  extern task body();

endclass : rf_wrong_op_seq


function rf_wrong_op_seq::new(string name = "");
  super.new(name);
endfunction : new

task rf_wrong_op_seq::body();
  super.body();

  rf_rb.m_reg_status_general.write(status, 64'h0, .parent(this));
  rf_rb.m_reg_status_init.write(status, 64'h0, .parent(this));
  rf_rb.m_reg_sent_p.write(status, 64'h0, .parent(this));
  rf_rb.m_reg_sent_np.write(status, 64'h0, .parent(this));
  rf_rb.m_reg_sent_r.write(status, 64'h0, .parent(this));
  rf_rb.m_reg_poisoned_packets.write(status, 64'h0, .parent(this));
  rf_rb.m_reg_rcvd_rsp.write(status, 64'h0, .parent(this));
  rf_rb.m_reg_tx_link_retries.write(status, 64'h0, .parent(this));
  rf_rb.m_reg_errors_on_rx.write(status, 64'h0, .parent(this));
  rf_rb.m_reg_run_length_bit_flip.write(status, 64'h0, .parent(this));
  rf_rb.m_reg_error_abort_not_cleared.write(status, 64'h0, .parent(this));

  rf_rb.m_reg_counter_reset.read(status, data, .parent(this));

endtask : body