
class hmc_pkt_item_request extends hmc_pkt_item;
`uvm_object_utils(hmc_pkt_item_request)

function new(string name = "hmc_pkt_item_request");
  super.new(name);
endfunction : new

//constraint to generate write and read commands
constraint c_req_command {
command inside {
  // Write Requests
  WR16, WR32, WR48, WR64, WR80, WR96, WR112, WR128,
  //  Misc Write Requests
  MD_WR, BWR, DUAL_2ADD8, SINGLE_ADD16,
  // Posted Write Requests
  P_WR16, P_WR32, P_WR48, P_WR64, P_WR80, P_WR96, P_WR112, P_WR128,
  // Posted Misc Write Requests
  P_BWR, P_DUAL_2ADD8, P_SINGLE_ADD16,
  // Read Requests
  RD16, RD32, RD48, RD64, RD80, RD96, RD112, RD128,
  // Mode Read Request
  MD_RD
  };  
}



// constraint for tail fields to equal zeros
constraint c_zero_tail_fields {
  crc == 0;
  return_token_cnt == 0;
  source_link_ID == 0;
  sequence_number == 0;
  forward_retry_ptr == 0;
  return_retry_ptr == 0;
}


// helper field
rand int        flit_delay;

 endclass :  hmc_pkt_item_request

