#create_generated_clock -name cpu_spi_clk -source [get_pins inst0/inst1_litepcie_top/inst0_litepcie_core/pcie_support/pipe_clock_i/mmcm_i/CLKOUT2] -divide_by 16 [get_pins inst1_cpu/inst0_mb_cpu/axi_quad_spi_0/U0/NO_DUAL_QUAD_MODE.QSPI_NORMAL/QSPI_LEGACY_MD_GEN.QSPI_CORE_INTERFACE_I/LOGIC_FOR_MD_0_GEN.SPI_MODULE_I/RATIO_NOT_EQUAL_4_GENERATE.SCK_O_NQ_4_NO_STARTUP_USED.SCK_O_NE_4_FDRE_INST/Q]


create_generated_clock -name cpu_spi_clk -source [get_pins inst0/inst1_litepcie_top/inst0_litepcie_core/MMCME2_ADV/CLKOUT3] -divide_by 16 [get_pins inst1_cpu/inst0_mb_cpu/SPI_CORES/SPI0/U0/NO_DUAL_QUAD_MODE.QSPI_NORMAL/QSPI_LEGACY_MD_GEN.QSPI_CORE_INTERFACE_I/LOGIC_FOR_MD_0_GEN.SPI_MODULE_I/RATIO_NOT_EQUAL_4_GENERATE.SCK_O_NQ_4_NO_STARTUP_USED.SCK_O_NE_4_FDRE_INST/Q]
#set_clock_groups -asynchronous -group [get_clocks {txoutclk_x0y0 sys_clk clk_125mhz clk_250mhz mmcm_fb userclk1}] -group [get_clocks cpu_spi_clk] -group [get_clocks -include_generated_clocks LMS_MCLK1] -group [get_clocks -include_generated_clocks LMS_MCLK2]
set_clock_groups -asynchronous -group [get_clocks {txoutclk_x0y0 s7pciephy_clkout0 s7pciephy_clkout1 s7pciephy_clkout2 s7pciephy_clkout3 clk_125mhz clk_250mhz mmcm_fb userclk1}] -group [get_clocks cpu_spi_clk] -group [get_clocks FPGA_CLK] -group [get_clocks -include_generated_clocks LMS_MCLK1] -group [get_clocks -include_generated_clocks LMS_MCLK2] -group [get_clocks -include_generated_clocks usb_phy_clk] -group [get_clocks -include_generated_clocks usb_clk_mmcm_inst/inst/clk_in1]
#set_clock_groups -name Async_clocks -asynchronous -group [get_clocks [list txoutclk_x0y0 sys_clk [get_clocks -of_objects [get_pins inst0/inst1_litepcie_top/inst0_litepcie_core/pcie_support/pipe_clock_i/mmcm_i/CLKOUT0]] [get_clocks -of_objects [get_pins inst0/inst1_litepcie_top/inst0_litepcie_core/pcie_support/pipe_clock_i/mmcm_i/CLKOUT1]] [get_clocks -of_objects [get_pins inst0/inst1_litepcie_top/inst0_litepcie_core/pcie_support/pipe_clock_i/mmcm_i/CLKFBOUT]] [get_clocks -of_objects [get_pins inst0/inst1_litepcie_top/inst0_litepcie_core/pcie_support/pipe_clock_i/mmcm_i/CLKOUT2]]]] -group [get_clocks cpu_spi_clk] -group [get_clocks [list tx_mclk_in [get_clocks -of_objects [get_pins inst2_pll_top/inst0_tx_pll_top_cyc5/XILINX_MMCM.MMCM_inst1/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT0]] [get_clocks -of_objects [get_pins inst2_pll_top/inst0_tx_pll_top_cyc5/XILINX_MMCM.MMCM_inst1/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT1]] [get_clocks -of_objects [get_pins inst2_pll_top/inst0_tx_pll_top_cyc5/XILINX_MMCM.MMCM_inst1/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKFBOUT]]]] -group [get_clocks [list rx_mclk_in [get_clocks -of_objects [get_pins inst2_pll_top/inst1_rx_pll_top_cyc5/XILINX_MMCM.MMCM_inst1/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT0]] [get_clocks -of_objects [get_pins inst2_pll_top/inst1_rx_pll_top_cyc5/XILINX_MMCM.MMCM_inst1/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT1]] [get_clocks -of_objects [get_pins inst2_pll_top/inst1_rx_pll_top_cyc5/XILINX_MMCM.MMCM_inst1/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKFBOUT]]]]

#create_generated_clock -name inst1_cpu/inst0_mb_cpu/SPI_CORES/SPI0/U0/NO_DUAL_QUAD_MODE.QSPI_NORMAL/QSPI_LEGACY_MD_GEN.QSPI_CORE_INTERFACE_I/LOGIC_FOR_MD_0_GEN.SPI_MODULE_I/sck_o -source [get_pins inst0/inst1_litepcie_top/inst0_litepcie_core/pcie_support/pipe_clock_i/mmcm_i/CLKOUT2] -divide_by 16 [get_pins inst1_cpu/inst0_mb_cpu/SPI_CORES/SPI0/U0/NO_DUAL_QUAD_MODE.QSPI_NORMAL/QSPI_LEGACY_MD_GEN.QSPI_CORE_INTERFACE_I/LOGIC_FOR_MD_0_GEN.SPI_MODULE_I/RATIO_NOT_EQUAL_4_GENERATE.SCK_O_NQ_4_NO_STARTUP_USED.SCK_O_NE_4_FDRE_INST/Q]
#create_generated_clock -name cpu_spi_clk -source [get_pins inst0/inst1_litepcie_top/inst0_litepcie_core/pcie_support/pipe_clock_i/mmcm_i/CLKOUT2] -divide_by 16 [get_pins inst1_cpu/inst0_mb_cpu/SPI_CORES/SPI0/U0/NO_DUAL_QUAD_MODE.QSPI_NORMAL/QSPI_LEGACY_MD_GEN.QSPI_CORE_INTERFACE_I/LOGIC_FOR_MD_0_GEN.SPI_MODULE_I/RATIO_NOT_EQUAL_4_GENERATE.SCK_O_NQ_4_NO_STARTUP_USED.SCK_O_NE_4_FDRE_INST/Q]



set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.CONFIGFALLBACK ENABLE [current_design]
# set_property BITSTREAM.CONFIG.NEXT_CONFIG_ADDR 32'h00220000 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

set_property BITSTREAM.CONFIG.TIMER_CFG 32'h000493E0 [current_design]

# USR_ACCESS Field at 00007C-00007F binfile For Bitstream identification:
#[32:24] - DEVICE ID
#[23:20] - HW_VER
#[19:16] - Image identifier ( 0 - Gold image, 1- User image)
#[15: 0] - Reserved
set_property BITSTREAM.CONFIG.USR_ACCESS 0X1B210000 [current_design]



create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list usb_clk_mmcm_inst/inst/clk_out2]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 8 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {vctcxo_tamer_top_inst/vctcxo_tamer_inst0/mm_control_reg[0]} {vctcxo_tamer_top_inst/vctcxo_tamer_inst0/mm_control_reg[1]} {vctcxo_tamer_top_inst/vctcxo_tamer_inst0/mm_control_reg[2]} {vctcxo_tamer_top_inst/vctcxo_tamer_inst0/mm_control_reg[3]} {vctcxo_tamer_top_inst/vctcxo_tamer_inst0/mm_control_reg[4]} {vctcxo_tamer_top_inst/vctcxo_tamer_inst0/mm_control_reg[5]} {vctcxo_tamer_top_inst/vctcxo_tamer_inst0/mm_control_reg[6]} {vctcxo_tamer_top_inst/vctcxo_tamer_inst0/mm_control_reg[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 8 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {vctcxo_tamer_top_inst/mm_wr_data[0]} {vctcxo_tamer_top_inst/mm_wr_data[1]} {vctcxo_tamer_top_inst/mm_wr_data[2]} {vctcxo_tamer_top_inst/mm_wr_data[3]} {vctcxo_tamer_top_inst/mm_wr_data[4]} {vctcxo_tamer_top_inst/mm_wr_data[5]} {vctcxo_tamer_top_inst/mm_wr_data[6]} {vctcxo_tamer_top_inst/mm_wr_data[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 8 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {vctcxo_tamer_top_inst/uart_data_stream_in[0]} {vctcxo_tamer_top_inst/uart_data_stream_in[1]} {vctcxo_tamer_top_inst/uart_data_stream_in[2]} {vctcxo_tamer_top_inst/uart_data_stream_in[3]} {vctcxo_tamer_top_inst/uart_data_stream_in[4]} {vctcxo_tamer_top_inst/uart_data_stream_in[5]} {vctcxo_tamer_top_inst/uart_data_stream_in[6]} {vctcxo_tamer_top_inst/uart_data_stream_in[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 8 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {vctcxo_tamer_top_inst/uart_data_stream_out[0]} {vctcxo_tamer_top_inst/uart_data_stream_out[1]} {vctcxo_tamer_top_inst/uart_data_stream_out[2]} {vctcxo_tamer_top_inst/uart_data_stream_out[3]} {vctcxo_tamer_top_inst/uart_data_stream_out[4]} {vctcxo_tamer_top_inst/uart_data_stream_out[5]} {vctcxo_tamer_top_inst/uart_data_stream_out[6]} {vctcxo_tamer_top_inst/uart_data_stream_out[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 32 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {vctcxo_tamer_top_inst/pps_100s_error[0]} {vctcxo_tamer_top_inst/pps_100s_error[1]} {vctcxo_tamer_top_inst/pps_100s_error[2]} {vctcxo_tamer_top_inst/pps_100s_error[3]} {vctcxo_tamer_top_inst/pps_100s_error[4]} {vctcxo_tamer_top_inst/pps_100s_error[5]} {vctcxo_tamer_top_inst/pps_100s_error[6]} {vctcxo_tamer_top_inst/pps_100s_error[7]} {vctcxo_tamer_top_inst/pps_100s_error[8]} {vctcxo_tamer_top_inst/pps_100s_error[9]} {vctcxo_tamer_top_inst/pps_100s_error[10]} {vctcxo_tamer_top_inst/pps_100s_error[11]} {vctcxo_tamer_top_inst/pps_100s_error[12]} {vctcxo_tamer_top_inst/pps_100s_error[13]} {vctcxo_tamer_top_inst/pps_100s_error[14]} {vctcxo_tamer_top_inst/pps_100s_error[15]} {vctcxo_tamer_top_inst/pps_100s_error[16]} {vctcxo_tamer_top_inst/pps_100s_error[17]} {vctcxo_tamer_top_inst/pps_100s_error[18]} {vctcxo_tamer_top_inst/pps_100s_error[19]} {vctcxo_tamer_top_inst/pps_100s_error[20]} {vctcxo_tamer_top_inst/pps_100s_error[21]} {vctcxo_tamer_top_inst/pps_100s_error[22]} {vctcxo_tamer_top_inst/pps_100s_error[23]} {vctcxo_tamer_top_inst/pps_100s_error[24]} {vctcxo_tamer_top_inst/pps_100s_error[25]} {vctcxo_tamer_top_inst/pps_100s_error[26]} {vctcxo_tamer_top_inst/pps_100s_error[27]} {vctcxo_tamer_top_inst/pps_100s_error[28]} {vctcxo_tamer_top_inst/pps_100s_error[29]} {vctcxo_tamer_top_inst/pps_100s_error[30]} {vctcxo_tamer_top_inst/pps_100s_error[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 8 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list {vctcxo_tamer_top_inst/mm_addr[0]} {vctcxo_tamer_top_inst/mm_addr[1]} {vctcxo_tamer_top_inst/mm_addr[2]} {vctcxo_tamer_top_inst/mm_addr[3]} {vctcxo_tamer_top_inst/mm_addr[4]} {vctcxo_tamer_top_inst/mm_addr[5]} {vctcxo_tamer_top_inst/mm_addr[6]} {vctcxo_tamer_top_inst/mm_addr[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 8 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list {vctcxo_tamer_top_inst/mm_rd_data[0]} {vctcxo_tamer_top_inst/mm_rd_data[1]} {vctcxo_tamer_top_inst/mm_rd_data[2]} {vctcxo_tamer_top_inst/mm_rd_data[3]} {vctcxo_tamer_top_inst/mm_rd_data[4]} {vctcxo_tamer_top_inst/mm_rd_data[5]} {vctcxo_tamer_top_inst/mm_rd_data[6]} {vctcxo_tamer_top_inst/mm_rd_data[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 1 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list vctcxo_tamer_top_inst/iicfg_valid]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 1 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list vctcxo_tamer_top_inst/iiena_en]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
set_property port_width 1 [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list vctcxo_tamer_top_inst/iiena_valid]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
set_property port_width 1 [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list vctcxo_tamer_top_inst/iiirq_en]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe11]
set_property port_width 1 [get_debug_ports u_ila_0/probe11]
connect_debug_port u_ila_0/probe11 [get_nets [list vctcxo_tamer_top_inst/iiirq_rst]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe12]
set_property port_width 1 [get_debug_ports u_ila_0/probe12]
connect_debug_port u_ila_0/probe12 [get_nets [list vctcxo_tamer_top_inst/iiirq_valid]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe13]
set_property port_width 1 [get_debug_ports u_ila_0/probe13]
connect_debug_port u_ila_0/probe13 [get_nets [list vctcxo_tamer_top_inst/iirst_cnt]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe14]
set_property port_width 1 [get_debug_ports u_ila_0/probe14]
connect_debug_port u_ila_0/probe14 [get_nets [list vctcxo_tamer_top_inst/iirst_valid]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe15]
set_property port_width 1 [get_debug_ports u_ila_0/probe15]
connect_debug_port u_ila_0/probe15 [get_nets [list vctcxo_tamer_top_inst/mm_irq]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe16]
set_property port_width 1 [get_debug_ports u_ila_0/probe16]
connect_debug_port u_ila_0/probe16 [get_nets [list vctcxo_tamer_top_inst/mm_rd_datav]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe17]
set_property port_width 1 [get_debug_ports u_ila_0/probe17]
connect_debug_port u_ila_0/probe17 [get_nets [list vctcxo_tamer_top_inst/mm_rd_req]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe18]
set_property port_width 1 [get_debug_ports u_ila_0/probe18]
connect_debug_port u_ila_0/probe18 [get_nets [list vctcxo_tamer_top_inst/mm_wait_req]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe19]
set_property port_width 1 [get_debug_ports u_ila_0/probe19]
connect_debug_port u_ila_0/probe19 [get_nets [list vctcxo_tamer_top_inst/mm_wr_req]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe20]
set_property port_width 1 [get_debug_ports u_ila_0/probe20]
connect_debug_port u_ila_0/probe20 [get_nets [list vctcxo_tamer_top_inst/pps_1s_count_v]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe21]
set_property port_width 1 [get_debug_ports u_ila_0/probe21]
connect_debug_port u_ila_0/probe21 [get_nets [list vctcxo_tamer_top_inst/pps_10s_count_v]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe22]
set_property port_width 1 [get_debug_ports u_ila_0/probe22]
connect_debug_port u_ila_0/probe22 [get_nets [list vctcxo_tamer_top_inst/pps_100s_count_v]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe23]
set_property port_width 1 [get_debug_ports u_ila_0/probe23]
connect_debug_port u_ila_0/probe23 [get_nets [list vctcxo_tamer_top_inst/uart_data_stream_in_ack]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe24]
set_property port_width 1 [get_debug_ports u_ila_0/probe24]
connect_debug_port u_ila_0/probe24 [get_nets [list vctcxo_tamer_top_inst/uart_data_stream_in_stb]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe25]
set_property port_width 1 [get_debug_ports u_ila_0/probe25]
connect_debug_port u_ila_0/probe25 [get_nets [list vctcxo_tamer_top_inst/uart_data_stream_out_ack]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe26]
set_property port_width 1 [get_debug_ports u_ila_0/probe26]
connect_debug_port u_ila_0/probe26 [get_nets [list vctcxo_tamer_top_inst/uart_data_stream_out_stb]]
create_debug_core u_ila_1 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_1]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_1]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_1]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_1]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_1]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_1]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_1]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_1]
set_property port_width 1 [get_debug_ports u_ila_1/clk]
connect_debug_port u_ila_1/clk [get_nets [list inst0/inst1_litepcie_top/inst0_litepcie_core/userclk2_clk]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe0]
set_property port_width 1 [get_debug_ports u_ila_1/probe0]
connect_debug_port u_ila_1/probe0 [get_nets [list vctcxo_tamer_top_inst/tune_ref]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe1]
set_property port_width 1 [get_debug_ports u_ila_1/probe1]
connect_debug_port u_ila_1/probe1 [get_nets [list GNSS_HW_R_OBUF]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe2]
set_property port_width 1 [get_debug_ports u_ila_1/probe2]
connect_debug_port u_ila_1/probe2 [get_nets [list GNSS_HW_S_OBUF]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets sys_clk]
