// a macro to compare with the command field 
// to find general command type from the 3 MSB
`define TYPE_MASK 6'h38 // 6'b111_000

class hmc_pkt_item extends  uvm_sequence_item;
  
  // Request Header fields
  rand   bit   [2:0]      cube_ID;             // CUB    [63:61]
  rand   bit   [33:0]     address;             // ADRS   [57:24]
  rand   bit   [8:0]      tag;                 // TAG    [23:15]
  rand   bit   [3:0]      duplicate_length;    // DLN    [14:11]
  rand   bit   [3:0]      length;              // LNG    [10: 7]
  rand   cmd_encoding     command;             // CMD    [ 5: 0]

  bit    [127:0]          payload[$];          // data payload queue, multiples of 16-byte FLITs

  // Request Tail fields
  rand   bit   [31:0]     crc;                 // CRC    [63:32]
  rand   bit   [4:0]      return_token_cnt;    // RTC    [31:27]
  rand   bit   [2:0]      source_link_ID;      // SLID   [26:24]
  rand   bit   [2:0]      sequence_number;     // SEQ    [18:16]
  rand   bit   [7:0]      forward_retry_ptr;   // FRP    [15: 8]
  rand   bit   [7:0]      return_retry_ptr;    // RRP    [ 7: 0]

  //*****************************************************************************//
  // Response Header fields
                          //source_link_ID     // SLID   [41:39]
  rand   bit   [8:0]      return_tag;          // TGA    [23:15]  (Optional)
                          //tag                // TAG    [23:15]  
                          //duplicate_length   // DLN    [14:11] 
                          //length             // LNG    [10: 7]
                          //command            // CMD    [ 5: 0]


  // Response Tail fields
                          //crc                // CRC    [63:32]
  rand   bit   [6:0]      error_status;        // ERRSTAT[26:20]
  rand   bit              data_invalid;        // DINV   [19]
                          //sequence_number    // SEQ    [18:16]
                          //forward_retry_ptr  // FRP    [15: 8]
                          //return_retry_ptr   // RRP    [ 7: 0]

  //*****************************************************************************//
  // special bits for IRTRY
  rand     bit            start_retry;         //flag, FRP[0]
  rand     bit            clear_error_abort;   //flag, FRP[1]

  // CRC status fields
  rand     bit            poisoned;       // a flag, if CRC is inverted
  rand     bit            crc_error;      // a flag, if CRC isn't matching

  //*****************************************************************************//

  `uvm_object_utils_begin(hmc_pkt_item)
    `uvm_field_int      (cube_ID,          UVM_DEFAULT | UVM_NOPACK | UVM_DEC)
    `uvm_field_int      (address,          UVM_DEFAULT | UVM_NOPACK | UVM_HEX)
    `uvm_field_int      (tag,              UVM_DEFAULT | UVM_NOPACK | UVM_DEC)
    `uvm_field_int      (duplicate_length, UVM_DEFAULT | UVM_NOPACK | UVM_DEC)
    `uvm_field_int      (length,           UVM_DEFAULT | UVM_NOPACK | UVM_DEC)
    `uvm_field_enum(cmd_encoding, command, UVM_DEFAULT | UVM_NOPACK )

    `uvm_field_queue_int(payload,          UVM_DEFAULT | UVM_NOPACK)

    `uvm_field_int      (crc,              UVM_DEFAULT | UVM_NOPACK | UVM_HEX)
    `uvm_field_int      (return_token_cnt, UVM_DEFAULT | UVM_NOPACK | UVM_DEC)
    `uvm_field_int      (source_link_ID,   UVM_DEFAULT | UVM_NOPACK | UVM_DEC)
    `uvm_field_int      (sequence_number,  UVM_DEFAULT | UVM_NOPACK | UVM_DEC)
    `uvm_field_int      (forward_retry_ptr,UVM_DEFAULT | UVM_NOPACK | UVM_DEC)
    `uvm_field_int      (return_retry_ptr, UVM_DEFAULT | UVM_NOPACK | UVM_DEC)

    `uvm_field_int      (return_tag,       UVM_DEFAULT | UVM_NOPACK | UVM_DEC)

    `uvm_field_int      (error_status,     UVM_DEFAULT | UVM_NOPACK | UVM_DEC)
    `uvm_field_int      (data_invalid,     UVM_DEFAULT | UVM_NOPACK | UVM_DEC)

    `uvm_field_int      (poisoned,         UVM_DEFAULT | UVM_NOPACK | UVM_DEC)
    `uvm_field_int      (crc_error,        UVM_DEFAULT | UVM_NOPACK | UVM_DEC)
  `uvm_object_utils_end

  //*****************************************************************************//
  //***************************      Constraints      ***************************//
  //*****************************************************************************//
  constraint cube_id_c {
    cube_ID = 0;
  }

  constraint address_c {
    //soft address < 80000000;
    ((command & `TYPE_MASK) == FLOW_TYPE) -> address == 0; 
    soft address[3:0]==4'h0;      // the 4 LSB are ignored 
  }

  constraint matching_length_c {
    length == duplicate_length;
  }

  constraint length_per_command_c {
     (
      // Flow Commands (always LNG = 1)
      (length == 1 && (command & `TYPE_MASK) == FLOW_TYPE) ||
      // Write Request Commands
      (length == 2 && command == WR16) ||
      (length == 3 && command == WR32) ||
      (length == 4 && command == WR48) ||
      (length == 5 && command == WR64) ||
      (length == 6 && command == WR80) ||
      (length == 7 && command == WR96) ||
      (length == 8 && command == WR112) ||
      (length == 9 && command == WR128) ||
      // Misc Write Request commands (always LNG = 2)
      (length == 2 && (command & `TYPE_MASK) == MISC_WRITE_TYPE) ||
      // Posted Write Request commands
      (length == 2 && command == P_WR16) ||
      (length == 3 && command == P_WR32) ||
      (length == 4 && command == P_WR48) ||
      (length == 5 && command == P_WR64) ||
      (length == 6 && command == P_WR80) ||
      (length == 7 && command == P_WR96) ||
      (length == 8 && command == P_WR112) ||
      (length == 9 && command == P_WR128) ||
      // Posted Misc Write Requests
      (length == 2 && (command & `TYPE_MASK) == POSTED_MISC_WRITE_TYPE) ||
      // Mode Read Request (always LNG = 1)
      (length == 1 && (command & `TYPE_MASK) == MODE_READ_TYPE) ||
      // Read Request (always LNG = 1)
      (length == 1 && (command & `TYPE_MASK) == READ_TYPE) ||
      // Read Response (LNG depends on request)
      (length > 1 && length <= 9 && command == RD_RS) ||
      // other Response types (LNG = 1)
      (length == 1 && command == WR_RS) ||
      (length == 1 && command == MD_WR_RS) ||
      (length == 1 && command == ERROR_RS)
    ); 
  }

  constraint source_link_id_c {
    source_link_ID = 0;
  }

  constraint return_tag_c {
    return_tag = 0;
  }

  constraint error_status_c {
    soft  error_status = 0;
  }

  constraint data_invalid_c {
    soft  data_invalid = 0;
  }

  constraint poisoned_c {
    poisoned = 0;
  }

  constraint crc_error_c {
    crc_error = 0;
  }

  // Flow packets
  constraint flow_packets_c { // TAG field = 0 for all flow packets
    ((command & `TYPE_MASK) == FLOW_TYPE) -> tag == 0;
    ((command & `TYPE_MASK) == FLOW_TYPE) -> cube_ID == 0; // TAG[2:0] = CUB[2:0]
  }

  constraint retry_pointer_return_c { // PRET
    (command == PRET) ->  forward_retry_ptr = 0;  // FRP = 0, not saved in retry pointer
    (command == PRET) ->  sequence_number   = 0;  // SEQ = 0, not saved in retry pointer
    (command == PRET) ->  return_token_cnt  = 0;  // RTC = 0, tokens shouldn't be returned
  }

  constraint init_retry_c {  // IRTRY
    (command == IRTRY)                      -> start_retry != clear_error_abort;
    ((command == IRTRY)&&start_retry)       -> forward_retry_pointer == 1;  // FRP[0] = 1
    ((command == IRTRY)&&clear_error_abort) -> forward_retry_pointer == 2;  // FRP[1] = 1
    (command == IRTRY)                      -> sequence_number    == 0;  // SEQ = 0, not saved in retry pointer
    (command == IRTRY)                      -> return_token_cnt   =  0;  // RTC = 0, tokens shouldn't be returned
  }

  //*****************************************************************************//
  extern function new(string name = "");
  extern function void post_randomize();
  extern function cmd_type get_command_type();
  extern function bit [31:0] calculate_crc();
  extern function bit [31:0] calc_crc(bit bitstream[]);

  //*****************************************************************************//
  //***************************         Pack          ***************************//
  //*****************************************************************************//
  virtual function void do_pack(uvm_packer packer);

    super.do_pack(packer);
    packer.big_endian = 0; // This bit determines the order that integral data is packed
    //---------------------------------------------------------------------------------------------------//
    // pack header (Request)
    // CUB[63:61] - RES[60:58] - ADRS[57:24] - TAG[23:15] - DLN[14:11] - LNG[10:7] - RES[6] - CMD[5:0]
    // pack header (Response)
    // RES[63:42] - SLID[41:39] - RES[38:33] - TGA[32:24] - TAG[23:15] - DLN[14:11] - LNG[10:7] - RES[6] - CMD[5:0]
    //---------------------------------------------------------------------------------------------------//
      //  pack_field(int,size): Packs an integral value into the packed array
    case (command & `TYPE_MASK)
      FLOW_TYPE:
        case (command)
          NULL:  packer.pack_field ( {64'h0}, 64);
          PRET:  packer.pack_field ( {3'h0, 3'h0, 34'h0, 9'h0, duplicate_length[3:0], length[3:0], 1'b0, command[5:0]}, 64);
          TRET:  packer.pack_field ( {3'h0, 3'h0, 34'h0, 9'h0, duplicate_length[3:0], length[3:0], 1'b0, command[5:0]}, 64);
          IRTRY: packer.pack_field ( {3'h0, 3'h0, 34'h0, 9'h0, duplicate_length[3:0], length[3:0], 1'b0, command[5:0]}, 64);
          default : `uvm_fatal(get_type_name(), $psprintf("pack function called for a hmc_pkt_item with an illegal FLOW type='h%0h!", command))
        endcase
      WRITE_TYPE:             packer.pack_field ( {cube_ID[2:0], 3'h0, address[33:0], tag[8:0], duplicate_length[3:0], length[3:0], 1'b0, command[5:0]}, 64);
      MISC_WRITE_TYPE:        packer.pack_field ( {cube_ID[2:0], 3'h0, address[33:0], tag[8:0], duplicate_length[3:0], length[3:0], 1'b0, command[5:0]}, 64);
      POSTED_WRITE_TYPE:      packer.pack_field ( {cube_ID[2:0], 3'h0, address[33:0], tag[8:0], duplicate_length[3:0], length[3:0], 1'b0, command[5:0]}, 64);
      POSTED_MISC_WRITE_TYPE: packer.pack_field ( {cube_ID[2:0], 3'h0, address[33:0], tag[8:0], duplicate_length[3:0], length[3:0], 1'b0, command[5:0]}, 64);
      MODE_READ_TYPE:         packer.pack_field ( {cube_ID[2:0], 3'h0,         34'h0, tag[8:0], duplicate_length[3:0], length[3:0], 1'b0, command[5:0]}, 64);
      READ_TYPE:              packer.pack_field ( {cube_ID[2:0], 3'h0, address[33:0], tag[8:0], duplicate_length[3:0], length[3:0], 1'b0, command[5:0]}, 64);

      RESPONSE_TYPE:          packer.pack_field ( {22'h0, source_link_ID[2:0], 6'h0, return_tag[8:0], tag[8:0], duplicate_length[3:0], length[3:0], 1'b0, command[5:0]}, 64);

      default : `uvm_fatal(get_type_name(), $psprintf("pack function called for a hmc_pkt_item with an illegal command type='h%0h!", command))
    endcase

    // Allow for errors when length != duplicate_length
    //if ((length == duplicate_length) && payload.size() + 1 != length && command != HMC_NULL)
    //  `uvm_fatal(get_type_name(), $psprintf("pack function size mismatch payload.size=%0d length=%0d!", payload.size(), length))

    // pack payload
    for( int i=0; i<payload.size(); i++ ) begin
      packer.pack_field ( payload[i], 128);
    end 

    //---------------------------------------------------------------------------------------------------//
    // pack tail (Request)
    // CRC[63:32] - RTC[31:27] - SLID[26:24] - RES[23:19] - SEQ[18:16] - FRP[15:8] - RRP[7:0]
    // pack tail (Response)
    // CRC[63:32] - RTC[31:27] - ERRSTAT[26:20] - DINV[19] - SEQ[18:16] - FRP[15:8] - RRP[7:0]
    //---------------------------------------------------------------------------------------------------//
    case (command & `TYPE_MASK)
      FLOW_TYPE:
        case (command)
          NULL:  packer.pack_field ( {64'h0}, 64);
          PRET:  packer.pack_field ( {crc[31:0],                  5'h0, 3'h0, 5'h0,                 3'h0,                   8'h0,               return_retry_ptr[7:0]}, 64);
          TRET:  packer.pack_field ( {crc[31:0], return_token_cnt[4:0], 3'h0, 5'h0, sequence_number[2:0], forward_retry_ptr[7:0],               return_retry_ptr[7:0]}, 64);
          IRTRY: packer.pack_field ( {crc[31:0],                  5'h0, 3'h0, 5'h0,                 3'h0, 6'h0, clear_error_abort, start_retry, return_retry_ptr[7:0]}, 64);
          default : `uvm_fatal(get_type_name(), $psprintf("pack function called for a hmc_pkt_item with an illegal FLOW type='h%0h!", command))
        endcase
      WRITE_TYPE:             packer.pack_field ( {crc[31:0], return_token_cnt[4:0], source_link_ID[2:0], 5'h0, sequence_number[2:0], forward_retry_ptr[7:0], return_retry_ptr[7:0]}, 64);
      MISC_WRITE_TYPE:        packer.pack_field ( {crc[31:0], return_token_cnt[4:0], source_link_ID[2:0], 5'h0, sequence_number[2:0], forward_retry_ptr[7:0], return_retry_ptr[7:0]}, 64);
      POSTED_WRITE_TYPE:      packer.pack_field ( {crc[31:0], return_token_cnt[4:0], source_link_ID[2:0], 5'h0, sequence_number[2:0], forward_retry_ptr[7:0], return_retry_ptr[7:0]}, 64);
      POSTED_MISC_WRITE_TYPE: packer.pack_field ( {crc[31:0], return_token_cnt[4:0], source_link_ID[2:0], 5'h0, sequence_number[2:0], forward_retry_ptr[7:0], return_retry_ptr[7:0]}, 64);
      MODE_READ_TYPE:         packer.pack_field ( {crc[31:0], return_token_cnt[4:0], source_link_ID[2:0], 5'h0, sequence_number[2:0], forward_retry_ptr[7:0], return_retry_ptr[7:0]}, 64);
      READ_TYPE:              packer.pack_field ( {crc[31:0], return_token_cnt[4:0], source_link_ID[2:0], 5'h0, sequence_number[2:0], forward_retry_ptr[7:0], return_retry_ptr[7:0]}, 64);

      RESPONSE_TYPE:          packer.pack_field ( {crc[31:0], return_token_cnt[4:0], error_status[6:0], data_invalid, sequence_number[2:0], forward_retry_ptr[7:0], return_retry_ptr[7:0]}, 64);

      default : `uvm_fatal(get_type_name(), $psprintf("pack function called for a hmc_pkt_item with an illegal command type='h%0h!", command))
    endcase

  endfunction: do_pack

  //*****************************************************************************//
  //***************************        UnPack         ***************************//
  //*****************************************************************************//
  virtual function void do_unpack(uvm_packer packer);
    bit  [63:0]   header;
    bit  [63:0]   tail;

    bit  [31:0]   calculated_crc;
    bit  [21:0]   res22;
    bit  [ 5:0]   res6;
    bit  [ 4:0]   res5;
    bit  [ 2:0]   res3;
    bit           res1;

    bit bitstream[];

    super.do_unpack(packer);
    packer.big_endian = 0;

    packer.unpack_bits(bitstream); // unpack all into this bitstream

    //for (int i = 0; i <32; i++) begin
    //  crc[i] = bitstream[bitstream.size()-32 +i];
    //end
    calculated_crc = calc_crc(bitstream);

    //---------------------------------------------------------------------------------------------------//
    // unpack header (Request)
    // CUB[63:61] - RES[60:58] - ADRS[57:24] - TAG[23:15] - DLN[14:11] - LNG[10:7] - RES[6] - CMD[5:0]
    // unpack header (Response)
    // RES[63:42] - SLID[41:39] - RES[38:33] - TGA[32:24] - TAG[23:15] - DLN[14:11] - LNG[10:7] - RES[6] - CMD[5:0]
    //---------------------------------------------------------------------------------------------------//
    header = packer.unpack_field(64); // unpack only 64 bits
    command[5:0] = header[5:0];

    if (get_command_type() != RESPONSE_TYPE) begin
      {cube_ID[2:0], res3, address[33:0], tag[8:0], duplicate_length[3:0], length[3:0], res1, command[5:0]}  = header;
    end else begin
      {res22[21:0], source_link_ID[2:0], res6[5:0], return_tag[8:0], tag[8:0], duplicate_length[3:0], length[3:0], res1, command[5:0]}  = header;
    end

    // unpack payload
    for (int i = 0; i < length-1; i++) begin
      payload.push_back(packer.unpack_field(128));
    end 

    //---------------------------------------------------------------------------------------------------//
    // unpack tail (Request)
    // CRC[63:32] - RTC[31:27] - SLID[26:24] - RES[23:19] - SEQ[18:16] - FRP[15:8] - RRP[7:0]
    // unpack tail (Response)
    // CRC[63:32] - RTC[31:27] - ERRSTAT[26:20] - DINV[19] - SEQ[18:16] - FRP[15:8] - RRP[7:0]
    //---------------------------------------------------------------------------------------------------//
    tail = packer.unpack_field(64);

    if (get_command_type() != RESPONSE_TYPE) begin
      {crc[31:0], return_token_cnt[4:0], source_link_ID[2:0], res5, sequence_number[2:0], forward_retry_ptr[7:0], return_retry_ptr[7:0]}  = tail;
    end else begin
      {crc[31:0], return_token_cnt[4:0], error_status[6:0], data_invalid, sequence_number[2:0], forward_retry_ptr[7:0], return_retry_ptr[7:0]} = tail;
    end

    start_retry       = (command == IRTRY ? forward_retry_ptr[0] : 1'b0);
    clear_error_abort = (command == IRTRY ? forward_retry_ptr[1] : 1'b0);

    
    poisoned = (packet_crc == ~calculated_crc) ? 1'b1 : 1'b0;
    if (packet_crc != calculated_crc &&  !poisoned ) begin
      crc_error = 1;
    end else begin
      crc_error = 0;
    end

  endfunction : do_unpack


  //virtual function bit compare_adaptive_packet(hmc_packet rhs, uvm_comparer comparer);

endclass : hmc_pkt_item


function hmc_pkt_item::new(string name = "");
  super.new(name);
endfunction : new

function cmd_type hmc_pkt_item::get_command_type();
  case(command & `TYPE_MASK)
    FLOW_TYPE:              return FLOW_TYPE;
    WRITE_TYPE:             return WRITE_TYPE;
    MISC_WRITE_TYPE:        return MISC_WRITE_TYPE;
    POSTED_WRITE_TYPE:      return POSTED_WRITE_TYPE;
    POSTED_MISC_WRITE_TYPE: return POSTED_MISC_WRITE_TYPE;
    MODE_READ_TYPE:         return MODE_READ_TYPE;
    READ_TYPE:              return READ_TYPE;
    RESPONSE_TYPE:          return RESPONSE_TYPE;
    default: `uvm_fatal(get_type_name(), $psprintf("command with an illegal command type='h%0h!", command))
  endcase
endfunction : get_command_type


//*****************************************************************************//
//***************************    Post Randomize     ***************************//
//*****************************************************************************//
function void hmc_pkt_item::post_randomize();
  bit [127:0] rand_flit;

    super.post_randomize();

  if (length > 9) begin // max length is 9
    `uvm_fatal(get_type_name(),$psprintf("post_randomize length = %0d",length))
  end

  `uvm_info("AXI Packet queued",$psprintf("%0s length = %0d",command.name(), length), UVM_HIGH)

  if (length < 2)
    return; // no data payload

  for (int i=0; i<length-1; i++) begin
    randomize_flit_successful : assert (std::randomize(rand_flit));
    payload.push_back(rand_flit);
  end

  // not sure about this 2 if conditions, maybe the payload not random here
  if ( (command == P_DUAL_2ADD8) || (command == DUAL_2ADD8) ) begin
    payload[0] [63:32] = 32'b0;
    payload[0][127:96] = 32'b0;
  end

  if ( (command == MD_WR)|| (command == MD_RD) ) begin
    payload[0][127:32] = 96'b0;
  end
endfunction : post_randomize

//*****************************************************************************//
//***************************    CRC Calculation    ***************************//
//*****************************************************************************//
// taken from OpenHMC codes as it is
function bit [31:0] hmc_pkt_item::calculate_crc();
  bit bitstream[];
  packer_succeeded : assert (pack(bitstream) > 0); // call do_pack
  return calc_crc(bitstream);
endfunction : calculate_crc

function bit [31:0] hmc_pkt_item::calc_crc(bit bitstream[]);
  bit [32:0] polynomial = 33'h1741B8CD7; // Normal
  
  bit [32:0] remainder = 33'h0;
  for( int i=0; i < bitstream.size()-32; i++ ) begin  // without the CRC
    remainder = {remainder[31:0], bitstream[i]};
    if( remainder[32] ) begin
      remainder = remainder ^ polynomial;
    end
  end

  for( int i=0; i < 64; i++ ) begin // zeroes for CRC and remainder
    remainder = {remainder[31:0], 1'b0};
    if( remainder[32] ) begin
      remainder = remainder ^ polynomial;
    end
  end

  return remainder[31:0];
endfunction : calc_crc
//*****************************************************************************//