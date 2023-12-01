set prog_file "./flash_programming_file.bin"
set xtrx_dev_list [get_hw_devices xc7a50t_*]

foreach xtrx_device $xtrx_dev_list {
   puts "Programming $xtrx_device" 

   current_hw_device [get_hw_devices $xtrx_device]
   refresh_hw_device [lindex [get_hw_devices $xtrx_device] 0]
   create_hw_cfgmem -hw_device [get_hw_devices $xtrx_device] -mem_dev [lindex [get_cfgmem_parts {mx25l25673g-spi-x1_x2_x4}] 0]
   
   set_property PROGRAM.ADDRESS_RANGE  {use_file} [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices $xtrx_device] 0]]
   set_property PROGRAM.FILES [list $prog_file ] [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices $xtrx_device] 0]]
   set_property PROGRAM.PRM_FILE {} [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices $xtrx_device] 0]]
   set_property PROGRAM.UNUSED_PIN_TERMINATION {pull-none} [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices $xtrx_device] 0]]
   set_property PROGRAM.BLANK_CHECK  0 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices $xtrx_device] 0]]
   set_property PROGRAM.ERASE  1 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices $xtrx_device] 0]]
   set_property PROGRAM.CFG_PROGRAM  1 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices $xtrx_device] 0]]
   set_property PROGRAM.VERIFY  1 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices $xtrx_device] 0]]
   set_property PROGRAM.CHECKSUM  0 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices $xtrx_device] 0]]
   
   startgroup
   create_hw_bitstream -hw_device [lindex [get_hw_devices $xtrx_device] 0] [get_property PROGRAM.HW_CFGMEM_BITFILE [ lindex [get_hw_devices $xtrx_device] 0]]; program_hw_devices [lindex [get_hw_devices $xtrx_device] 0]; refresh_hw_device [lindex [get_hw_devices $xtrx_device] 0];
   program_hw_cfgmem -hw_cfgmem [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices $xtrx_device] 0]]
   endgroup   
   
}


