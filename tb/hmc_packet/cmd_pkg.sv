package cmd_pkg;

  `include "uvm_macros.svh"
  import uvm_pkg::*;

typedef enum bit [5:0] { // the 3 MSB are unique to each type
FLOW_TYPE              = 6'h00, // 6'b000_xxx
WRITE_TYPE             = 6'h08, // 6'b001_xxx
MISC_WRITE_TYPE        = 6'h10, // 6'b010_xxx
POSTED_WRITE_TYPE      = 6'h18, // 6'b011_xxx
POSTED_MISC_WRITE_TYPE = 6'h20, // 6'b100_xxx
MODE_READ_TYPE         = 6'h28, // 6'b101_xxx
READ_TYPE              = 6'h30, // 6'b110_xxx
RESPONSE_TYPE          = 6'h38  // 6'b111_xxx
} cmd_type;

typedef enum bit [5:0] {
// Flow
NULL    = 6'h00, // 6'b000_000
PRET    = 6'h01, // 6'b000_001
TRET    = 6'h02, // 6'b000_010
IRTRY   = 6'h03, // 6'b000_011
// Write Requests
WR16   = 6'h08, // 6'b001_000
WR32   = 6'h09, // 6'b001_001
WR48   = 6'h0a, // 6'b001_010
WR64   = 6'h0b, // 6'b001_011
WR80   = 6'h0c, // 6'b001_100
WR96   = 6'h0d, // 6'b001_101
WR112  = 6'h0e, // 6'b001_110
WR128  = 6'h0f, // 6'b001_111
//  Misc Write Requests
MD_WR        = 6'h10, // 6'b010_000
BWR          = 6'h11, // 6'b010_001
DUAL_2ADD8   = 6'h12, // 6'b010_010
SINGLE_ADD16 = 6'h13, // 6'b010_011
// Posted Write Requests
P_WR16   = 6'h18, // 6'b011_000
P_WR32   = 6'h19, // 6'b011_001
P_WR48   = 6'h1a, // 6'b011_010
P_WR64   = 6'h1b, // 6'b011_011
P_WR80   = 6'h1c, // 6'b011_100
P_WR96   = 6'h1d, // 6'b011_101
P_WR112  = 6'h1e, // 6'b011_110
P_WR128  = 6'h1f, // 6'b011_111
// Posted Misc Write Requests
P_BWR          = 6'h21, // 6'b100_001
P_DUAL_2ADD8   = 6'h22, // 6'b100_010
P_SINGLE_ADD16 = 6'h23, // 6'b100_011
// Mode Read Request
MD_RD = 6'h28, // 6'b101_000
// Read Requests
RD16   = 6'h30, // 6'b110_000
RD32   = 6'h31, // 6'b110_001
RD48   = 6'h32, // 6'b110_010
RD64   = 6'h33, // 6'b110_011
RD80   = 6'h34, // 6'b110_100
RD96   = 6'h35, // 6'b110_101
RD112  = 6'h36, // 6'b110_110
RD128  = 6'h37, // 6'b110_111
// Response Commands
RD_RS    = 6'h38, // 6'b111_000
WR_RS    = 6'h39, // 6'b111_001
MD_RD_RS = 6'h3A, // 6'b111_010
MD_WR_RS = 6'h3B, // 6'b111_011
ERROR_RS = 6'h3E  // 6'b111_110
} cmd_encoding;
  
endpackage : cmd_pkg