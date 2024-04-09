
# Create Project

create_project -force -name litepcie_core -part xc7a
set_msg_config -id {Common 17-55} -new_severity {Warning}

# Add Sources

read_verilog {D:\work_dir\LimeSDR-XTRX\LimeSDR-XTRX_GW_M2\litepcie_gen\build\gateware\litepcie_core.v}

# Add EDIFs


# Add IPs


# Add constraints

read_xdc litepcie_core.xdc
set_property PROCESSING_ORDER EARLY [get_files litepcie_core.xdc]

# Add pre-synthesis commands

create_ip -vendor xilinx.com -name pcie_7x -module_name pcie_s7
set obj [get_ips pcie_s7]
set_property -dict [list \
CONFIG.Bar0_Scale {Megabytes} \
CONFIG.Bar0_Size {1} \
CONFIG.Buf_Opt_BMA {True} \
CONFIG.Component_Name {pcie} \
CONFIG.Device_ID {7022} \
CONFIG.IntX_Generation {False} \
CONFIG.Interface_Width {64_bit} \
CONFIG.Legacy_Interrupt {None} \
CONFIG.Multiple_Message_Capable {1_vector} \
CONFIG.Link_Speed {5.0_GT/s} \
CONFIG.MSI_64b {False} \
CONFIG.Max_Payload_Size {512_bytes} \
CONFIG.Maximum_Link_Width {X2} \
CONFIG.PCIe_Blk_Locn {X0Y0} \
CONFIG.Ref_Clk_Freq {100_MHz} \
CONFIG.Trans_Buf_Pipeline {None} \
CONFIG.Trgt_Link_Speed {4'h2} \
CONFIG.User_Clk_Freq {125} \
] $obj
synth_ip $obj

# Synthesis

synth_design -directive default -top litepcie_core -part xc7a

# Synthesis report

report_timing_summary -file litepcie_core_timing_synth.rpt
report_utilization -hierarchical -file litepcie_core_utilization_hierarchical_synth.rpt
report_utilization -file litepcie_core_utilization_synth.rpt

# Optimize design

opt_design -directive default

# Add pre-placement commands

reset_property LOC [get_cells -hierarchical -filter {NAME=~pcie_s7/*gtp_common.gtpe2_common_i}]
reset_property LOC [get_cells -hierarchical -filter {NAME=~pcie_s7/*genblk*.bram36_tdp_bl.bram36_tdp_bl}]

# Placement

place_design -directive default

# Placement report

report_utilization -hierarchical -file litepcie_core_utilization_hierarchical_place.rpt
report_utilization -file litepcie_core_utilization_place.rpt
report_io -file litepcie_core_io.rpt
report_control_sets -verbose -file litepcie_core_control_sets.rpt
report_clock_utilization -file litepcie_core_clock_utilization.rpt

# Add pre-routing commands


# Routing

route_design -directive default
phys_opt_design -directive default
write_checkpoint -force litepcie_core_route.dcp

# Routing report

report_timing_summary -no_header -no_detailed_paths
report_route_status -file litepcie_core_route_status.rpt
report_drc -file litepcie_core_drc.rpt
report_timing_summary -datasheet -max_paths 10 -file litepcie_core_timing.rpt
report_power -file litepcie_core_power.rpt

# Bitstream generation

write_bitstream -force litepcie_core.bit 

# End

quit