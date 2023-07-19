# #################################################################
# Project configuration
# #################################################################
set script_path [file dirname [file normalize [info script]]]
puts $script_path
cd $script_path

# Get configuration variables 
source ./config.tcl

 # Create project
 create_project $PROJ_NAME ./$PROJ_FOLDER -part $PROJ_PART
 
 # Set strategies
 if {[info exists $SYNTH_STRAT]} {
    set_property strategy $SYNTH_STRAT [get_runs synth_1]
 }
 
 if {[info exists $IMPL_STRAT]} {
    set_property strategy $IMPL_STRAT [get_runs impl_1]
 }


# #################################################################
# Restore IP
# #################################################################
foreach dir $IP_TCL_DIRS {
   foreach file [glob $dir/*.tcl] {
      source $file
   }
}

generate_target all [get_ips -exclude_bd_ips]

# #################################################################
# Restore Block designs
# #################################################################
# Add User IP repo paths needed for block design
set_property  ip_repo_paths  $IP_REPO_PATH [current_project]
update_ip_catalog -rebuild

# Restore BD
source $BLOCK_DESIGN_FILE

generate_target all [get_ips -exclude_bd_ips]
validate_bd_design -force
generate_target all [get_files  *$BD_INSTANCE_NAME.bd]


# Associate .elf file to microblaze_0
add_files $MB_ELF_FILE_PATH
set_property SCOPED_TO_CELLS {microblaze_0} [get_files $MB_ELF_FILE]
set_property SCOPED_TO_REF $BD_INSTANCE_NAME [get_files $MB_ELF_FILE]

#set_property SCOPED_TO_REF mb_subsystem [get_files -all -of_objects [get_fileset sources_1] {d:/work_dir/ZCU106/limemm-x8_gw/src/mb_elf/mb_app.elf}]
#set_property SCOPED_TO_CELLS { microblaze_0 } [get_files -all -of_objects [get_fileset sources_1] {d:/work_dir/ZCU106/limemm-x8_gw/src/mb_elf/mb_app.elf}]

close_bd_design [get_bd_designs $BD_INSTANCE_NAME]


# #################################################################
# Add project files
# #################################################################
# Add files from directories
foreach dir $HDL_DIRS {
   add_files -quiet $dir
}

# Add separate files
foreach file $HDL_FILES {
   add_files -quiet $file
}

# Add LimeIP modules
foreach module $LIME_IP {
   source [file join [file dirname [info script]] "$LIME_IP_DIR/$module/add_module.tcl"] 
}

# Set VHDL2008 standart for VHDL files
set_property file_type {VHDL 2008} [get_files -filter {FILE_TYPE == VHDL}]


# #################################################################
# Add constraints
# #################################################################
add_files -fileset constrs_1 -norecurse -quiet [glob -nocomplain $CONSTR_DIR/*.xdc]
add_files -fileset constrs_1 -norecurse -quiet [glob -nocomplain $CONSTR_DIR/*.tcl]




