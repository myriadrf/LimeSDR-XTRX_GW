
################################################################
# This is a generated script based on design: cpu_design
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2022.1
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source cpu_design_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xc7a50tcpg236-2
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name cpu_design

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_gid_msg -ssname BD::TCL -id 2001 -severity "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_gid_msg -ssname BD::TCL -id 2002 -severity "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_gid_msg -ssname BD::TCL -id 2005 -severity "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_gid_msg -ssname BD::TCL -id 2006 -severity "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
xilinx.com:ip:axi_gpio:2.0\
xilinx.com:user:AXI_to_native_FIFO:1.0\
xilinx.com:ip:axi_amm_bridge:1.0\
xilinx.com:ip:axi_uartlite:2.0\
xilinx.com:ip:mdm:3.2\
xilinx.com:ip:microblaze:11.0\
xilinx.com:ip:axi_intc:4.1\
xilinx.com:ip:xlconcat:2.1\
xilinx.com:ip:proc_sys_reset:5.0\
xilinx.com:ip:axi_iic:2.1\
xilinx.com:ip:axi_quad_spi:3.2\
xilinx.com:ip:lmb_bram_if_cntlr:4.0\
xilinx.com:ip:lmb_v10:3.0\
xilinx.com:ip:blk_mem_gen:8.4\
"

   set list_ips_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

if { $bCheckIPsPassed != 1 } {
  common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################


# Hierarchical cell: microblaze_0_local_memory
proc create_hier_cell_microblaze_0_local_memory { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_microblaze_0_local_memory() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode MirroredMaster -vlnv xilinx.com:interface:lmb_rtl:1.0 DLMB

  create_bd_intf_pin -mode MirroredMaster -vlnv xilinx.com:interface:lmb_rtl:1.0 ILMB


  # Create pins
  create_bd_pin -dir I -type clk Clk
  create_bd_pin -dir I -type rst SYS_Rst

  # Create instance: dlmb_bram_if_cntlr, and set properties
  set dlmb_bram_if_cntlr [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr:4.0 dlmb_bram_if_cntlr ]
  set_property -dict [ list \
   CONFIG.C_ECC {0} \
 ] $dlmb_bram_if_cntlr

  # Create instance: dlmb_v10, and set properties
  set dlmb_v10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10:3.0 dlmb_v10 ]

  # Create instance: ilmb_bram_if_cntlr, and set properties
  set ilmb_bram_if_cntlr [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr:4.0 ilmb_bram_if_cntlr ]
  set_property -dict [ list \
   CONFIG.C_ECC {0} \
 ] $ilmb_bram_if_cntlr

  # Create instance: ilmb_v10, and set properties
  set ilmb_v10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10:3.0 ilmb_v10 ]

  # Create instance: lmb_bram, and set properties
  set lmb_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 lmb_bram ]
  set_property -dict [ list \
   CONFIG.Enable_B {Use_ENB_Pin} \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
   CONFIG.Port_B_Clock {100} \
   CONFIG.Port_B_Enable_Rate {100} \
   CONFIG.Port_B_Write_Rate {50} \
   CONFIG.Use_RSTB_Pin {true} \
   CONFIG.use_bram_block {BRAM_Controller} \
 ] $lmb_bram

  # Create interface connections
  connect_bd_intf_net -intf_net microblaze_0_dlmb [get_bd_intf_pins DLMB] [get_bd_intf_pins dlmb_v10/LMB_M]
  connect_bd_intf_net -intf_net microblaze_0_dlmb_bus [get_bd_intf_pins dlmb_bram_if_cntlr/SLMB] [get_bd_intf_pins dlmb_v10/LMB_Sl_0]
  connect_bd_intf_net -intf_net microblaze_0_dlmb_cntlr [get_bd_intf_pins dlmb_bram_if_cntlr/BRAM_PORT] [get_bd_intf_pins lmb_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net microblaze_0_ilmb [get_bd_intf_pins ILMB] [get_bd_intf_pins ilmb_v10/LMB_M]
  connect_bd_intf_net -intf_net microblaze_0_ilmb_bus [get_bd_intf_pins ilmb_bram_if_cntlr/SLMB] [get_bd_intf_pins ilmb_v10/LMB_Sl_0]
  connect_bd_intf_net -intf_net microblaze_0_ilmb_cntlr [get_bd_intf_pins ilmb_bram_if_cntlr/BRAM_PORT] [get_bd_intf_pins lmb_bram/BRAM_PORTB]

  # Create port connections
  connect_bd_net -net SYS_Rst_1 [get_bd_pins SYS_Rst] [get_bd_pins dlmb_bram_if_cntlr/LMB_Rst] [get_bd_pins dlmb_v10/SYS_Rst] [get_bd_pins ilmb_bram_if_cntlr/LMB_Rst] [get_bd_pins ilmb_v10/SYS_Rst]
  connect_bd_net -net microblaze_0_Clk [get_bd_pins Clk] [get_bd_pins dlmb_bram_if_cntlr/LMB_Clk] [get_bd_pins dlmb_v10/LMB_Clk] [get_bd_pins ilmb_bram_if_cntlr/LMB_Clk] [get_bd_pins ilmb_v10/LMB_Clk]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: SPI_CORES
proc create_hier_cell_SPI_CORES { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_SPI_CORES() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 AXI_LITE

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 AXI_LITE1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:spi_rtl:1.0 FPGA_CFG_QSPI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:spi_rtl:1.0 spi_0


  # Create pins
  create_bd_pin -dir I -type clk Clk
  create_bd_pin -dir I -type rst extm_axi_resetn_out
  create_bd_pin -dir O -type intr ip2intc_irpt

  # Create instance: SPI0, and set properties
  set SPI0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_quad_spi:3.2 SPI0 ]
  set_property -dict [ list \
   CONFIG.C_FIFO_DEPTH {16} \
   CONFIG.C_NUM_SS_BITS {2} \
   CONFIG.C_SCK_RATIO {16} \
   CONFIG.C_TYPE_OF_AXI4_INTERFACE {0} \
   CONFIG.C_USE_STARTUP {0} \
   CONFIG.C_USE_STARTUP_INT {0} \
   CONFIG.FIFO_INCLUDED {1} \
   CONFIG.Multiples16 {1} \
 ] $SPI0

  # Create instance: SPI1_FLASH, and set properties
  set SPI1_FLASH [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_quad_spi:3.2 SPI1_FLASH ]
  set_property -dict [ list \
   CONFIG.C_FIFO_DEPTH {256} \
   CONFIG.C_SCK_RATIO {16} \
   CONFIG.C_SPI_MEMORY {4} \
   CONFIG.C_SPI_MODE {0} \
   CONFIG.C_USE_STARTUP {1} \
   CONFIG.C_USE_STARTUP_INT {1} \
 ] $SPI1_FLASH

  # Create interface connections
  connect_bd_intf_net -intf_net ConfigurationFlashQSPI_SPI_0 [get_bd_intf_pins FPGA_CFG_QSPI] [get_bd_intf_pins SPI1_FLASH/SPI_0]
  connect_bd_intf_net -intf_net axi_quad_spi_0_SPI_0 [get_bd_intf_pins spi_0] [get_bd_intf_pins SPI0/SPI_0]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M02_AXI [get_bd_intf_pins AXI_LITE] [get_bd_intf_pins SPI0/AXI_LITE]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M07_AXI [get_bd_intf_pins AXI_LITE1] [get_bd_intf_pins SPI1_FLASH/AXI_LITE]

  # Create port connections
  connect_bd_net -net axi_quad_spi_0_ip2intc_irpt [get_bd_pins ip2intc_irpt] [get_bd_pins SPI0/ip2intc_irpt]
  connect_bd_net -net microblaze_0_Clk [get_bd_pins Clk] [get_bd_pins SPI0/ext_spi_clk] [get_bd_pins SPI0/s_axi_aclk] [get_bd_pins SPI1_FLASH/ext_spi_clk] [get_bd_pins SPI1_FLASH/s_axi_aclk]
  connect_bd_net -net rst_Clk_100M_peripheral_aresetn [get_bd_pins extm_axi_resetn_out] [get_bd_pins SPI0/s_axi_aresetn] [get_bd_pins SPI1_FLASH/s_axi_aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: SMPL_CMP_GPIO
proc create_hier_cell_SMPL_CMP_GPIO { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_SMPL_CMP_GPIO() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 smpl_cmp_en

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 smpl_cmp_status


  # Create pins
  create_bd_pin -dir I -type clk Clk
  create_bd_pin -dir I -type rst extm_axi_resetn_out

  # Create instance: smpl_cmp_cmd, and set properties
  set smpl_cmp_cmd [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 smpl_cmp_cmd ]
  set_property -dict [ list \
   CONFIG.C_ALL_OUTPUTS {1} \
   CONFIG.C_ALL_OUTPUTS_2 {0} \
   CONFIG.C_GPIO2_WIDTH {32} \
   CONFIG.C_GPIO_WIDTH {1} \
   CONFIG.C_IS_DUAL {0} \
 ] $smpl_cmp_cmd

  # Create instance: smpl_cmp_stat, and set properties
  set smpl_cmp_stat [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 smpl_cmp_stat ]
  set_property -dict [ list \
   CONFIG.C_ALL_INPUTS {1} \
   CONFIG.C_ALL_OUTPUTS_2 {0} \
   CONFIG.C_GPIO2_WIDTH {32} \
   CONFIG.C_GPIO_WIDTH {2} \
   CONFIG.C_IS_DUAL {0} \
 ] $smpl_cmp_stat

  # Create interface connections
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M14_AXI [get_bd_intf_pins S_AXI] [get_bd_intf_pins smpl_cmp_cmd/S_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M15_AXI [get_bd_intf_pins S_AXI1] [get_bd_intf_pins smpl_cmp_stat/S_AXI]
  connect_bd_intf_net -intf_net smpl_cmp_cmd_GPIO [get_bd_intf_pins smpl_cmp_en] [get_bd_intf_pins smpl_cmp_cmd/GPIO]
  connect_bd_intf_net -intf_net smpl_cmp_stat_GPIO [get_bd_intf_pins smpl_cmp_status] [get_bd_intf_pins smpl_cmp_stat/GPIO]

  # Create port connections
  connect_bd_net -net microblaze_0_Clk [get_bd_pins Clk] [get_bd_pins smpl_cmp_cmd/s_axi_aclk] [get_bd_pins smpl_cmp_stat/s_axi_aclk]
  connect_bd_net -net rst_Clk_100M_peripheral_aresetn [get_bd_pins extm_axi_resetn_out] [get_bd_pins smpl_cmp_cmd/s_axi_aresetn] [get_bd_pins smpl_cmp_stat/s_axi_aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: PLL_GPIO
proc create_hier_cell_PLL_GPIO { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_PLL_GPIO() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI2

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI3

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI4

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 extm_0_axi_sel

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 pll_locked

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 pll_rst

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 pllcfg_cmd

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 pllcfg_stat


  # Create pins
  create_bd_pin -dir I -type clk Clk
  create_bd_pin -dir I -type rst extm_axi_resetn_out

  # Create instance: PLLCFG_Command, and set properties
  set PLLCFG_Command [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 PLLCFG_Command ]
  set_property -dict [ list \
   CONFIG.C_ALL_INPUTS {1} \
   CONFIG.C_GPIO_WIDTH {4} \
 ] $PLLCFG_Command

  # Create instance: PLLCFG_Status, and set properties
  set PLLCFG_Status [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 PLLCFG_Status ]
  set_property -dict [ list \
   CONFIG.C_ALL_OUTPUTS {1} \
   CONFIG.C_GPIO_WIDTH {12} \
 ] $PLLCFG_Status

  # Create instance: PLL_LOCKED, and set properties
  set PLL_LOCKED [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 PLL_LOCKED ]
  set_property -dict [ list \
   CONFIG.C_ALL_INPUTS {1} \
   CONFIG.C_GPIO_WIDTH {1} \
 ] $PLL_LOCKED

  # Create instance: PLL_RST, and set properties
  set PLL_RST [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 PLL_RST ]
  set_property -dict [ list \
   CONFIG.C_ALL_OUTPUTS {1} \
   CONFIG.C_GPIO_WIDTH {2} \
 ] $PLL_RST

  # Create instance: PLL_SEL, and set properties
  set PLL_SEL [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 PLL_SEL ]
  set_property -dict [ list \
   CONFIG.C_ALL_OUTPUTS {1} \
   CONFIG.C_GPIO_WIDTH {4} \
 ] $PLL_SEL

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins pll_locked] [get_bd_intf_pins PLL_LOCKED/GPIO]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins S_AXI4] [get_bd_intf_pins PLL_LOCKED/S_AXI]
  connect_bd_intf_net -intf_net PLLCFG_Command_GPIO [get_bd_intf_pins pllcfg_cmd] [get_bd_intf_pins PLLCFG_Command/GPIO]
  connect_bd_intf_net -intf_net PLLCFG_Status_GPIO [get_bd_intf_pins pllcfg_stat] [get_bd_intf_pins PLLCFG_Status/GPIO]
  connect_bd_intf_net -intf_net PLL_RST_GPIO [get_bd_intf_pins pll_rst] [get_bd_intf_pins PLL_RST/GPIO]
  connect_bd_intf_net -intf_net axi_gpio_1_GPIO [get_bd_intf_pins extm_0_axi_sel] [get_bd_intf_pins PLL_SEL/GPIO]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M06_AXI [get_bd_intf_pins S_AXI] [get_bd_intf_pins PLLCFG_Status/S_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M09_AXI [get_bd_intf_pins S_AXI3] [get_bd_intf_pins PLLCFG_Command/S_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M10_AXI [get_bd_intf_pins S_AXI2] [get_bd_intf_pins PLL_RST/S_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M13_AXI [get_bd_intf_pins S_AXI1] [get_bd_intf_pins PLL_SEL/S_AXI]

  # Create port connections
  connect_bd_net -net microblaze_0_Clk [get_bd_pins Clk] [get_bd_pins PLLCFG_Command/s_axi_aclk] [get_bd_pins PLLCFG_Status/s_axi_aclk] [get_bd_pins PLL_LOCKED/s_axi_aclk] [get_bd_pins PLL_RST/s_axi_aclk] [get_bd_pins PLL_SEL/s_axi_aclk]
  connect_bd_net -net rst_Clk_100M_peripheral_aresetn [get_bd_pins extm_axi_resetn_out] [get_bd_pins PLLCFG_Command/s_axi_aresetn] [get_bd_pins PLLCFG_Status/s_axi_aresetn] [get_bd_pins PLL_LOCKED/s_axi_aresetn] [get_bd_pins PLL_RST/s_axi_aresetn] [get_bd_pins PLL_SEL/s_axi_aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: I2C_CORES
proc create_hier_cell_I2C_CORES { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_I2C_CORES() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 IIC_1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 iic_0


  # Create pins
  create_bd_pin -dir I -type clk Clk
  create_bd_pin -dir I -type rst extm_axi_resetn_out
  create_bd_pin -dir O -type intr iic2intc_irpt
  create_bd_pin -dir O -type intr iic2intc_irpt1

  # Create instance: I2C1, and set properties
  set I2C1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_iic:2.1 I2C1 ]

  # Create instance: I2C2, and set properties
  set I2C2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_iic:2.1 I2C2 ]

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins IIC_1] [get_bd_intf_pins I2C2/IIC]
  connect_bd_intf_net -intf_net axi_iic_0_IIC [get_bd_intf_pins iic_0] [get_bd_intf_pins I2C1/IIC]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M01_AXI [get_bd_intf_pins S_AXI1] [get_bd_intf_pins I2C1/S_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M17_AXI [get_bd_intf_pins S_AXI] [get_bd_intf_pins I2C2/S_AXI]

  # Create port connections
  connect_bd_net -net I2C2_iic2intc_irpt [get_bd_pins iic2intc_irpt] [get_bd_pins I2C2/iic2intc_irpt]
  connect_bd_net -net axi_iic_0_iic2intc_irpt [get_bd_pins iic2intc_irpt1] [get_bd_pins I2C1/iic2intc_irpt]
  connect_bd_net -net microblaze_0_Clk [get_bd_pins Clk] [get_bd_pins I2C1/s_axi_aclk] [get_bd_pins I2C2/s_axi_aclk]
  connect_bd_net -net rst_Clk_100M_peripheral_aresetn [get_bd_pins extm_axi_resetn_out] [get_bd_pins I2C1/s_axi_aresetn] [get_bd_pins I2C2/s_axi_aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}


# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set FPGA_CFG_QSPI [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:spi_rtl:1.0 FPGA_CFG_QSPI ]

  set I2C_1 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 I2C_1 ]

  set I2C_2 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 I2C_2 ]

  set avmm_m0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:avalon_rtl:1.0 avmm_m0 ]

  set extm_0_axi [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 extm_0_axi ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {32} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.HAS_BURST {0} \
   CONFIG.HAS_CACHE {0} \
   CONFIG.HAS_LOCK {0} \
   CONFIG.HAS_QOS {0} \
   CONFIG.HAS_REGION {0} \
   CONFIG.PROTOCOL {AXI4LITE} \
   ] $extm_0_axi

  set extm_0_axi_sel [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 extm_0_axi_sel ]

  set fifo_read_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:fifo_read_rtl:1.0 fifo_read_0 ]

  set fifo_write_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:fifo_write_rtl:1.0 fifo_write_0 ]

  set gpio_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 gpio_0 ]

  set gpio_1 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 gpio_1 ]

  set pll_locked [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 pll_locked ]

  set pll_rst [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 pll_rst ]

  set pllcfg_cmd [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 pllcfg_cmd ]

  set pllcfg_stat [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 pllcfg_stat ]

  set smpl_cmp_en [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 smpl_cmp_en ]

  set smpl_cmp_status [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 smpl_cmp_status ]

  set spi_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:spi_rtl:1.0 spi_0 ]

  set uart_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 uart_0 ]

  set vctcxo_tamer_0_ctrl [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 vctcxo_tamer_0_ctrl ]

  set xtrx_ctrl_gpio [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 xtrx_ctrl_gpio ]


  # Create ports
  set Clk [ create_bd_port -dir I -type clk -freq_hz 100000000 Clk ]
  set extm_axi_resetn_out [ create_bd_port -dir O -from 0 -to 0 -type rst extm_axi_resetn_out ]
  set fifo_write_0_aclr [ create_bd_port -dir O -type rst fifo_write_0_aclr ]
  set reset_n [ create_bd_port -dir I -type rst reset_n ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_LOW} \
 ] $reset_n

  # Create instance: ADC_reset_gpio, and set properties
  set ADC_reset_gpio [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 ADC_reset_gpio ]
  set_property -dict [ list \
   CONFIG.C_ALL_INPUTS {1} \
   CONFIG.C_ALL_OUTPUTS_2 {1} \
   CONFIG.C_GPIO2_WIDTH {8} \
   CONFIG.C_GPIO_WIDTH {8} \
   CONFIG.C_IS_DUAL {1} \
 ] $ADC_reset_gpio

  # Create instance: AXI_to_native_FIFO_0, and set properties
  set AXI_to_native_FIFO_0 [ create_bd_cell -type ip -vlnv xilinx.com:user:AXI_to_native_FIFO:1.0 AXI_to_native_FIFO_0 ]

  # Create instance: I2C_CORES
  create_hier_cell_I2C_CORES [current_bd_instance .] I2C_CORES

  # Create instance: PLL_GPIO
  create_hier_cell_PLL_GPIO [current_bd_instance .] PLL_GPIO

  # Create instance: SMPL_CMP_GPIO
  create_hier_cell_SMPL_CMP_GPIO [current_bd_instance .] SMPL_CMP_GPIO

  # Create instance: SPI_CORES
  create_hier_cell_SPI_CORES [current_bd_instance .] SPI_CORES

  # Create instance: XTRX_CTRL_GPIO, and set properties
  set XTRX_CTRL_GPIO [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 XTRX_CTRL_GPIO ]
  set_property -dict [ list \
   CONFIG.C_ALL_OUTPUTS {1} \
   CONFIG.C_DOUT_DEFAULT {0x00000002} \
   CONFIG.C_GPIO_WIDTH {4} \
 ] $XTRX_CTRL_GPIO

  # Create instance: axi_amm_bridge_0, and set properties
  set axi_amm_bridge_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_amm_bridge:1.0 axi_amm_bridge_0 ]
  set_property -dict [ list \
   CONFIG.C_ADDRESS_MODE {0} \
   CONFIG.C_AVM_BURST_WIDTH {1} \
   CONFIG.C_BURST_SUPPORT {0} \
   CONFIG.C_HAS_RESPONSE {0} \
   CONFIG.C_PROTOCOL {0} \
   CONFIG.C_S_AXI_ADDR_WIDTH {32} \
   CONFIG.C_USE_BYTEENABLE {0} \
 ] $axi_amm_bridge_0

  # Create instance: axi_uartlite_0, and set properties
  set axi_uartlite_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uartlite:2.0 axi_uartlite_0 ]

  # Create instance: mdm_1, and set properties
  set mdm_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:mdm:3.2 mdm_1 ]

  # Create instance: microblaze_0, and set properties
  set microblaze_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze:11.0 microblaze_0 ]
  set_property -dict [ list \
   CONFIG.C_ADDR_TAG_BITS {0} \
   CONFIG.C_AREA_OPTIMIZED {1} \
   CONFIG.C_DCACHE_ADDR_TAG {0} \
   CONFIG.C_DCACHE_ALWAYS_USED {1} \
   CONFIG.C_DEBUG_ENABLED {1} \
   CONFIG.C_D_AXI {1} \
   CONFIG.C_D_LMB {1} \
   CONFIG.C_ICACHE_ALWAYS_USED {1} \
   CONFIG.C_I_LMB {1} \
 ] $microblaze_0

  # Create instance: microblaze_0_axi_intc, and set properties
  set microblaze_0_axi_intc [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc:4.1 microblaze_0_axi_intc ]
  set_property -dict [ list \
   CONFIG.C_HAS_FAST {1} \
 ] $microblaze_0_axi_intc

  # Create instance: microblaze_0_axi_periph, and set properties
  set microblaze_0_axi_periph [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 microblaze_0_axi_periph ]
  set_property -dict [ list \
   CONFIG.NUM_MI {19} \
 ] $microblaze_0_axi_periph

  # Create instance: microblaze_0_local_memory
  create_hier_cell_microblaze_0_local_memory [current_bd_instance .] microblaze_0_local_memory

  # Create instance: microblaze_0_xlconcat, and set properties
  set microblaze_0_xlconcat [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 microblaze_0_xlconcat ]
  set_property -dict [ list \
   CONFIG.NUM_PORTS {4} \
 ] $microblaze_0_xlconcat

  # Create instance: rst_Clk_100M, and set properties
  set rst_Clk_100M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_Clk_100M ]

  # Create instance: vctcxo_tamer_ctrl, and set properties
  set vctcxo_tamer_ctrl [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 vctcxo_tamer_ctrl ]
  set_property -dict [ list \
   CONFIG.C_ALL_INPUTS {1} \
   CONFIG.C_GPIO_WIDTH {4} \
 ] $vctcxo_tamer_ctrl

  # Create interface connections
  connect_bd_intf_net -intf_net AXI_to_native_FIFO_0_M00_NATIVE_READ [get_bd_intf_ports fifo_read_0] [get_bd_intf_pins AXI_to_native_FIFO_0/M00_NATIVE_READ]
  connect_bd_intf_net -intf_net AXI_to_native_FIFO_0_M00_NATIVE_WRITE [get_bd_intf_ports fifo_write_0] [get_bd_intf_pins AXI_to_native_FIFO_0/M00_NATIVE_WRITE]
  connect_bd_intf_net -intf_net ConfigurationFlashQSPI_SPI_0 [get_bd_intf_ports FPGA_CFG_QSPI] [get_bd_intf_pins SPI_CORES/FPGA_CFG_QSPI]
  connect_bd_intf_net -intf_net I2C_CORES_IIC_1 [get_bd_intf_ports I2C_2] [get_bd_intf_pins I2C_CORES/IIC_1]
  connect_bd_intf_net -intf_net PLLCFG_Command_GPIO [get_bd_intf_ports pllcfg_cmd] [get_bd_intf_pins PLL_GPIO/pllcfg_cmd]
  connect_bd_intf_net -intf_net PLLCFG_Status_GPIO [get_bd_intf_ports pllcfg_stat] [get_bd_intf_pins PLL_GPIO/pllcfg_stat]
  connect_bd_intf_net -intf_net PLL_RST_GPIO [get_bd_intf_ports pll_rst] [get_bd_intf_pins PLL_GPIO/pll_rst]
  connect_bd_intf_net -intf_net XTRX_CTRL_GPIO_GPIO [get_bd_intf_ports xtrx_ctrl_gpio] [get_bd_intf_pins XTRX_CTRL_GPIO/GPIO]
  connect_bd_intf_net -intf_net axi_amm_bridge_0_M_AVALON [get_bd_intf_ports avmm_m0] [get_bd_intf_pins axi_amm_bridge_0/M_AVALON]
  connect_bd_intf_net -intf_net axi_gpio_0_GPIO [get_bd_intf_ports gpio_0] [get_bd_intf_pins ADC_reset_gpio/GPIO]
  connect_bd_intf_net -intf_net axi_gpio_0_GPIO2 [get_bd_intf_ports gpio_1] [get_bd_intf_pins ADC_reset_gpio/GPIO2]
  connect_bd_intf_net -intf_net axi_gpio_1_GPIO [get_bd_intf_ports extm_0_axi_sel] [get_bd_intf_pins PLL_GPIO/extm_0_axi_sel]
  connect_bd_intf_net -intf_net axi_iic_0_IIC [get_bd_intf_ports I2C_1] [get_bd_intf_pins I2C_CORES/iic_0]
  connect_bd_intf_net -intf_net axi_quad_spi_0_SPI_0 [get_bd_intf_ports spi_0] [get_bd_intf_pins SPI_CORES/spi_0]
  connect_bd_intf_net -intf_net axi_uartlite_0_UART [get_bd_intf_ports uart_0] [get_bd_intf_pins axi_uartlite_0/UART]
  connect_bd_intf_net -intf_net microblaze_0_axi_dp [get_bd_intf_pins microblaze_0/M_AXI_DP] [get_bd_intf_pins microblaze_0_axi_periph/S00_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M01_AXI [get_bd_intf_pins I2C_CORES/S_AXI1] [get_bd_intf_pins microblaze_0_axi_periph/M01_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M02_AXI [get_bd_intf_pins SPI_CORES/AXI_LITE] [get_bd_intf_pins microblaze_0_axi_periph/M02_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M03_AXI [get_bd_intf_pins ADC_reset_gpio/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M03_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M04_AXI [get_bd_intf_pins AXI_to_native_FIFO_0/S00_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M04_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M05_AXI [get_bd_intf_pins axi_uartlite_0/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M05_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M06_AXI [get_bd_intf_pins PLL_GPIO/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M06_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M07_AXI [get_bd_intf_pins SPI_CORES/AXI_LITE1] [get_bd_intf_pins microblaze_0_axi_periph/M07_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M08_AXI [get_bd_intf_pins microblaze_0_axi_periph/M08_AXI] [get_bd_intf_pins vctcxo_tamer_ctrl/S_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M09_AXI [get_bd_intf_pins PLL_GPIO/S_AXI3] [get_bd_intf_pins microblaze_0_axi_periph/M09_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M10_AXI [get_bd_intf_pins PLL_GPIO/S_AXI2] [get_bd_intf_pins microblaze_0_axi_periph/M10_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M11_AXI [get_bd_intf_pins axi_amm_bridge_0/S_AXI_LITE] [get_bd_intf_pins microblaze_0_axi_periph/M11_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M12_AXI [get_bd_intf_ports extm_0_axi] [get_bd_intf_pins microblaze_0_axi_periph/M12_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M13_AXI [get_bd_intf_pins PLL_GPIO/S_AXI1] [get_bd_intf_pins microblaze_0_axi_periph/M13_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M14_AXI [get_bd_intf_pins SMPL_CMP_GPIO/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M14_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M15_AXI [get_bd_intf_pins SMPL_CMP_GPIO/S_AXI1] [get_bd_intf_pins microblaze_0_axi_periph/M15_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M16_AXI [get_bd_intf_pins PLL_GPIO/S_AXI4] [get_bd_intf_pins microblaze_0_axi_periph/M16_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M17_AXI [get_bd_intf_pins I2C_CORES/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M17_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M18_AXI [get_bd_intf_pins XTRX_CTRL_GPIO/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M18_AXI]
  connect_bd_intf_net -intf_net microblaze_0_debug [get_bd_intf_pins mdm_1/MBDEBUG_0] [get_bd_intf_pins microblaze_0/DEBUG]
  connect_bd_intf_net -intf_net microblaze_0_dlmb_1 [get_bd_intf_pins microblaze_0/DLMB] [get_bd_intf_pins microblaze_0_local_memory/DLMB]
  connect_bd_intf_net -intf_net microblaze_0_ilmb_1 [get_bd_intf_pins microblaze_0/ILMB] [get_bd_intf_pins microblaze_0_local_memory/ILMB]
  connect_bd_intf_net -intf_net microblaze_0_intc_axi [get_bd_intf_pins microblaze_0_axi_intc/s_axi] [get_bd_intf_pins microblaze_0_axi_periph/M00_AXI]
  connect_bd_intf_net -intf_net microblaze_0_interrupt [get_bd_intf_pins microblaze_0/INTERRUPT] [get_bd_intf_pins microblaze_0_axi_intc/interrupt]
  connect_bd_intf_net -intf_net pll_locked [get_bd_intf_ports pll_locked] [get_bd_intf_pins PLL_GPIO/pll_locked]
  connect_bd_intf_net -intf_net smpl_cmp_cmd_GPIO [get_bd_intf_ports smpl_cmp_en] [get_bd_intf_pins SMPL_CMP_GPIO/smpl_cmp_en]
  connect_bd_intf_net -intf_net smpl_cmp_stat_GPIO [get_bd_intf_ports smpl_cmp_status] [get_bd_intf_pins SMPL_CMP_GPIO/smpl_cmp_status]
  connect_bd_intf_net -intf_net vctcxo_tamer_ctrl_GPIO [get_bd_intf_ports vctcxo_tamer_0_ctrl] [get_bd_intf_pins vctcxo_tamer_ctrl/GPIO]

  # Create port connections
  connect_bd_net -net AXI_to_native_FIFO_0_M_NATIVE_WRITE_ACLR [get_bd_ports fifo_write_0_aclr] [get_bd_pins AXI_to_native_FIFO_0/M_NATIVE_WRITE_ACLR]
  connect_bd_net -net I2C2_iic2intc_irpt [get_bd_pins I2C_CORES/iic2intc_irpt] [get_bd_pins microblaze_0_xlconcat/In3]
  connect_bd_net -net axi_iic_0_iic2intc_irpt [get_bd_pins I2C_CORES/iic2intc_irpt1] [get_bd_pins microblaze_0_xlconcat/In0]
  connect_bd_net -net axi_quad_spi_0_ip2intc_irpt [get_bd_pins SPI_CORES/ip2intc_irpt] [get_bd_pins microblaze_0_xlconcat/In1]
  connect_bd_net -net axi_uartlite_0_interrupt [get_bd_pins axi_uartlite_0/interrupt] [get_bd_pins microblaze_0_xlconcat/In2]
  connect_bd_net -net mdm_1_debug_sys_rst [get_bd_pins mdm_1/Debug_SYS_Rst] [get_bd_pins rst_Clk_100M/mb_debug_sys_rst]
  connect_bd_net -net microblaze_0_Clk [get_bd_ports Clk] [get_bd_pins ADC_reset_gpio/s_axi_aclk] [get_bd_pins AXI_to_native_FIFO_0/s00_axi_aclk] [get_bd_pins I2C_CORES/Clk] [get_bd_pins PLL_GPIO/Clk] [get_bd_pins SMPL_CMP_GPIO/Clk] [get_bd_pins SPI_CORES/Clk] [get_bd_pins XTRX_CTRL_GPIO/s_axi_aclk] [get_bd_pins axi_amm_bridge_0/s_axi_aclk] [get_bd_pins axi_uartlite_0/s_axi_aclk] [get_bd_pins microblaze_0/Clk] [get_bd_pins microblaze_0_axi_intc/processor_clk] [get_bd_pins microblaze_0_axi_intc/s_axi_aclk] [get_bd_pins microblaze_0_axi_periph/ACLK] [get_bd_pins microblaze_0_axi_periph/M00_ACLK] [get_bd_pins microblaze_0_axi_periph/M01_ACLK] [get_bd_pins microblaze_0_axi_periph/M02_ACLK] [get_bd_pins microblaze_0_axi_periph/M03_ACLK] [get_bd_pins microblaze_0_axi_periph/M04_ACLK] [get_bd_pins microblaze_0_axi_periph/M05_ACLK] [get_bd_pins microblaze_0_axi_periph/M06_ACLK] [get_bd_pins microblaze_0_axi_periph/M07_ACLK] [get_bd_pins microblaze_0_axi_periph/M08_ACLK] [get_bd_pins microblaze_0_axi_periph/M09_ACLK] [get_bd_pins microblaze_0_axi_periph/M10_ACLK] [get_bd_pins microblaze_0_axi_periph/M11_ACLK] [get_bd_pins microblaze_0_axi_periph/M12_ACLK] [get_bd_pins microblaze_0_axi_periph/M13_ACLK] [get_bd_pins microblaze_0_axi_periph/M14_ACLK] [get_bd_pins microblaze_0_axi_periph/M15_ACLK] [get_bd_pins microblaze_0_axi_periph/M16_ACLK] [get_bd_pins microblaze_0_axi_periph/M17_ACLK] [get_bd_pins microblaze_0_axi_periph/M18_ACLK] [get_bd_pins microblaze_0_axi_periph/S00_ACLK] [get_bd_pins microblaze_0_local_memory/Clk] [get_bd_pins rst_Clk_100M/slowest_sync_clk] [get_bd_pins vctcxo_tamer_ctrl/s_axi_aclk]
  connect_bd_net -net microblaze_0_intr [get_bd_pins microblaze_0_axi_intc/intr] [get_bd_pins microblaze_0_xlconcat/dout]
  connect_bd_net -net reset_rtl_0_1 [get_bd_ports reset_n] [get_bd_pins rst_Clk_100M/ext_reset_in]
  connect_bd_net -net rst_Clk_100M_bus_struct_reset [get_bd_pins microblaze_0_local_memory/SYS_Rst] [get_bd_pins rst_Clk_100M/bus_struct_reset]
  connect_bd_net -net rst_Clk_100M_mb_reset [get_bd_pins microblaze_0/Reset] [get_bd_pins microblaze_0_axi_intc/processor_rst] [get_bd_pins rst_Clk_100M/mb_reset]
  connect_bd_net -net rst_Clk_100M_peripheral_aresetn [get_bd_ports extm_axi_resetn_out] [get_bd_pins ADC_reset_gpio/s_axi_aresetn] [get_bd_pins AXI_to_native_FIFO_0/s00_axi_aresetn] [get_bd_pins I2C_CORES/extm_axi_resetn_out] [get_bd_pins PLL_GPIO/extm_axi_resetn_out] [get_bd_pins SMPL_CMP_GPIO/extm_axi_resetn_out] [get_bd_pins SPI_CORES/extm_axi_resetn_out] [get_bd_pins XTRX_CTRL_GPIO/s_axi_aresetn] [get_bd_pins axi_amm_bridge_0/s_axi_aresetn] [get_bd_pins axi_uartlite_0/s_axi_aresetn] [get_bd_pins microblaze_0_axi_intc/s_axi_aresetn] [get_bd_pins microblaze_0_axi_periph/ARESETN] [get_bd_pins microblaze_0_axi_periph/M00_ARESETN] [get_bd_pins microblaze_0_axi_periph/M01_ARESETN] [get_bd_pins microblaze_0_axi_periph/M02_ARESETN] [get_bd_pins microblaze_0_axi_periph/M03_ARESETN] [get_bd_pins microblaze_0_axi_periph/M04_ARESETN] [get_bd_pins microblaze_0_axi_periph/M05_ARESETN] [get_bd_pins microblaze_0_axi_periph/M06_ARESETN] [get_bd_pins microblaze_0_axi_periph/M07_ARESETN] [get_bd_pins microblaze_0_axi_periph/M08_ARESETN] [get_bd_pins microblaze_0_axi_periph/M09_ARESETN] [get_bd_pins microblaze_0_axi_periph/M10_ARESETN] [get_bd_pins microblaze_0_axi_periph/M11_ARESETN] [get_bd_pins microblaze_0_axi_periph/M12_ARESETN] [get_bd_pins microblaze_0_axi_periph/M13_ARESETN] [get_bd_pins microblaze_0_axi_periph/M14_ARESETN] [get_bd_pins microblaze_0_axi_periph/M15_ARESETN] [get_bd_pins microblaze_0_axi_periph/M16_ARESETN] [get_bd_pins microblaze_0_axi_periph/M17_ARESETN] [get_bd_pins microblaze_0_axi_periph/M18_ARESETN] [get_bd_pins microblaze_0_axi_periph/S00_ARESETN] [get_bd_pins rst_Clk_100M/peripheral_aresetn] [get_bd_pins vctcxo_tamer_ctrl/s_axi_aresetn]

  # Create address segments
  assign_bd_address -offset 0x40000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs ADC_reset_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0x44A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs AXI_to_native_FIFO_0/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0x40800000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs I2C_CORES/I2C1/S_AXI/Reg] -force
  assign_bd_address -offset 0x40810000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs I2C_CORES/I2C2/S_AXI/Reg] -force
  assign_bd_address -offset 0x40010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs PLL_GPIO/PLLCFG_Command/S_AXI/Reg] -force
  assign_bd_address -offset 0x40020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs PLL_GPIO/PLLCFG_Status/S_AXI/Reg] -force
  assign_bd_address -offset 0x40070000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs PLL_GPIO/PLL_LOCKED/S_AXI/Reg] -force
  assign_bd_address -offset 0x40030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs PLL_GPIO/PLL_RST/S_AXI/Reg] -force
  assign_bd_address -offset 0x40040000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs PLL_GPIO/PLL_SEL/S_AXI/Reg] -force
  assign_bd_address -offset 0x44A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs SPI_CORES/SPI0/AXI_LITE/Reg] -force
  assign_bd_address -offset 0x44A20000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs SPI_CORES/SPI1_FLASH/AXI_LITE/Reg] -force
  assign_bd_address -offset 0x40090000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs XTRX_CTRL_GPIO/S_AXI/Reg] -force
  assign_bd_address -offset 0x44A30000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs avmm_m0/Reg] -force
  assign_bd_address -offset 0x40600000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs axi_uartlite_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x00008000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs microblaze_0_local_memory/dlmb_bram_if_cntlr/SLMB/Mem] -force
  assign_bd_address -offset 0x44A50000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs extm_0_axi/Reg] -force
  assign_bd_address -offset 0x41200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs microblaze_0_axi_intc/S_AXI/Reg] -force
  assign_bd_address -offset 0x40050000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs SMPL_CMP_GPIO/smpl_cmp_cmd/S_AXI/Reg] -force
  assign_bd_address -offset 0x40060000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs SMPL_CMP_GPIO/smpl_cmp_stat/S_AXI/Reg] -force
  assign_bd_address -offset 0x40080000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs vctcxo_tamer_ctrl/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x00008000 -target_address_space [get_bd_addr_spaces microblaze_0/Instruction] [get_bd_addr_segs microblaze_0_local_memory/ilmb_bram_if_cntlr/SLMB/Mem] -force


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


