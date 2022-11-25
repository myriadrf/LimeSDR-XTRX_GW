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
set_property BITSTREAM.config.SPI_opcode 0x6B [current_design ]
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]


set_false_path -from [get_ports sys_rst_n]


# CLOCKS
create_clock -name usb_phy_clk -period 16 [get_ports usb_clk]
create_clock -name cfg_mclk -period 12  [get_nets inst0_xtrx_top/cfg_mclk]
create_clock -name sys_clk -period 10   [get_ports sys_clk_p]
create_clock -name clk_vctcxo -period 20 [get_ports fpga_clk_vctcxo]
create_clock -name rx_mclk_in -period 8.138 [get_ports lms_o_mclk2]
create_clock -name tx_mclk_in -period 8.138 [get_ports lms_o_mclk1]


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

#create_generated_clock -name clk_125mhz_mux_x0y0 \
#                        -source [get_pins inst0_xtrx_top/xlnx_pci_clocking/pclk_i1_bufgctrl.pclk_i1/I0] \
#                        -divide_by 1 \
#                        [get_pins inst0_xtrx_top/xlnx_pci_clocking/pclk_i1_bufgctrl.pclk_i1/O]

#create_generated_clock -name clk_250mhz_mux_x0y0 \
#                        -source [get_pins inst0_xtrx_top/xlnx_pci_clocking/pclk_i1_bufgctrl.pclk_i1/I1] \
#                        -divide_by 1 -add -master_clock [get_clocks -of [get_pins inst0_xtrx_top/xlnx_pci_clocking/pclk_i1_bufgctrl.pclk_i1/I1]] \
#                        [get_pins inst0_xtrx_top/xlnx_pci_clocking/pclk_i1_bufgctrl.pclk_i1/O]

#set_clock_groups -name pcieclkmux -physically_exclusive -group clk_125mhz_mux_x0y0 -group clk_250mhz_mux_x0y0



#create_generated_clock -name clk_userclk_mux \
#                        -source [get_pins inst0_xtrx_top/userclk_c_bufg/I0] \
#                        -divide_by 1 \
#                        [get_pins inst0_xtrx_top/userclk_c_bufg/O]

#create_generated_clock -name clk_cfgmclk_mux \
#                        -source [get_pins inst0_xtrx_top/userclk_c_bufg/I1] \
#                        -divide_by 1 -add -master_clock [get_clocks -of [get_pins inst0_xtrx_top/userclk_c_bufg/I1]] \
#                        [get_pins inst0_xtrx_top/userclk_c_bufg/O]

##create_generated_clock -name clk_cfgmclk_mux \
##                        -source [get_pins inst0_xtrx_top/STARTUPE2_inst/CFGMCLK] \
##                        -divide_by 1 -add -master_clock \ 
##                        [get_pins inst0_xtrx_top/userclk_c_bufg/O]

#create_generated_clock -name clk_cfgmclk_mux \
#                       -source [get_pins inst0_xtrx_top/userclk_c_bufg/I1] \ 
#                       -divide_by 1 -add -master_clock [get_clocks cfg_mclk] \
#                       [get_pins inst0_xtrx_top/userclk_c_bufg/O]

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

set VIO_CMOS_TYPE        LVCMOS25
set VIO_CMOS_LML_DRIVE   8

set VIO_LML1_TYPE        LVCMOS25
set VIO_LML2_TYPE        LVCMOS25

###########################################################
# PCIexpress (3.3V) Pinout and Related I/O Constraints
###########################################################

# system reset PCI_PERST#
set_property IOSTANDARD  $VIO_CMOS_TYPE [get_ports sys_rst_n]
set_property PULLUP      true           [get_ports sys_rst_n]
set_property PACKAGE_PIN T3             [get_ports sys_rst_n]

# PCI_REF_CLK
set_property PACKAGE_PIN A8 [get_ports sys_clk_n]
set_property PACKAGE_PIN B8 [get_ports sys_clk_p]


##########################################################
# USB PHY (1.8-3.3V) (BANK 16)
##########################################################
set_property IOSTANDARD $VIO_CMOS_TYPE [get_ports {usb_d[*] usb_clk usb_dir usb_stp usb_nxt}]

set_property PACKAGE_PIN A14 [get_ports usb_d[6]]
set_property PACKAGE_PIN A15 [get_ports usb_d[5]]
set_property PACKAGE_PIN C15 [get_ports usb_d[7]]
set_property PACKAGE_PIN B15 [get_ports usb_d[4]]
set_property PACKAGE_PIN A16 [get_ports usb_d[3]]
set_property PACKAGE_PIN A17 [get_ports usb_d[1]]
set_property PACKAGE_PIN C16 [get_ports usb_clk]
set_property PACKAGE_PIN B16 [get_ports usb_d[2]]
set_property PACKAGE_PIN C17 [get_ports usb_stp]
set_property PACKAGE_PIN B17 [get_ports usb_d[0]]
set_property PACKAGE_PIN B18 [get_ports usb_dir]
set_property PACKAGE_PIN A18 [get_ports usb_nxt]

# (BANK14)
set_property IOSTANDARD $VIO_CMOS_TYPE [get_ports usb_nrst]
set_property IOSTANDARD $VIO_CMOS_TYPE [get_ports usb_26m]

set_property PACKAGE_PIN M18 [get_ports usb_nrst]
set_property PACKAGE_PIN E19 [get_ports usb_26m]

set_property PULLUP   true [get_ports usb_stp]
set_property PULLDOWN true [get_ports usb_nrst]


##########################################################
# GPS module (BANK35)
##########################################################
set_property IOSTANDARD LVCMOS33 [get_ports gps_pps]
set_property IOSTANDARD LVCMOS33 [get_ports gps_txd]
set_property IOSTANDARD LVCMOS33 [get_ports gps_rxd]

set_property PULLDOWN true [get_ports gps_pps]
set_property PULLUP   true [get_ports gps_txd]
set_property PULLUP   true [get_ports gps_rxd]

set_property PACKAGE_PIN P3 [get_ports gps_pps]
set_property PACKAGE_PIN N2 [get_ports gps_txd]
set_property PACKAGE_PIN L1 [get_ports gps_rxd]


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


set_property IOSTANDARD LVCMOS33 [get_ports gpio[0]]
set_property IOSTANDARD LVCMOS33 [get_ports gpio[1]]
set_property IOSTANDARD LVCMOS33 [get_ports gpio[2]]
set_property IOSTANDARD LVCMOS33 [get_ports gpio[3]]
set_property IOSTANDARD LVCMOS33 [get_ports gpio[4]]
set_property IOSTANDARD LVCMOS33 [get_ports gpio[5]]
set_property IOSTANDARD LVCMOS33 [get_ports gpio[6]]
set_property IOSTANDARD LVCMOS33 [get_ports gpio[7]]
set_property IOSTANDARD LVCMOS33 [get_ports gpio[8]]
set_property IOSTANDARD LVCMOS33 [get_ports gpio[9]]
set_property IOSTANDARD LVCMOS33 [get_ports gpio[10]]
set_property IOSTANDARD LVCMOS33 [get_ports gpio[11]]



set_property PACKAGE_PIN M3 [get_ports gpio[0]]
set_property PACKAGE_PIN L3 [get_ports gpio[1]]
set_property PACKAGE_PIN H2 [get_ports gpio[2]]
set_property PACKAGE_PIN J2 [get_ports gpio[3]]
set_property PACKAGE_PIN G3 [get_ports gpio[4]]
set_property PACKAGE_PIN M2 [get_ports gpio[5]]
set_property PACKAGE_PIN G2 [get_ports gpio[6]]
set_property PACKAGE_PIN N3 [get_ports gpio[7]]
set_property PACKAGE_PIN H1 [get_ports gpio[8]]
set_property PACKAGE_PIN J1 [get_ports gpio[9]]
set_property PACKAGE_PIN K2 [get_ports gpio[10]]
set_property PACKAGE_PIN L2 [get_ports gpio[11]]


##########################################################
# SKY13330 & SKY13384 switches (3.3V devided to 2.5V)
##########################################################
set_property IOSTANDARD LVCMOS33 [get_ports tx_switch]
set_property IOSTANDARD LVCMOS33 [get_ports rx_switch_1]
set_property IOSTANDARD LVCMOS33 [get_ports rx_switch_2]

set_property PACKAGE_PIN P1 [get_ports tx_switch]
set_property PACKAGE_PIN K3 [get_ports rx_switch_1]
set_property PACKAGE_PIN J3 [get_ports rx_switch_2]

set_property PULLUP true [get_ports tx_switch]
set_property PULLUP true [get_ports rx_switch_1]
set_property PULLUP true [get_ports rx_switch_2]

##########################################################
# BANK35 I2C BUS #1 (3.3V)
##########################################################
set_property IOSTANDARD LVCMOS33 [get_ports i2c1_sda]
set_property IOSTANDARD LVCMOS33 [get_ports i2c1_scl]

set_property PULLUP true [get_ports i2c1_sda]
set_property PULLUP true [get_ports i2c1_scl]

set_property PACKAGE_PIN N1 [get_ports i2c1_sda]
set_property PACKAGE_PIN M1 [get_ports i2c1_scl]


##########################################################
# FPGA FLASH N25Q256 (1.8-3.3V) BANK14
##########################################################
set_property IOSTANDARD $VIO_CMOS_TYPE [get_ports {flash_d[*]}]
set_property IOSTANDARD $VIO_CMOS_TYPE [get_ports flash_fcs_b]

set_property PACKAGE_PIN D18 [get_ports flash_d[0]]
set_property PACKAGE_PIN D19 [get_ports flash_d[1]]
set_property PACKAGE_PIN G18 [get_ports flash_d[2]]
set_property PACKAGE_PIN F18 [get_ports flash_d[3]]
set_property PACKAGE_PIN K19 [get_ports flash_fcs_b]

# AUX signals
set_property IOSTANDARD $VIO_CMOS_TYPE [get_ports fpga_clk_vctcxo]
set_property IOSTANDARD $VIO_CMOS_TYPE [get_ports en_tcxo]
set_property IOSTANDARD $VIO_CMOS_TYPE [get_ports ext_clk]
set_property IOSTANDARD $VIO_CMOS_TYPE [get_ports led_2]
set_property IOSTANDARD $VIO_CMOS_TYPE [get_ports option]
set_property IOSTANDARD $VIO_CMOS_TYPE [get_ports gpio13]
set_property IOSTANDARD $VIO_CMOS_TYPE [get_ports en_gps]
set_property IOSTANDARD $VIO_CMOS_TYPE [get_ports iovcc_sel]
set_property IOSTANDARD $VIO_CMOS_TYPE [get_ports en_smsigio]

set_property PACKAGE_PIN N17 [get_ports fpga_clk_vctcxo]
set_property PACKAGE_PIN R19 [get_ports en_tcxo]
set_property PACKAGE_PIN V17 [get_ports ext_clk]
set_property PACKAGE_PIN N18 [get_ports led_2]
set_property PACKAGE_PIN V14 [get_ports option]
set_property PACKAGE_PIN T17 [get_ports gpio13]
set_property PACKAGE_PIN L18 [get_ports en_gps]
set_property PACKAGE_PIN V19 [get_ports iovcc_sel]
set_property PACKAGE_PIN D17 [get_ports en_smsigio]


set_property PULLDOWN true [get_ports fpga_clk_vctcxo]
set_property PULLUP   true [get_ports en_tcxo]
set_property PULLDOWN true [get_ports ext_clk]



# I2C BUS #2
set_property IOSTANDARD $VIO_CMOS_TYPE [get_ports i2c2_sda]
set_property IOSTANDARD $VIO_CMOS_TYPE [get_ports i2c2_scl]

set_property PACKAGE_PIN U15 [get_ports i2c2_sda]
set_property PACKAGE_PIN U14 [get_ports i2c2_scl]

set_property PULLUP true [get_ports i2c2_sda]
set_property PULLUP true [get_ports i2c2_scl]


# SIM card (1.8V) BANK 34
set_property IOSTANDARD $VIO_CMOS_TYPE [get_ports sim_mode]
set_property IOSTANDARD $VIO_CMOS_TYPE [get_ports sim_enable]
set_property IOSTANDARD $VIO_CMOS_TYPE [get_ports sim_clk]
set_property IOSTANDARD $VIO_CMOS_TYPE [get_ports sim_reset]
set_property IOSTANDARD $VIO_CMOS_TYPE [get_ports sim_data]

set_property PACKAGE_PIN R3 [get_ports sim_mode]
set_property PACKAGE_PIN U1 [get_ports sim_enable]
set_property PACKAGE_PIN T1 [get_ports sim_clk]
set_property PACKAGE_PIN R2 [get_ports sim_reset]
set_property PACKAGE_PIN T2 [get_ports sim_data]

######################################################
# LMS7002M Pinout
######################################################
set_property PACKAGE_PIN W13 [get_ports lms_i_saen]
set_property PACKAGE_PIN W16 [get_ports lms_io_sdio]
set_property PACKAGE_PIN W15 [get_ports lms_o_sdo]
set_property PACKAGE_PIN W14 [get_ports lms_i_sclk]
set_property PACKAGE_PIN U19 [get_ports lms_i_reset]
set_property PACKAGE_PIN W17 [get_ports lms_i_gpwrdwn]
set_property PACKAGE_PIN W18 [get_ports lms_i_rxen]
set_property PACKAGE_PIN W19 [get_ports lms_i_txen]
#
# DIQ2 BANK34
#
set_property PACKAGE_PIN W2 [get_ports lms_diq2[0]]
set_property PACKAGE_PIN U2 [get_ports lms_diq2[1]]
set_property PACKAGE_PIN V3 [get_ports lms_diq2[2]]
set_property PACKAGE_PIN V4 [get_ports lms_diq2[3]]
set_property PACKAGE_PIN V5 [get_ports lms_diq2[4]]
set_property PACKAGE_PIN W7 [get_ports lms_diq2[5]]
set_property PACKAGE_PIN V2 [get_ports lms_diq2[6]]
set_property PACKAGE_PIN W4 [get_ports lms_diq2[7]]
set_property PACKAGE_PIN U5 [get_ports lms_diq2[8]]
set_property PACKAGE_PIN V8 [get_ports lms_diq2[9]]
set_property PACKAGE_PIN U7 [get_ports lms_diq2[10]]
set_property PACKAGE_PIN U8 [get_ports lms_diq2[11]]
set_property PACKAGE_PIN U4 [get_ports lms_i_txnrx2]
set_property PACKAGE_PIN U3 [get_ports lms_io_iqsel2]
set_property PACKAGE_PIN W5 [get_ports lms_o_mclk2]
set_property PACKAGE_PIN W6 [get_ports lms_i_fclk2]
#
# DIQ1 BANK14
#
set_property PACKAGE_PIN J19 [get_ports lms_diq1[0]]
set_property PACKAGE_PIN H17 [get_ports lms_diq1[1]]
set_property PACKAGE_PIN G17 [get_ports lms_diq1[2]]
set_property PACKAGE_PIN K17 [get_ports lms_diq1[3]]
set_property PACKAGE_PIN H19 [get_ports lms_diq1[4]]
set_property PACKAGE_PIN U16 [get_ports lms_diq1[5]]
set_property PACKAGE_PIN J17 [get_ports lms_diq1[6]]
set_property PACKAGE_PIN P19 [get_ports lms_diq1[7]]
set_property PACKAGE_PIN U17 [get_ports lms_diq1[8]]
set_property PACKAGE_PIN N19 [get_ports lms_diq1[9]]
set_property PACKAGE_PIN V15 [get_ports lms_diq1[10]]
set_property PACKAGE_PIN V16 [get_ports lms_diq1[11]]
set_property PACKAGE_PIN M19 [get_ports lms_i_txnrx1]
set_property PACKAGE_PIN P17 [get_ports lms_io_iqsel1]
set_property PACKAGE_PIN L17 [get_ports lms_o_mclk1]
set_property PACKAGE_PIN G19 [get_ports lms_i_fclk1]


## LMS constrains

# LMS SPI & reset logic
set_property IOSTANDARD $VIO_CMOS_TYPE [get_ports {lms_i_saen lms_io_sdio lms_o_sdo lms_i_sclk}]
set_property IOSTANDARD $VIO_CMOS_TYPE [get_ports {lms_i_reset lms_i_gpwrdwn}]
set_property IOSTANDARD $VIO_CMOS_TYPE [get_ports {lms_i_rxen lms_i_txen}]
set_property PULLDOWN   true           [get_ports {lms_io_sdio lms_o_sdo}]

# LML Port 1
set_property IOSTANDARD $VIO_LML1_TYPE     [get_ports {lms_i_fclk1}]
set_property IOSTANDARD $VIO_LML1_TYPE     [get_ports {lms_diq1[*] lms_i_txnrx1 lms_io_iqsel1 lms_o_mclk1}]
#set_property IOSTANDARD HSTL_I_18          [get_ports {lms_diq1[*] lms_i_txnrx1 lms_io_iqsel1 lms_o_mclk1}]

# 'if' isn't supported, so edit it manually:
#if { $VIO_LML1_TYPE == "HSTL_II_18"} {
    #set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {lms_diq1[*] lms_i_fclk1 lms_io_iqsel1}]
    #set_property INTERNAL_VREF 0.9         [get_iobanks 14]
#} else {
    set_property SLEW  FAST                [get_ports {lms_i_fclk1}]
    set_property DRIVE $VIO_CMOS_LML_DRIVE [get_ports {lms_i_fclk1}]
    set_property SLEW  FAST                [get_ports {lms_diq1[*] lms_i_fclk1 lms_io_iqsel1}]
    set_property DRIVE $VIO_CMOS_LML_DRIVE [get_ports {lms_diq1[*] lms_i_fclk1 lms_io_iqsel1}]
#}

# LML Port 2
set_property IOSTANDARD $VIO_LML2_TYPE     [get_ports {lms_diq2[*] lms_i_txnrx2 lms_io_iqsel2 lms_o_mclk2 lms_i_fclk2}]
#if { $VIO_LML2_TYPE == "HSTL_II_18"} {
    #set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {lms_diq2[*] lms_i_fclk2 lms_io_iqsel1}]
    #set_property INTERNAL_VREF 0.9         [get_iobanks 34]
#} else {
    set_property SLEW  FAST                [get_ports {lms_diq2[*] lms_i_fclk2 lms_io_iqsel2}]
    set_property DRIVE $VIO_CMOS_LML_DRIVE [get_ports {lms_diq2[*] lms_i_fclk2 lms_io_iqsel2}]
#}

