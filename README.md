Gateware version 1.10

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

## Programming the board

### Programming via LimeSuite 

* A working board can be reprogrammed in LimeSuite by using the program function in Modules -> Programming

**Note!** If an invalid file is uploaded to the board, or if the programming process is interrupted, the board will become inaccessible via LimeSuite

### Programming via JTAG

* Make sure you have a Xilinx JTAG programmer connected to the LimeSDR-XTRX's JTAG pins via a PCIe adapter or in some other way
* Open Vivado
* Open Hardware manager
* Click Tools -> Auto connect
* An FPGA device should be detected. Right click on it and select "Add configuration memory device"
* Select "mx25l25673g-spi-x1_x2_x4"
* Right click on the newly added memory device and choose "Program configuration memory device"
* Select your configuration file and click OK

## Branches

This repository contains the following branches:

* Master:
  * Main branch;
  * LimeSDR-XTRX_fairwaves_rev5;

  
## Licensing

The hardware designs are licensed under the Solderpad Hardware License v2.1.
