set script_path [file dirname [file normalize [info script]]]
puts $script_path

cd $script_path
source LimeSDR-XTRX.tcl
