package test_pkg ;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import cmd_pkg::*;
    import tb_params_pkg::* ;
    import axi_pkg::* ;
    import hmc_agent_pkg::* ;    
    import rf_reg_block_pkg::* ;    
    import rf_agent_pkg::* ;    
    import seq_pkg::* ;
    import tb_pkg::* ;
    
    `include "vseq_base.sv"
    `include "base_test.sv"

  `include "init-test/hmc_init_vseq.sv"
  `include "rf-reset-test/rf_reset_vseq.sv"

  `include "init-test/hmc_init_test.sv"
  `include "rf-reset-test/rf_reset_test.sv"

  `include "axi-test/axi_vseq.sv"
  `include "axi-test/axi_test.sv"

  `include "final-test/hmc_req_resp_vseq.sv" 
  `include "final-test/rf_check_vseq.sv" 
  `include "final-test/hmc_final_test.sv"

endpackage : test_pkg