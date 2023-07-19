##################################################################
# CHECK VIVADO VERSION
##################################################################

set scripts_vivado_version 2022.1
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
  catch {common::send_msg_id "IPS_TCL-100" "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_ip_tcl to create an updated script."}
  return 1
}

##################################################################
# START
##################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source rx_pll.tcl
# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./LimeSDR-XTRX/LimeSDR-XTRX.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
  create_project LimeSDR-XTRX LimeSDR-XTRX -part xc7a50tcpg236-2
  set_property target_language Verilog [current_project]
  set_property simulator_language Mixed [current_project]
}

##################################################################
# CHECK IPs
##################################################################

set bCheckIPs 1
set bCheckIPsPassed 1
if { $bCheckIPs == 1 } {
  set list_check_ips { xilinx.com:ip:clk_wiz:6.0 }
  set list_ips_missing ""
  common::send_msg_id "IPS_TCL-1001" "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

  foreach ip_vlnv $list_check_ips {
  set ip_obj [get_ipdefs -all $ip_vlnv]
  if { $ip_obj eq "" } {
    lappend list_ips_missing $ip_vlnv
    }
  }

  if { $list_ips_missing ne "" } {
    catch {common::send_msg_id "IPS_TCL-105" "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
    set bCheckIPsPassed 0
  }
}

if { $bCheckIPsPassed != 1 } {
  common::send_msg_id "IPS_TCL-102" "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 1
}

##################################################################
# CREATE IP rx_pll
##################################################################

set rx_pll [create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 -module_name rx_pll]

set_property -dict { 
  CONFIG.ENABLE_CLOCK_MONITOR {false}
  CONFIG.PRIMITIVE {MMCM}
  CONFIG.USE_FREQ_SYNTH {true}
  CONFIG.USE_PHASE_ALIGNMENT {true}
  CONFIG.USE_DYN_PHASE_SHIFT {false}
  CONFIG.USE_DYN_RECONFIG {true}
  CONFIG.JITTER_SEL {Min_O_Jitter}
  CONFIG.PRIM_IN_FREQ {122.88}
  CONFIG.SECONDARY_SOURCE {Single_ended_clock_capable_pin}
  CONFIG.CLKIN1_JITTER_PS {81.38}
  CONFIG.CLKOUT2_USED {true}
  CONFIG.NUM_OUT_CLKS {2}
  CONFIG.CLK_OUT1_USE_FINE_PS_GUI {false}
  CONFIG.CLK_OUT2_USE_FINE_PS_GUI {false}
  CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {122.88}
  CONFIG.CLKOUT1_REQUESTED_PHASE {0}
  CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {122.88}
  CONFIG.CLKOUT2_REQUESTED_PHASE {0}
  CONFIG.CLKOUT3_REQUESTED_OUT_FREQ {122.88}
  CONFIG.CLKOUT4_REQUESTED_OUT_FREQ {122.88}
  CONFIG.CLKOUT5_REQUESTED_OUT_FREQ {122.88}
  CONFIG.CLKOUT6_REQUESTED_OUT_FREQ {122.88}
  CONFIG.CLKOUT7_REQUESTED_OUT_FREQ {122.88}
  CONFIG.PRIM_SOURCE {Global_buffer}
  CONFIG.CLKOUT1_DRIVES {BUFG}
  CONFIG.CLKOUT2_DRIVES {BUFG}
  CONFIG.CLKOUT3_DRIVES {BUFG}
  CONFIG.CLKOUT4_DRIVES {BUFG}
  CONFIG.CLKOUT5_DRIVES {BUFG}
  CONFIG.CLKOUT6_DRIVES {BUFG}
  CONFIG.CLKOUT7_DRIVES {BUFG}
  CONFIG.FEEDBACK_SOURCE {FDBK_AUTO}
  CONFIG.USE_INCLK_STOPPED {false}
  CONFIG.RESET_PORT {reset}
  CONFIG.OVERRIDE_MMCM {false}
  CONFIG.MMCM_DIVCLK_DIVIDE {1}
  CONFIG.MMCM_BANDWIDTH {HIGH}
  CONFIG.MMCM_CLKFBOUT_MULT_F {10.000}
  CONFIG.MMCM_CLKIN1_PERIOD {8.138}
  CONFIG.MMCM_CLKIN2_PERIOD {10.000}
  CONFIG.MMCM_COMPENSATION {ZHOLD}
  CONFIG.MMCM_CLKOUT0_DIVIDE_F {10.000}
  CONFIG.MMCM_CLKOUT0_PHASE {0.000}
  CONFIG.MMCM_CLKOUT0_USE_FINE_PS {false}
  CONFIG.MMCM_CLKOUT1_DIVIDE {10}
  CONFIG.MMCM_CLKOUT1_PHASE {0.000}
  CONFIG.MMCM_CLKOUT1_USE_FINE_PS {false}
  CONFIG.RESET_TYPE {ACTIVE_HIGH}
  CONFIG.CLKOUT1_JITTER {107.317}
  CONFIG.CLKOUT1_PHASE_ERROR {84.619}
  CONFIG.CLKOUT2_JITTER {107.317}
  CONFIG.CLKOUT2_PHASE_ERROR {84.619}
  CONFIG.INTERFACE_SELECTION {Enable_AXI}
  CONFIG.AXI_DRP {true}
  CONFIG.PHASE_DUTY_CONFIG {false}
} [get_ips rx_pll]

set_property -dict { 
  GENERATE_SYNTH_CHECKPOINT {1}
} $rx_pll

##################################################################

