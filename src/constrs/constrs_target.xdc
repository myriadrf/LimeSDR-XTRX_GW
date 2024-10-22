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



