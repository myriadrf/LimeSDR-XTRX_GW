create_generated_clock -name cpu_spi_clk -source [get_pins inst0/inst1_litepcie_top/inst0_litepcie_core/pcie_support/pipe_clock_i/mmcm_i/CLKOUT2] -divide_by 16 [get_pins inst1_cpu/inst0_mb_cpu/axi_quad_spi_0/U0/NO_DUAL_QUAD_MODE.QSPI_NORMAL/QSPI_LEGACY_MD_GEN.QSPI_CORE_INTERFACE_I/LOGIC_FOR_MD_0_GEN.SPI_MODULE_I/RATIO_NOT_EQUAL_4_GENERATE.SCK_O_NQ_4_NO_STARTUP_USED.SCK_O_NE_4_FDRE_INST/Q]
set_clock_groups -logically_exclusive -group [get_clocks -include_generated_clocks clk_125mhz] -group [get_clocks -include_generated_clocks clk_250mhz]

set_clock_groups -asynchronous -group [get_clocks {txoutclk_x0y0 sys_clk clk_125mhz clk_250mhz mmcm_fb userclk1}] -group [get_clocks cpu_spi_clk] -group [get_clocks {tx_mclk_in clk_out1_tx_pll_1 clk_out2_tx_pll_1 clkfbout_tx_pll_1}] -group [get_clocks {rx_mclk_in clk_out1_rx_pll clk_out2_rx_pll clkfbout_rx_pll}]


create_generated_clock -name inst1_cpu/inst0_mb_cpu/SPI_CORES/SPI0/U0/NO_DUAL_QUAD_MODE.QSPI_NORMAL/QSPI_LEGACY_MD_GEN.QSPI_CORE_INTERFACE_I/LOGIC_FOR_MD_0_GEN.SPI_MODULE_I/sck_o -source [get_pins inst0/inst1_litepcie_top/inst0_litepcie_core/pcie_support/pipe_clock_i/mmcm_i/CLKOUT2] -divide_by 16 [get_pins inst1_cpu/inst0_mb_cpu/SPI_CORES/SPI0/U0/NO_DUAL_QUAD_MODE.QSPI_NORMAL/QSPI_LEGACY_MD_GEN.QSPI_CORE_INTERFACE_I/LOGIC_FOR_MD_0_GEN.SPI_MODULE_I/RATIO_NOT_EQUAL_4_GENERATE.SCK_O_NQ_4_NO_STARTUP_USED.SCK_O_NE_4_FDRE_INST/Q]






set_property MARK_DEBUG true [get_nets {inst0/inst1_to_dma_reader0[valid]}]
set_property MARK_DEBUG true [get_nets inst0/inst0_fifo_inst/empty]
set_property MARK_DEBUG true [get_nets {inst0/wr_data_count[0]}]
set_property MARK_DEBUG true [get_nets {inst0/wr_data_count[1]}]
set_property MARK_DEBUG true [get_nets {inst0/wr_data_count[2]}]
create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 2 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 2048 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL true [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list inst2_pll_top/inst1_rx_pll_top_cyc5/XILINX_MMCM.MMCM_inst1/inst/CLK_CORE_DRP_I/clk_inst/clk_out2]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 3 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {inst0/wr_data_count[0]} {inst0/wr_data_count[1]} {inst0/wr_data_count[2]}]]
create_debug_core u_ila_1 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_1]
set_property ALL_PROBE_SAME_MU_CNT 2 [get_debug_cores u_ila_1]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_1]
set_property C_DATA_DEPTH 2048 [get_debug_cores u_ila_1]
set_property C_EN_STRG_QUAL true [get_debug_cores u_ila_1]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_1]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_1]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_1]
set_property port_width 1 [get_debug_ports u_ila_1/clk]
connect_debug_port u_ila_1/clk [get_nets [list inst0/inst1_litepcie_top/inst0_litepcie_core/pcie_support/pipe_clock_i/pipe_userclk2_in]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe0]
set_property port_width 1 [get_debug_ports u_ila_1/probe0]
connect_debug_port u_ila_1/probe0 [get_nets [list inst0/inst0_fifo_inst/empty]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe1]
set_property port_width 1 [get_debug_ports u_ila_1/probe1]
connect_debug_port u_ila_1/probe1 [get_nets [list {inst0/inst1_to_dma_reader0[valid]}]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets sys_clk]
