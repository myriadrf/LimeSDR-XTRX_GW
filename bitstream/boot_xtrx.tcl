set xtrx_dev_list [get_hw_devices xc7a50t_*]

foreach xtrx_device $xtrx_dev_list {
   puts "Booting $xtrx_device" 
   
   boot_hw_device  [lindex [get_hw_devices $xtrx_device] 0]
   refresh_hw_device [lindex [get_hw_devices $xtrx_device] 0]  
   
}


