# #################################################################
# Project settings
# #################################################################

set PROJ_NAME     LimeSDR-XTRX-Aurora
set PROJ_FOLDER   projects/$PROJ_NAME
set PROJ_PART     xc7a50tcpg236-2

# Leave empty variable "" if default strategy is used
set SYNTH_STRAT   ""
set IMPL_STRAT    "Performance_ExtraTimingOpt"


# #################################################################
# HDL source files
# #################################################################

# HDL source directories
set HDL_DIRS { 
   src/hdl
}

# Separate HDL source files
set HDL_FILES {
   # ip/xilinx_usp_gen3_x4/pcie_usp_support.v
   # Litepcie_gen/build/gateware/litepcie_core.v
}

# LimeIP path
set LIME_IP_DIR src/limeip_hdl

# LimeIP Modules
set LIME_IP {
   gt_channel
}


# #################################################################
# Constraints
# #################################################################

set CONSTR_DIR src/constr

# #################################################################
# IP files
# #################################################################

set IP_TCL_DIRS {
   ip/tcl
}

set IP_XCI_FILES {
   # ip/xilinx_usp_gen3_x4/pcie_usp.xci
}

# #################################################################
# Microblaze Block design
# #################################################################

set IP_REPO_PATH ip/ip_repo

set BLOCK_DESIGN_FILE   ip/block_design/cpu_design.tcl
set BD_INSTANCE_NAME    cpu_design

set MB_ELF_FILE_DIR  src/mb_elf
set MB_ELF_FILE      cpu.elf
set MB_ELF_FILE_PATH [file join $MB_ELF_FILE_DIR $MB_ELF_FILE]


