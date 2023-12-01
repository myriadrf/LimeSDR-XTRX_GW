#set mpsoc_dev           [get_hw_devices xczu7_*]
#set mpsoc_probes_file   D:/work_dir/ZCU106/limemm-x8_gw/projects/LimeMM-X8/LimeMM-X8.runs/impl_1/top.ltx
#set mpsoc_program_file  D:/work_dir/ZCU106/limemm-x8_gw/projects/LimeMM-X8/LimeMM-X8.runs/impl_1/top.bit

set xtrx_dev_list       [get_hw_devices xc7a50t_*]
set xtrx_probes_file    D:/work_dir/LimeSDR-XTRX/limesdr-xtrx/projects/LimeSDR-XTRX-Aurora/LimeSDR-XTRX-Aurora.runs/impl_1/LimeSDR_XTRX_top.ltx
set xtrx_program_file   ./ram_programming_file.bit

#Program MPSoC
#set_property PROBES.FILE      $mpsoc_probes_file    [get_hw_devices $mpsoc_dev]
#set_property FULL_PROBES.FILE $mpsoc_probes_file    [get_hw_devices $mpsoc_dev]
#set_property PROGRAM.FILE     $mpsoc_program_file   [get_hw_devices $mpsoc_dev]

#program_hw_devices   [get_hw_devices $mpsoc_dev]
#refresh_hw_device    [lindex [get_hw_devices $mpsoc_dev] 0]


#Program XTRX devices
foreach xtrx_device $xtrx_dev_list {
   puts "Programming $xtrx_device" 
   set_property PROBES.FILE      $xtrx_probes_file    [get_hw_devices $xtrx_device]
   set_property FULL_PROBES.FILE $xtrx_probes_file    [get_hw_devices $xtrx_device]
   set_property PROGRAM.FILE     $xtrx_program_file   [get_hw_devices $xtrx_device]
   program_hw_devices [get_hw_devices $xtrx_device]
   refresh_hw_device    [lindex [get_hw_devices $xtrx_device] 0]
 }