##############################################################
## Copyright (c) 2016-2020 Fairwaves, Inc.
## SPDX-License-Identifier: CERN-OHL-W-2.0
##############################################################

set_property BITSTREAM.CONFIG.UNUSEDPIN Pulldown [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN Disable [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 66 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]
set_property BITSTREAM.CONFIG.SPI_OPCODE 8'h6B [current_design]
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]


set_false_path -from [get_ports PERST]


# CLOCKS
create_clock -period 16.000 -name usb_phy_clk [get_ports USB_CLK]
create_clock -name cfg_mclk -period 12  [get_nets inst0_xtrx_top/cfg_mclk]
create_clock -period 10.000 -name sys_clk [get_ports sys_clk_p]
create_clock -period 20.000 -name clk_vctcxo [get_ports FPGA_CLK]
#create_clock -period 8.138 -name rx_mclk_in [get_ports LMS_MCLK2]
#create_clock -period 8.138 -name tx_mclk_in [get_ports lms_o_mclk1]


# PCIe and master clocks
#set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks usb_phy_clk]
#set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks sys_clk]
#set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks clk_vctcxo]

#set_property LOC MMCME2_ADV_X1Y1 [get_cells inst0_xtrx_top/xlnx_pci_clocking/mmcm_i]

#set_false_path -to [get_pins {inst0_xtrx_top/xlnx_pci_clocking/pclk_i1_bufgctrl.pclk_i1/S0}]
#set_false_path -to [get_pins {inst0_xtrx_top/xlnx_pci_clocking/pclk_i1_bufgctrl.pclk_i1/S1}]

#create_generated_clock -name clk_125mhz_x0y0 [get_pins inst0_xtrx_top/xlnx_pci_clocking/mmcm_i/CLKOUT0]
#create_generated_clock -name clk_250mhz_x0y0 [get_pins inst0_xtrx_top/xlnx_pci_clocking/mmcm_i/CLKOUT1]
#create_generated_clock -name clk_31mhz_x0y0 [get_pins inst0_xtrx_top/xlnx_pci_clocking/mmcm_i/CLKOUT4]

#create_generated_clock -name clk_125mhz_mux_x0y0 #                        -source [get_pins inst0_xtrx_top/xlnx_pci_clocking/pclk_i1_bufgctrl.pclk_i1/I0] #                        -divide_by 1 #                        [get_pins inst0_xtrx_top/xlnx_pci_clocking/pclk_i1_bufgctrl.pclk_i1/O]

#create_generated_clock -name clk_250mhz_mux_x0y0 #                        -source [get_pins inst0_xtrx_top/xlnx_pci_clocking/pclk_i1_bufgctrl.pclk_i1/I1] #                        -divide_by 1 -add -master_clock [get_clocks -of [get_pins inst0_xtrx_top/xlnx_pci_clocking/pclk_i1_bufgctrl.pclk_i1/I1]] #                        [get_pins inst0_xtrx_top/xlnx_pci_clocking/pclk_i1_bufgctrl.pclk_i1/O]

#set_clock_groups -name pcieclkmux -physically_exclusive -group clk_125mhz_mux_x0y0 -group clk_250mhz_mux_x0y0



#create_generated_clock -name clk_userclk_mux #                        -source [get_pins inst0_xtrx_top/userclk_c_bufg/I0] #                        -divide_by 1 #                        [get_pins inst0_xtrx_top/userclk_c_bufg/O]

#create_generated_clock -name clk_cfgmclk_mux #                        -source [get_pins inst0_xtrx_top/userclk_c_bufg/I1] #                        -divide_by 1 -add -master_clock [get_clocks -of [get_pins inst0_xtrx_top/userclk_c_bufg/I1]] #                        [get_pins inst0_xtrx_top/userclk_c_bufg/O]

##create_generated_clock -name clk_cfgmclk_mux ##                        -source [get_pins inst0_xtrx_top/STARTUPE2_inst/CFGMCLK] ##                        -divide_by 1 -add -master_clock ##                        [get_pins inst0_xtrx_top/userclk_c_bufg/O]

#create_generated_clock -name clk_cfgmclk_mux #                       -source [get_pins inst0_xtrx_top/userclk_c_bufg/I1] #                       -divide_by 1 -add -master_clock [get_clocks cfg_mclk] #                       [get_pins inst0_xtrx_top/userclk_c_bufg/O]

#set_clock_groups -name userclkmux -physically_exclusive -group clk_userclk_mux -group clk_cfgmclk_mux


#set_false_path -from [get_clocks -of [get_pins inst0_xtrx_top/userclk_c_bufg/I0]] -to [get_clocks -of [get_pins inst0_xtrx_top/userclk_c_bufg/I1]]
#set_false_path -from [get_clocks -of [get_pins inst0_xtrx_top/userclk_c_bufg/I1]] -to [get_clocks -of [get_pins inst0_xtrx_top/userclk_c_bufg/I0]]

#set_false_path -from [get_clocks -of [get_pins inst0_xtrx_top/userclk_c_bufg/I0]] -to [get_clocks clk_cfgmclk_mux]
#set_false_path -from [get_clocks clk_cfgmclk_mux] -to [get_clocks -of [get_pins inst0_xtrx_top/userclk_c_bufg/I0]]


# LML Port 1
#set_property LOC OUT_FIFO_X0Y0   [get_cells lml_tx/tx_fifo.out_fifo]
#set_property LOC IN_FIFO_X0Y0    [get_cells inst0_xtrx_top/lml_tx/rx_fifo.in_fifo]
#set_property LOC MMCME2_ADV_X0Y0 [get_cells lml_tx/mmcm_gen.mmcme2]

#create_generated_clock -name tx_fclk      -source [get_pins lml_tx/mmcm_gen.mmcme2/CLKIN1] [get_pins lml_tx/mmcm_gen.mmcme2/CLKOUT0]
#create_generated_clock -name tx_int_clk   -source [get_pins lml_tx/mmcm_gen.mmcme2/CLKIN1] [get_pins lml_tx/mmcm_gen.mmcme2/CLKOUT1]
#create_generated_clock -name tx_data_clk  -source [get_pins lml_tx/mmcm_gen.mmcme2/CLKIN1] [get_pins lml_tx/mmcm_gen.mmcme2/CLKOUT4]

#set_false_path -from [get_clocks tx_data_clk] -to [get_clocks tx_int_clk]
#set_false_path -from [get_clocks tx_int_clk] -to [get_clocks tx_data_clk]

#set_false_path -from [get_clocks tx_data_clk] -to [get_clocks phy_fclk_clk_div_1]
#set_false_path -from [get_clocks tx_data_clk] -to [get_clocks phy_fclk_clk_div]

#set_false_path -from [get_clocks -of_objects [get_pins lml_tx/tx_fifo.out_fifo/WRCLK]] -to [get_clocks -of_objects [get_nets lml_tx/phy_tx_data_clk_div]]


# LML Port 2
#set_property LOC OUT_FIFO_X1Y1   [get_cells inst0_xtrx_top/lml_rx/tx_fifo.out_fifo]
#set_property LOC IN_FIFO_X1Y1    [get_cells lml_rx/rx_fifo.in_fifo]
#set_property LOC MMCME2_ADV_X1Y0 [get_cells lml_rx/mmcm_gen.mmcme2]

#create_generated_clock -name rx_fclk      -source [get_pins lml_rx/mmcm_gen.mmcme2/CLKIN1] [get_pins lml_rx/mmcm_gen.mmcme2/CLKOUT0]
#create_generated_clock -name rx_int_clk   -source [get_pins lml_rx/mmcm_gen.mmcme2/CLKIN1] [get_pins lml_rx/mmcm_gen.mmcme2/CLKOUT1]
#create_generated_clock -name rx_data_clk  -source [get_pins lml_rx/mmcm_gen.mmcme2/CLKIN1] [get_pins lml_rx/mmcm_gen.mmcme2/CLKOUT4]

#set_false_path -from [get_clocks rx_data_clk] -to [get_clocks rx_int_clk]
#set_false_path -from [get_clocks rx_int_clk] -to [get_clocks rx_data_clk]

#set_false_path -from [get_clocks rx_data_clk] -to [get_clocks phy_fclk_clk_div]

#set_false_path -from [get_clocks -of_objects [get_pins lml_rx/rx_fifo.in_fifo/RDCLK]] -to [get_clocks rx_mclk_in]
#set_false_path -from [get_clocks rx_ref_clk_p1] -to [get_clocks rx_mclk_in]


#set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks rx_mclk_in]
#set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks tx_mclk_in]


# other clocks rules

#set_false_path -from [get_clocks -of_objects [get_nets inst0_xtrx_top/user_clk]] -to [get_clocks usb_phy_clk]
#set_false_path -from [get_clocks usb_phy_clk] -to [get_clocks -of_objects [get_nets inst0_xtrx_top/user_clk]]

#set_false_path -from [get_clocks -of_objects [get_nets inst0_xtrx_top/user_clk]] -to [get_clocks cfg_mclk]
#set_false_path -from [get_clocks cfg_mclk] -to [get_clocks -of_objects [get_nets inst0_xtrx_top/user_clk]]

#set_false_path -from [get_clocks -of_objects [get_nets inst0_xtrx_top/user_clk]] -to [get_clocks tx_mclk_in]
#set_false_path -from [get_clocks tx_mclk_in] -to [get_clocks -of_objects [get_nets inst0_xtrx_top/user_clk]]

#set_false_path -from [get_clocks -of_objects [get_nets inst0_xtrx_top/user_clk]] -to [get_clocks rx_mclk_in]
#set_false_path -from [get_clocks rx_mclk_in] -to [get_clocks -of_objects [get_nets inst0_xtrx_top/user_clk]]

#set_false_path -from [get_clocks -of_objects [get_nets inst0_xtrx_top/user_clk]] -to [get_clocks clk_vctcxo]
#set_false_path -from [get_clocks clk_vctcxo] -to [get_clocks -of_objects [get_nets inst0_xtrx_top/user_clk]]

#set_false_path -from [get_clocks -of_objects [get_nets inst0_xtrx_top/user_clk]] -to [get_clocks clk_31mhz_x0y0]
#set_false_path -from [get_clocks clk_31mhz_x0y0] -to [get_clocks -of_objects [get_nets inst0_xtrx_top/user_clk]]



# see AR# 63174
create_generated_clock -name cclk -source [get_pins inst0_xtrx_top/STARTUPE2_inst/USRCCLKO] -combinational [get_pins inst0_xtrx_top/STARTUPE2_inst/USRCCLKO]
set_clock_latency -min 0.5 [get_clocks cclk]
set_clock_latency -max 6.7 [get_clocks cclk]

set_input_delay -max 6   -clock [get_clocks cclk] -clock_fall [get_ports {flash_d[*]}]
set_input_delay -min 1.5 -clock [get_clocks cclk] -clock_fall [get_ports {flash_d[*]}]

set_output_delay -max  1.75  -clock [get_clocks cclk]  [get_ports {flash_d[*]}]
set_output_delay -min -2.3   -clock [get_clocks cclk]  [get_ports {flash_d[*]}]

set_output_delay -max  3.375 -clock [get_clocks cclk]  [get_ports flash_fcs_b]
set_output_delay -min -3.375 -clock [get_clocks cclk]  [get_ports flash_fcs_b]


###########################################################
# IO types
###########################################################



###########################################################
# PCIexpress (3.3V) Pinout and Related I/O Constraints
###########################################################

# system reset PCI_PERST#
set_property IOSTANDARD LVCMOS25 [get_ports PERST]
set_property PULLUP true [get_ports PERST]
set_property PACKAGE_PIN T3 [get_ports PERST]

# PCI_REF_CLK
set_property PACKAGE_PIN B8 [get_ports sys_clk_p]
set_property PACKAGE_PIN A8 [get_ports sys_clk_n]


##########################################################
# USB PHY (1.8-3.3V) (BANK 16)
##########################################################
set_property IOSTANDARD LVCMOS25 [get_ports {{USB_D[*]} USB_CLK USB_DIR USB_STP USB_NXT}]

set_property PACKAGE_PIN A14 [get_ports {USB_D[6]}]
set_property PACKAGE_PIN A15 [get_ports {USB_D[5]}]
set_property PACKAGE_PIN C15 [get_ports {USB_D[7]}]
set_property PACKAGE_PIN B15 [get_ports {USB_D[4]}]
set_property PACKAGE_PIN A16 [get_ports {USB_D[3]}]
set_property PACKAGE_PIN A17 [get_ports {USB_D[1]}]
set_property PACKAGE_PIN C16 [get_ports USB_CLK]
set_property PACKAGE_PIN B16 [get_ports {USB_D[2]}]
set_property PACKAGE_PIN C17 [get_ports USB_STP]
set_property PACKAGE_PIN B17 [get_ports {USB_D[0]}]
set_property PACKAGE_PIN B18 [get_ports USB_DIR]
set_property PACKAGE_PIN A18 [get_ports USB_NXT]

# (BANK14)
set_property IOSTANDARD LVCMOS25 [get_ports USB_NRST]
set_property IOSTANDARD LVCMOS25 [get_ports usb_26m]

set_property PACKAGE_PIN M18 [get_ports USB_NRST]
set_property PACKAGE_PIN E19 [get_ports usb_26m]

set_property PULLUP true [get_ports USB_STP]
set_property PULLDOWN true [get_ports USB_NRST]


##########################################################
# GPS module (BANK35)
##########################################################
set_property IOSTANDARD LVCMOS33 [get_ports GNSS_1PPS]
set_property IOSTANDARD LVCMOS33 [get_ports GNSS_TXD]
set_property IOSTANDARD LVCMOS33 [get_ports GNSS_RXD]

set_property PULLDOWN true [get_ports GNSS_1PPS]
set_property PULLUP true [get_ports GNSS_TXD]
set_property PULLUP true [get_ports GNSS_RXD]

set_property PACKAGE_PIN P3 [get_ports GNSS_1PPS]
set_property PACKAGE_PIN N2 [get_ports GNSS_TXD]
set_property PACKAGE_PIN L1 [get_ports GNSS_RXD]


##########################################################
# GPIO (BANK35)
##########################################################
# gpio1  - 1pps_i (sync in)
# gpio2  - 1pps_o (sync out)
# gpio3  - TDD_P
# gpio4  - TDD_N
# gpio5  - LED_WWAN
# gpio6  - LED_WLAN
# gpio7  - LED_WPAN
# gpio8  - general (smb_data)
# gpio9  - G9_P
# gpio10 - G9_N
# gpio11 - G11_P
# gpio12 - G11_N


set_property IOSTANDARD LVCMOS33 [get_ports {gpio[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpio[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpio[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpio[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpio[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpio[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpio[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpio[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpio[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpio[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpio[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpio[11]}]



set_property PACKAGE_PIN M3 [get_ports PPSI_GPIO1]
set_property PACKAGE_PIN L3 [get_ports PPSO_GPIO2]
set_property PACKAGE_PIN H2 [get_ports TDD_GPIO3_P]
set_property PACKAGE_PIN J2 [get_ports TDD_GPIO3_N]
set_property PACKAGE_PIN G3 [get_ports LED_WWAN_GPIO5]
set_property PACKAGE_PIN M2 [get_ports LED_WLAN_GPIO6]
set_property PACKAGE_PIN G2 [get_ports LED_WPAN_GPIO7]
set_property PACKAGE_PIN N3 [get_ports GPIO8]
set_property PACKAGE_PIN H1 [get_ports GPIO9_P]
set_property PACKAGE_PIN J1 [get_ports GPIO9_N]
set_property PACKAGE_PIN K2 [get_ports GPIO11_P]
set_property PACKAGE_PIN L2 [get_ports GPIO11_N]


##########################################################
# SKY13330 & SKY13384 switches (3.3V devided to 2.5V)
##########################################################
set_property IOSTANDARD LVCMOS33 [get_ports TX_SW]
set_property IOSTANDARD LVCMOS33 [get_ports RX_SW3]
set_property IOSTANDARD LVCMOS33 [get_ports RX_SW2]

set_property PACKAGE_PIN P1 [get_ports TX_SW]
set_property PACKAGE_PIN K3 [get_ports RX_SW3]
set_property PACKAGE_PIN J3 [get_ports RX_SW2]

set_property PULLUP true [get_ports TX_SW]
set_property PULLUP true [get_ports RX_SW3]
set_property PULLUP true [get_ports RX_SW2]

##########################################################
# BANK35 I2C BUS #1 (3.3V)
##########################################################
set_property IOSTANDARD LVCMOS33 [get_ports FPGA_I2C1_SDA]
set_property IOSTANDARD LVCMOS33 [get_ports FPGA_I2C1_SCL]

set_property PULLUP true [get_ports FPGA_I2C1_SDA]
set_property PULLUP true [get_ports FPGA_I2C1_SCL]

set_property PACKAGE_PIN N1 [get_ports FPGA_I2C1_SDA]
set_property PACKAGE_PIN M1 [get_ports FPGA_I2C1_SCL]


##########################################################
# FPGA FLASH N25Q256 (1.8-3.3V) BANK14
##########################################################
set_property IOSTANDARD LVCMOS25 [get_ports {FPGA_CFG_D[*]}]
set_property IOSTANDARD LVCMOS25 [get_ports flash_fcs_b]

set_property PACKAGE_PIN D18 [get_ports {FPGA_CFG_D[0]}]
set_property PACKAGE_PIN D19 [get_ports {FPGA_CFG_D[1]}]
set_property PACKAGE_PIN G18 [get_ports {FPGA_CFG_D[2]}]
set_property PACKAGE_PIN F18 [get_ports {FPGA_CFG_D[3]}]
set_property PACKAGE_PIN K19 [get_ports FPGA_CFG_CS]

# AUX signals
set_property IOSTANDARD LVCMOS25 [get_ports FPGA_CLK]
set_property IOSTANDARD LVCMOS25 [get_ports EN_TCXO]
set_property IOSTANDARD LVCMOS25 [get_ports EXT_CLK]
set_property IOSTANDARD LVCMOS25 [get_ports led_2]
set_property IOSTANDARD LVCMOS25 [get_ports option]
set_property IOSTANDARD LVCMOS25 [get_ports GPIO13]
set_property IOSTANDARD LVCMOS25 [get_ports GNSS_HW_S]
set_property IOSTANDARD LVCMOS25 [get_ports GNSS_HW_R]
set_property IOSTANDARD LVCMOS25 [get_ports GNSS_FIX]
set_property IOSTANDARD LVCMOS25 [get_ports FPGA_LED2]
set_property IOSTANDARD LVCMOS25 [get_ports en_smsigio]

set_property PACKAGE_PIN N17 [get_ports FPGA_CLK]
set_property PACKAGE_PIN R19 [get_ports EN_TCXO]
set_property PACKAGE_PIN V17 [get_ports EXT_CLK]
set_property PACKAGE_PIN N18 [get_ports FPGA_LED1]
set_property PACKAGE_PIN V14 [get_ports option]
set_property PACKAGE_PIN T17 [get_ports GPIO13]
set_property PACKAGE_PIN L18 [get_ports GNSS_HW_S]
set_property PACKAGE_PIN U18 [get_ports GNSS_HW_R]
set_property PACKAGE_PIN L18 [get_ports GNSS_FIX]
set_property PACKAGE_PIN V19 [get_ports FPGA_LED2]
set_property PACKAGE_PIN D17 [get_ports en_smsigio]


set_property PULLDOWN true [get_ports FPGA_CLK]
set_property PULLUP true [get_ports en_tcxo]
set_property PULLDOWN true [get_ports EXT_CLK]



# I2C BUS #2
set_property IOSTANDARD LVCMOS25 [get_ports FPGA_I2C_SDA]
set_property IOSTANDARD LVCMOS25 [get_ports FPGA_I2C_SCL]

set_property PACKAGE_PIN U15 [get_ports FPGA_I2C_SDA]
set_property PACKAGE_PIN U14 [get_ports FPGA_I2C_SCL]

set_property PULLUP true [get_ports FPGA_I2C_SDA]
set_property PULLUP true [get_ports FPGA_I2C_SCL]


# SIM card (1.8V) BANK 34
set_property IOSTANDARD LVCMOS25 [get_ports SIM_MOD]
set_property IOSTANDARD LVCMOS25 [get_ports SIM_ENA]
set_property IOSTANDARD LVCMOS25 [get_ports SIM_CLK]
set_property IOSTANDARD LVCMOS25 [get_ports SIM_RST]
set_property IOSTANDARD LVCMOS25 [get_ports SIM_DIO]

set_property PACKAGE_PIN R3 [get_ports SIM_MOD]
set_property PACKAGE_PIN U1 [get_ports SIM_ENA]
set_property PACKAGE_PIN T1 [get_ports SIM_CLK]
set_property PACKAGE_PIN R2 [get_ports SIM_RST]
set_property PACKAGE_PIN T2 [get_ports SIM_DIO]

######################################################
# LMS7002M Pinout
######################################################
set_property PACKAGE_PIN W13 [get_ports FPGA_SPI_LMS_SS]
set_property PACKAGE_PIN W16 [get_ports FPGA_SPI_MOSI]
set_property PACKAGE_PIN W15 [get_ports FPGA_SPI_MISO]
set_property PACKAGE_PIN W14 [get_ports FPGA_SPI_SCLK]
set_property PACKAGE_PIN U19 [get_ports LMS_RESET]
set_property PACKAGE_PIN W17 [get_ports LMS_CORE_LDO_EN]
set_property PACKAGE_PIN W18 [get_ports LMS_RXEN]
set_property PACKAGE_PIN W19 [get_ports LMS_TXEN]
#
# DIQ2 BANK34
#
set_property PACKAGE_PIN W2 [get_ports {LMS_DIQ2_D[0]}]
set_property PACKAGE_PIN U2 [get_ports {LMS_DIQ2_D[1]}]
set_property PACKAGE_PIN U3 [get_ports {LMS_DIQ2_D[2]}]
set_property PACKAGE_PIN V4 [get_ports {LMS_DIQ2_D[3]}]
set_property PACKAGE_PIN V4 [get_ports {LMS_DIQ2_D[4]}]
set_property PACKAGE_PIN V2 [get_ports {LMS_DIQ2_D[5]}]
set_property PACKAGE_PIN V5 [get_ports {LMS_DIQ2_D[6]}]
set_property PACKAGE_PIN W4 [get_ports {LMS_DIQ2_D[7]}]
set_property PACKAGE_PIN U5 [get_ports {LMS_DIQ2_D[8]}]
set_property PACKAGE_PIN U4 [get_ports {LMS_DIQ2_D[9]}]
set_property PACKAGE_PIN U8 [get_ports {LMS_DIQ2_D[10]}]
set_property PACKAGE_PIN U7 [get_ports {LMS_DIQ2_D[11]}]
set_property PACKAGE_PIN U5 [get_ports LMS_TXNRX2]
set_property PACKAGE_PIN W7 [get_ports LMS_EN_IQSEL2]
set_property PACKAGE_PIN W5 [get_ports LMS_MCLK2]
set_property PACKAGE_PIN W6 [get_ports LMS_FLCK2]
#
# DIQ1 BANK14
#
set_property PACKAGE_PIN J17 [get_ports {LMS_DIQ1_D[0]}]
set_property PACKAGE_PIN H17 [get_ports {LMS_DIQ1_D[1]}]
set_property PACKAGE_PIN H19 [get_ports {LMS_DIQ1_D[2]}]
set_property PACKAGE_PIN K17 [get_ports {LMS_DIQ1_D[3]}]
set_property PACKAGE_PIN G17 [get_ports {LMS_DIQ1_D[4]}]
set_property PACKAGE_PIN V16 [get_ports {LMS_DIQ1_D[5]}]
set_property PACKAGE_PIN J19 [get_ports {LMS_DIQ1_D[6]}]
set_property PACKAGE_PIN M19 [get_ports {LMS_DIQ1_D[7]}]
set_property PACKAGE_PIN P17 [get_ports {LMS_DIQ1_D[8]}]
set_property PACKAGE_PIN N19 [get_ports {LMS_DIQ1_D[9]}]
set_property PACKAGE_PIN U17 [get_ports {LMS_DIQ1_D[10]}]
set_property PACKAGE_PIN U16 [get_ports {LMS_DIQ1_D[11]}]
set_property PACKAGE_PIN V15 [get_ports LMS_TXNRX1]
set_property PACKAGE_PIN P19 [get_ports LMS_EN_IQSEL1]
set_property PACKAGE_PIN L17 [get_ports LMS_MCLK1]
set_property PACKAGE_PIN G19 [get_ports LMS_FCLK1]


## LMS constrains

# LMS SPI & reset logic
set_property IOSTANDARD LVCMOS25 [get_ports FPGA_SPI_LMS_SS]
set_property IOSTANDARD LVCMOS25 [get_ports FPGA_SPI_MOSI]
set_property IOSTANDARD LVCMOS25 [get_ports FPGA_SPI_MISO]
set_property IOSTANDARD LVCMOS25 [get_ports FPGA_SPI_SCLK]
set_property IOSTANDARD LVCMOS25 [get_ports LMS_RESET]
set_property IOSTANDARD LVCMOS25 [get_ports LMS_CORE_LDO_EN]
set_property IOSTANDARD LVCMOS25 [get_ports LMS_RXEN]
set_property IOSTANDARD LVCMOS25 [get_ports LMS_TXEN]
set_property PULLDOWN true [get_ports FPGA_SPI_MOSI]
set_property PULLDOWN true [get_ports FPGA_SPI_MISO]

# LML Port 1
set_property IOSTANDARD LVCMOS25 [get_ports LMS_FLCK2]
set_property IOSTANDARD LVCMOS25 [get_ports {{LMS_DIQ2_D[*]} LMS_TXNRX2 LMS_EN_IQSEL2 LMS_MCLK2}]
#set_property IOSTANDARD HSTL_I_18          [get_ports {lms_diq1[*] LMS_TXNRX1 lms_io_iqsel1 lms_o_mclk1}]

# 'if' isn't supported, so edit it manually:
#if { $VIO_LML1_TYPE == "HSTL_II_18"} {
#set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {lms_diq1[*] lms_i_fclk1 lms_io_iqsel1}]
#set_property INTERNAL_VREF 0.9         [get_iobanks 14]
#} else {
set_property SLEW FAST [get_ports {{LMS_DIQ2_D[*]} LMS_FLCK2 LMS_EN_IQSEL2}]
set_property DRIVE 8 [get_ports {{LMS_DIQ2_D[*]} LMS_FLCK2 LMS_EN_IQSEL2}]
#}

# LML Port 2
set_property IOSTANDARD LVCMOS25 [get_ports {{lms_diq1[*]} LMS_TXNRX1 lms_io_iqsel1 lms_o_mclk1 lms_i_fclk1}]
#if { $VIO_LML2_TYPE == "HSTL_II_18"} {
#set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {LMS_DIQ2_D[*] LMS_FLCK2 lms_io_iqsel1}]
#set_property INTERNAL_VREF 0.9         [get_iobanks 34]
#} else {
set_property SLEW FAST [get_ports lms_i_fclk1]
set_property DRIVE 8 [get_ports lms_i_fclk1]
#}


