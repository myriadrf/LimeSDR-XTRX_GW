# Set the reference directory to where the script is
set script_path [file dirname [file normalize [info script]]]
puts $script_path

# Set output file path and name
set golden_bit_path  "[file normalize "$script_path/bitstream/gold_ram_programming_file.bit"]"
set user_bit_path    "[file normalize "$script_path/bitstream/user_ram_programming_file.bit"]"

puts $golden_bit_path
puts $user_bit_path

set bit_string   "up 0x00000000 $golden_bit_path up 0x220000 $user_bit_path"

puts $bit_string

write_cfgmem  -format bin -force -size 4 -interface SPIx4 -loadbit $bit_string -file "[file normalize "$script_path/bitstream/combined_flash_programming_file.bin"]"

#source $script_path/update_readme.tcl
#source $script_path/update_rev.tcl