# Clocks
add wave /tb_top/dut/clk_hmc
add wave /tb_top/dut/res_n_hmc

# AXI
add wave -group AXI /tb_top/dut/s_axis_tx_TVALID \
                    /tb_top/dut/s_axis_tx_TREADY \
                    /tb_top/dut/s_axis_tx_TDATA \
                    /tb_top/dut/s_axis_tx_TUSER \
                    /tb_top/dut/m_axis_rx_TVALID \
                    /tb_top/dut/m_axis_rx_TREADY \
                    /tb_top/dut/m_axis_rx_TDATA \
                    /tb_top/dut/m_axis_rx_TUSER 

# transceiver
add wave -group Transceiver  /tb_top/dut/phy_data_tx_link2phy \
                            /tb_top/dut/phy_data_rx_phy2link \
                            /tb_top/dut/phy_bit_slip \
                            /tb_top/dut/phy_lane_polarity \
                            /tb_top/dut/phy_tx_ready \
                            /tb_top/dut/phy_rx_ready \
                            /tb_top/dut/phy_init_cont_set 

# hmc
add wave -group HMC /tb_top/dut/P_RST_N \
                    /tb_top/dut/LXRXPS \
                    /tb_top/dut/LXTXPS \
                    /tb_top/dut/FERR_N 

# Register file
add wave -group RF -color Magenta /tb_top/dut/rf_address \
                    /tb_top/dut/rf_read_data \
                    /tb_top/dut/rf_invalid_address \
                    /tb_top/dut/rf_access_complete \
                    /tb_top/dut/rf_read_en \
                    /tb_top/dut/rf_write_en \
                    /tb_top/dut/rf_write_data