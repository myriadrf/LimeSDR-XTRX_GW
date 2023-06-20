proc update_readme_number { input_file output_file source_file} {
	# If the input file can't be opened, return an error.
	if { [catch {open $input_file} input] } {
		 return -code error $input
		 puts "can't open input"
	}

	# If the output file can't be opened, return an error
	if { [catch {open $output_file w} output] } {
		 return -code error $output
		 puts "can't open output"
	}
	
	# If the input file can't be opened, return an error.
	if { [catch {open $source_file} source] } {
		 return -code error $source
		 puts "can't open source"
	}

	# Read through the input file a line at a time
	while {-1 != [gets $source line] } {
		if { [regexp {^\s*constant compile_rev : integer := ([[:digit:]]+);\s*$} \ $line match version_number] } {
			set minor_compile_ver $version_number
		} elseif { [regexp {^\s*constant major_rev : integer := ([[:digit:]]+);\s*$} \ $line match version_number] } {
			set major_compile_ver $version_number
		} elseif { [regexp {^\s*constant major_rev : integer := -([[:digit:]]+);\s*$} \ $line match version_number] } {
			set major_compile_ver "-"
            append major_compile_ver $version_number
		}
		
	}
	
	set string "Gateware version "
	append string $major_compile_ver
	append string "."
	append string $minor_compile_ver
	
	# throw away first input line, change it with a new string
	gets $input line
	puts $output $string
	# keep all other lines the same
	while {-1 != [gets $input line] } {
		puts $output $line
	}
	
	close $input 
	close $output 
	close $source
}

set script_path [file dirname [file normalize [info script]]]
set source_name "[file normalize "$script_path/src/hdl/revision/revisions.vhd"]"
set input_name "[file normalize "$script_path/README.md"]"
set output_name "[file normalize "$script_path/README.md.temp"]"

update_readme_number $input_name $output_name $source_name
file rename -force $output_name $input_name