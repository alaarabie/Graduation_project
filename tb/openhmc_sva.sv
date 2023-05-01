module openhmc_sva #(
    //Define width of the datapath
    parameter FPW                   = 4,        //Legal Values: 2,4,6,8
    parameter LOG_FPW               = 2,        //Legal Values: 1 for FPW=2 ,2 for FPW=4 ,3 for FPW=6/8
    parameter DWIDTH                = FPW*128,  //Leave untouched
    //Define HMC interface width
    parameter LOG_NUM_LANES         = 3,                //Set 3 for half-width, 4 for full-width
    parameter NUM_LANES             = 2**LOG_NUM_LANES, //Leave untouched
    parameter NUM_DATA_BYTES        = FPW*16,           //Leave untouched
    //Define width of the register file
    parameter HMC_RF_WWIDTH         = 64,   //Leave untouched    
    parameter HMC_RF_RWIDTH         = 64,   //Leave untouched
    parameter HMC_RF_AWIDTH         = 4,    //Leave untouched
    //Configure the Functionality
    parameter LOG_MAX_RX_TOKENS     = 8,    //Set the depth of the RX input buffer. Must be >= LOG(rf_rx_buffer_rtc) in the RF. Dont't care if OPEN_RSP_MODE=1
    parameter LOG_MAX_HMC_TOKENS    = 10,   //Set the depth of the HMC input buffer. Must be >= LOG of the corresponding field in the HMC internal register
    parameter HMC_RX_AC_COUPLED     = 1,    //Set to 0 to bypass the run length limiter, saves logic and 1 cycle delay
    parameter DETECT_LANE_POLARITY  = 1,    //Set to 0 if lane polarity is not applicable, saves logic
    parameter CTRL_LANE_POLARITY    = 1,    //Set to 0 if lane polarity is not applicable or performed by the transceivers, saves logic and 1 cycle delay
                                            //If set to 1: Only valid if DETECT_LANE_POLARITY==1, otherwise tied to zero
    parameter CTRL_LANE_REVERSAL    = 1,    //Set to 0 if lane reversal is not applicable or performed by the transceivers, saves logic
    parameter CTRL_SCRAMBLERS       = 1,    //Set to 0 to remove the option to disable (de-)scramblers for debugging, saves logic
    parameter OPEN_RSP_MODE         = 0,    //Set to 1 if running response open loop mode, bypasses the RX input buffer
    parameter RX_RELAX_INIT_TIMING  = 1,    //Per default, incoming TS1 sequences are only checked for the lane independent h'F0 sequence. Save resources and
                                            //eases timing closure. !Lane reversal is still detected
    parameter RX_BIT_SLIP_CNT_LOG   = 5,    //Define the number of cycles between bit slips. Refer to the transceiver user guide
                                            //Example: RX_BIT_SLIP_CNT_LOG=5 results in 2^5=32 cycles between two bit slips
    parameter SYNC_AXI4_IF          = 0,    //Set to 1 if AXI IF is synchronous to clk_hmc to use simple fifos
    parameter XIL_CNT_PIPELINED     = 1,    //If Xilinx counters are used, set to 1 to enabled output register pipelining
    //Set the direction of bitslip. Set to 1 if bitslip performs a shift right, otherwise set to 0 (see the corresponding transceiver user guide)
    parameter BITSLIP_SHIFT_RIGHT   = 1,    
    //Debug Params
    parameter DBG_RX_TOKEN_MON      = 1     //Set to 0 to remove the RX Link token monitor, saves logic
    )
(
    //----------------------------------
    //----SYSTEM INTERFACES
    //----------------------------------
    input  wire                         clk_user,   //Connect if SYNC_AXI4_IF==0
    input  wire                         clk_hmc,    //Connect!
    input  wire                         res_n_user, //Connect if SYNC_AXI4_IF==0
    input  wire                         res_n_hmc,  //Connect!

    //----------------------------------
    //----Connect AXI Ports
    //----------------------------------
    //From AXI to HMC Ctrl TX
    input  wire                         s_axis_tx_TVALID,
    input  wire                         s_axis_tx_TREADY,
    input  wire [DWIDTH-1:0]            s_axis_tx_TDATA,
    input  wire [NUM_DATA_BYTES-1:0]    s_axis_tx_TUSER,
    //From HMC Ctrl RX to AXI
    input  wire                         m_axis_rx_TVALID,
    input  wire                         m_axis_rx_TREADY,
    input  wire [DWIDTH-1:0]            m_axis_rx_TDATA,
    input  wire [NUM_DATA_BYTES-1:0]    m_axis_rx_TUSER,

    //----------------------------------
    //----Connect Transceiver
    //----------------------------------
    input  wire  [DWIDTH-1:0]           phy_data_tx_link2phy,//Connect!
    input  wire  [DWIDTH-1:0]           phy_data_rx_phy2link,//Connect!
    input  wire  [NUM_LANES-1:0]        phy_bit_slip,       //Must be connected if DETECT_LANE_POLARITY==1 AND CTRL_LANE_POLARITY=0
    input  wire  [NUM_LANES-1:0]        phy_lane_polarity,  //All 0 if CTRL_LANE_POLARITY=1
    input  wire                         phy_tx_ready,       //Optional information to RF
    input  wire                         phy_rx_ready,       //Release RX descrambler reset when PHY ready
    input  wire                         phy_init_cont_set,  //Can be used to release transceiver reset if used

    //----------------------------------
    //----Connect HMC
    //----------------------------------
    input  wire                         P_RST_N,
    input  wire                         LXRXPS,
    input  wire                         LXTXPS,
    input  wire                         FERR_N,

    //----------------------------------
    //----Connect RF
    //----------------------------------
    input  wire  [HMC_RF_AWIDTH-1:0]    rf_address,
    input  wire  [HMC_RF_RWIDTH-1:0]    rf_read_data,
    input  wire                         rf_invalid_address,
    input  wire                         rf_access_complete,
    input  wire                         rf_read_en,
    input  wire                         rf_write_en,
    input  wire  [HMC_RF_WWIDTH-1:0]    rf_write_data
);

// macros
`define assert_clk(arg) \
  assert property (@(posedge clk_hmc) disable iff (!res_n_hmc) arg);

`define assert_async_rst(arg) \
  assert property (@(posedge res_n_hmc) arg);

//------------------------------------------------------------------------------------------//
//--------------------------------- AXI Assertions -----------------------------------------//
//------------------------------------------------------------------------------------------//
tx_valid_hold_until_ready_active :
  `assert_clk ( (s_axis_tx_TVALID == 1 && s_axis_tx_TREADY == 0) |=> (s_axis_tx_TVALID==1) )

rx_valid_hold_until_ready_active :
  `assert_clk ( (m_axis_rx_TVALID == 1 && m_axis_rx_TREADY == 0) |=> (m_axis_rx_TVALID==1) )

  property tx_user_hold_p;
    //-- if TVALID is set TUSER must not be changed until TREADY
    logic [NUM_DATA_BYTES-1:0] m_user;
    (s_axis_tx_TVALID == 1 && s_axis_tx_TREADY == 0, m_user = s_axis_tx_TUSER) |=> (s_axis_tx_TUSER == m_user);
  endproperty : tx_user_hold_p

  tx_user_hold_until_ready_active : 
  `assert_clk ( tx_user_hold_p )

  property rx_user_hold_p;
    //-- if TVALID is set TUSER must not be changed until TREADY
    logic [NUM_DATA_BYTES-1:0] m_user;
    (m_axis_rx_TVALID == 1 && m_axis_rx_TREADY == 0, m_user = m_axis_rx_TUSER) |=> (m_axis_rx_TUSER == m_user);
  endproperty : rx_user_hold_p

  rx_user_hold_until_ready_active :
  `assert_clk ( rx_user_hold_p )

  property tx_data_hold_p;
    //-- if TVALID is set TDATA must not be changed until TREADY
    logic [DWIDTH-1:0] m_data;
      (s_axis_tx_TVALID == 1 && s_axis_tx_TREADY == 0, m_data = s_axis_tx_TDATA) |=> (s_axis_tx_TDATA == m_data);
  endproperty : tx_data_hold_p

tx_data_hold_until_ready_active :
  `assert_clk ( tx_data_hold_p )

  property rx_data_hold_p;
    //-- if TVALID is set TDATA must not be changed until TREADY
    logic [DWIDTH-1:0] m_data;
      (m_axis_rx_TVALID == 1 && m_axis_rx_TREADY == 0, m_data = m_axis_rx_TDATA) |=> (m_axis_rx_TDATA == m_data);
  endproperty : rx_data_hold_p

rx_data_hold_until_ready_active :
  `assert_clk ( rx_data_hold_p )

//------------------------------------------------------------------------------------------//
//---------------------------- Register File Assertions ------------------------------------//
//------------------------------------------------------------------------------------------//
no_simultaneous_read_and_write_1 :
  `assert_clk (rf_read_en |-> !rf_write_en)

no_simultaneous_read_and_write_2 :
  `assert_clk (rf_write_en |-> !rf_read_en)

endmodule : openhmc_sva