#create_generated_clock -name cpu_spi_clk -source [get_pins inst0/inst1_litepcie_top/inst0_litepcie_core/pcie_support/pipe_clock_i/mmcm_i/CLKOUT2] -divide_by 16 [get_pins inst1_cpu/inst0_mb_cpu/axi_quad_spi_0/U0/NO_DUAL_QUAD_MODE.QSPI_NORMAL/QSPI_LEGACY_MD_GEN.QSPI_CORE_INTERFACE_I/LOGIC_FOR_MD_0_GEN.SPI_MODULE_I/RATIO_NOT_EQUAL_4_GENERATE.SCK_O_NQ_4_NO_STARTUP_USED.SCK_O_NE_4_FDRE_INST/Q]



#set_clock_groups -asynchronous -group [get_clocks {txoutclk_x0y0 sys_clk clk_125mhz clk_250mhz mmcm_fb userclk1}] -group [get_clocks cpu_spi_clk] -group [get_clocks -include_generated_clocks LMS_MCLK1] -group [get_clocks -include_generated_clocks LMS_MCLK2]
set_clock_groups -asynchronous -group [get_clocks {txoutclk_x0y0 sys_clk clk_125mhz clk_250mhz mmcm_fb userclk1}] -group [get_clocks cpu_spi_clk] -group [get_clocks FPGA_CLK] -group [get_clocks -include_generated_clocks LMS_MCLK1] -group [get_clocks -include_generated_clocks LMS_MCLK2]
#set_clock_groups -name Async_clocks -asynchronous -group [get_clocks [list txoutclk_x0y0 sys_clk [get_clocks -of_objects [get_pins inst0/inst1_litepcie_top/inst0_litepcie_core/pcie_support/pipe_clock_i/mmcm_i/CLKOUT0]] [get_clocks -of_objects [get_pins inst0/inst1_litepcie_top/inst0_litepcie_core/pcie_support/pipe_clock_i/mmcm_i/CLKOUT1]] [get_clocks -of_objects [get_pins inst0/inst1_litepcie_top/inst0_litepcie_core/pcie_support/pipe_clock_i/mmcm_i/CLKFBOUT]] [get_clocks -of_objects [get_pins inst0/inst1_litepcie_top/inst0_litepcie_core/pcie_support/pipe_clock_i/mmcm_i/CLKOUT2]]]] -group [get_clocks cpu_spi_clk] -group [get_clocks [list tx_mclk_in [get_clocks -of_objects [get_pins inst2_pll_top/inst0_tx_pll_top_cyc5/XILINX_MMCM.MMCM_inst1/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT0]] [get_clocks -of_objects [get_pins inst2_pll_top/inst0_tx_pll_top_cyc5/XILINX_MMCM.MMCM_inst1/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT1]] [get_clocks -of_objects [get_pins inst2_pll_top/inst0_tx_pll_top_cyc5/XILINX_MMCM.MMCM_inst1/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKFBOUT]]]] -group [get_clocks [list rx_mclk_in [get_clocks -of_objects [get_pins inst2_pll_top/inst1_rx_pll_top_cyc5/XILINX_MMCM.MMCM_inst1/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT0]] [get_clocks -of_objects [get_pins inst2_pll_top/inst1_rx_pll_top_cyc5/XILINX_MMCM.MMCM_inst1/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT1]] [get_clocks -of_objects [get_pins inst2_pll_top/inst1_rx_pll_top_cyc5/XILINX_MMCM.MMCM_inst1/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKFBOUT]]]]

#create_generated_clock -name inst1_cpu/inst0_mb_cpu/SPI_CORES/SPI0/U0/NO_DUAL_QUAD_MODE.QSPI_NORMAL/QSPI_LEGACY_MD_GEN.QSPI_CORE_INTERFACE_I/LOGIC_FOR_MD_0_GEN.SPI_MODULE_I/sck_o -source [get_pins inst0/inst1_litepcie_top/inst0_litepcie_core/pcie_support/pipe_clock_i/mmcm_i/CLKOUT2] -divide_by 16 [get_pins inst1_cpu/inst0_mb_cpu/SPI_CORES/SPI0/U0/NO_DUAL_QUAD_MODE.QSPI_NORMAL/QSPI_LEGACY_MD_GEN.QSPI_CORE_INTERFACE_I/LOGIC_FOR_MD_0_GEN.SPI_MODULE_I/RATIO_NOT_EQUAL_4_GENERATE.SCK_O_NQ_4_NO_STARTUP_USED.SCK_O_NE_4_FDRE_INST/Q]
#create_generated_clock -name cpu_spi_clk -source [get_pins inst0/inst1_litepcie_top/inst0_litepcie_core/pcie_support/pipe_clock_i/mmcm_i/CLKOUT2] -divide_by 16 [get_pins inst1_cpu/inst0_mb_cpu/SPI_CORES/SPI0/U0/NO_DUAL_QUAD_MODE.QSPI_NORMAL/QSPI_LEGACY_MD_GEN.QSPI_CORE_INTERFACE_I/LOGIC_FOR_MD_0_GEN.SPI_MODULE_I/RATIO_NOT_EQUAL_4_GENERATE.SCK_O_NQ_4_NO_STARTUP_USED.SCK_O_NE_4_FDRE_INST/Q]



set_property CONFIG_MODE SPIx1 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 1 [current_design]
set_property BITSTREAM.CONFIG.CONFIGFALLBACK ENABLE [current_design]
set_property BITSTREAM.CONFIG.NEXT_CONFIG_ADDR 32'h001C0000 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

set_property BITSTREAM.CONFIG.TIMER_CFG 32'h0002FBD0 [current_design]


set_false_path -to [get_pins {inst*/comp_bus_sync_reg*/sync_reg0_reg[*]/D}]
set_false_path -to [get_pins {inst*/sync_reg0/sync_reg_reg[*]/CLR}]





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
connect_debug_port u_ila_0/clk [get_nets [list inst2_pll_top/inst1_rx_pll_top_cyc5/XILINX_MMCM.MMCM_inst1/inst/CLK_CORE_DRP_I/clk_inst/clk_out2]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 13 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {inst4_lms7002_top/inst0_diq2fifo/inst3_smpl_cmp/diq_l_reg[0]} {inst4_lms7002_top/inst0_diq2fifo/inst3_smpl_cmp/diq_l_reg[1]} {inst4_lms7002_top/inst0_diq2fifo/inst3_smpl_cmp/diq_l_reg[2]} {inst4_lms7002_top/inst0_diq2fifo/inst3_smpl_cmp/diq_l_reg[3]} {inst4_lms7002_top/inst0_diq2fifo/inst3_smpl_cmp/diq_l_reg[4]} {inst4_lms7002_top/inst0_diq2fifo/inst3_smpl_cmp/diq_l_reg[5]} {inst4_lms7002_top/inst0_diq2fifo/inst3_smpl_cmp/diq_l_reg[6]} {inst4_lms7002_top/inst0_diq2fifo/inst3_smpl_cmp/diq_l_reg[7]} {inst4_lms7002_top/inst0_diq2fifo/inst3_smpl_cmp/diq_l_reg[8]} {inst4_lms7002_top/inst0_diq2fifo/inst3_smpl_cmp/diq_l_reg[9]} {inst4_lms7002_top/inst0_diq2fifo/inst3_smpl_cmp/diq_l_reg[10]} {inst4_lms7002_top/inst0_diq2fifo/inst3_smpl_cmp/diq_l_reg[11]} {inst4_lms7002_top/inst0_diq2fifo/inst3_smpl_cmp/diq_l_reg[12]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 13 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {inst4_lms7002_top/inst0_diq2fifo/inst3_smpl_cmp/diq_h_reg[0]} {inst4_lms7002_top/inst0_diq2fifo/inst3_smpl_cmp/diq_h_reg[1]} {inst4_lms7002_top/inst0_diq2fifo/inst3_smpl_cmp/diq_h_reg[2]} {inst4_lms7002_top/inst0_diq2fifo/inst3_smpl_cmp/diq_h_reg[3]} {inst4_lms7002_top/inst0_diq2fifo/inst3_smpl_cmp/diq_h_reg[4]} {inst4_lms7002_top/inst0_diq2fifo/inst3_smpl_cmp/diq_h_reg[5]} {inst4_lms7002_top/inst0_diq2fifo/inst3_smpl_cmp/diq_h_reg[6]} {inst4_lms7002_top/inst0_diq2fifo/inst3_smpl_cmp/diq_h_reg[7]} {inst4_lms7002_top/inst0_diq2fifo/inst3_smpl_cmp/diq_h_reg[8]} {inst4_lms7002_top/inst0_diq2fifo/inst3_smpl_cmp/diq_h_reg[9]} {inst4_lms7002_top/inst0_diq2fifo/inst3_smpl_cmp/diq_h_reg[10]} {inst4_lms7002_top/inst0_diq2fifo/inst3_smpl_cmp/diq_h_reg[11]} {inst4_lms7002_top/inst0_diq2fifo/inst3_smpl_cmp/diq_h_reg[12]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 1 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list inst4_lms7002_top/inst0_diq2fifo/inst3_smpl_cmp/AI_err]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 1 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list inst4_lms7002_top/inst0_diq2fifo/inst3_smpl_cmp/AQ_err]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 1 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list inst4_lms7002_top/inst0_diq2fifo/inst3_smpl_cmp/BQ_err]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 1 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list inst4_lms7002_top/inst0_diq2fifo/inst3_smpl_cmp/cmp_done_reg]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 1 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list inst4_lms7002_top/inst0_diq2fifo/inst3_smpl_cmp/cmp_error_reg]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 1 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list inst4_lms7002_top/inst0_diq2fifo/inst3_smpl_cmp/cmp_start_reg]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 1 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list inst4_lms7002_top/inst0_diq2fifo/inst3_smpl_cmp/debug_compare_stop]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
set_property port_width 1 [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list inst4_lms7002_top/inst0_diq2fifo/inst3_smpl_cmp/IQ_SEL_err]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
set_property port_width 1 [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list inst4_lms7002_top/inst0_diq2fifo/inst3_smpl_cmp/reset_n]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe11]
set_property port_width 1 [get_debug_ports u_ila_0/probe11]
connect_debug_port u_ila_0/probe11 [get_nets [list inst4_lms7002_top/inst0_diq2fifo/inst3_smpl_cmp/smpl_err]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe12]
set_property port_width 1 [get_debug_ports u_ila_0/probe12]
connect_debug_port u_ila_0/probe12 [get_nets [list inst4_lms7002_top/inst1_lms7002_tx/test_ptrn_en]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets inst0_s0_wclk]
