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
# source LimeSDR-XTRX-Aurora.tcl
# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./LimeSDR-XTRX-Aurora/LimeSDR-XTRX-Aurora.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
  create_project LimeSDR-XTRX-Aurora LimeSDR-XTRX-Aurora -part xc7a50tcpg236-2
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
# CREATE IP aurora_init_pll
##################################################################

set aurora_init_pll [create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 -module_name aurora_init_pll]

set_property -dict { 
  CONFIG.PRIMITIVE {PLL}
  CONFIG.USE_PHASE_ALIGNMENT {true}
  CONFIG.PRIM_IN_FREQ {26}
  CONFIG.SECONDARY_SOURCE {Single_ended_clock_capable_pin}
  CONFIG.CLKIN1_JITTER_PS {384.61}
  CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {124.8}
  CONFIG.PRIM_SOURCE {Single_ended_clock_capable_pin}
  CONFIG.CLKOUT1_DRIVES {BUFG}
  CONFIG.CLKOUT2_DRIVES {BUFG}
  CONFIG.CLKOUT3_DRIVES {BUFG}
  CONFIG.CLKOUT4_DRIVES {BUFG}
  CONFIG.CLKOUT5_DRIVES {BUFG}
  CONFIG.CLKOUT6_DRIVES {BUFG}
  CONFIG.CLKOUT7_DRIVES {BUFG}
  CONFIG.USE_RESET {true}
  CONFIG.MMCM_BANDWIDTH {OPTIMIZED}
  CONFIG.MMCM_CLKFBOUT_MULT_F {48}
  CONFIG.MMCM_CLKIN1_PERIOD {38.462}
  CONFIG.MMCM_CLKIN2_PERIOD {10.0}
  CONFIG.MMCM_COMPENSATION {ZHOLD}
  CONFIG.MMCM_CLKOUT0_DIVIDE_F {10}
  CONFIG.CLKOUT1_JITTER {174.637}
  CONFIG.CLKOUT1_PHASE_ERROR {210.700}
} [get_ips aurora_init_pll]

set_property -dict { 
  GENERATE_SYNTH_CHECKPOINT {1}
} $aurora_init_pll

##################################################################

