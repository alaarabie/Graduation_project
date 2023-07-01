class hmc_final_test_vseq extends vseq_base ;

  `uvm_object_utils(hmc_final_test_vseq)

  axi_seq axi_seq_h ;
  hmc_response_seq hmc_response_seq_h ;
  rf_control_configuration_seq rf_control_configuration_seq_h;

  hmc_model_init_seq bfm;
  openhmc_init_seq init;

  extern function new (string name = "");
  extern task body(); 

endclass : hmc_final_test_vseq


function hmc_final_test_vseq::new(string name = "");
  super.new(name);
endfunction : new

task hmc_final_test_vseq::body();

  axi_seq_h=axi_seq::type_id::create("axi_seq_h") ;
  hmc_response_seq_h=hmc_response_seq::type_id::create("hmc_response_seq_h") ;
  rf_control_configuration_seq_h = rf_control_configuration_seq::type_id::create("rf_control_configuration_seq_h");

  seq_set_cfg(axi_seq_h);
  seq_set_cfg2(hmc_response_seq_h);
  seq_set_cfg(rf_control_configuration_seq_h);

  bfm = hmc_model_init_seq::type_id::create("bfm");
  seq_set_cfg(bfm);
  init = openhmc_init_seq::type_id::create("init");
  seq_set_cfg(init);



  super.body();
    `uvm_info("hmc_final_test_vseq", "Executing sequence", UVM_MEDIUM)

      bfm.start(m_rf_seqr);
      #1us;
      init.start(m_rf_seqr);
      #1us;
      fork

        begin
          #1us;
          axi_seq_h.start(m_axi_sqr);  
        end

        begin
          repeat(1) begin
          hmc_response_seq_h.start(m_hmc_sqr);
          end
        end
      join
      #5000ns;
    `uvm_info("hmc_final_test", "Sequence complete", UVM_MEDIUM)

endtask : body