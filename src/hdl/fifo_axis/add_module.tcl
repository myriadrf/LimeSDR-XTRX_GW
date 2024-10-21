# #################################################################
# FILE:          add_module.tcl
# DESCRIPTION:   Script to add LimeIP-HDL module
# DATE:          15:06 2023-07-03
# AUTHOR(s):     Lime Microsystems
# REVISIONS:
#  2024-03-12 : Added additional code to specify VHDL version
# #################################################################

# #################################################################
# NOTES:
# This script adds files from file_list.tcl file to project. 
# 
# #################################################################

source [file join [file dirname [info script]] "file_list.tcl"]

puts "Sourcing SYNTH SRC"

if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

foreach file $SYNTH_SRC {
   puts $file
   add_files -fileset sources_1 $file
   set file [file normalize $file]
   set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
   set_property -name "file_type" -value "VHDL 2008" -objects $file_obj
}


puts "Sourcing SIM SRC"

if {[string equal [get_filesets -quiet sim_1] ""]} {
  create_fileset -srcset sim_1
}

foreach file $SIM_SRC {
   puts $file
   add_files -fileset sim_1 $file
   set file [file normalize $file]
   set file_obj [get_files -of_objects [get_filesets sim_1] [list "*$file"]]
   set_property -name "file_type" -value "VHDL 2008" -objects $file_obj
}

puts "Sourcing IP"
foreach file $IP {
   puts $file
   source [file join [file dirname [info script]] $file]
}

foreach file $DEP_FILES {
   puts $file
   add_files -fileset sources_1 $file
   set file [file normalize $file]
   set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
   set_property -name "file_type" -value "VHDL 2008" -objects $file_obj
}

puts "Dependencies"
foreach module $DEP_MODULES {
   puts $module
   source [file join [file dirname [info script]] "../$module/add_module.tcl"]
}

