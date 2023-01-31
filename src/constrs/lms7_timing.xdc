# ----------------------------------------------------------------------------
# FILE: 	lms7_timing.xdc
# DESCRIPTION:	Timing constrains file for lms7 lml interface
# DATE:	January 16, 2023
# AUTHOR(s):	Lime Microsystems
# REVISIONS:
# ----------------------------------------------------------------------------
# NOTES:
#
# ----------------------------------------------------------------------------

set clk_period        8.138; 
# ----------------------------------------------------------------------------
# Primary Clocks
# ----------------------------------------------------------------------------
create_clock -period $clk_period -name LMS1_MCLK1 [get_ports lms_o_mclk1]

create_clock -period $clk_period -name LMS1_MCLK2 [get_ports lms_o_mclk2]

# ----------------------------------------------------------------------------
# Virtual clocks
# ----------------------------------------------------------------------------
#Adding an offset to the clock to satisfy timing analysis, since the phase can be changed during runtime
create_clock -period 8.138 -name LMS1_MCLK2_VIRT -waveform {3.8 7.869}
# ----------------------------------------------------------------------------
# Generated clocks
# ----------------------------------------------------------------------------
#Adding an offset to the clock to satisfy timing analysis, since the phase can be changed during runtime
create_generated_clock -name LMS1_FCLK1 -source [get_pins inst2_pll_top/inst0_tx_pll_top_cyc5/XILINX_PLL_DDIO.XILINX_PLL_DDIO/C] -multiply_by 1 [get_ports lms_i_fclk1] -waveform {1 5.069}

##  B.J.
##create_generated_clock -name LMS1_FCLK2 -source [get_pins inst1_pll_top/inst1_rx_pll_top_cyc5/XILINX_PLL_DDIO.XILINX_PLL_DDIO/C] -multiply_by 1 -phase 90 [get_ports LMS1_FCLK2]
##create_generated_clock -name LMS1_MCLK2 -source [get_pins inst1_pll_top/inst1_rx_pll_top_cyc5/XILINX_PLL_DDIO.XILINX_PLL_DDIO/C] -multiply_by 1 [get_ports LMS1_MCLK2]

##create_generated_clock -name LMS1_MCLK2_1 -source [get_ports LMS1_MCLK2] -multiply_by 1 -phase 0 [get_pins inst1_pll_top/inst1_rx_pll_top_cyc5/XILINX_MMCM.MMCM_inst1/clk_out2]

# ----------------------------------------------------------------------------
#Input constraints
# ----------------------------------------------------------------------------
#  B.J.
#set MIN_DELAY_RX 3.900

#set MAX_DELAY_RX 5.050

#LMS1
set_input_delay -clock [get_clocks LMS1_MCLK2_VIRT] -max 1 [get_ports {{lms_diq2[*]} lms_io_iqsel2}]

set_input_delay -clock [get_clocks LMS1_MCLK2_VIRT] -min -0.2 [get_ports {{lms_diq2[*]} lms_io_iqsel2}]

set_input_delay -clock [get_clocks LMS1_MCLK2_VIRT] -clock_fall -max -add_delay 1 [get_ports {{lms_diq2[*]} lms_io_iqsel2}]

set_input_delay -clock [get_clocks LMS1_MCLK2_VIRT] -clock_fall -min -add_delay -0.2 [get_ports {{lms_diq2[*]} lms_io_iqsel2}]


# ----------------------------------------------------------------------------
#Output constraints
# ----------------------------------------------------------------------------
#  B.J.
#was: set MAX_DELAY_TX 2.800  $MAX_DELAY_TX

#was: set MIN_DELAY_TX 1.000  $MIN_DELAY_TX




#LMS1
set_output_delay -clock [get_clocks LMS1_FCLK1] -max 1 [get_ports {{lms_diq1[*]} lms_io_iqsel1}]
set_output_delay -clock [get_clocks LMS1_FCLK1] -min -0.2 [get_ports {{lms_diq1[*]} lms_io_iqsel1}]

set_output_delay -clock [get_clocks LMS1_FCLK1] -clock_fall -max -add_delay 1 [get_ports {{lms_diq1[*]} lms_io_iqsel1}]
set_output_delay -clock [get_clocks LMS1_FCLK1] -clock_fall -min -add_delay -0.2 [get_ports {{lms_diq1[*]} lms_io_iqsel1}]

#set_output_delay -clock [get_clocks LMS1_FCLK1] -max 3.800 [get_ports {LMS1_DIQ1_D[11]}]
#set_output_delay -clock [get_clocks LMS1_FCLK1] -min 2.000 [get_ports {LMS1_DIQ1_D[11]}]

#set_output_delay -clock [get_clocks LMS1_FCLK1] -clock_fall -max -add_delay 3.800 [get_ports {LMS1_DIQ1_D[11]}]
#set_output_delay -clock [get_clocks LMS1_FCLK1] -clock_fall -min -add_delay 2.000 [get_ports {LMS1_DIQ1_D[11]}]

set_false_path -to [get_ports LMS1_FCLK1]


##  Setup/Hold Case:
##  Setup and hold requirements for the destination device and board trace delays are known.
##
## forwarded                        _________________________________
## clock                 __________|                                 |______________
##                                 |                                 |
##                           tsu_r |  thd_r                    tsu_f | thd_f
##                         <------>|<------->                <------>|<----->
##                         ________|_________                ________|_______
## data @ destination   XXX__________________XXXXXXXXXXXXXXXX________________XXXXX
##
## Example of creating generated clock at clock output port
## create_generated_clock -name <gen_clock_name> -multiply_by 1 -source [get_pins <source_pin>] [get_ports <output_clock_port>]
## gen_clock_name is the name of forwarded clock here. It should be used below for defining "fwclk".	

#set fwclk        <clock-name>;     # forwarded clock name (generated using create_generated_clock at output clock port)        
#set tsu_r        0.000;            # destination device setup time requirement for rising edge
#set thd_r        0.000;            # destination device hold time requirement for rising edge
#set tsu_f        0.000;            # destination device setup time requirement for falling edge
#set thd_f        0.000;            # destination device hold time requirement for falling edge
#set trce_dly_max 0.000;            # maximum board trace delay
#set trce_dly_min 0.000;            # minimum board trace delay
#set output_ports <output_ports>;   # list of output ports

## Output Delay Constraints
#set_output_delay -clock $fwclk -max [expr $trce_dly_max + $tsu_r] [get_ports $output_ports];
#set_output_delay -clock $fwclk -min [expr $trce_dly_min - $thd_r] [get_ports $output_ports];
#set_output_delay -clock $fwclk -max [expr $trce_dly_max + $tsu_f] [get_ports $output_ports] -clock_fall -add_delay;
#set_output_delay -clock $fwclk -min [expr $trce_dly_min - $thd_f] [get_ports $output_ports] -clock_fall -add_delay;
