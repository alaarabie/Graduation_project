`timescale 100ps/1ps

module tb_top();

  `include "uvm_macros.svh"
  import uvm_pkg::*;
  import tb_params_pkg::*;
  import tb_pkg::* ;
  import seq_pkg::* ;
  import test_pkg::* ;

  parameter LANE_WIDTH = DWIDTH / NUM_LANES;

  logic clk;
  logic clk_hmc_refclk;
  logic res_n;

//**************** INTERFACES INSTANTIATIONS **************//
  rf_if #(.HMC_RF_WWIDTH(HMC_RF_WWIDTH),
          .HMC_RF_RWIDTH(HMC_RF_RWIDTH),
          .HMC_RF_AWIDTH(HMC_RF_AWIDTH))
    RF (.clk(clk), .res_n(res_n));

  hmc_agent_if #(.NUM_LANES(NUM_LANES)) 
  HMC_IF ();

  axi_interface #(.DWIDTH(DWIDTH),
                 .NUM_DATA_BYTES(NUM_DATA_BYTES))
  AXI_IF (.clk(clk), .res_n(res_n));

//*******************************************************//

//*************** Handling HMC interface ***************//

//----------------------------- Wiring openHMC controller
wire [DWIDTH-1:0]       to_serializers;
wire [DWIDTH-1:0]       from_deserializers;
wire [NUM_LANES-1:0]    bit_slip;
wire [NUM_LANES-1:0]    phy_lane_polarity;
bit                     phy_rx_ready;
bit                     P_RST_N;
// Wire the HMC interface in the openHMC
wire            LxRXPS; // HMC input
wire            LxTXPS; // HMC output
wire            FERR_N; // HMC output
wire            LxTXPS_pullup;
assign          LxTXPS_pullup = (LxTXPS === 1'bz) ? 1'b1 : LxTXPS;
wire            FERR_N_pullup;
assign          FERR_N_pullup = (FERR_N === 1'bz) ? 1'b1 : FERR_N;
//------------------------------ Attach the HMC Link interface
 assign HMC_IF.REFCLKP = clk_hmc_refclk;
 assign HMC_IF.REFCLKN = ~clk_hmc_refclk;
 assign FERR_N  = HMC_IF.FERR_N;
 assign HMC_IF.REFCLK_BOOT = 2'b00; // 00 -> 125 MHz, 01 -> 156.25 MHz, 10 -> 166.67 MHz
 assign HMC_IF.P_RST_N = P_RST_N;
 assign LxTXPS = HMC_IF.TXPS;
 assign HMC_IF.RXPS = LxRXPS;
  
 assign HMC_IF.RXP = NUM_LANES==8 ? {8'h0, serial_Txp[NUM_LANES-1:0]} : serial_Txp; // Controller Tx is Cube Rx
 assign HMC_IF.RXN = ~HMC_IF.RXP;//NUM_LANES==8 ? {8'h0, ~serial_Txp[NUM_LANES-1:0]} : ~serial_Txp; // Controller Tx is Cube Rx
 assign serial_Rx = HMC_IF.TXP; // Controller Rx is Cube Tx

//----------------------------- Generate a fast clock for serializers
bit clk_10G;
generate
    begin : clocking_gen
        initial clk_10G = 1'b1;
        always #0.05ns clk_10G = ~clk_10G;  
    end
endgenerate

bit LxTXPS_synced;
genvar lane;
generate
  begin : serializers_gen
      for (lane=0; lane<NUM_LANES; lane++) begin : behavioral_gen
          serializer #(
              .DWIDTH(LANE_WIDTH)
          ) serializer_I (
              .clk(clk),
              .res_n(res_n),
              .fast_clk(clk_10G),
              .data_in(to_serializers[lane*LANE_WIDTH+LANE_WIDTH-1:lane*LANE_WIDTH]),
              .data_out(serial_Txp[lane])
          );
          deserializer #(
              .DWIDTH(LANE_WIDTH)
          ) deserializer_I (
              .clk(clk),
              .res_n(LxTXPS_synced && res_n),
              .fast_clk(clk_10G),
              .bit_slip(bit_slip[lane]),
              .lane_polarity(phy_lane_polarity[lane]),
              .data_in(serial_Rx[lane]),
              .data_out(from_deserializers[lane*LANE_WIDTH+LANE_WIDTH-1:lane*LANE_WIDTH])
          );
      end
  end
endgenerate
always @(LxTXPS) phy_rx_ready   <= #500ns LxTXPS;
always @(posedge clk) LxTXPS_synced <= LxTXPS;
//*******************************************************//

//***************** DUT INSTANTIATION *****************//
  openhmc_top #(.FPW(FPW),
                .LOG_FPW(LOG_FPW),
                .DWIDTH(DWIDTH),
                .LOG_NUM_LANES(LOG_NUM_LANES),
                .NUM_DATA_BYTES(NUM_DATA_BYTES),
                .HMC_RF_WWIDTH(HMC_RF_WWIDTH),
                .HMC_RF_RWIDTH(HMC_RF_RWIDTH),
                .HMC_RF_AWIDTH(HMC_RF_AWIDTH),
                .LOG_MAX_RX_TOKENS(LOG_MAX_RX_TOKENS),
                .LOG_MAX_HMC_TOKENS(LOG_MAX_HMC_TOKENS),
                .HMC_RX_AC_COUPLED(HMC_RX_AC_COUPLED),
                .DETECT_LANE_POLARITY(DETECT_LANE_POLARITY),
                .CTRL_LANE_POLARITY(CTRL_LANE_POLARITY),
                .CTRL_LANE_REVERSAL(CTRL_LANE_REVERSAL),
                .CTRL_SCRAMBLERS(CTRL_SCRAMBLERS),
                .OPEN_RSP_MODE(OPEN_RSP_MODE),
                .RX_RELAX_INIT_TIMING(RX_RELAX_INIT_TIMING),
                .RX_BIT_SLIP_CNT_LOG(RX_BIT_SLIP_CNT_LOG),
                .SYNC_AXI4_IF(SYNC_AXI4_IF),
                .XIL_CNT_PIPELINED(XIL_CNT_PIPELINED),
                .BITSLIP_SHIFT_RIGHT(BITSLIP_SHIFT_RIGHT),
                .DBG_RX_TOKEN_MON(DBG_RX_TOKEN_MON))

    dut (.clk_hmc(clk),
         .res_n_hmc(res_n),
         .res_n_user(res_n),
         .clk_user(clk),
         //axi interface
         .s_axis_tx_TVALID(AXI_IF.t_valid),
         .s_axis_tx_TREADY(AXI_IF.t_ready),
         .s_axis_tx_TDATA(AXI_IF.t_data),
         .s_axis_tx_TUSER(AXI_IF.t_user),
         .m_axis_rx_TVALID(AXI_IF.rx_valid),
         .m_axis_rx_TREADY(AXI_IF.rx_ready),
         .m_axis_rx_TDATA(AXI_IF.rx_data),
         .m_axis_rx_TUSER(AXI_IF.rx_user),
         // transceiver (physical link)
         .phy_data_tx_link2phy(to_serializers),
         .phy_data_rx_phy2link(from_deserializers),
         .phy_bit_slip(bit_slip), //Must be connected if DETECT_LANE_POLARITY==1 AND CTRL_LANE_POLARITY=0
         .phy_lane_polarity(phy_lane_polarity), //All 0 if CTRL_LANE_POLARITY=1
         .phy_tx_ready(res_n), //Optional information to RF
         .phy_rx_ready(phy_rx_ready && LxTXPS), //Release RX descrambler reset when PHY ready
         .phy_init_cont_set(), //Can be used to release transceiver reset if used
         // hmc
         .P_RST_N(P_RST_N),
         .LXRXPS(LXRXPS),
         .LXTXPS(LxTXPS_pullup),
         .FERR_N(FERR_N_pullup),
         // register file
         .rf_address(RF.rf_address),
         .rf_read_data(RF.rf_read_data),
         .rf_invalid_address(RF.rf_invalid_address),
         .rf_access_complete(RF.rf_access_complete),
         .rf_read_en(RF.rf_read_enable),
         .rf_write_en(RF.rf_write_enable),
         .rf_write_data(RF.rf_write_data)
         );
//*****************************************************//

//********************** ASSERTIONS MODULE ***********************//
 bind openhmc_top : dut openhmc_sva #(.FPW(FPW),
                                       .LOG_FPW(LOG_FPW),
                                       .DWIDTH(DWIDTH),
                                       .LOG_NUM_LANES(LOG_NUM_LANES),
                                       .NUM_DATA_BYTES(NUM_DATA_BYTES),
                                       .HMC_RF_WWIDTH(HMC_RF_WWIDTH),
                                       .HMC_RF_RWIDTH(HMC_RF_RWIDTH),
                                       .HMC_RF_AWIDTH(HMC_RF_AWIDTH),
                                       .LOG_MAX_RX_TOKENS(LOG_MAX_RX_TOKENS),
                                       .LOG_MAX_HMC_TOKENS(LOG_MAX_HMC_TOKENS),
                                       .HMC_RX_AC_COUPLED(HMC_RX_AC_COUPLED),
                                       .DETECT_LANE_POLARITY(DETECT_LANE_POLARITY),
                                       .CTRL_LANE_POLARITY(CTRL_LANE_POLARITY),
                                       .CTRL_LANE_REVERSAL(CTRL_LANE_REVERSAL),
                                       .CTRL_SCRAMBLERS(CTRL_SCRAMBLERS),
                                       .OPEN_RSP_MODE(OPEN_RSP_MODE),
                                       .RX_RELAX_INIT_TIMING(RX_RELAX_INIT_TIMING),
                                       .RX_BIT_SLIP_CNT_LOG(RX_BIT_SLIP_CNT_LOG),
                                       .SYNC_AXI4_IF(SYNC_AXI4_IF),
                                       .XIL_CNT_PIPELINED(XIL_CNT_PIPELINED),
                                       .BITSLIP_SHIFT_RIGHT(BITSLIP_SHIFT_RIGHT),
                                       .DBG_RX_TOKEN_MON(DBG_RX_TOKEN_MON)) 
                         openhmc_sva_1 (.*);
//****************************************************************//                       

initial begin
  uvm_config_db#(virtual rf_if #(HMC_RF_WWIDTH, HMC_RF_RWIDTH, HMC_RF_AWIDTH))::set(null, "uvm_test_top", "RF", RF);
  uvm_config_db#(virtual hmc_agent_if #(NUM_LANES))::set(null, "uvm_test_top", "HMC_IF", HMC_IF);
  uvm_config_db#(virtual axi_interface #(NUM_DATA_BYTES, DWIDTH))::set(null, "uvm_test_top", "AXI_IF", AXI_IF);
  run_test();
end

//*********** CLOCK **********//
  always begin
    case(FPW)
        2: begin
            if(LOG_NUM_LANES==3) //8 or 16 lanes
                #1.6ns clk = !clk;
            else begin
              #0.8ns clk = !clk;
            end
        end
        4: begin
            if(LOG_NUM_LANES==3)
                #3.2ns clk = !clk;
            else
                #1.6ns clk = !clk;
        end
        6: begin
            if(LOG_NUM_LANES==3)
                #4.8ns clk = !clk;
            else
                #2.4ns clk = !clk;
        end
        8: begin
            if(LOG_NUM_LANES==3)
                #6.4ns clk = !clk;
            else
                #3.2ns clk = !clk;
        end
    endcase
  end
  //-- 125 MHz HMC/Transceiver refclock
  always #4ns clk_hmc_refclk <= ~clk_hmc_refclk;
//****************************//


endmodule : tb_top