Gateware version 1.00

# LimeSDR-XTRX FPGA gateware

LimeSDR XTRX is Small form factor mini PCIe expansion card Software Defined Radio (SDR) board. It provides a hardware platform for developing and prototyping high-performance and logic-intensive digital and RF designs based on Xilinx’s XC7A50T-2CPG236I FPGA and Lime Microsystems transceiver chipsets.

This repository contains the FPGA gateware project for the LimeSDR-XTRX board, adapted for use with Fairwaves XTRX rev5.

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
* Create a workspace
* Click File->Import..
* Select "Vitis project exported zip file"
* Select vitis_export_archive.ide.zip file included in the project folder
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

* Open Vitis
* Click File->Export
* Select all projects
* When prompted to overwrite the already existing vitis_export_archive.ide.zip, click Yes.

## Branches

This repository contains the following branches:

* Master:
  * Main branch;
  * LimeSDR-XTRX_fairwaves_rev5;

  
## Licensing

The hardware designs are licensed under the Solderpad Hardware License v2.1.
