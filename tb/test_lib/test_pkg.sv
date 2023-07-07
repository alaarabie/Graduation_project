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

  `include "vseq_base.svh"
  `include "base_test.svh"
    
  `include "simple-test/simple_test_vseq.svh"  
  `include "simple-test/rf_check_vseq.svh" 
  `include "simple-test/rf_wrong_op_vseq.svh"   
  `include "simple-test/simple_test.svh"

  `include "read-only-test/read_only_test_vseq.svh"
  `include "read-only-test/read_only_test.svh"

  `include "write-only-test/write_only_test_vseq.svh"
  `include "write-only-test/write_only_test.svh"

  `include "posted-only-test/posted_only_test_vseq.svh"
  `include "posted-only-test/posted_only_test.svh"  

  `include "hmc-retry-test/hmc_retry_test_vseq.svh"
  `include "hmc-retry-test/hmc_retry_test.svh"

  `include "reset-tests/reset1_test_vseq.svh"
  `include "reset-tests/reset1_test.svh"
  `include "reset-tests/reset2_test_vseq.svh"
  `include "reset-tests/reset2_test.svh"
  `include "reset-tests/reset3_test_vseq.svh"
  `include "reset-tests/reset3_test.svh"
  `include "reset-tests/reset4_test_vseq.svh"
  `include "reset-tests/reset4_test.svh"

endpackage : test_pkg