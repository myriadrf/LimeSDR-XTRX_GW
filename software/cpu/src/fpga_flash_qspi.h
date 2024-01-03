/*
 * fpga_flash_qspi.h
 *
 *  Created on: Sep 7, 2022
 *      Author: Lime Microsystems
 */

#ifndef SRC_FPGA_FLASH_QSPI_H_
#define SRC_FPGA_FLASH_QSPI_H_

#include "xspi.h"		/* SPI device driver */
#include <stdint.h>

void Init_flash_qspi(u16 DeviceId, XSpi *InstancePtr, u32 Options);
int FlashQspi_CMD_ReadRDSR(XSpi *InstancePtr, u8* Data);
int FlashQspi_CMD_WREN(XSpi *InstancePtr);
int FlashQspi_CMD_WRDI(XSpi *InstancePtr);
int FlashQspi_CMD_WRSR(XSpi *InstancePtr, u8 StatusReg, u8 ConfigReg);
int FlashQspi_CMD_ReadRDCR(XSpi *InstancePtr, u8* Data);
int FlashQspi_CMD_ReadDataPage(XSpi *InstancePtr, u32 address, u8* buffer);
int FlashQspi_CMD_WriteDataPage(XSpi *InstancePtr, u32 address, u8* buffer);
int FlashQspi_CMD_SectorErase(XSpi *InstancePtr, u32 address);

int FlashQspi_ProgramPage(XSpi *InstancePtr, u32 address, u8* data);
int FlashQspi_EraseSector(XSpi *InstancePtr, u32 address);
int FlashQspi_ReadPage(XSpi *InstancePtr, u32 address, u8* data);

#endif /* SRC_FPGA_FLASH_QSPI_H_ */
