package tb_params_pkg;

import axi_pkg::*;
import rf_agent_pkg::*;
import hmc_agent_pkg::*;

  parameter FPW                   = 4;    //Legal Values: 2,4,6,8
  parameter LOG_FPW               = 2;    //Legal Values: 1 for FPW=2 ,2 for FPW=4 ,3 for FPW=6/8
  //Define HMC interface width
  parameter LOG_NUM_LANES         = 4;    //Set 3 for half-width, 4 for full-width
  //Configure the Functionality
  parameter LOG_MAX_RX_TOKENS     = 10;   //Set the depth of the RX input buffer. Must be >= LOG(rf_rx_buffer_rtc) in the RF. Dont't care if OPEN_RSP_MODE=1
  parameter LOG_MAX_HMC_TOKENS    = 10;   //Set the depth of the HMC input buffer. Must be >= LOG of the corresponding field in the HMC internal register
  parameter HMC_RX_AC_COUPLED     = 1;    //Set to 0 to bypass the run length limiter, saves logic and 1 cycle delay
  parameter DETECT_LANE_POLARITY  = 1;    //Set to 0 if lane polarity is not applicable, saves logic
  parameter CTRL_LANE_POLARITY    = 1;    //Set to 0 if lane polarity is not applicable or performed by the transceivers, saves logic and 1 cycle delay
                                          //If set to 1: Only valid if DETECT_LANE_POLARITY==1, otherwise tied to zero
  parameter CTRL_LANE_REVERSAL    = 1;    //Set to 0 if lane reversal is not applicable or performed by the transceivers, saves logic
  parameter CTRL_SCRAMBLERS       = 1;    //Set to 0 to remove the option to disable (de-)scramblers for debugging, saves logic
  parameter OPEN_RSP_MODE         = 0;    //Set to 1 if running response open loop mode, bypasses the RX input buffer
  parameter RX_RELAX_INIT_TIMING  = 1;    //Per default, incoming TS1 sequences are only checked for the lane independent h'F0 sequence. Save resources and
                                          //eases timing closure. !Lane reversal is still detected
  parameter RX_BIT_SLIP_CNT_LOG   = 5;    //Define the number of cycles between bit slips. Refer to the transceiver user guide
                                          //Example: RX_BIT_SLIP_CNT_LOG=5 results in 2^5=32 cycles between two bit slips
  parameter SYNC_AXI4_IF          = 1;    //Set to 1 if AXI IF is synchronous to clk_hmc to use simple fifos
  parameter XIL_CNT_PIPELINED     = 1;    //If Xilinx counters are used, set to 1 to enabled output register pipelining
  //Set the direction of bitslip. Set to 1 if bitslip performs a shift right, otherwise set to 0 (see the corresponding transceiver user guide)
  parameter BITSLIP_SHIFT_RIGHT   = 1;    
  //Debug Params
  parameter DBG_RX_TOKEN_MON      = 1;    //Set to 0 to remove the RX Link token monitor, saves logic


typedef hmc_agent_config #(.NUM_LANES(2**LOG_NUM_LANES)) hmc_agent_config_t;
typedef hmc_agent        #(.NUM_LANES(2**LOG_NUM_LANES)) hmc_agent_t;

typedef axi_config #(.NUM_DATA_BYTES(FPW*16), .DWIDTH(FPW*128)) axi_config_t;
typedef axi_agent  #(.NUM_DATA_BYTES(FPW*16), .DWIDTH(FPW*128)) axi_agent_t;
typedef axi_sequencer  #(.NUM_DATA_BYTES(FPW*16), .DWIDTH(FPW*128)) axi_sequencer_t;

typedef virtual hmc_agent_if #(.NUM_LANES(2**LOG_NUM_LANES)) hmc_agent_if_t;
typedef virtual axi_interface #(.NUM_DATA_BYTES(FPW*16), .DWIDTH(FPW*128)) axi_interface_t;

endpackage