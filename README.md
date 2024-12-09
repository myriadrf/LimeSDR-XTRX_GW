Gateware version 1.20

# LimeSDR-XTRX FPGA gateware

LimeSDR XTRX is Small form factor mini PCIe expansion card Software Defined Radio (SDR) board. It provides a hardware platform for developing and prototyping high-performance and logic-intensive digital and RF designs based on Xilinx’s XC7A50T-2CPG236I FPGA and Lime Microsystems transceiver chipsets.

This repository contains the LimeSDR XTRX FPGA gateware project, as well as a "gold" version of said project, which is
modified to generate a fallback image for implementing multiboot functionality.
It is not recommended to edit or generate the "gold" version of the project. Instructions below, if not specified 
otherwise, refer only to the regular "user" project.

More information on multiboot functionality can be found below.

:warning: Please use specific branch according to your board version. 

The gateware can be built with the free version of the Xilinx Vivado v2022.1 (64-bit).

## Cloning repository

* git clone https://github.com/myriadrf/LimeSDR-XTRX_GW
* git submodule init
* git submodule update

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

## Multiboot functionality

This repository contains images intended to implement multiboot functionality on the LimeSDR-XTRX board.
Their functions are as follows:

* **user_*_programming_file** - up-to-date gateware intended for regular use, referred to as **user** image
* **gold_*_programming_file** - fallback image, should not be used under normal circumstances, referred to as **gold** image
* **combined_flash_programming_file** - an image combining both **user** and **gold** images

Multiboot functions as follows:

* **gold** image header is read from the bottom of flash memory
* **gold** image header specifies the memory address offset for **user** image
* If booting from the **user** image fails or times out, the FPGA loads the **gold** image
* If booting from the **user** image succeeds, the FPGA load the **user** image

**Note!** **Gold** image can be recognized by its GW revision number (57005.57005) and LED blink pattern (both LEDs blink slowly and synchronously)

### Choosing the right image for programming via LimeSuite

If your GW version is v1.13 or higher, your board should already have the gold image written into the flash memory. In that case **user_flash_programming_file.bin** should be used.

If your GW version is v1.12 or lower, use **combined_flash_programming_file.bin** to update your GW and add multiboot functionality.

### Notes

* If after updating from GW >v1.13 to a different version the gw version reported in LimeSuite does not change after a board power cycle, it is likely that your **gold** image was overwritten by **user** image. In this case you should write **gold_flash_programming_file.bin** or **combined_flash_programming_file.bin** using the gold image write function in software.  
* Loading **gold** image when **user** image loading fails takes more time than successfully loading **user** image. For this reason, in fallback mode, your OS may have issues recognizing the board. Entering the UEFI/BIOS settings while booting up and exiting may alleviate this. Powering the board via USB is also known to help. 
* If for some reason you do not wish to use multiboot functionality, you can program your board using the **gold_image** programming function in software and the **user_flash_programming_file.bin** file.

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
* Select **combined_flash_programming_file.bin** in bitstream directory and click OK

## Branches
This repository contains the following branches:

* Master:
  * Main branch                  - Gateware for LimeSDR-XTRX boards;
  * LimeSDR-XTRX_fairwaves_rev5  - Gateware for Fairwaves rev5 boards;

  
## Licensing

The hardware designs are licensed under the Solderpad Hardware License v2.1.
