set_property PACKAGE_PIN W13 [get_ports LMS_SCLK]
##############################################################
## Copyright (c) 2016-2020 Fairwaves, Inc.
## SPDX-License-Identifier: CERN-OHL-W-2.0
##############################################################

set_property BITSTREAM.CONFIG.UNUSEDPIN Pulldown [current_design]
set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN Disable [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 66 [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]
set_property BITSTREAM.CONFIG.SPI_OPCODE 8'h0B [current_design]
set_property CFGBVS GND [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]


#set_false_path -from [get_ports PERST]


# CLOCKS
create_clock -period 16.000 -name usb_phy_clk [get_ports USB_CLK]
create_clock -period 8.000 -name sys_clk [get_ports GTP_REF_P]

# see AR# 63174





###########################################################
# IO types
###########################################################



###########################################################
# PCIexpress (3.3V) Pinout and Related I/O Constraints
###########################################################

# system reset PCI_PERST#
# set_property IOSTANDARD LVCMOS33 [get_ports PERST]
# set_property PULLUP true [get_ports PERST]
# set_property PACKAGE_PIN T3 [get_ports PERST]

# PCI_REF_CLK
set_property PACKAGE_PIN B8 [get_ports GTP_REF_P]
set_property PACKAGE_PIN A8 [get_ports GTP_REF_N]


set_property LOC GTPE2_CHANNEL_X0Y1 [get_cells {inst0/inst1_litepcie_top/inst0_litepcie_core/pcie_s7/inst/inst/gt_top_i/pipe_wrapper_i/pipe_lane[0].gt_wrapper_i/gtp_channel.gtpe2_channel_i}]
set_property PACKAGE_PIN A6 [get_ports {GTP_RX_N[0]}]
set_property PACKAGE_PIN B6 [get_ports {GTP_RX_P[0]}]
set_property PACKAGE_PIN A2 [get_ports {GTP_TX_N[0]}]
set_property PACKAGE_PIN B2 [get_ports {GTP_TX_P[0]}]


##########################################################
# USB PHY (1.8-3.3V) (BANK 16)
##########################################################
set_property IOSTANDARD LVCMOS18 [get_ports {{USB_D[*]} USB_CLK USB_DIR USB_STP USB_NXT}]

set_property PACKAGE_PIN A14 [get_ports {USB_D[7]}]
set_property PACKAGE_PIN A15 [get_ports {USB_D[6]}]
set_property PACKAGE_PIN C15 [get_ports {USB_D[5]}]
set_property PACKAGE_PIN B15 [get_ports {USB_D[3]}]
set_property PACKAGE_PIN A16 [get_ports {USB_D[4]}]
set_property PACKAGE_PIN A17 [get_ports {USB_D[2]}]
set_property PACKAGE_PIN C16 [get_ports USB_CLK]
set_property PACKAGE_PIN B16 [get_ports {USB_D[1]}]
set_property PACKAGE_PIN C17 [get_ports USB_STP]
set_property PACKAGE_PIN B17 [get_ports USB_NXT]
set_property PACKAGE_PIN B18 [get_ports USB_DIR]
set_property PACKAGE_PIN A18 [get_ports {USB_D[0]}]

# (BANK14)
set_property IOSTANDARD LVCMOS18 [get_ports USB_NRST]
set_property PACKAGE_PIN D17 [get_ports USB_NRST]

set_property PULLUP true [get_ports USB_STP]
set_property PULLDOWN true [get_ports USB_NRST]

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


set_property IOSTANDARD LVCMOS18 [get_ports GPLEDINT]
set_property IOSTANDARD LVCMOS18 [get_ports GPLED0]
set_property IOSTANDARD LVCMOS18 [get_ports GPLED1]
set_property IOSTANDARD LVCMOS18 [get_ports {GPIO[*]}]



set_property PACKAGE_PIN K3 [get_ports GPLEDINT]
set_property PACKAGE_PIN N3 [get_ports GPLED0]
set_property PACKAGE_PIN N2 [get_ports GPLED1]
set_property PACKAGE_PIN M1 [get_ports {GPIO[10]}]
set_property PACKAGE_PIN P1 [get_ports {GPIO[11]}]

##########################################################
# MISC
##########################################################


##########################################################
# SPDT switches (RF)
##########################################################
set_property IOSTANDARD LVCMOS18 [get_ports TXSW]
set_property IOSTANDARD LVCMOS18 [get_ports RXSW]

set_property PACKAGE_PIN P3 [get_ports TXSW]
set_property PACKAGE_PIN G19 [get_ports RXSW]

set_property PULLUP true [get_ports TXSW]
set_property PULLUP true [get_ports RXSW]

##########################################################
# FPGA FLASH AT25SL321 (1.8) BANK14
##########################################################
set_property IOSTANDARD LVCMOS18 [get_ports {FLASH_D[*]}]
set_property IOSTANDARD LVCMOS18 [get_ports FLASH_FCS_B]

set_property PACKAGE_PIN D18 [get_ports {FLASH_D[0]}]
set_property PACKAGE_PIN D19 [get_ports {FLASH_D[1]}]
set_property PACKAGE_PIN G18 [get_ports {FLASH_D[2]}]
set_property PACKAGE_PIN F18 [get_ports {FLASH_D[3]}]
set_property PACKAGE_PIN K19 [get_ports FLASH_FCS_B]

##########################################################
# AUX signals
##########################################################

set_property IOSTANDARD LVCMOS18 [get_ports INTREF_SW]
set_property IOSTANDARD LVCMOS18 [get_ports LDOEN]
set_property IOSTANDARD LVCMOS18 [get_ports USB_CLK_EN]

set_property PACKAGE_PIN H17 [get_ports INTREF_SW]
set_property PACKAGE_PIN M3 [get_ports LDOEN]
set_property PACKAGE_PIN G17 [get_ports USB_CLK_EN]

set_property PULLDOWN true [get_ports INTREF_SW]
set_property PULLUP true [get_ports LDOEN]
set_property PULLUP true [get_ports USB_CLK_EN]


##########################################################
# I2C BUS #2 BANK14
##########################################################
set_property IOSTANDARD LVCMOS18 [get_ports SDA2]
set_property IOSTANDARD LVCMOS18 [get_ports SCL2]

set_property PACKAGE_PIN W14 [get_ports SDA2]
set_property PACKAGE_PIN V14 [get_ports SCL2]

set_property PULLUP true [get_ports SDA2]
set_property PULLUP true [get_ports SCL2]

######################################################
# LMS7002M Pinout
######################################################
set_property PACKAGE_PIN V13 [get_ports LMS_SEN]
set_property PACKAGE_PIN V15 [get_ports LMS_SDIO]
set_property PACKAGE_PIN W15 [get_ports LMS_SDO]
set_property PACKAGE_PIN J3 [get_ports LMS_RESET]
set_property PACKAGE_PIN R19 [get_ports LMS_LDO_EN]
set_property PACKAGE_PIN R18 [get_ports RXEN]
set_property PACKAGE_PIN U14 [get_ports TXEN]
#
# LML Port 2
#
set_property PACKAGE_PIN W16 [get_ports {TXD[0]}]
set_property PACKAGE_PIN W17 [get_ports {TXD[1]}]
set_property PACKAGE_PIN V16 [get_ports {TXD[2]}]
set_property PACKAGE_PIN U17 [get_ports {TXD[3]}]
set_property PACKAGE_PIN W18 [get_ports {TXD[4]}]
set_property PACKAGE_PIN W19 [get_ports {TXD[5]}]
set_property PACKAGE_PIN V19 [get_ports {TXD[6]}]
set_property PACKAGE_PIN U18 [get_ports {TXD[7]}]
set_property PACKAGE_PIN V17 [get_ports {TXD[8]}]
set_property PACKAGE_PIN U19 [get_ports {TXD[9]}]
set_property PACKAGE_PIN U16 [get_ports {TXD[10]}]
set_property PACKAGE_PIN U15 [get_ports {TXD[11]}]
set_property PACKAGE_PIN G3 [get_ports TXNRX2]
set_property PACKAGE_PIN T18 [get_ports TXIQSEL]
set_property PACKAGE_PIN N17 [get_ports TXCLK_M]
set_property PACKAGE_PIN P17 [get_ports TXCLK_F]
#
# LML Port 1
#
set_property PACKAGE_PIN J17 [get_ports {RXD[0]}]
set_property PACKAGE_PIN L18 [get_ports {RXD[1]}]
set_property PACKAGE_PIN H19 [get_ports {RXD[2]}]
set_property PACKAGE_PIN M18 [get_ports {RXD[3]}]
set_property PACKAGE_PIN N18 [get_ports {RXD[4]}]
set_property PACKAGE_PIN N19 [get_ports {RXD[5]}]
set_property PACKAGE_PIN J18 [get_ports {RXD[6]}]
set_property PACKAGE_PIN J19 [get_ports {RXD[7]}]
set_property PACKAGE_PIN P18 [get_ports {RXD[8]}]
set_property PACKAGE_PIN K18 [get_ports {RXD[9]}]
set_property PACKAGE_PIN T17 [get_ports {RXD[10]}]
set_property PACKAGE_PIN P19 [get_ports {RXD[11]}]
set_property PACKAGE_PIN L3 [get_ports TXNRX1]
set_property PACKAGE_PIN M19 [get_ports RXIQSEL]
set_property PACKAGE_PIN L17 [get_ports RXCLK_M]
set_property PACKAGE_PIN K17 [get_ports RXCLK_F]


#set_property SLEW SLOW [get_ports RXD[0]]
#set_property SLEW FAST [get_ports RXD[1]]
#set_property SLEW SLOW [get_ports RXD[2]]
#set_property SLEW SLOW [get_ports RXD[3]]
#set_property SLEW SLOW [get_ports RXD[4]]
#set_property SLEW SLOW [get_ports RXD[5]]
#set_property SLEW SLOW [get_ports RXD[6]]
#set_property SLEW FAST [get_ports RXD[7]]
#set_property SLEW FAST [get_ports RXD[8]]
set_property SLEW SLOW [get_ports RXD[9]]
#set_property SLEW SLOW [get_ports RXD[10]]
set_property SLEW FAST [get_ports RXD[11]]
#set_property SLEW SLOW [get_ports TXNRX1]
#set_property SLEW FAST [get_ports RXIQSEL]
#set_property SLEW FAST [get_ports RXCLK_F]


#set_property DRIVE  4 [get_ports RXD[0]]
#set_property DRIVE 16 [get_ports RXD[1]]
#set_property DRIVE  4 [get_ports RXD[2]]
#set_property DRIVE  4 [get_ports RXD[3]]
#set_property DRIVE  4 [get_ports RXD[4]]
#set_property DRIVE  4 [get_ports RXD[5]]
#set_property DRIVE  4 [get_ports RXD[6]]
#set_property DRIVE 16 [get_ports RXD[7]]
#set_property DRIVE 16 [get_ports RXD[8]]
set_property DRIVE  4 [get_ports RXD[9]]
#set_property DRIVE  4 [get_ports RXD[10]]
set_property DRIVE 24 [get_ports RXD[11]]
#set_property DRIVE  4 [get_ports TXNRX1]
#set_property DRIVE 16 [get_ports RXIQSEL]
#set_property DRIVE 24 [get_ports RXCLK_F]


#set_property IOSTANDARD LVCMOS33 [get_ports LMS_DIQ1_D[0]]
#set_property IOSTANDARD LVCMOS33 [get_ports LMS_DIQ1_D[1]]
#set_property IOSTANDARD LVCMOS33 [get_ports LMS_DIQ1_D[2]]
#set_property IOSTANDARD LVCMOS33 [get_ports LMS_DIQ1_D[3]]
#set_property IOSTANDARD LVCMOS33 [get_ports LMS_DIQ1_D[4]]
#set_property IOSTANDARD LVCMOS33 [get_ports LMS_DIQ1_D[5]]
#set_property IOSTANDARD LVCMOS33 [get_ports LMS_DIQ1_D[6]]
#set_property IOSTANDARD LVCMOS33 [get_ports LMS_DIQ1_D[7]]
#set_property IOSTANDARD LVCMOS33 [get_ports LMS_DIQ1_D[8]]
#set_property IOSTANDARD LVCMOS33 [get_ports LMS_DIQ1_D[9]]
#set_property IOSTANDARD LVCMOS33 [get_ports LMS_DIQ1_D[10]]
#set_property IOSTANDARD LVTTL    [get_ports LMS_DIQ1_D[11]]
#set_property IOSTANDARD LVCMOS33 [get_ports LMS_TXNRX1]
#set_property IOSTANDARD LVCMOS33 [get_ports LMS_EN_IQSEL1]
#set_property IOSTANDARD LVCMOS33 [get_ports LMS_MCLK1]
#set_property IOSTANDARD LVTTL    [get_ports LMS_FCLK1]


## LMS constrains

# LMS SPI & reset logic
set_property IOSTANDARD LVCMOS18 [get_ports LMS_SEN]
set_property IOSTANDARD LVCMOS18 [get_ports LMS_SDIO]
set_property IOSTANDARD LVCMOS18 [get_ports LMS_SDO]
set_property IOSTANDARD LVCMOS18 [get_ports LMS_SCLK]
set_property IOSTANDARD LVCMOS18 [get_ports LMS_RESET]
set_property IOSTANDARD LVCMOS18 [get_ports LMS_LDO_EN]
set_property IOSTANDARD LVCMOS18 [get_ports RXEN]
set_property IOSTANDARD LVCMOS18 [get_ports TXEN]
set_property PULLDOWN true [get_ports LMS_SDIO]
set_property PULLDOWN true [get_ports LMS_SDO]

# LML Port 1
#set_property INTERNAL_VREF 0.900 [get_iobanks 14]
set_property IOSTANDARD LVCMOS18 [get_ports {{RXD[*]} TXNRX1 RXIQSEL RXCLK_M RXCLK_F}]
#set_property IOSTANDARD HSTL_I_18 [get_ports {{RXD[*]} TXNRX1 RXIQSEL RXCLK_M RXCLK_F}]
# LML Port 2
set_property IOSTANDARD LVCMOS18 [get_ports {{TXD[*]} TXNRX2 TXIQSEL TXCLK_M TXCLK_F}]


#set_property IOSTANDARD HSTL_I_18          [get_ports {lms_diq1[*] LMS_TXNRX1 LMS_EN_IQSEL1 LMS_MCLK1}]

# 'if' isn't supported, so edit it manually:
#if { $VIO_LML1_TYPE == "HSTL_II_18"} {
#set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {lms_diq1[*] LMS_FCLK1 LMS_EN_IQSEL1}]
#set_property INTERNAL_VREF 0.9         [get_iobanks 14]
#} else {
#set_property SLEW FAST [get_ports {{LMS_DIQ2_D[*]} LMS_FCLK2 LMS_EN_IQSEL2}]
#set_property DRIVE 8 [get_ports {{LMS_DIQ2_D[*]} LMS_FCLK2 LMS_EN_IQSEL2}]
#}


#if { $VIO_LML2_TYPE == "HSTL_II_18"} {
#set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {LMS_DIQ2_D[*] LMS_FCLK2 LMS_EN_IQSEL1}]
#set_property INTERNAL_VREF 0.9         [get_iobanks 34]
#} else {
#set_property SLEW FAST [get_ports LMS_FCLK1]
#set_property DRIVE 24 [get_ports LMS_FCLK1]
#}





