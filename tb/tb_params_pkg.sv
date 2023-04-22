package tb_params_pkg;

import rf_agent_pkg::*;
import hmc_agent_pkg::*;

class HMC;

  //Define width of the datapath
  localparam FPW = 4;        //Legal Values: 2,4,6,8
  localparam LOG_FPW               = 2,        //Legal Values: 1 for FPW=2 ,2 for FPW=4 ,3 for FPW=6/8
  localparam DWIDTH                = FPW*128,  //Leave untouched
  //Define HMC interface width
  localparam LOG_NUM_LANES         = 3,                //Set 3 for half-width, 4 for full-width
  localparam NUM_LANES             = 2**LOG_NUM_LANES, //Leave untouched
  localparam NUM_DATA_BYTES        = FPW*16,           //Leave untouched
  //Define width of the register file
  localparam HMC_RF_WWIDTH         = 64,   //Leave untouched    
  localparam HMC_RF_RWIDTH         = 64,   //Leave untouched
  localparam HMC_RF_AWIDTH         = 4,    //Leave untouched
  //Configure the Functionality
  localparam LOG_MAX_RX_TOKENS     = 8,    //Set the depth of the RX input buffer. Must be >= LOG(rf_rx_buffer_rtc) in the RF. Dont't care if OPEN_RSP_MODE=1
  localparam LOG_MAX_HMC_TOKENS    = 10,   //Set the depth of the HMC input buffer. Must be >= LOG of the corresponding field in the HMC internal register
  /*
  localparam HMC_RX_AC_COUPLED     = 1,    //Set to 0 to bypass the run length limiter, saves logic and 1 cycle delay
  localparam DETECT_LANE_POLARITY  = 1,    //Set to 0 if lane polarity is not applicable, saves logic
  localparam CTRL_LANE_POLARITY    = 1,    //Set to 0 if lane polarity is not applicable or performed by the transceivers, saves logic and 1 cycle delay
                                           //If set to 1: Only valid if DETECT_LANE_POLARITY==1, otherwise tied to zero
  localparam CTRL_LANE_REVERSAL    = 1,    //Set to 0 if lane reversal is not applicable or performed by the transceivers, saves logic
  localparam CTRL_SCRAMBLERS       = 1,    //Set to 0 to remove the option to disable (de-)scramblers for debugging, saves logic
  localparam OPEN_RSP_MODE         = 0,    //Set to 1 if running response open loop mode, bypasses the RX input buffer
  localparam RX_RELAX_INIT_TIMING  = 1,    //Per default, incoming TS1 sequences are only checked for the lane independent h'F0 sequence. Save resources and
                                          //eases timing closure. !Lane reversal is still detected
  localparam RX_BIT_SLIP_CNT_LOG   = 5,    //Define the number of cycles between bit slips. Refer to the transceiver user guide
                                          //Example: RX_BIT_SLIP_CNT_LOG=5 results in 2^5=32 cycles between two bit slips
  //localparam SYNC_AXI4_IF          = 0,    //Set to 1 if AXI IF is synchronous to clk_hmc to use simple fifos
  localparam XIL_CNT_PIPELINED     = 1,    //If Xilinx counters are used, set to 1 to enabled output register pipelining
  //Set the direction of bitslip. Set to 1 if bitslip performs a shift right, otherwise set to 0 (see the corresponding transceiver user guide)
  localparam BITSLIP_SHIFT_RIGHT   = 1,    
  //Debug Params
  localparam DBG_RX_TOKEN_MON      = 1     //Set to 0 to remove the RX Link token monitor, saves logic
  */
  localparam FLIT_SIZE = 128
endclass

typedef rf_agent_cfg #(HMC::HMC_RF_WWIDTH, HMC::HMC_RF_RWIDTH, HMC::HMC_RF_AWIDTH) rf_agent_cfg_t;
typedef rf_agent     #(HMC::HMC_RF_WWIDTH, HMC::HMC_RF_RWIDTH, HMC::HMC_RF_AWIDTH) rf_agent_t;

typedef hmc_agent_config #(HMC::DWIDTH, HMC::NUM_LANES, HMC::FPW, FLIT_SIZE::FLIT_SIZE) hmc_agent_config_t;
typedef hmc_agent        #(HMC::DWIDTH, HMC::NUM_LANES, HMC::FPW, FLIT_SIZE::FLIT_SIZE) hmc_agent_t;

typedef virtual rf_if #(HMC::HMC_RF_WWIDTH, HMC::HMC_RF_RWIDTH, HMC::HMC_RF_AWIDTH) rf_if_t;
typedef virtual hmc_agent_if #(HMC::DWIDTH, HMC::NUM_LANES, HMC::FPW, FLIT_SIZE::FLIT_SIZE) hmc_agent_if_t;

endpackage
