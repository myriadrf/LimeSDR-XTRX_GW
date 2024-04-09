# Set the reference directory to where the script is
set script_path [file dirname [file normalize [info script]]]
puts $script_path

source $script_path/gen_prog_file_user.tcl
source $script_path/gen_prog_file_golden.tcl
source $script_path/gen_prog_file_combined.tcl

