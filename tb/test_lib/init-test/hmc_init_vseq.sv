class hmc_init_vseq extends vseq_base ;

  `uvm_object_utils(hmc_init_vseq)

  bit [1:0] tx_state;
  bit [2:0] rx_state;
  hmc_pkt_item response_packet ;

  hmc_initialization_seq hmc_initialization_seq_h ;
  hmc_response_seq hmc_response_seq_h ;
  hmc_state_seq hmc_state_seq_h ;

  rf_control_configuration_seq rf_control_configuration_seq_h;
  rf_status_init_mirror_seq rf_status_init_mirror_seq_h;  

  extern function new (string name = "");
  extern task body(); 

endclass : hmc_init_vseq


function hmc_init_vseq::new(string name = "");
  super.new(name);
endfunction : new

task hmc_init_vseq::body();

  hmc_initialization_seq_h=hmc_initialization_seq::type_id::create("hmc_initialization") ;
  hmc_response_seq_h=hmc_response_seq::type_id::create("hmc_response") ;
  hmc_state_seq_h=hmc_state_seq::type_id::create("hmc_state_seq") ; 

  rf_control_configuration_seq_h= rf_control_configuration_seq::type_id::create("rf_control_configuration_seq_h");
  rf_status_init_mirror_seq_h= rf_status_init_mirror_seq::type_id::create("rf_status_init_mirror_seq_h");

  seq_set_cfg(hmc_initialization_seq_h);
  seq_set_cfg(hmc_response_seq_h);
  seq_set_cfg(hmc_state_seq_h);

  seq_set_cfg(rf_control_configuration_seq_h);
  seq_set_cfg(rf_status_init_mirror_seq_h);

  super.body();

  `uvm_info("HMC_INIT_SEQ", "Executing sequence", UVM_MEDIUM)

  // edit the configuration of control register
  `uvm_info("HMC_INIT_SEQ", "Executing rf_control_configuration_seq", UVM_MEDIUM)
  rf_control_configuration_seq_h.start(m_rf_seqr);
  `uvm_info("HMC_INIT_SEQ", "rf_control_configuration_seq complete", UVM_MEDIUM)


  fork
  //************************************************************//
  //************************* Thread 1 *************************//
  //************************************************************//
  begin
    `uvm_info("HMC_INIT_SEQ", "Executing rf_status_init_mirror_seq", UVM_MEDIUM)
    repeat(20) begin

      if(tx_state!=2'b11) begin
        rf_status_init_mirror_seq_h.start(m_rf_seqr);
      end else begin
        `uvm_info("HMC_INIT_SEQ", $sformatf("tx_state=INIT_DONE"), UVM_LOW)      
        break ;
      end
    end 
    `uvm_info("HMC_INIT_SEQ", "rf_status_init_mirror_seq complete", UVM_MEDIUM)      
  end
  
  //************************************************************//
  //************************* Thread 2 *************************//
  //************************************************************//
  begin

    repeat(20) begin
      tx_state = rf_rb.m_reg_status_init.status_init_tx_init_state.get();
      rx_state = rf_rb.m_reg_status_init.status_init_rx_init_state.get();
      `uvm_info("HMC_INIT_SEQ", $sformatf("tx_state=%b, rx_state=%b",tx_state, rx_state),UVM_LOW)

      `uvm_info("HMC_INIT_SEQ", "Executing hmc_state_seq", UVM_MEDIUM)
      hmc_state_seq_h.start(m_seqr_hmc_agent) ;
      `uvm_info("HMC_INIT_SEQ", "hmc_state_seq complete", UVM_MEDIUM)

      if(tx_state!=2'b11) begin
        `uvm_info("HMC_INIT_SEQ", "Executing hmc_initialization_seq", UVM_MEDIUM)
        hmc_initialization_seq_h.start(m_seqr_hmc_agent) ;
        `uvm_info("HMC_INIT_SEQ", "hmc_initialization_seq complete", UVM_MEDIUM)
      end else begin
       `uvm_info("HMC_INIT_SEQ", $sformatf("tx_state=INIT_DONE"), UVM_LOW)      
       break ;
      end
    end
  end

join

`uvm_info("HMC_INIT_SEQ", "Sequence complete", UVM_MEDIUM)

endtask : body



