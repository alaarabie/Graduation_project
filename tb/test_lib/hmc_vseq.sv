class hmc_vseq extends vseq_base ;

  `uvm_object_utils(hmc_vseq)

  bit [1:0] tx_state;
  hmc_pkt_item response_packet ;

  hmc_initialization_seq hmc_initialization_seq_h ;
  hmc_response_seq hmc_response_seq_h ;
  hmc_state_seq hmc_state_seq_h ;
  rf_reset_seq rf_reset_seq_h;
  rf_control_configuration_seq rf_control_configuration_seq_h;
  rf_status_init_mirror_seq rf_status_init_mirror_seq_h;  

  extern function new (string name = "");
  extern task body(); 

endclass : hmc_vseq


function hmc_vseq::new(string name = "");
  super.new(name);
endfunction : new

task hmc_vseq::body();

  hmc_initialization_seq_h=hmc_initialization_seq::type_id::create("hmc_initialization") ;
  hmc_response_seq_h=hmc_response_seq::type_id::create("hmc_response") ;
  hmc_state_seq_h=hmc_state_seq::type_id::create("hmc_state_seq") ; 
  rf_reset_seq_h= rf_reset_seq::type_id::create("rf_reset_seq_h");
  rf_control_configuration_seq_h= rf_control_configuration_seq::type_id::create("rf_control_configuration_seq_h");
  rf_status_init_mirror_seq_h= rf_status_init_mirror_seq::type_id::create("rf_status_init_mirror_seq_h");

  seq_set_cfg(hmc_initialization_seq_h);
  seq_set_cfg(hmc_response_seq_h);
  seq_set_cfg(hmc_state_seq_h);
  seq_set_cfg(rf_reset_seq_h);
  seq_set_cfg(rf_control_configuration_seq_h);
  seq_set_cfg(rf_status_init_mirror_seq_h);

  super.body();

  `uvm_info("hmc_vseq", "Executing sequence", UVM_MEDIUM)

  // edit the configuration of control register
  `uvm_info("rf_control_configuration_seq", "Executing sequence", UVM_MEDIUM)
  rf_control_configuration_seq_h.start(m_rf_seqr);
  `uvm_info("rf_control_configuration_seq", "Sequence complete", UVM_MEDIUM)

  // check that all registers reseted correctly
  `uvm_info("rf_reset_seq", "Executing sequence", UVM_MEDIUM)
  rf_reset_seq_h.start(m_rf_seqr);
  `uvm_info("rf_reset_seq", "Sequence complete", UVM_MEDIUM)



  fork
  //************************************************************//
  //************************* Thread 1 *************************//
  //************************************************************//
   begin
    `uvm_info("rf_status_init_mirror_seq", "Executing sequence", UVM_MEDIUM)
    repeat(20) begin

      if(tx_state!=2'b11) begin
        rf_status_init_mirror_seq_h.start(m_rf_seqr);
      end else begin
        `uvm_info("hmc_vseq", $sformatf("tx_state=INIT_DONE"), UVM_LOW)      
        break ;
      end
    end 
    `uvm_info("rf_status_init_mirror_seq", "Sequence complete", UVM_MEDIUM)      
   end
  
  //************************************************************//
  //************************* Thread 2 *************************//
  //************************************************************//
  begin
    `uvm_info("hmc_state_seq", "Executing sequence", UVM_MEDIUM)
    repeat(20) begin
    tx_state = rf_rb.m_reg_status_init.status_init_tx_init_state.get();
    `uvm_info("hmc_vseq", $sformatf("tx_state=%b",tx_state ),UVM_LOW)
    
    hmc_state_seq_h.start(m_seqr_hmc_agent) ;
    //`uvm_info("hmc_state_seq", "Sequence complete", UVM_MEDIUM)

    if(tx_state!=2'b11)
            begin
              //`uvm_info("hmc_initialization_seq", "Executing sequence", UVM_MEDIUM)
               hmc_initialization_seq_h.start(m_seqr_hmc_agent) ;
              //`uvm_info("hmc_initialization_seq", "Sequence complete", UVM_MEDIUM)
            end
    else begin
     `uvm_info("hmc_vseq", $sformatf("tx_state=INIT_DONE"), UVM_LOW)      
      break ;
    end
  // else
  //    begin
  //        hmc_response_seq_h.start(m_seqr_hmc_agent) ;
  //    end         
    end
   
   end

  join

  //
  
  `uvm_info("hmc_vseq", "Sequence complete", UVM_MEDIUM)

  endtask : body



