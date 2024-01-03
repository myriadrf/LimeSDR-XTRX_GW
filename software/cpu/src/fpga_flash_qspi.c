/*
 * fpga_flash_qspi.c
 *
 *  Created on: Sep 7, 2022
 *      Author: Lime Microsystems
 */

#include "fpga_flash_qspi.h"

void Init_flash_qspi(u16 DeviceId, XSpi *InstancePtr, u32 Options)
{
	int spi_status;
	XSpi_Config *ConfigPtr;

    //Get default config
	ConfigPtr = XSpi_LookupConfig(DeviceId);
	if (ConfigPtr == NULL) {
		//return XST_DEVICE_NOT_FOUND;
	}

    //Temporary mode override for initialization, saving original value
//    spi_mode = ConfigPtr->SpiMode;
//    ConfigPtr->SpiMode = 0;

    //Perform IP core config
    spi_status = XSpi_CfgInitialize(InstancePtr, ConfigPtr,
				  ConfigPtr->BaseAddress);

    //Set Options
    spi_status = XSpi_SetOptions(InstancePtr, Options);
	if(spi_status != XST_SUCCESS) {
		//return XST_FAILURE;
	}

    // Start the SPI driver so that interrupts and the device are enabled
	spi_status = XSpi_Start(InstancePtr);

    //disable global interrupts since we will use a polled approach
	XSpi_IntrGlobalDisable(InstancePtr);
    XSpi_SetSlaveSelect(InstancePtr,1);
    FlashQspi_CMD_DisQPI(InstancePtr);
//	 retval = FlashQspi_CMD_WREN(InstancePtr);

//     retval = FlashQspi_CMD_ReadRDSR(InstancePtr,&status_reg);
//     retval = FlashQspi_CMD_ReadRDCR(InstancePtr,&config_reg);

    // retval = FlashQspi_WRSR(InstancePtr,status_reg,config_reg);

    // retval = FlashQspi_ReadRDSR(InstancePtr,&status_reg);
    // retval = FlashQspi_ReadRDCR(InstancePtr,&config_reg);

//	 retval = FlashQspi_CMD_WRDI(InstancePtr);
    // retval = FlashQspi_ReadRDSR(InstancePtr,&status_reg);
    // retval = FlashQspi_ReadRDCR(InstancePtr,&config_reg);
//////////////
    // retval = FlashQspi_CMD_WREN(InstancePtr);
    // retval = FlashQspi_CMD_ReadRDSR(InstancePtr,&status_reg);

    // retval = FlashQspi_CMD_ReadDataPage(InstancePtr, 0x8000,bufferRD);
    // retval = FlashQspi_CMD_ReadRDSR(InstancePtr,&status_reg);

    // retval = FlashQspi_CMD_SectorErase(InstancePtr, 0x8000);

    // retval = FlashQspi_CMD_ReadRDSR(InstancePtr,&status_reg);
    // retval = FlashQspi_CMD_ReadDataPage(InstancePtr, 0x8000,bufferRD);
    // retval = FlashQspi_CMD_ReadRDSR(InstancePtr,&status_reg);

    // retval = FlashQspi_CMD_WREN(InstancePtr);

    // retval = FlashQspi_CMD_WriteDataPage(InstancePtr, 0x8000,bufferWR);

    // retval = FlashQspi_CMD_ReadRDSR(InstancePtr,&status_reg);
    // while(status_reg&1 > 0)
    // {
    //     retval = FlashQspi_CMD_ReadRDSR(InstancePtr,&status_reg);
    // }
    // retval = FlashQspi_CMD_ReadDataPage(InstancePtr, 0x8000,bufferRD);
    // retval = FlashQspi_CMD_WRDI(InstancePtr);

//    FlashQspi_ReadPage(InstancePtr,0x8000,bufferRD);
//    FlashQspi_EraseSector(InstancePtr,0x8000);
//    FlashQspi_ReadPage(InstancePtr,0x8000,bufferRD);
//    FlashQspi_ProgramPage(InstancePtr,0x8000,bufferWR);
//    FlashQspi_ReadPage(InstancePtr,0x8000,bufferRD);



}

int FlashQspi_CMD_ReadRDSR(XSpi *InstancePtr, u8* Data)
{
    u8 sendbuf[3]={0};
    u8 recvbuf[3]={0};
    int retval;

    sendbuf[0] = 0x5;

    retval = XSpi_Transfer(InstancePtr, sendbuf, recvbuf, 3);
    //Flash memory repeats status register two times
    *Data = recvbuf[1];

    return retval;
}

int FlashQspi_CMD_WREN(XSpi *InstancePtr)
{
    u8 sendbuf[1]={0};
    //Write enable command
    sendbuf[0] = 0x6;
    return XSpi_Transfer(InstancePtr, sendbuf, NULL, 1);
}

int FlashQspi_CMD_WRDI(XSpi *InstancePtr)
{
    u8 sendbuf[1]={0};
    //Write disable command
    sendbuf[0] = 0x4;

    return XSpi_Transfer(InstancePtr, sendbuf, NULL, 1);
}

int FlashQspi_CMD_EnQPI(XSpi *InstancePtr)
{
	u8 sendbuf[1]={0};
	//Enable quad mode command
	sendbuf[0] = 0x35;

	return XSpi_Transfer(InstancePtr, sendbuf, NULL, 1);
}

int FlashQspi_CMD_DisQPI(XSpi *InstancePtr)
{
	u8 sendbuf[1]={0};
	//Enable quad mode command
	sendbuf[0] = 0xF5;

	return XSpi_Transfer(InstancePtr, sendbuf, NULL, 1);
}

int FlashQspi_CMD_WRSR(XSpi *InstancePtr, u8 StatusReg, u8 ConfigReg)
{
	u8 sendbuf[3]={0};
	//set command and output data
	sendbuf[0] = 0x1;
	sendbuf[1] = StatusReg;
	sendbuf[2] = ConfigReg;

	return XSpi_Transfer(InstancePtr, sendbuf, NULL, 1);
}

int FlashQspi_CMD_ReadRDCR(XSpi *InstancePtr, u8* Data)
{
    u8 sendbuf[3]={0};
    u8 recvbuf[3]={0};
    int retval;

    sendbuf[0] = 0x15;

    retval = XSpi_Transfer(InstancePtr, sendbuf, recvbuf, 3);
    //Flash memory repeats status register two times
    *Data = recvbuf[1];

    return retval;
}

int FlashQspi_CMD_ReadDataPage(XSpi *InstancePtr, u32 address, u8* buffer)
{
    // 256 bytes in a page, 1 byte command, 3 byte address
//    u8 sendbuf[260] = {0};
    u8 recvbuf[260] = {0};
    int retval;

    recvbuf[0] = 0x03;
    recvbuf[1] = (address >> 16)&0xff;
    recvbuf[2] = (address >> 8)&0xff;
    recvbuf[3] = 0;//(address )&0xff;

    retval = XSpi_Transfer(InstancePtr, recvbuf, recvbuf, 260);

    for(int i=4; i<260; i++)
    {
        buffer[i-4] = recvbuf[i];
    }
    
    return retval;
}

int FlashQspi_CMD_WriteDataPage(XSpi *InstancePtr, u32 address, u8* buffer)
{
    // 256 bytes in a page, 1 byte command, 3 byte address
    u8 sendbuf[260] = {0};
//    u8 recvbuf[260] = {0};
    int retval;

    sendbuf[0] = 0x02;
    sendbuf[1] = (address >> 16)&0xff;
    sendbuf[2] = (address >> 8)&0xff;
    sendbuf[3] = 0;//(address)&0xff;

    for(int i=4; i<260; i++)
    {
        sendbuf[i] = buffer[i-4];
    }

    retval = XSpi_Transfer(InstancePtr, sendbuf, NULL, 260);


    
    return retval;
}

int FlashQspi_CMD_SectorErase(XSpi *InstancePtr, u32 address)
{
    u8 sendbuf[4] = {0};
    int retval;

    sendbuf[0] = 0x20;
    sendbuf[1] = (address >> 16)&0xff;
    sendbuf[2] = (address >> 8)&0xff;
    sendbuf[3] = 0;//(address)&0xff;

    retval = XSpi_Transfer(InstancePtr, sendbuf, NULL, 4);

    return retval;

}

int FlashQspi_ProgramPage(XSpi *InstancePtr, u32 address, u8* data)
{
    u8 status_reg = 0;
    int retval;
    //Set Write enable
    do
    {
        retval = FlashQspi_CMD_WREN(InstancePtr);
        if(retval != XST_SUCCESS) return retval;
        retval = FlashQspi_CMD_ReadRDSR(InstancePtr,&status_reg); 
        if(retval != XST_SUCCESS) return retval;       
    } while(status_reg&2 == 0); //Check write enable
    //Perform write
    retval = FlashQspi_CMD_WriteDataPage(InstancePtr,address,data);
    if(retval != XST_SUCCESS) return retval;   
    //Check if flash is busy
    do
    {
        retval = FlashQspi_CMD_ReadRDSR(InstancePtr,&status_reg); 
        if(retval != XST_SUCCESS) return retval;  
    } while(status_reg&1 == 1);
    //Return success if no problems
    return XST_SUCCESS;
}

int FlashQspi_EraseSector(XSpi *InstancePtr, u32 address)
{
    u8 status_reg = 0;
    int retval;
    //Set Write enable
    do
    {
        retval = FlashQspi_CMD_WREN(InstancePtr);
        if(retval != XST_SUCCESS) return retval;
        retval = FlashQspi_CMD_ReadRDSR(InstancePtr,&status_reg); 
        if(retval != XST_SUCCESS) return retval;       
    } while(status_reg&2 == 0); //Check write enable
    // Perform erase
    retval = FlashQspi_CMD_SectorErase(InstancePtr,address);
    if(retval != XST_SUCCESS) return retval;   
    // Check if flash is busy
    do
    {
        retval = FlashQspi_CMD_ReadRDSR(InstancePtr,&status_reg); 
        if(retval != XST_SUCCESS) return retval;  
    } while(status_reg&1 == 1);
    //Return success if no problems
    return XST_SUCCESS;
}

int FlashQspi_ReadPage(XSpi *InstancePtr, u32 address, u8* data)
{
    //No additional operations are needed
    return FlashQspi_CMD_ReadDataPage(InstancePtr,address,data);
}
