class vseq_random_test extends  uvm_sequence;

  `uvm_object_utils(vseq_random_test)


  function new(string name = "");
    super.new(name);
  endfunction : new


  virtual task body();
    //seq_class_name  seq_handle
    //--------------------------------------------------------------//
    rf_reset_seq rf_reset_seq_h;
    rf_control_configuration_seq rf_control_configuration_seq_h;
    rf_status_init_mirror_seq rf_status_init_mirror_seq_h;
    //--------------------------------------------------------------//
    super.body();
    
    `uvm_info("vseq_random_test", "Executing sequence", UVM_HIGH)

    //`uvm_do_on(seq_handle, sequencer_handle)

    // check that all registers reseted correctly
    `uvm_do_on(rf_reset_seq_h , m_rf_seqr)

    // edit the configuration of control register
    `uvm_do_on(rf_control_configuration_seq_h , m_rf_seqr)

    // start initialization
    fork
      
      repeat(100) begin
        `uvm_do_on(rf_status_init_mirror_seq_h , m_rf_seqr)
      end

      // hmc initialization

    join_any

      // send requests from axi and responds from hmc
      /*fork
        
      join
      */

    `uvm_info("vseq_random_test", "Sequence complete", UVM_HIGH)

  endtask : body

endclass : vseq_random_test