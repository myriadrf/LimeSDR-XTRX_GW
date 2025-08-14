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
#set_property BITSTREAM.CONFIG.SPI_OPCODE 8'h6B [current_design]
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

set_false_path -from [get_ports PERST]


# CLOCKS
create_clock -name cfg_mclk -period 12  [get_nets inst0_xtrx_top/cfg_mclk]
create_clock -period 8.000 -name sys_clk [get_ports PCI_REF_CLK_p]
create_clock -period 38.460 -name FPGA_CLK [get_ports FPGA_CLK]
create_clock -period 100 -name GNSS_1PPS [get_ports GNSS_1PPS]
# see AR# 63174
create_generated_clock -name cclk -source [get_pins inst0_xtrx_top/STARTUPE2_inst/USRCCLKO] -combinational [get_pins inst0_xtrx_top/STARTUPE2_inst/USRCCLKO]
set_clock_latency -min 0.5 [get_clocks cclk]
set_clock_latency -max 6.7 [get_clocks cclk]

set_input_delay -max 6   -clock [get_clocks cclk] -clock_fall [get_ports {FPGA_CFG_D[*]}]
set_input_delay -min 1.5 -clock [get_clocks cclk] -clock_fall [get_ports {FPGA_CFG_D[*]}]

set_output_delay -max  1.75  -clock [get_clocks cclk]  [get_ports {FPGA_CFG_D[*]}]
set_output_delay -min -2.3   -clock [get_clocks cclk]  [get_ports {FPGA_CFG_D[*]}]

set_output_delay -max  3.375 -clock [get_clocks cclk]  [get_ports FPGA_CFG_CS]
set_output_delay -min -3.375 -clock [get_clocks cclk]  [get_ports FPGA_CFG_CS]


###########################################################
# IO types
###########################################################



###########################################################
# PCIexpress (3.3V) Pinout and Related I/O Constraints
###########################################################

# system reset PCI_PERST#
set_property IOSTANDARD LVCMOS33 [get_ports PERST]
set_property PULLUP true [get_ports PERST]
set_property PACKAGE_PIN T3 [get_ports PERST]

# PCI_REF_CLK
set_property PACKAGE_PIN B8 [get_ports PCI_REF_CLK_p]
set_property PACKAGE_PIN A8 [get_ports PCI_REF_CLK_n]

set_property PACKAGE_PIN A6 [get_ports PCI_EXP_RXN[0]]
set_property PACKAGE_PIN B6 [get_ports PCI_EXP_RXP[0]]

set_property PACKAGE_PIN A2 [get_ports PCI_EXP_TXN[0]]
set_property PACKAGE_PIN B2 [get_ports PCI_EXP_TXP[0]]

##########################################################
# GPS module (BANK16)
##########################################################
set_property IOSTANDARD LVCMOS33 [get_ports GNSS_EXTINT ]
set_property IOSTANDARD LVCMOS33 [get_ports GNSS_RESET  ]
set_property IOSTANDARD LVCMOS33 [get_ports GNSS_UART_TX]
set_property IOSTANDARD LVCMOS33 [get_ports GNSS_UART_RX]
set_property IOSTANDARD LVCMOS33 [get_ports GNSS_DDC_SCL]
set_property IOSTANDARD LVCMOS33 [get_ports GNSS_DDC_SDA]
set_property IOSTANDARD LVCMOS33 [get_ports GNSS_TPULSE ]

set_property PACKAGE_PIN A14 [get_ports GNSS_EXTINT ]
set_property PACKAGE_PIN A15 [get_ports GNSS_RESET  ]
set_property PACKAGE_PIN C15 [get_ports GNSS_UART_TX]
set_property PACKAGE_PIN B15 [get_ports GNSS_UART_RX]
set_property PACKAGE_PIN A16 [get_ports GNSS_DDC_SCL]
set_property PACKAGE_PIN A17 [get_ports GNSS_DDC_SDA]
set_property PACKAGE_PIN C16 [get_ports GNSS_TPULSE ]

##########################################################
# MISC
##########################################################
set_property PACKAGE_PIN T17 [get_ports FPGA_SYNC_OUT1]
set_property PACKAGE_PIN U18 [get_ports FPGA_SYNC_OUT2]
set_property PACKAGE_PIN J18 [get_ports BOM_VER[0]]
set_property PACKAGE_PIN T18 [get_ports BOM_VER[1]]
set_property PACKAGE_PIN V14 [get_ports BOM_VER[2]]
set_property PACKAGE_PIN V7  [get_ports BOM_VER[3]]
set_property PACKAGE_PIN V13 [get_ports HW_VER[0]]
set_property PACKAGE_PIN E19 [get_ports HW_VER[1]]
set_property PACKAGE_PIN K18 [get_ports HW_VER[2]]
set_property PACKAGE_PIN D17 [get_ports HW_VER[3]]
set_property PACKAGE_PIN L18 [get_ports FPGA_GPIO[0]]
set_property PACKAGE_PIN N18 [get_ports FPGA_GPIO[1]]
set_property PACKAGE_PIN V19 [get_ports FPGA_GPIO[2]]
set_property PACKAGE_PIN V17 [get_ports FPGA_GPIO[3]]
set_property PACKAGE_PIN W3  [get_ports FPGA_DSW_BIT2]


set_property IOSTANDARD LVCMOS33 [get_ports FPGA_SYNC_OUT1]
set_property IOSTANDARD LVCMOS33 [get_ports FPGA_SYNC_OUT2]
set_property IOSTANDARD LVCMOS33 [get_ports BOM_VER[0]]
set_property IOSTANDARD LVCMOS33 [get_ports BOM_VER[1]]
set_property IOSTANDARD LVCMOS33 [get_ports BOM_VER[2]]
set_property IOSTANDARD LVCMOS33 [get_ports BOM_VER[3]]
set_property IOSTANDARD LVCMOS33 [get_ports HW_VER[0]]
set_property IOSTANDARD LVCMOS33 [get_ports HW_VER[1]]
set_property IOSTANDARD LVCMOS33 [get_ports HW_VER[2]]
set_property IOSTANDARD LVCMOS33 [get_ports HW_VER[3]]
set_property IOSTANDARD LVCMOS33 [get_ports FPGA_GPIO[0]]
set_property IOSTANDARD LVCMOS33 [get_ports FPGA_GPIO[1]]
set_property IOSTANDARD LVCMOS33 [get_ports FPGA_GPIO[2]]
set_property IOSTANDARD LVCMOS33 [get_ports FPGA_GPIO[3]]
set_property IOSTANDARD LVCMOS33 [get_ports FPGA_DSW_BIT2]

##########################################################
# XO DAC SPI
##########################################################
set_property IOSTANDARD LVCMOS33 [get_ports FPGA_SPI1_SCLK]
set_property IOSTANDARD LVCMOS33 [get_ports FPGA_SPI1_MOSI]
set_property IOSTANDARD LVCMOS33 [get_ports FPGA_SPI1_DAC_SS]

set_property PACKAGE_PIN R2 [get_ports FPGA_SPI1_SCLK]
set_property PACKAGE_PIN T2 [get_ports FPGA_SPI1_MOSI]
set_property PACKAGE_PIN R3 [get_ports FPGA_SPI1_DAC_SS]

##########################################################
# TDD Switch
##########################################################
set_property IOSTANDARD LVCMOS33 [get_ports FPGA_RF_SW_TDD]

set_property PACKAGE_PIN U15 [get_ports FPGA_RF_SW_TDD]

##########################################################
# RF Control
##########################################################
set_property IOSTANDARD LVCMOS18 [get_ports RX1_RF_SCLK   ]
set_property IOSTANDARD LVCMOS18 [get_ports RX1_RF_SDATA  ]
set_property IOSTANDARD LVCMOS18 [get_ports TRX1_RF_SCLK  ]
set_property IOSTANDARD LVCMOS18 [get_ports TRX1_RF_SDATA ]
set_property IOSTANDARD LVCMOS18 [get_ports TRX1_ANT_SCLK ]
set_property IOSTANDARD LVCMOS18 [get_ports TRX1_ANT_SDATA]
set_property IOSTANDARD LVCMOS18 [get_ports RX2_RF_SCLK   ]
set_property IOSTANDARD LVCMOS18 [get_ports RX2_RF_SDATA  ]
set_property IOSTANDARD LVCMOS18 [get_ports TRX2_RF_SCLK  ]
set_property IOSTANDARD LVCMOS18 [get_ports TRX2_RF_SDATA ]
set_property IOSTANDARD LVCMOS18 [get_ports TRX2_ANT_SCLK ]
set_property IOSTANDARD LVCMOS18 [get_ports TRX2_ANT_SDATA]

set_property PACKAGE_PIN G3 [get_ports RX1_RF_SCLK   ]
set_property PACKAGE_PIN G2 [get_ports RX1_RF_SDATA  ]
set_property PACKAGE_PIN H2 [get_ports TRX1_RF_SCLK  ]
set_property PACKAGE_PIN J2 [get_ports TRX1_RF_SDATA ]
set_property PACKAGE_PIN H1 [get_ports TRX1_ANT_SCLK ]
set_property PACKAGE_PIN J1 [get_ports TRX1_ANT_SDATA]
set_property PACKAGE_PIN K2 [get_ports RX2_RF_SCLK   ]
set_property PACKAGE_PIN L2 [get_ports RX2_RF_SDATA  ]
set_property PACKAGE_PIN L1 [get_ports TRX2_RF_SCLK  ]
set_property PACKAGE_PIN J3 [get_ports TRX2_RF_SDATA ]
set_property PACKAGE_PIN K3 [get_ports TRX2_ANT_SCLK ]
set_property PACKAGE_PIN L3 [get_ports TRX2_ANT_SDATA]


##########################################################
# M.2 Signals
##########################################################
set_property IOSTANDARD LVCMOS18 [get_ports M2_DEVSLP     ]
set_property IOSTANDARD LVCMOS18 [get_ports M2_COEX1      ]
set_property IOSTANDARD LVCMOS18 [get_ports M2_COEX2      ]
set_property IOSTANDARD LVCMOS18 [get_ports M2_COEX3      ]
set_property IOSTANDARD LVCMOS18 [get_ports M2_W_DISABLE_2]
set_property IOSTANDARD LVCMOS18 [get_ports M2_DPR        ]
set_property IOSTANDARD LVCMOS18 [get_ports M2_RESET      ]
set_property IOSTANDARD LVCMOS18 [get_ports M2_FCP_OFF    ]


set_property PACKAGE_PIN M3 [get_ports M2_DEVSLP     ]
set_property PACKAGE_PIN M2 [get_ports M2_COEX1      ]
set_property PACKAGE_PIN M1 [get_ports M2_COEX2      ]
set_property PACKAGE_PIN N2 [get_ports M2_COEX3      ]
set_property PACKAGE_PIN N1 [get_ports M2_W_DISABLE_2]
set_property PACKAGE_PIN N3 [get_ports M2_DPR        ]
set_property PACKAGE_PIN P3 [get_ports M2_RESET      ]
set_property PACKAGE_PIN P1 [get_ports M2_FCP_OFF    ]

##########################################################
# FPGA FLASH N25Q256 (1.8-3.3V) BANK14
##########################################################
set_property IOSTANDARD LVCMOS33 [get_ports {FPGA_CFG_D[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports FPGA_CFG_CS]

set_property PACKAGE_PIN D18 [get_ports {FPGA_CFG_D[0]}]
set_property PACKAGE_PIN D19 [get_ports {FPGA_CFG_D[1]}]
set_property PACKAGE_PIN G18 [get_ports {FPGA_CFG_D[2]}]
set_property PACKAGE_PIN F18 [get_ports {FPGA_CFG_D[3]}]
set_property PACKAGE_PIN K19 [get_ports FPGA_CFG_CS]

# AUX signals
set_property IOSTANDARD LVCMOS33 [get_ports FPGA_CLK]
set_property IOSTANDARD LVCMOS33 [get_ports FPGA_LED_R]
set_property IOSTANDARD LVCMOS33 [get_ports FPGA_LED_G]

set_property PACKAGE_PIN N17 [get_ports FPGA_CLK]
set_property PACKAGE_PIN R18 [get_ports FPGA_LED_R]
set_property PACKAGE_PIN U14 [get_ports FPGA_LED_G]


set_property PULLDOWN true [get_ports FPGA_CLK]

######################################################
# RPI Related
######################################################
set_property IOSTANDARD LVCMOS33 [get_ports RPI_SYNC_OUT ]
set_property IOSTANDARD LVCMOS33 [get_ports RPI_SPI1_SCLK]
set_property IOSTANDARD LVCMOS33 [get_ports RPI_SPI1_MOSI]
set_property IOSTANDARD LVCMOS33 [get_ports RPI_SPI1_MISO]
set_property IOSTANDARD LVCMOS33 [get_ports RPI_SYNC_SS1 ]
set_property IOSTANDARD LVCMOS33 [get_ports RPI_SYNC_SS2 ]
set_property IOSTANDARD LVCMOS33 [get_ports RPI_UART4_RX ]
set_property IOSTANDARD LVCMOS33 [get_ports RPI_UART4_TX ]


set_property PACKAGE_PIN P18 [get_ports RPI_SYNC_OUT ]
set_property PACKAGE_PIN B16 [get_ports RPI_SPI1_SCLK]
set_property PACKAGE_PIN C17 [get_ports RPI_SPI1_MOSI]
set_property PACKAGE_PIN B17 [get_ports RPI_SPI1_MISO]
set_property PACKAGE_PIN B18 [get_ports RPI_SYNC_SS1 ]
set_property PACKAGE_PIN A18 [get_ports RPI_SYNC_SS2 ]
set_property PACKAGE_PIN T1  [get_ports RPI_UART4_RX ]
set_property PACKAGE_PIN U1  [get_ports RPI_UART4_TX ]


# I2C BUS (Slave)
set_property IOSTANDARD LVCMOS33 [get_ports FPGA_I2C_SDA]
set_property IOSTANDARD LVCMOS33 [get_ports FPGA_I2C_SCL]

set_property PACKAGE_PIN M18 [get_ports FPGA_I2C_SDA]
set_property PACKAGE_PIN R19 [get_ports FPGA_I2C_SCL]

set_property PULLUP true [get_ports FPGA_I2C_SDA]
set_property PULLUP true [get_ports FPGA_I2C_SCL]

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
set_property PACKAGE_PIN V3 [get_ports {LMS_DIQ2_D[3]}]
set_property PACKAGE_PIN V4 [get_ports {LMS_DIQ2_D[4]}]
set_property PACKAGE_PIN V2 [get_ports {LMS_DIQ2_D[5]}]
set_property PACKAGE_PIN V5 [get_ports {LMS_DIQ2_D[6]}]
set_property PACKAGE_PIN W4 [get_ports {LMS_DIQ2_D[7]}]
set_property PACKAGE_PIN V8 [get_ports {LMS_DIQ2_D[8]}]
set_property PACKAGE_PIN U4 [get_ports {LMS_DIQ2_D[9]}]
set_property PACKAGE_PIN U8 [get_ports {LMS_DIQ2_D[10]}]
set_property PACKAGE_PIN U7 [get_ports {LMS_DIQ2_D[11]}]
set_property PACKAGE_PIN U5 [get_ports LMS_TXNRX2]
set_property PACKAGE_PIN W7 [get_ports LMS_EN_IQSEL2]
set_property PACKAGE_PIN W5 [get_ports LMS_MCLK2]
set_property PACKAGE_PIN W6 [get_ports LMS_FCLK2]
#
# DIQ1 BANK14
#
set_property PACKAGE_PIN J17 [get_ports LMS_DIQ1_D[0]]
set_property PACKAGE_PIN H17 [get_ports LMS_DIQ1_D[1]]
set_property PACKAGE_PIN H19 [get_ports LMS_DIQ1_D[2]]
set_property PACKAGE_PIN K17 [get_ports LMS_DIQ1_D[3]]
set_property PACKAGE_PIN G17 [get_ports LMS_DIQ1_D[4]]
set_property PACKAGE_PIN V16 [get_ports LMS_DIQ1_D[5]]
set_property PACKAGE_PIN J19 [get_ports LMS_DIQ1_D[6]]
set_property PACKAGE_PIN M19 [get_ports LMS_DIQ1_D[7]]
set_property PACKAGE_PIN P17 [get_ports LMS_DIQ1_D[8]]
set_property PACKAGE_PIN N19 [get_ports LMS_DIQ1_D[9]]
set_property PACKAGE_PIN U17 [get_ports LMS_DIQ1_D[10]]
set_property PACKAGE_PIN U16 [get_ports LMS_DIQ1_D[11]]
set_property PACKAGE_PIN V15 [get_ports LMS_TXNRX1]
set_property PACKAGE_PIN P19 [get_ports LMS_EN_IQSEL1]
set_property PACKAGE_PIN L17 [get_ports LMS_MCLK1]
set_property PACKAGE_PIN G19 [get_ports LMS_FCLK1]


set_property SLEW SLOW [get_ports LMS_DIQ1_D[0]]
set_property SLEW FAST [get_ports LMS_DIQ1_D[1]]
set_property SLEW SLOW [get_ports LMS_DIQ1_D[2]]
set_property SLEW SLOW [get_ports LMS_DIQ1_D[3]]
set_property SLEW SLOW [get_ports LMS_DIQ1_D[4]]
set_property SLEW SLOW [get_ports LMS_DIQ1_D[5]]
set_property SLEW SLOW [get_ports LMS_DIQ1_D[6]]
set_property SLEW FAST [get_ports LMS_DIQ1_D[7]]
set_property SLEW FAST [get_ports LMS_DIQ1_D[8]]
set_property SLEW SLOW [get_ports LMS_DIQ1_D[9]]
set_property SLEW SLOW [get_ports LMS_DIQ1_D[10]]
set_property SLEW FAST [get_ports LMS_DIQ1_D[11]]
set_property SLEW SLOW [get_ports LMS_TXNRX1]
set_property SLEW FAST [get_ports LMS_EN_IQSEL1]
set_property SLEW FAST [get_ports LMS_FCLK1]


set_property DRIVE  4 [get_ports LMS_DIQ1_D[0]]
set_property DRIVE 16 [get_ports LMS_DIQ1_D[1]]
set_property DRIVE  4 [get_ports LMS_DIQ1_D[2]]
set_property DRIVE  4 [get_ports LMS_DIQ1_D[3]]
set_property DRIVE  4 [get_ports LMS_DIQ1_D[4]]
set_property DRIVE  4 [get_ports LMS_DIQ1_D[5]]
set_property DRIVE  4 [get_ports LMS_DIQ1_D[6]]
set_property DRIVE 16 [get_ports LMS_DIQ1_D[7]]
set_property DRIVE 16 [get_ports LMS_DIQ1_D[8]]
set_property DRIVE  4 [get_ports LMS_DIQ1_D[9]]
set_property DRIVE  4 [get_ports LMS_DIQ1_D[10]]
set_property DRIVE 24 [get_ports LMS_DIQ1_D[11]]
set_property DRIVE  4 [get_ports LMS_TXNRX1]
set_property DRIVE 16 [get_ports LMS_EN_IQSEL1]
set_property DRIVE 24 [get_ports LMS_FCLK1]


set_property IOSTANDARD LVCMOS33 [get_ports LMS_DIQ1_D[0]]
set_property IOSTANDARD LVCMOS33 [get_ports LMS_DIQ1_D[1]]
set_property IOSTANDARD LVCMOS33 [get_ports LMS_DIQ1_D[2]]
set_property IOSTANDARD LVCMOS33 [get_ports LMS_DIQ1_D[3]]
set_property IOSTANDARD LVCMOS33 [get_ports LMS_DIQ1_D[4]]
set_property IOSTANDARD LVCMOS33 [get_ports LMS_DIQ1_D[5]]
set_property IOSTANDARD LVCMOS33 [get_ports LMS_DIQ1_D[6]]
set_property IOSTANDARD LVCMOS33 [get_ports LMS_DIQ1_D[7]]
set_property IOSTANDARD LVCMOS33 [get_ports LMS_DIQ1_D[8]]
set_property IOSTANDARD LVCMOS33 [get_ports LMS_DIQ1_D[9]]
set_property IOSTANDARD LVCMOS33 [get_ports LMS_DIQ1_D[10]]
set_property IOSTANDARD LVTTL    [get_ports LMS_DIQ1_D[11]]
set_property IOSTANDARD LVCMOS33 [get_ports LMS_TXNRX1]
set_property IOSTANDARD LVCMOS33 [get_ports LMS_EN_IQSEL1]
set_property IOSTANDARD LVCMOS33 [get_ports LMS_MCLK1]
set_property IOSTANDARD LVTTL    [get_ports LMS_FCLK1]


## LMS constrains

# LMS SPI & reset logic
set_property IOSTANDARD LVCMOS33 [get_ports FPGA_SPI_LMS_SS]
set_property IOSTANDARD LVCMOS33 [get_ports FPGA_SPI_MOSI]
set_property IOSTANDARD LVCMOS33 [get_ports FPGA_SPI_MISO]
set_property IOSTANDARD LVCMOS33 [get_ports FPGA_SPI_SCLK]
set_property IOSTANDARD LVCMOS33 [get_ports LMS_RESET]
set_property IOSTANDARD LVCMOS33 [get_ports LMS_CORE_LDO_EN]
set_property IOSTANDARD LVCMOS33 [get_ports LMS_RXEN]
set_property IOSTANDARD LVCMOS33 [get_ports LMS_TXEN]
set_property PULLDOWN true [get_ports FPGA_SPI_MOSI]
set_property PULLDOWN true [get_ports FPGA_SPI_MISO]

# LML Port 1
set_property IOSTANDARD LVCMOS33 [get_ports LMS_FCLK2]
set_property IOSTANDARD LVCMOS33 [get_ports {{LMS_DIQ2_D[*]} LMS_TXNRX2 LMS_EN_IQSEL2 LMS_MCLK2}]
#set_property IOSTANDARD HSTL_I_18          [get_ports {lms_diq1[*] LMS_TXNRX1 LMS_EN_IQSEL1 LMS_MCLK1}]

# 'if' isn't supported, so edit it manually:
#if { $VIO_LML1_TYPE == "HSTL_II_18"} {
#set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {lms_diq1[*] LMS_FCLK1 LMS_EN_IQSEL1}]
#set_property INTERNAL_VREF 0.9         [get_iobanks 14]
#} else {
set_property SLEW FAST [get_ports {{LMS_DIQ2_D[*]} LMS_FCLK2 LMS_EN_IQSEL2}]
set_property DRIVE 8 [get_ports {{LMS_DIQ2_D[*]} LMS_FCLK2 LMS_EN_IQSEL2}]
#}


#if { $VIO_LML2_TYPE == "HSTL_II_18"} {
#set_property IN_TERM UNTUNED_SPLIT_50 [get_ports {LMS_DIQ2_D[*] LMS_FCLK2 LMS_EN_IQSEL1}]
#set_property INTERNAL_VREF 0.9         [get_iobanks 34]
#} else {
#set_property SLEW FAST [get_ports LMS_FCLK1]
#set_property DRIVE 24 [get_ports LMS_FCLK1]
#}


