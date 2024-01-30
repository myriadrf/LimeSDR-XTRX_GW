Gateware version 1.9

# LimeSDR-XTRX FPGA gateware

LimeSDR XTRX is Small form factor mini PCIe expansion card Software Defined Radio (SDR) board. It provides a hardware platform for developing and prototyping high-performance and logic-intensive digital and RF designs based on Xilinx’s XC7A50T-2CPG236I FPGA and Lime Microsystems transceiver chipsets.

This repository contains the LimeSDR XTRX FPGA gateware project.

The gateware can be built with the free version of the Xilinx Vivado v2022.1 (64-bit).

## Project building

* Open Vivado;
* Select Tools->Run Tcl script.. 
* Move into the gateware directory and execute "Generate_Project.tcl"

## Changing project settings or adding new src files

* Open LimeSDR-XTRX project with Vivado;
* Select Tools->Run Tcl script.. 
* Move into the gateware directory and execute "write_proj_script.tcl"

## Modifying microblaze(embedded processor) code

* Open Vitis
* Choose LimeSDR-XTRX_GW\software as your workspace
* Click File->Import..
* Select "Eclipse workspace or zip file"
* Select LimeSDR-XTRX_GW\software as the root folder
* Make sure "Copy projects into workspace" is NOT checked
* Import all suggested projects

## Updating hardware description for vitis project

* Open Vivado project
* Fully compile the project and generate bitstream
* Click File->Export->Export Hardware
* In the "Platform type" dialog select "Fixed"
* In the "Output" dialog select "Include bitstream"
* In the "Files" dialog note the export location
* Open Vitis
* Right click on the lms7_trx_top project and select "Update Hardware Specification"
* Provide the path to the file exported by Vivado and click OK

## Importing microblaze code to vivado project

* Compile Vitis project
* Replace the cpu.elf file in <repo dir>/src/mb_elf/ with the new one in <workspace dir>/cpu/Debug
* Recompile Vivado project

## Exporting Vitis code

* If projects were imported as directed, no special actions should be needed

## Branches

This repository contains the following branches:

* Master:
  * Main branch;
  * LimeSDR-XTRX_fairwaves_rev5;

  
## Licensing

The hardware designs are licensed under the Solderpad Hardware License v2.1.
