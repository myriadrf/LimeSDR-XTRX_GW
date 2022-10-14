# ----------------------------------------------------------------------------
# FILE:          write_proj_script.tcl
# DESCRIPTION:   Project build script
# 
# DATE:          11:06 AM Tuesday, September 3, 2019
# AUTHOR(s):     Lime Microsystems
# REVISIONS:
# ----------------------------------------------------------------------------
#
# ----------------------------------------------------------------------------
# NOTES:
# ----------------------------------------------------------------------------


# Set the reference directory to where the script is
set script_path [file dirname [file normalize [info script]]]
puts $script_path

# Set output file path and name
set output_path "[file normalize "$script_path/LimeSDR-XTRX.tcl"]"
puts $output_path

# Generate project build script
write_project_tcl -all_properties -force $output_path

