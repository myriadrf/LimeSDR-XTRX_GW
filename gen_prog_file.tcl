# Set the reference directory to where the script is
set script_path [file dirname [file normalize [info script]]]
puts $script_path
set proj_name [get_property NAME [current_project]]

# Set output file path and name
set bit_path "[file normalize "$script_path/$proj_name/$proj_name.runs/impl_1/LimeSDR_XTRX_top.bit"]"
puts $bit_path


# this checks if the project name contains the string "gold"
if {[regexp "gold" $proj_name]} {
    #gold image address
    set bit_string "up 0x00000000 $bit_path "
    puts $bit_string
    set gold 1
    set name gold
} else {  
     #user image address
    # set bit_string "up 0x00220000 $bit_path "
    set bit_string "up 0x00000000 $bit_path "
    puts $bit_string
    set gold 0
    set name user
}

set path temp
unset path
append path "$script_path/bitstream/" $name "_flash_programming_file.bin"
write_cfgmem  -format bin -force -size 32 -interface SPIx4 -loadbit $bit_string -file "[file normalize $path]"
unset path
append path "$script_path/bitstream/" $name "_ram_programming_file.bit"
file copy -force $bit_path "[file normalize $path]"

# write_cfgmem  -format bin -force -size 32 -interface SPIx4 -loadbit $bit_string -file "[file normalize "$script_path/bitstream/flash_programming_file.bin"]"
# file copy -force $bit_path $script_path/bitstream/ram_programming_file.bit


if {$gold == 0} {
    source $script_path/update_readme.tcl
    source $script_path/update_rev.tcl
    source $script_path/gen_combi_prog_file.tcl
}

