/*
 * main.c
 */

#include <stdio.h>
#include <stdbool.h>
#include "platform.h"
#include "xil_printf.h"
#include <xgpio.h>				/* GPIO driver*/
#include <xiic.h>				/* I2C driver*/
#include "xspi.h"				/* SPI device driver */
#include "AXI_to_native_FIFO.h" /* Native FIFO driver*/

#include "fpga_flash_qspi.h"
#include "LMS64C_protocol.h"
#include "LimeSDR_XTRX.h"
#include "pll_rcfg.h"
#include "ads4246_reg.h"
#include "sleep.h"
#include "utility_functions.h"
#include "LP8758.h"
// #include "math.h"
/************************** Constant Definitions *****************************/
/*
 * The following constants map to the XPAR parameters created in the
 * xparameters.h file. They are defined here such that a user can easily
 * change all the needed parameters in one place.
 */
#define SPI0_DEVICE_ID XPAR_SPI_0_DEVICE_ID
#define QSPI_DEVICE_ID XPAR_SPI_CORES_SPI1_FLASH_DEVICE_ID

/*
 * The following constant defines the slave select signal that is used to
 * to select the  device on the SPI bus, this signal is typically
 * connected to the chip select of the device.
 */
#define SPI0_FPGA_SS 0x01
#define SPI0_LMS7002M_1_SS 0x02

#define BRD_SPI_REG_LMS1_LMS2_CTRL 0x13
#define LMS1_SS 0
#define LMS1_RESET 1
#define MEMORY_MAP_REG_MSB 0xFF
#define MEMORY_MAP_REG_LSB 0xFF
#define MEMOR_MAP_BIT 0x0
#define I2C_DAC_ADDR 0x4C
#define I2C_TERMO_ADDR 0x4A
#define I2C_LP8758_ADDRESS 0x60
// Since there is no eeprom on the XTRX board and the flash is too large for the gw
// we use the top of the flash instead of eeprom, thus the offset to last sector
#define mem_write_offset 0x01FF0000

#define FLASH_USER_SECTOR_START_ADDR 	0x01FE0000
#define FLASH_USER_SECTOR_END_ADDR 		0x01FEFFFF

/*
 * The following constants are part of clock dynamic reconfiguration
 * They are only defined here such that a user can easily change
 * needed parameters
 */

#define CLK_LOCK 1

/*FIXED Value */
#define VCO_FREQ 600
#define CLK_WIZ_VCO_FACTOR (VCO_FREQ * 10000)

/*Input frequency in MHz */
#define DYNAMIC_INPUT_FREQ 100
#define DYNAMIC_INPUT_FREQ_FACTOR (DYNAMIC_INPUT_FREQ * 10000)

/*
 * Output frequency in MHz. User need to change this value to
 * generate grater/lesser interrupt as per input frequency
 */
#define DYNAMIC_OUTPUT_FREQ 25
#define DYNAMIC_OUTPUT_FREQFACTOR (DYNAMIC_OUTPUT_FREQ * 10000)

#define CLK_WIZ_RECONFIG_OUTPUT DYNAMIC_OUTPUT_FREQ
#define CLK_FRAC_EN 1

uint8_t temp_buffer0[4];
uint8_t temp_buffer1[4];
// storage for dac values
uint16_t pa1_dac_val = 0xFFFF;
uint16_t pa2_dac_val = 0xFFFF;
uint16_t dac_val = 30714;			  // TCXO DAC value
signed short int converted_val = 300; // Temperature
int data_cnt = 0;

/************************** Variable Definitions *****************************/

/*
 * The instances to support the device drivers are global such that they
 * are initialized to zero each time the program runs. They could be local
 * but should at least be static so they are zeroed.
 */
static XSpi Spi0;
static XSpi CFG_QSPI;
static XGpio gpio, gpio_2, pll_rst, pllcfg_cmd, pllcfg_stat, extm_0_axi_sel, smpl_cmp_en, smpl_cmp_status;

static XGpio vctcxo_tamer_ctrl;
// XClk_Wiz ClkWiz_Dynamic; /* The instance of the ClkWiz_Dynamic */

#define sbi(p, n) ((p) |= (1UL << (n)))
#define cbi(p, n) ((p) &= ~(1 << (n)))

//#define FW_VER 1 // Initial version
#define FW_VER 2 // Fix for PLL config. hang when changing from low to high frequency.

// Variables for QSPI config (configuration flash programming)
unsigned long int last_portion, current_portion, fpga_data, fpga_byte;
// unsigned char data_cnt, sc_brdg_data[255];

uint8_t test, block, cmd_errors, glEp0Buffer_Rx[64], glEp0Buffer_Tx[64];
tLMS_Ctrl_Packet *LMS_Ctrl_Packet_Tx = (tLMS_Ctrl_Packet *)glEp0Buffer_Tx;
tLMS_Ctrl_Packet *LMS_Ctrl_Packet_Rx = (tLMS_Ctrl_Packet *)glEp0Buffer_Rx;

/**	This function checks if all blocks could fit in data field.
 *	If blocks will not fit, function returns TRUE. */
unsigned char Check_many_blocks(unsigned char block_size)
{
	if (LMS_Ctrl_Packet_Rx->Header.Data_blocks > (sizeof(LMS_Ctrl_Packet_Tx->Data_field) / block_size))
	{
		LMS_Ctrl_Packet_Tx->Header.Status = STATUS_BLOCKS_ERROR_CMD;
		return 1;
	}
	else
		return 0;
	return 1;
}

void Init_SPI(u16 DeviceId, XSpi *InstancePtr, u32 Options)
{
	int spi_status;
	XSpi_Config *ConfigPtr;

	/*
	 * Initialize the SPI driver so that it is  ready to use.
	 */
	ConfigPtr = XSpi_LookupConfig(DeviceId);
	if (ConfigPtr == NULL)
	{
		// return XST_DEVICE_NOT_FOUND;
	}

	spi_status = XSpi_CfgInitialize(InstancePtr, ConfigPtr,
									ConfigPtr->BaseAddress);
	if (spi_status != XST_SUCCESS)
	{
		// return XST_FAILURE;
	}

	/*
	 * Set the SPI device as a master and in manual slave select mode such
	 * that the slave select signal does not toggle for every byte of a
	 * transfer, this must be done before the slave select is set.
	 */
	spi_status = XSpi_SetOptions(InstancePtr, Options);
	if (spi_status != XST_SUCCESS)
	{
		// return XST_FAILURE;
	}

	// Start the SPI driver so that interrupts and the device are enabled
	spi_status = XSpi_Start(InstancePtr);

	// disable global interrupts since we will use a polled approach
	XSpi_IntrGlobalDisable(InstancePtr);
}

/** Checks if peripheral ID is valid.
 Returns 1 if valid, else 0. */
unsigned char Check_Periph_ID(unsigned char max_periph_id, unsigned char Periph_ID)
{
	if (LMS_Ctrl_Packet_Rx->Header.Periph_ID > max_periph_id)
	{
		LMS_Ctrl_Packet_Tx->Header.Status = STATUS_INVALID_PERIPH_ID_CMD;
		return 0;
	}
	else
		return 1;
}

/**
 * Gets 64 bytes packet from FIFO.
 */
void getFifoData(uint8_t *buf, uint8_t k)
{
	uint8_t cnt = 0;
	uint32_t *dest = (uint32_t *)buf;
	for (cnt = 0; cnt < k / sizeof(uint32_t); ++cnt)
	{
		dest[cnt] = AXI_TO_NATIVE_FIFO_mReadReg(XPAR_AXI_TO_NATIVE_FIFO_0_S00_AXI_BASEADDR, AXI_TO_NATIVE_FIFO_S00_AXI_SLV_REG1_OFFSET);
	};
}

/**
 *	@brief Function to modify BRD (FPGA) spi register bits
 *	@param SPI_reg_addr register address
 *	@param MSB_bit MSB bit of range that will be modified
 *	@param LSB_bit LSB bit of range that will be modified
 */
void Modify_BRDSPI16_Reg_bits(unsigned short int SPI_reg_addr, unsigned char MSB_bit, unsigned char LSB_bit, unsigned short int new_bits_data)
{
	unsigned short int mask, SPI_reg_data;
	unsigned char bits_number;
	// uint8_t MSB_byte, LSB_byte;
	unsigned char WrBuff[4];
	unsigned char RdBuff[4];

	//**Reconfigure_SPI_for_LMS();

	bits_number = MSB_bit - LSB_bit + 1;

	mask = 0xFFFF;

	// removing unnecessary bits from mask
	mask = mask << (16 - bits_number);
	mask = mask >> (16 - bits_number);

	new_bits_data &= mask; // mask new data

	new_bits_data = new_bits_data << LSB_bit; // shift new data

	mask = mask << LSB_bit; // shift mask
	mask = ~mask;			// invert mask

	// Read original data
	WrBuff[0] = (SPI_reg_addr >> 8) & 0xFF; // MSB_byte
	WrBuff[1] = SPI_reg_addr & 0xFF;		// LSB_byte
	cbi(WrBuff[0], 7);						// clear write bit
	// spirez = alt_avalon_spi_command(FPGA_SPI0_BASE, SPI_NR_FPGA, 2, WrBuff, 2, RdBuff, 0);
	XSpi_SetSlaveSelect(&Spi0, SPI0_FPGA_SS);
	XSpi_Transfer(&Spi0, WrBuff, RdBuff, 4);

	// SPI_reg_data = (RdBuff[0] << 8) + RdBuff[1]; //read current SPI reg data
	//  we are reading 4 bytes
	SPI_reg_data = (RdBuff[2] << 8) + RdBuff[3]; // read current SPI reg data

	// modify reg data
	SPI_reg_data &= mask;		   // clear bits
	SPI_reg_data |= new_bits_data; // set bits with new data

	// write reg addr
	WrBuff[0] = (SPI_reg_addr >> 8) & 0xFF; // MSB_byte
	WrBuff[1] = SPI_reg_addr & 0xFF;		// LSB_byte
	// modified data to be written to SPI reg
	WrBuff[2] = (SPI_reg_data >> 8) & 0xFF;
	WrBuff[3] = SPI_reg_data & 0xFF;
	sbi(WrBuff[0], 7); // set write bit
	// spirez = alt_avalon_spi_command(FPGA_SPI0_BASE, SPI_NR_FPGA, 4, WrBuff, 0, NULL, 0);
	XSpi_SetSlaveSelect(&Spi0, SPI0_FPGA_SS);
	XSpi_Transfer(&Spi0, WrBuff, NULL, 4);
}

// Change PLL phase
void RdPLLCFG(tXPLL_CFG *pll_cfg)
{
	uint8_t wr_buf[4];
	uint8_t rd_buf[4];
	uint8_t value_cap;

	uint8_t D_BYP, M_BYP, C0_BYP, C1_BYP, C2_BYP, C3_BYP, C4_BYP, C5_BYP, C6_BYP;

	/* Get DIV and MULT bypass values */
	/* D_BYP and M_BYP values comes from compatibility with existing Altera GW*/
	wr_buf[0] = 0x00; // Command and Address
	wr_buf[1] = 0x26; // Command and Address
	XSpi_SetSlaveSelect(&Spi0, SPI0_FPGA_SS);
	XSpi_Transfer(&Spi0, wr_buf, rd_buf, 4);
	D_BYP = rd_buf[3] & 0x01;
	M_BYP = (rd_buf[3] >> 2) & 0x01;

	/* Get Output counter bypass values */
	/* OX_BYP values comes from compatibility with existing Altera GW*/
	wr_buf[0] = 0x00; // Command and Address
	wr_buf[1] = 0x27; // Command and Address
	XSpi_SetSlaveSelect(&Spi0, SPI0_FPGA_SS);
	XSpi_Transfer(&Spi0, wr_buf, rd_buf, 4);
	C0_BYP = rd_buf[3] & 0x01;
	C1_BYP = (rd_buf[3] >> 2) & 0x01;
	C2_BYP = (rd_buf[3] >> 4) & 0x01;
	C3_BYP = (rd_buf[3] >> 6) & 0x01;
	C4_BYP = (rd_buf[2]) & 0x01;
	C5_BYP = (rd_buf[2] >> 2) & 0x01;
	C6_BYP = (rd_buf[2] >> 4) & 0x01;

	/* Read Divide value */
	if (D_BYP)
	{
		pll_cfg->DIVCLK_DIVIDE = 1;
	}
	else
	{
		wr_buf[0] = 0x00; // Command and Address
		wr_buf[1] = 0x2A; // Command and Address
		XSpi_SetSlaveSelect(&Spi0, SPI0_FPGA_SS);
		XSpi_Transfer(&Spi0, wr_buf, rd_buf, 4);
		value_cap = rd_buf[2] + rd_buf[3];
		if (value_cap > 64)
			value_cap = 64;
		pll_cfg->DIVCLK_DIVIDE = value_cap; // rd_buf[2] + rd_buf[3];
	}

	/* Read Multiply value */
	if (M_BYP)
	{
		pll_cfg->CLKFBOUT_MULT = 1;
	}
	else
	{
		wr_buf[0] = 0x00; // Command and Address
		wr_buf[1] = 0x2B; // Command and Address
		XSpi_SetSlaveSelect(&Spi0, SPI0_FPGA_SS);
		XSpi_Transfer(&Spi0, wr_buf, rd_buf, 4);
		value_cap = rd_buf[2] + rd_buf[3];
		if (value_cap > 64)
			value_cap = 64;
		pll_cfg->CLKFBOUT_MULT = value_cap;
		//		pll_cfg->CLKFBOUT_MULT	=rd_buf[2] + rd_buf[3];
	}

	/* Read Fractional multiply part*/
	wr_buf[0] = 0x00; // Command and Address
	wr_buf[1] = 0x2C; // Command and Address
	XSpi_SetSlaveSelect(&Spi0, SPI0_FPGA_SS);
	XSpi_Transfer(&Spi0, wr_buf, rd_buf, 4);
	pll_cfg->CLKFBOUT_FRAC = MFRAC_CNT_LSB(rd_buf[2], rd_buf[3]);

	wr_buf[0] = 0x00; // Command and Address
	wr_buf[1] = 0x2D; // Command and Address
	XSpi_SetSlaveSelect(&Spi0, SPI0_FPGA_SS);
	XSpi_Transfer(&Spi0, wr_buf, rd_buf, 4);

	pll_cfg->CLKFBOUT_FRAC = pll_cfg->CLKFBOUT_FRAC | MFRAC_CNT_MSB(rd_buf[2], rd_buf[3]);
	pll_cfg->CLKFBOUT_PHASE = 0;

	/* Read C0 divider*/
	if (C0_BYP)
	{
		pll_cfg->CLKOUT0_DIVIDE = 1;
	}
	else
	{
		wr_buf[0] = 0x00; // Command and Address
		wr_buf[1] = 0x2E; // Command and Address
		XSpi_SetSlaveSelect(&Spi0, SPI0_FPGA_SS);
		XSpi_Transfer(&Spi0, wr_buf, rd_buf, 4);
		value_cap = rd_buf[2] + rd_buf[3];
		if (value_cap > 64)
			value_cap = 64;
		pll_cfg->CLKOUT0_DIVIDE = value_cap; // rd_buf[2] + rd_buf[3];
	}

	pll_cfg->CLKOUT0_FRAC = 0;
	pll_cfg->CLKOUT0_PHASE = 0 * 1000; // Phase value = (Phase Requested) * 1000. For example, for a 45.5 degree phase, the required value is 45500 = 0xB1BC.
	pll_cfg->CLKOUT0_DUTY = 50 * 1000; // Duty cycle value = (Duty Cycle in %) * 1000

	/* Read C1 divider*/
	if (C1_BYP)
	{
		pll_cfg->CLKOUT1_DIVIDE = pll_cfg->CLKOUT0_DIVIDE;
	}
	else
	{
		wr_buf[0] = 0x00; // Command and Address
		wr_buf[1] = 0x2F; // Command and Address
		XSpi_SetSlaveSelect(&Spi0, SPI0_FPGA_SS);
		XSpi_Transfer(&Spi0, wr_buf, rd_buf, 4);
		value_cap = rd_buf[2] + rd_buf[3];
		if (value_cap > 64)
			value_cap = 64;
		pll_cfg->CLKOUT1_DIVIDE = value_cap; // rd_buf[2] + rd_buf[3];
	}

	/* Read phase value */
	wr_buf[0] = 0x00; // Command and Address
	wr_buf[1] = 0x20; // Command and Address
	XSpi_SetSlaveSelect(&Spi0, SPI0_FPGA_SS);
	XSpi_Transfer(&Spi0, wr_buf, rd_buf, 4);
	value_cap = rd_buf[3];

	pll_cfg->CLKOUT1_PHASE = value_cap * 1000;
	pll_cfg->CLKOUT1_DUTY = 50 * 1000;

	/* Read C2 divider*/
	if (C2_BYP)
	{
		/* All register has to be set to valid values so we take same value as CO output */
		pll_cfg->CLKOUT2_DIVIDE = pll_cfg->CLKOUT0_DIVIDE;
	}
	else
	{
		wr_buf[0] = 0x00; // Command and Address
		wr_buf[1] = 0x30; // Command and Address
		XSpi_SetSlaveSelect(&Spi0, SPI0_FPGA_SS);
		XSpi_Transfer(&Spi0, wr_buf, rd_buf, 4);
		pll_cfg->CLKOUT2_DIVIDE = rd_buf[2] + rd_buf[3];
	}

	pll_cfg->CLKOUT2_PHASE = 0;
	pll_cfg->CLKOUT2_DUTY = 50 * 1000;

	/* Read C3 divider*/
	if (C3_BYP)
	{
		/* All register has to be set to valid values so we take same value as CO output */
		pll_cfg->CLKOUT3_DIVIDE = pll_cfg->CLKOUT0_DIVIDE;
	}
	else
	{
		wr_buf[0] = 0x00; // Command and Address
		wr_buf[1] = 0x31; // Command and Address
		XSpi_SetSlaveSelect(&Spi0, SPI0_FPGA_SS);
		XSpi_Transfer(&Spi0, wr_buf, rd_buf, 4);
		pll_cfg->CLKOUT3_DIVIDE = rd_buf[2] + rd_buf[3];
	}

	pll_cfg->CLKOUT3_PHASE = 0;
	pll_cfg->CLKOUT3_DUTY = 50 * 1000;

	/* Read C4 divider*/
	if (C4_BYP)
	{
		/* All register has to be set to valid values so we take same value as CO output */
		pll_cfg->CLKOUT4_DIVIDE = pll_cfg->CLKOUT0_DIVIDE;
	}
	else
	{
		wr_buf[0] = 0x00; // Command and Address
		wr_buf[1] = 0x32; // Command and Address
		XSpi_SetSlaveSelect(&Spi0, SPI0_FPGA_SS);
		XSpi_Transfer(&Spi0, wr_buf, rd_buf, 4);
		pll_cfg->CLKOUT4_DIVIDE = rd_buf[2] + rd_buf[3];
	}
	pll_cfg->CLKOUT4_PHASE = 0;
	pll_cfg->CLKOUT4_DUTY = 50 * 1000;

	/* Read C5 divider*/
	if (C5_BYP)
	{
		/* All register has to be set to valid values so we take same value as CO output */
		pll_cfg->CLKOUT5_DIVIDE = pll_cfg->CLKOUT0_DIVIDE;
	}
	else
	{
		wr_buf[0] = 0x00; // Command and Address
		wr_buf[1] = 0x33; // Command and Address
		XSpi_SetSlaveSelect(&Spi0, SPI0_FPGA_SS);
		XSpi_Transfer(&Spi0, wr_buf, rd_buf, 4);
		pll_cfg->CLKOUT5_DIVIDE = rd_buf[2] + rd_buf[3];
	}
	pll_cfg->CLKOUT5_PHASE = 0;
	pll_cfg->CLKOUT5_DUTY = 50 * 1000;

	/* Read C6 divider*/
	if (C6_BYP)
	{
		/* All register has to be set to valid values so we take same value as CO output */
		pll_cfg->CLKOUT6_DIVIDE = pll_cfg->CLKOUT0_DIVIDE;
	}
	else
	{
		wr_buf[0] = 0x00; // Command and Address
		wr_buf[1] = 0x34; // Command and Address
		XSpi_SetSlaveSelect(&Spi0, SPI0_FPGA_SS);
		XSpi_Transfer(&Spi0, wr_buf, rd_buf, 4);
		pll_cfg->CLKOUT6_DIVIDE = rd_buf[2] + rd_buf[3];
	}
	pll_cfg->CLKOUT6_PHASE = 0;
	pll_cfg->CLKOUT6_DUTY = 50 * 1000;
}

int CheckSamples(int sel)
{

	int cmp_status = 1;
	int timeout;

	/* Disable sample compare*/
	XGpio_DiscreteWrite(&smpl_cmp_en, 1, 0x00);

	timeout = 0;
	do
	{
		cmp_status = XGpio_DiscreteRead(&smpl_cmp_status, 1);
		if (timeout++ > PLLCFG_TIMEOUT)
			return 0;
	} while ((cmp_status & 0x01) != 0);

	/* Enable sample compare */
	XGpio_DiscreteWrite(&smpl_cmp_en, 1, 0x01);

	timeout = 0;
	do
	{
		cmp_status = XGpio_DiscreteRead(&smpl_cmp_status, 1);
		if (timeout++ > PLLCFG_TIMEOUT)
			return 0;
	} while ((cmp_status & 0x01) == 0);

	return cmp_status;
}

void SetPhase_DRP(uint8_t phase_mux, uint8_t delay_time, uint16_t clkreg1_adr, uint16_t clkreg2_adr, uint8_t update_regs)
{
	uint16_t reg_val;
	// Read and write all previous values (all registers must be written to)
	if (update_regs == 1)
	{
		for (int j = 0x300; j <= 0x358; j += 4)
		{
			reg_val = Xil_In16(XPAR_EXTM_0_AXI_BASEADDR + j);
			Xil_Out16(XPAR_EXTM_0_AXI_BASEADDR + j, reg_val);
		}
		Xil_Out16(XPAR_EXTM_0_AXI_BASEADDR + 0x348, 0x00F4);
		Xil_Out16(XPAR_EXTM_0_AXI_BASEADDR + 0x34C, 0xFC01);
		Xil_Out16(XPAR_EXTM_0_AXI_BASEADDR + 0x350, 0xFDE9);
		Xil_Out16(XPAR_EXTM_0_AXI_BASEADDR + 0x354, 0x0800);
		Xil_Out16(XPAR_EXTM_0_AXI_BASEADDR + 0x358, 0x1800);
	}
	// Read current register value and update
	reg_val = Xil_In16(XPAR_EXTM_0_AXI_BASEADDR + clkreg1_adr); // Read current CLKOUT1 Reg1 Value
	reg_val &= 0x1FFF;											// Clear phase mux value (bits 15:13)
	reg_val |= phase_mux << 13;									// Using &0x7 to extract 3LSB, in essence modulus(8). Shift left to phase mux location
	Xil_Out16(XPAR_EXTM_0_AXI_BASEADDR + clkreg1_adr, reg_val); // Write new CLKOUT1 Reg1 Value
	// Read current register value and update
	reg_val = Xil_In16(XPAR_EXTM_0_AXI_BASEADDR + clkreg2_adr); // Read current CLKOUT1 Reg2 Value
	reg_val &= 0xFCFF;											// Clear MX bits(9:8). This is mandatory
	reg_val &= 0xFFC0;											// Clear Delay time bits(5:0)
	reg_val |= delay_time;										//(i>>3); // Write phase value divided by 8
	Xil_Out16(XPAR_EXTM_0_AXI_BASEADDR + clkreg2_adr, reg_val); // Write new CLKOUT1 Reg2 Value
}

void SetMMCM_CLKREG(uint8_t DIVIDE, uint32_t PHASE, uint16_t clkreg1_adr, uint16_t clkreg2_adr)
{
	uint8_t DELAY_TIME;
	uint8_t PHASE_MUX;
	uint8_t HIGH_TIME;
	uint8_t LOW_TIME;
	uint8_t NO_COUNT;
	uint8_t EDGE;
	int phase_step = 45 / DIVIDE; // 360/(DIVIDE*8);
	uint16_t phase_value;

	// calculate and write phase values first
	phase_value = PHASE / phase_step;
	DELAY_TIME = phase_value >> 3;
	PHASE_MUX = phase_value & 0x7;
	SetPhase_DRP(PHASE_MUX, DELAY_TIME, clkreg1_adr, clkreg2_adr, 0);

	uint16_t reg_val = Xil_In16(XPAR_EXTM_0_AXI_BASEADDR + clkreg1_adr);
	uint16_t reg_val_2 = Xil_In16(XPAR_EXTM_0_AXI_BASEADDR + clkreg2_adr);

	// PARSE OLD VALUES
	HIGH_TIME = (reg_val >> 6) & 0x3F;
	LOW_TIME = reg_val & 0x3F;
	NO_COUNT = (reg_val_2 >> 6) & 0x1;
	EDGE = (reg_val_2 >> 7) & 0x1;

	// Determine new values
	if (DIVIDE == 1) // If no dividing is required
	{
		NO_COUNT = 1; // Enable NO COUNT byte (this ignores the dividers)
	}
	else if (DIVIDE % 2 == 0) // If the divider is even
	{
		EDGE = 0;
		NO_COUNT = 0;
		HIGH_TIME = DIVIDE / 2;
		LOW_TIME = DIVIDE / 2;
	}
	else // Divider is odd
	{
		EDGE = 1;
		NO_COUNT = 0;
		HIGH_TIME = DIVIDE / 2;
		LOW_TIME = (DIVIDE / 2) + 1;
	}

	// Set and write new values
	reg_val &= 0xF000; // Clear HIGH TIME and LOW TIME bits
	reg_val |= LOW_TIME & 0x3F;
	reg_val |= (HIGH_TIME & 0x3F) << 6;
	Xil_Out16(XPAR_EXTM_0_AXI_BASEADDR + clkreg1_adr, reg_val);

	reg_val_2 &= 0xFC3F; // Clear NO COUNT, EDGE, MX(just in case) bits
	reg_val_2 |= NO_COUNT << 6;
	reg_val_2 |= EDGE << 7;
	Xil_Out16(XPAR_EXTM_0_AXI_BASEADDR + clkreg2_adr, reg_val_2);
}

void UpdateMMCM_Config(tXPLL_CFG *pll_cfg)
{
	uint16_t reg_val;
	uint8_t divider;
	uint8_t HIGH_TIME;
	uint8_t LOW_TIME;
	uint8_t NO_COUNT;
	uint8_t EDGE;
	// Read and write all previous values (all registers must be written to)
	for (int j = 0x300; j <= 0x358; j += 4)
	{
		reg_val = Xil_In16(XPAR_EXTM_0_AXI_BASEADDR + j);
		Xil_Out16(XPAR_EXTM_0_AXI_BASEADDR + j, reg_val);
	}

	Xil_Out16(XPAR_EXTM_0_AXI_BASEADDR + 0x348, 0x00F4);
	Xil_Out16(XPAR_EXTM_0_AXI_BASEADDR + 0x34C, 0xFC01);
	Xil_Out16(XPAR_EXTM_0_AXI_BASEADDR + 0x350, 0xFDE9);
	Xil_Out16(XPAR_EXTM_0_AXI_BASEADDR + 0x354, 0x0800);
	Xil_Out16(XPAR_EXTM_0_AXI_BASEADDR + 0x358, 0x1800);

	// DIVCLK (0x33C) written out in full, because divclk uses different register maps
	//  READ VALUE
	reg_val = Xil_In16(XPAR_EXTM_0_AXI_BASEADDR + 0x33C);
	divider = pll_cfg->DIVCLK_DIVIDE;
	HIGH_TIME = (reg_val >> 6) & 0x3F;
	LOW_TIME = reg_val & 0x3F;
	NO_COUNT = (reg_val >> 12) & 0x1;
	EDGE = (reg_val >> 13) & 0x1;

	// Determine new values
	if (divider == 1) // If no dividing is required
	{
		NO_COUNT = 1; // Enable NO COUNT byte (this ignores the dividers)
	}
	else if (divider % 2 == 0) // If the divider is even
	{
		EDGE = 0;
		NO_COUNT = 0;
		HIGH_TIME = divider / 2;
		LOW_TIME = divider / 2;
	}
	else // Divider is odd
	{
		EDGE = 1;
		NO_COUNT = 0;
		HIGH_TIME = divider / 2;
		LOW_TIME = (divider / 2) + 1;
	}
	reg_val &= 0xC000;					// Clear EDGE,NO COUNT, HIGH TIME, LOW TIME bits
	reg_val |= LOW_TIME & 0x3F;			// Set new LOW TIME value
	reg_val |= (HIGH_TIME & 0x3F) << 6; // Set new HIGH TIME value
	reg_val |= (NO_COUNT & 0x01) << 12; // Set new NO COUNT value
	reg_val |= (EDGE & 0x01) << 13;		// Set new EDGE value
	Xil_Out16(XPAR_EXTM_0_AXI_BASEADDR + 0x33C, reg_val);

	// CLK0 (0x304 and 0x308)
	SetMMCM_CLKREG((uint8_t)pll_cfg->CLKOUT0_DIVIDE, pll_cfg->CLKOUT0_PHASE, 0x304, 0x308);
	// CLK1 (0x30C and 0x310)
	SetMMCM_CLKREG((uint8_t)pll_cfg->CLKOUT1_DIVIDE, pll_cfg->CLKOUT1_PHASE, 0x30C, 0x310);
	// CLKFB(0x340 and 0x344)
	SetMMCM_CLKREG((uint8_t)pll_cfg->CLKFBOUT_MULT, pll_cfg->CLKFBOUT_PHASE, 0x340, 0x344);
}

// Start reconfig and check for lock
// IMPORTANT : MAKE SURE placeholder FUNCTION WAS RUN BEFORE THIS
uint8_t StartMMCM_Reconfig_DRP(void)
{
	int timeout;
	int lock_status;
	// Write 0x3 to start clocking reconfig
	Xil_Out16(XPAR_EXTM_0_AXI_BASEADDR + 0x35C, 3);
	// Check for lock
	timeout = 0;
	do
	{
		lock_status = Xil_In16(XPAR_EXTM_0_AXI_BASEADDR + XIL_CCR_STATUS);
		if (timeout++ > PLLCFG_TIMEOUT)
			return PHCFG_ERROR;
	} while (!(lock_status & 0x01));

	return PLLCFG_DONE;
}

// Change PLL phase using direct drp register writes
uint8_t AutoUpdatePHCFG_DRP(void)
{
	//	uint32_t PLL_BASE;
	//	uint32_t Val, Cx, Dir;
	uint8_t wr_buf[4];
	uint8_t rd_buf[4];
	int pll_ind;
	//	uint8_t pllcfgrez;
	tXPLL_CFG pll_cfg = {0};
	int PhaseMin = 0;
	int PhaseMax = 0;
	int PhaseMiddle = 0;
	//	int PhaseRange = 0;
	int cmp_status = 0;
	int cmp_sel = 0;
	//	int timeout;
	//	int lock_status;
	uint8_t phase_mux = 0;
	uint8_t delay_time = 0;
	int debug_var;
	uint8_t mmcm_cfg_status = 0;
	/* State machine for VCTCXO tuning */
	typedef enum state
	{
		PHASE_MIN_0,
		PHASE_MIN_1,
		PHASE_MIN_2,
		PHASE_MAX,
		PHASE_DONE0,
		PHASE_DONE,
		DO_NOTHING
	} state_t;

	state_t phase_state = PHASE_MIN_0;

	// Read
	wr_buf[0] = 0x00; // Command and Address
	wr_buf[1] = 0x23; // Command and Address

	XSpi_SetSlaveSelect(&Spi0, SPI0_FPGA_SS);
	XSpi_Transfer(&Spi0, wr_buf, rd_buf, 4);

	// Get PLL index
	pll_ind = PLL_IND(rd_buf[3]);					  //(rd_buf[0] >> 3) & 0x3F;
	XGpio_DiscreteWrite(&extm_0_axi_sel, 1, pll_ind); // Select PLL AXI slave
	RdPLLCFG(&pll_cfg);
	UpdateMMCM_Config(&pll_cfg);
	mmcm_cfg_status = StartMMCM_Reconfig_DRP();
	// Execute soft reset to CFG take effect if PLL looses lock
	Xil_Out16(XPAR_EXTM_0_AXI_BASEADDR, 0x000A);

	if (mmcm_cfg_status !=PLLCFG_DONE) {
		return PHCFG_ERROR;
	}

	uint16_t max_phase = pll_cfg.CLKOUT1_DIVIDE * 8; // 46*8;//
	//	uint16_t max_phase = 46*8;//

	//debug
	if (pll_ind == 0) {
		debug_var = 0;
	}

	if (pll_ind==1) {
		debug_var = 1;
	}

	for (int i = 0; i < max_phase; i++)
	{
		phase_mux = (i & 0x7);
		delay_time = i >> 3;
		SetPhase_DRP(phase_mux, delay_time, 0x30C, 0x310, 1);
		StartMMCM_Reconfig_DRP();

		cmp_status = CheckSamples(cmp_sel);

		switch (phase_state)
		{
		case PHASE_MIN_0:
			if (cmp_status == 0x01)
			{
				phase_state = PHASE_MIN_1;
				PhaseMin = i;
			}
			break;

		case PHASE_MIN_1:
			if (cmp_status == 0x01)
			{
				phase_state = PHASE_MIN_2;
				PhaseMin = i;
			}
			else if (cmp_status == 0x03) {
				phase_state = PHASE_MIN_0;
			}
			break;

		case PHASE_MIN_2:
			if (cmp_status == 0x01)
			{
				phase_state = PHASE_MAX;
				PhaseMin = i;
			}
			else if (cmp_status == 0x03) {
				phase_state = PHASE_MIN_0;
			}
			break;

		case PHASE_MAX:
			if ((cmp_status == 0x03) || (i >= max_phase-1))
			{
				PhaseMax = i;
				PhaseMiddle = PhaseMin + ((PhaseMax - PhaseMin) / 2);
				phase_state = PHASE_DONE0;
				//debug
				if (pll_ind == 0) {
					debug_var = 0;
				}
			}
			break;

		case PHASE_DONE0:
			if (i==max_phase-1){
				phase_state = PHASE_DONE;
			}
			break;

		case PHASE_DONE:
			break;

		default:
			break;
		}

		if (phase_state != PHASE_DONE)
		{
			XGpio_DiscreteWrite(&smpl_cmp_en, 1, 0x00);
			do
			{
				cmp_status = XGpio_DiscreteRead(&smpl_cmp_status, 1);
			} while ((cmp_status & 0x01) != 0);
		}

		else
		{
			XGpio_DiscreteWrite(&smpl_cmp_en, 1, 0x00);
			do
			{
				cmp_status = XGpio_DiscreteRead(&smpl_cmp_status, 1);
			} while ((cmp_status & 0x01) != 0);
			phase_mux = (PhaseMiddle & 0x7);
			delay_time = PhaseMiddle >> 3;
			SetPhase_DRP(phase_mux, delay_time, 0x30C, 0x310, 1);
			StartMMCM_Reconfig_DRP();

			return PHCFG_DONE;
			break;
		}
	}

	return PHCFG_ERROR;
}

int main()
{
	int PAGE_SIZE = 256; // page size
	u8 page_buffer[256]; // page buffer
	u16 page_buffer_cnt; // how many bytes are present in buffer
	u8 inc_data_count;	 // how much data we got
	u8 data_to_copy;	 // how much data to copy to page buffer (incase of overflow)
	u8 data_leftover;
	u64 total_data = 0; // how much data has been transferred in total (debug value)
	int address;
	int k;

	uint8_t phcfg_start_old, phcfg_start;
	uint8_t pllcfg_start_old, pllcfg_start;
	uint8_t pllrst_start_old, pllrst_start;
	uint8_t phcfg_mode;
	tXPLL_CFG pll_cfg = {0};
	uint16_t phcfgrez;

	//	XClk_Wiz_Config *CfgPtr_Mon;
	//	XClk_Wiz_Config *CfgPtr_Dynamic;

	int spirez;
	uint32_t *dest = (uint32_t *)glEp0Buffer_Tx;
	u8 spi_ReadBuffer[4];

	int flash_page_addr = 0;

	init_platform();


	// initialize XGpio variable
	XGpio_Initialize(&gpio, XPAR_ADC_RESET_GPIO_DEVICE_ID);
	XGpio_Initialize(&gpio_2, XPAR_AXI_GPIO_0_DEVICE_ID);
	XGpio_Initialize(&pll_rst, XPAR_PLL_GPIO_PLL_RST_DEVICE_ID);
	XGpio_Initialize(&pllcfg_cmd, XPAR_PLL_GPIO_PLLCFG_COMMAND_DEVICE_ID);
	XGpio_Initialize(&pllcfg_stat, XPAR_PLL_GPIO_PLLCFG_STATUS_DEVICE_ID);
	XGpio_Initialize(&extm_0_axi_sel, XPAR_PLL_GPIO_PLL_SEL_DEVICE_ID);
	XGpio_Initialize(&smpl_cmp_en, XPAR_SMPL_CMP_GPIO_SMPL_CMP_CMD_DEVICE_ID);
	XGpio_Initialize(&smpl_cmp_status, XPAR_SMPL_CMP_GPIO_SMPL_CMP_STAT_DEVICE_ID);
	XGpio_Initialize(&vctcxo_tamer_ctrl, XPAR_VCTCXO_TAMER_CTRL_DEVICE_ID);

	// I2C Voltage init
	//    XPAR_I2C_CORES_I2C1_BASEADDR
	//    XPAR_I2C_CORES_I2C2_BASEADDR

//    LP8758_WR_REG(XPAR_I2C_CORES_I2C1_BASEADDR,0x0A,0x4D);
//    LP8758_WR_REG(XPAR_I2C_CORES_I2C1_BASEADDR,0x03,0xD2);
//    LP8758_WR_REG(XPAR_I2C_CORES_I2C1_BASEADDR,0x0C,0xFC);
//    LP8758_WR_REG(XPAR_I2C_CORES_I2C1_BASEADDR,0x05,0xD2);
//    LP8758_WR_REG(XPAR_I2C_CORES_I2C1_BASEADDR,0x0E,0x75);
//    LP8758_WR_REG(XPAR_I2C_CORES_I2C1_BASEADDR,0x07,0xD2);
//    LP8758_WR_REG(XPAR_I2C_CORES_I2C1_BASEADDR,0x10,0xB1);
//    LP8758_WR_REG(XPAR_I2C_CORES_I2C1_BASEADDR,0x09,0xD2);

//	LP8758_WR_REG(XPAR_I2C_CORES_I2C1_BASEADDR, 0x02, 0x88);
//	LP8758_WR_REG(XPAR_I2C_CORES_I2C1_BASEADDR, 0x03, 0xD2);
//	LP8758_WR_REG(XPAR_I2C_CORES_I2C1_BASEADDR, 0x04, 0x88);
//	LP8758_WR_REG(XPAR_I2C_CORES_I2C1_BASEADDR, 0x05, 0xD2);
//	LP8758_WR_REG(XPAR_I2C_CORES_I2C1_BASEADDR, 0x06, 0x88);
//	LP8758_WR_REG(XPAR_I2C_CORES_I2C1_BASEADDR, 0x07, 0xD2);
//	LP8758_WR_REG(XPAR_I2C_CORES_I2C1_BASEADDR, 0x08, 0x88);
//	LP8758_WR_REG(XPAR_I2C_CORES_I2C1_BASEADDR, 0x09, 0xD2);

//	LP8758_WR_REG(XPAR_I2C_CORES_I2C1_BASEADDR, 0x0A, 0xA2);
//	LP8758_WR_REG(XPAR_I2C_CORES_I2C1_BASEADDR, 0x0C, 0xFC);
//	LP8758_WR_REG(XPAR_I2C_CORES_I2C1_BASEADDR, 0x0E, 0xAF);
//	LP8758_WR_REG(XPAR_I2C_CORES_I2C1_BASEADDR, 0x10, 0xBE);


	LP8758_WR_REG(XPAR_I2C_CORES_I2C2_BASEADDR, 0x02, 0x88);
	LP8758_WR_REG(XPAR_I2C_CORES_I2C2_BASEADDR, 0x03, 0xD2);
	LP8758_WR_REG(XPAR_I2C_CORES_I2C2_BASEADDR, 0x04, 0x88);
	LP8758_WR_REG(XPAR_I2C_CORES_I2C2_BASEADDR, 0x05, 0xD2);
	LP8758_WR_REG(XPAR_I2C_CORES_I2C2_BASEADDR, 0x06, 0x88);
	LP8758_WR_REG(XPAR_I2C_CORES_I2C2_BASEADDR, 0x07, 0xD2);
	LP8758_WR_REG(XPAR_I2C_CORES_I2C2_BASEADDR, 0x08, 0x88);
	LP8758_WR_REG(XPAR_I2C_CORES_I2C2_BASEADDR, 0x09, 0xD2);

	LP8758_WR_REG(XPAR_I2C_CORES_I2C2_BASEADDR, 0x0A, 0x4D); //Output 0 1V
	LP8758_WR_REG(XPAR_I2C_CORES_I2C2_BASEADDR, 0x0C, 0x9F); //Output 1 1.44V (1.45V requested)
//	LP8758_WR_REG(XPAR_I2C_CORES_I2C2_BASEADDR, 0x0C, 0xA0); //Output 1 1.46V (1.45V requested)
	LP8758_WR_REG(XPAR_I2C_CORES_I2C2_BASEADDR, 0x0E, 0x75); //Output 2 1.2V
	LP8758_WR_REG(XPAR_I2C_CORES_I2C2_BASEADDR, 0x10, 0xB1); //Output 3 1.8V

	LP8758_WR_REG(XPAR_I2C_CORES_I2C2_BASEADDR, 0x1A, 0xFF);


	uint8_t regvals2[1];
    //Waste time to make sure voltage regulator is done settling
    //TODO:: use something else to create a delay
    for (uint8_t i = 1; i<=35; i++)
    {
    	LP8758_RD_REG(XPAR_I2C_CORES_I2C2_BASEADDR,i,&regvals2[0]);
    }

    // Enable LDO
    XGpio_DiscreteWrite(&gpio_2, 1, 0x01);
    

	// Init flash SPI
	Init_flash_qspi(QSPI_DEVICE_ID, &CFG_QSPI, XSP_MASTER_OPTION | XSP_MANUAL_SSELECT_OPTION);

	// Write config to DAC
//	i2c_buf[0] = 0x04; // cmd
//	i2c_buf[1] = 0x01; // msb data
//	i2c_buf[2] = 0x01; // lsb data
//	XIic_Send(XPAR_I2C_CORES_I2C1_BASEADDR, I2C_DAC_ADDR, i2c_buf, 3, XIIC_STOP);
    uint8_t i2c_buf[3];
	// Write DAC value stored in flash storage only if it isn't default (0xFFFF)
    /* There is no DAC in this board
	FlashQspi_ReadPage(&CFG_QSPI, mem_write_offset, page_buffer);
	i2c_buf[0] = 0x30; // cmd
	i2c_buf[1] = page_buffer[1];
	i2c_buf[2] = page_buffer[0];
	if (!(i2c_buf[1] == 0xFF && i2c_buf[2] == 0xFF))
		XIic_Send(XPAR_I2C_CORES_I2C1_BASEADDR, I2C_DAC_ADDR, i2c_buf, 3, XIIC_STOP);
	*/

	// Initialize variables to detect PLL phase change and PLL config update request
	phcfg_start_old = 0;
	phcfg_start = 0;
	pllcfg_start_old = 0;
	pllcfg_start = 0;
	pllrst_start_old = 0;
	pllrst_start = 0;

	Init_SPI(SPI0_DEVICE_ID, &Spi0, XSP_MASTER_OPTION | XSP_MANUAL_SSELECT_OPTION);

	// Default config

	// pllcfgrez = AutoUpdatePHCFG();

	RdPLLCFG(&pll_cfg);
	// pllcfgrez = UpdatePLLCFG();

	while (1)
	{


		// Check if there is a request for PLL phase update
		if ((phcfg_start_old == 0) && (phcfg_start != 0))
		{
			phcfg_mode = (XGpio_DiscreteRead(&pllcfg_cmd, 1) & 0x08) >> 3;
			if (phcfg_mode)
			{
				phcfgrez = AutoUpdatePHCFG_DRP();
			}
			else
			{
				phcfgrez = 0x01;
			};

			XGpio_DiscreteWrite(&pllcfg_stat, 1, (phcfgrez << 10) | PLLCFG_DONE);
		}

		// Check if there is a request for PLL configuration update
		if ((pllcfg_start_old == 0) && (pllcfg_start != 0))
		{
			// nothing happens TODO: implement something or remove this
			XGpio_DiscreteWrite(&pllcfg_stat, 1, PLLCFG_BUSY);
			XGpio_DiscreteWrite(&pllcfg_stat, 1, PLLCFG_DONE);
		}

		// Check if there is a request for PLL configuration update
		if ((pllrst_start_old == 0) && (pllrst_start != 0))
		{
			// nothing happens TODO: implement something or remove this
			XGpio_DiscreteWrite(&pllcfg_stat, 1, PLLCFG_DONE);
		}

		// Update PLL configuration command status
		pllrst_start_old = pllrst_start;
		pllrst_start = (XGpio_DiscreteRead(&pllcfg_cmd, 1) & 0x04) >> 2;
		phcfg_start_old = phcfg_start;
		phcfg_start = (XGpio_DiscreteRead(&pllcfg_cmd, 1) & 0x02) >> 1;
		pllcfg_start_old = pllcfg_start;
		pllcfg_start = XGpio_DiscreteRead(&pllcfg_cmd, 1) & 0x01;

		// Read FIFO Status
		spirez = AXI_TO_NATIVE_FIFO_mReadReg(XPAR_AXI_TO_NATIVE_FIFO_0_S00_AXI_BASEADDR, AXI_TO_NATIVE_FIFO_S00_AXI_SLV_REG2_OFFSET);

		if (!(spirez & 0x01))
		{
			// Toggle FIFO reset
			AXI_TO_NATIVE_FIFO_mWriteReg(XPAR_AXI_TO_NATIVE_FIFO_0_S00_AXI_BASEADDR, AXI_TO_NATIVE_FIFO_S00_AXI_SLV_REG3_OFFSET, 0x01);
			AXI_TO_NATIVE_FIFO_mWriteReg(XPAR_AXI_TO_NATIVE_FIFO_0_S00_AXI_BASEADDR, AXI_TO_NATIVE_FIFO_S00_AXI_SLV_REG3_OFFSET, 0x00);

			getFifoData(glEp0Buffer_Rx, 64);

			memset(glEp0Buffer_Tx, 0, sizeof(glEp0Buffer_Tx)); // fill whole tx buffer with zeros
			cmd_errors = 0;

			LMS_Ctrl_Packet_Tx->Header.Command = LMS_Ctrl_Packet_Rx->Header.Command;
			LMS_Ctrl_Packet_Tx->Header.Data_blocks = LMS_Ctrl_Packet_Rx->Header.Data_blocks;
			LMS_Ctrl_Packet_Tx->Header.Periph_ID = LMS_Ctrl_Packet_Rx->Header.Periph_ID;
			LMS_Ctrl_Packet_Tx->Header.Status = STATUS_BUSY_CMD;

			switch (LMS_Ctrl_Packet_Rx->Header.Command)
			{
			case CMD_GET_INFO:

				LMS_Ctrl_Packet_Tx->Data_field[0] = FW_VER;
				LMS_Ctrl_Packet_Tx->Data_field[1] = DEV_TYPE;
				LMS_Ctrl_Packet_Tx->Data_field[2] = LMS_PROTOCOL_VER;
				LMS_Ctrl_Packet_Tx->Data_field[3] = HW_VER;
				LMS_Ctrl_Packet_Tx->Data_field[4] = EXP_BOARD;

				LMS_Ctrl_Packet_Tx->Header.Status = STATUS_COMPLETED_CMD;
				break;

				// COMMAND LMS RESET

			case CMD_LMS_RST:

				if (!Check_Periph_ID(MAX_ID_LMS7, LMS_Ctrl_Packet_Rx->Header.Periph_ID))
					break;

				// Store memory map address in buffer
				temp_buffer0[0] = MEMORY_MAP_REG_MSB;
				temp_buffer0[1] = MEMORY_MAP_REG_LSB;
				// Read current memory map value (for restoring it later)
				// The current value is stored in temp_buffer1[3-4]
				Board_SPI_Read(temp_buffer0, temp_buffer1, &Spi0, SPI0_FPGA_SS);

				switch (LMS_Ctrl_Packet_Rx->Header.Periph_ID)
				{
					// Set memory map value
					// temp_buffer0 still contains the memory map address
				case 0:
					temp_buffer0[3] = 1;
					break;
				case 1:
					temp_buffer0[3] = 2;
					break;
				case 2:
					temp_buffer0[3] = 4;
					break;
				default:
					cmd_errors++;
					break;
				}
				// Write new memory map value
				Board_SPI_Write(temp_buffer0, &Spi0, SPI0_FPGA_SS);
				// Do the reset
				switch (LMS_Ctrl_Packet_Rx->Data_field[0])
				{
				case LMS_RST_DEACTIVATE:
					Modify_BRDSPI16_Reg_bits(BRD_SPI_REG_LMS1_LMS2_CTRL, LMS1_RESET, LMS1_RESET, 1); // high level
					break;
				case LMS_RST_ACTIVATE:
					Modify_BRDSPI16_Reg_bits(BRD_SPI_REG_LMS1_LMS2_CTRL, LMS1_RESET, LMS1_RESET, 0); // low level
					break;

				case LMS_RST_PULSE:
					Modify_BRDSPI16_Reg_bits(BRD_SPI_REG_LMS1_LMS2_CTRL, LMS1_RESET, LMS1_RESET, 0); // low level
					Modify_BRDSPI16_Reg_bits(BRD_SPI_REG_LMS1_LMS2_CTRL, LMS1_RESET, LMS1_RESET, 1); // high level
					break;
				default:
					cmd_errors++;
					break;
				}
				// Restore old memory map value
				temp_buffer0[2] = temp_buffer1[2];
				temp_buffer0[3] = temp_buffer1[3];

				LMS_Ctrl_Packet_Tx->Header.Status = STATUS_COMPLETED_CMD;
				break;

				// COMMAND LMS WRITE

			case CMD_LMS7002_WR:
				if (!Check_Periph_ID(MAX_ID_LMS7, LMS_Ctrl_Packet_Rx->Header.Periph_ID))
					break;
				if (Check_many_blocks(4))
					break;

				for (block = 0; block < LMS_Ctrl_Packet_Rx->Header.Data_blocks; block++)
				{
					// Write LMS7 register
					sbi(LMS_Ctrl_Packet_Rx->Data_field[0 + (block * 4)], 7); // set write bit
					spirez = XSpi_SetSlaveSelect(&Spi0, SPI0_LMS7002M_1_SS);

					spirez = XSpi_Transfer(&Spi0, &LMS_Ctrl_Packet_Rx->Data_field[0 + (block * 4)], NULL, 4);
				}

				LMS_Ctrl_Packet_Tx->Header.Status = STATUS_COMPLETED_CMD;
				break;

				// COMMAND LMS READ

			case CMD_LMS7002_RD:
				if (Check_many_blocks(4))
					break;

				for (block = 0; block < LMS_Ctrl_Packet_Rx->Header.Data_blocks; block++)
				{
					// Read LMS7 register
					cbi(LMS_Ctrl_Packet_Rx->Data_field[0 + (block * 2)], 7); // clear write bit
					spirez = XSpi_SetSlaveSelect(&Spi0, SPI0_LMS7002M_1_SS);

					spirez = XSpi_Transfer(&Spi0, &LMS_Ctrl_Packet_Rx->Data_field[0 + (block * 2)], spi_ReadBuffer, 4);
					LMS_Ctrl_Packet_Tx->Data_field[2 + (block * 4)] = spi_ReadBuffer[2];
					LMS_Ctrl_Packet_Tx->Data_field[3 + (block * 4)] = spi_ReadBuffer[3];
				}

				LMS_Ctrl_Packet_Tx->Header.Status = STATUS_COMPLETED_CMD;
				break;

				// COMMAND BOARD SPI WRITE

			case CMD_BRDSPI16_WR:
				if (Check_many_blocks(4))
					break;

				for (block = 0; block < LMS_Ctrl_Packet_Rx->Header.Data_blocks; block++)
				{
					// write reg addr
					sbi(LMS_Ctrl_Packet_Rx->Data_field[0 + (block * 4)], 7); // set write bit

					// spirez = alt_avalon_spi_command(FPGA_SPI0_BASE, SPI_NR_FPGA, 4, &LMS_Ctrl_Packet_Rx->Data_field[0 + (block * 4)], 0, NULL, 0);
					spirez = XSpi_SetSlaveSelect(&Spi0, SPI0_FPGA_SS);
					spirez = XSpi_Transfer(&Spi0, &LMS_Ctrl_Packet_Rx->Data_field[0 + (block * 4)], NULL, 4);
				}

				LMS_Ctrl_Packet_Tx->Header.Status = STATUS_COMPLETED_CMD;
				break;

				// COMMAND BOARD SPI READ

			case CMD_BRDSPI16_RD:
				if (Check_many_blocks(4))
					break;

				for (block = 0; block < LMS_Ctrl_Packet_Rx->Header.Data_blocks; block++)
				{

					// write reg addr
					cbi(LMS_Ctrl_Packet_Rx->Data_field[0 + (block * 2)], 7); // clear write bit

					spirez = XSpi_SetSlaveSelect(&Spi0, SPI0_FPGA_SS);

					spirez = XSpi_Transfer(&Spi0, &LMS_Ctrl_Packet_Rx->Data_field[0 + (block * 2)], spi_ReadBuffer, 4);
					LMS_Ctrl_Packet_Tx->Data_field[2 + (block * 4)] = spi_ReadBuffer[2];
					LMS_Ctrl_Packet_Tx->Data_field[3 + (block * 4)] = spi_ReadBuffer[3];
				}

				LMS_Ctrl_Packet_Tx->Header.Status = STATUS_COMPLETED_CMD;
				break;

			case CMD_ALTERA_FPGA_GW_WR: // FPGA active serial

				current_portion = (LMS_Ctrl_Packet_Rx->Data_field[1] << 24) | (LMS_Ctrl_Packet_Rx->Data_field[2] << 16) | (LMS_Ctrl_Packet_Rx->Data_field[3] << 8) | (LMS_Ctrl_Packet_Rx->Data_field[4]);
				data_cnt = LMS_Ctrl_Packet_Rx->Data_field[5];

				switch (LMS_Ctrl_Packet_Rx->Data_field[0]) // prog_mode
				{
					/*
					Programming mode:
					0 - Bitstream to FPGA
					1 - Bitstream to Flash
					2 - Bitstream from FLASH
					*/
					// TODO: Add return value checks

				case 1: // write data to Flash from PC
					// Reset spirez
					spirez = 0;
					// Start of programming? reset variables
					if (current_portion == 0)
					{
						address = 0;
						page_buffer_cnt = 0;
						total_data = 0;
						// Erase firt sector
						spirez = spirez || FlashQspi_EraseSector(&CFG_QSPI, 0);
					}

					inc_data_count = LMS_Ctrl_Packet_Rx->Data_field[5];

					// Check if final packet
					if (inc_data_count == 0)
					{ // Flush letftover data, if any
						if (page_buffer_cnt > 0)
						{
							// Fill unused page data with 1 (no write)
							memset(&page_buffer[page_buffer_cnt], 0xFF, PAGE_SIZE - page_buffer_cnt);
							spirez = spirez || FlashQspi_ProgramPage(&CFG_QSPI, address, page_buffer);
						}
					}
					else
					{
						if (PAGE_SIZE < (inc_data_count + page_buffer_cnt))
						{ // Incoming data would overflow the page buffer
							// Calculate ammount of data to copy
							data_to_copy = PAGE_SIZE - page_buffer_cnt;
							data_leftover = page_buffer_cnt - data_to_copy;
							memcpy(&page_buffer[page_buffer_cnt], &LMS_Ctrl_Packet_Rx->Data_field[24], data_to_copy);
							// We already know the page is full because of overflowing input
							spirez = spirez || FlashQspi_ProgramPage(&CFG_QSPI, address, page_buffer);
							address += 256;
							total_data += 256;
							// Check if new address is bottom of sector, erase if needed
							if ((address & 0xFFF) == 0)
								spirez = spirez || FlashQspi_EraseSector(&CFG_QSPI, address);
							memcpy(&page_buffer[0], &LMS_Ctrl_Packet_Rx->Data_field[24 + data_to_copy], data_leftover);
							page_buffer_cnt = data_leftover;
						}
						else
						{ // Incoming data would not overflow the page buffer
							memcpy(&page_buffer[page_buffer_cnt], &LMS_Ctrl_Packet_Rx->Data_field[24], inc_data_count);
							page_buffer_cnt += inc_data_count;
							if (page_buffer_cnt == PAGE_SIZE)
							{
								spirez = spirez || FlashQspi_ProgramPage(&CFG_QSPI, address, page_buffer);
								page_buffer_cnt = 0;
								address += 256;
								total_data += 256;
								// Check if new address is bottom of sector, erase if needed
								if ((address & 0xFFF) == 0)
									spirez = spirez || FlashQspi_EraseSector(&CFG_QSPI, address);
							}
						}
					}
					if (spirez == XST_SUCCESS)
					{
						LMS_Ctrl_Packet_Tx->Header.Status = STATUS_COMPLETED_CMD;
					}
					else
					{
						LMS_Ctrl_Packet_Tx->Header.Status = STATUS_ERROR_CMD;
					}
					break;

				default:
					LMS_Ctrl_Packet_Tx->Header.Status = STATUS_ERROR_CMD;
					break;
				}

				break;

				// COMMAND ANALOG VALUE READ

			case CMD_ANALOG_VAL_RD:

				for (block = 0; block < LMS_Ctrl_Packet_Rx->Header.Data_blocks; block++)
				{
					switch (LMS_Ctrl_Packet_Rx->Data_field[0 + (block)]) // ch
					{
					/*
					case 0:				   // dac val
						XIic_Recv(XPAR_I2C_CORES_I2C1_BASEADDR, I2C_DAC_ADDR, i2c_buf, 2, XIIC_STOP);
						LMS_Ctrl_Packet_Tx->Data_field[0 + (block * 4)] = LMS_Ctrl_Packet_Rx->Data_field[block]; // ch
						LMS_Ctrl_Packet_Tx->Data_field[1 + (block * 4)] = 0x00;									 // RAW //unit, power
						LMS_Ctrl_Packet_Tx->Data_field[2 + (block * 4)] = i2c_buf[0];							 // unsigned val, MSB byte
						LMS_Ctrl_Packet_Tx->Data_field[3 + (block * 4)] = i2c_buf[1];							 // unsigned val, LSB byte

						break;

					case 1: // temperature
						i2c_buf[0] = 1;
						i2c_buf[1] = 0x25;
						i2c_buf[2] = 0x10;
						XIic_Send(XPAR_I2C_CORES_I2C1_BASEADDR,I2C_TERMO_ADDR,i2c_buf,3,XIIC_STOP);
						int b = 0;
						do
						{	//Check if conversion is complete
							b++;
							XIic_Recv(XPAR_I2C_CORES_I2C1_BASEADDR,I2C_TERMO_ADDR,i2c_buf,2,XIIC_STOP);
						} while ((i2c_buf[0] & 0x3) == 0);
						i2c_buf[0]=0;
						XIic_Send(XPAR_I2C_CORES_I2C1_BASEADDR,I2C_TERMO_ADDR,i2c_buf,1,XIIC_STOP);
						XIic_Recv(XPAR_I2C_CORES_I2C1_BASEADDR,I2C_TERMO_ADDR,i2c_buf,2,XIIC_STOP);

						LMS_Ctrl_Packet_Tx->Data_field[0 + (block * 4)] = LMS_Ctrl_Packet_Rx->Data_field[block]; //ch
						LMS_Ctrl_Packet_Tx->Data_field[1 + (block * 4)] = 0x50; //0.1C //unit, power

						int16_t converted_value = i2c_buf[1] | (i2c_buf[0] << 8);
						converted_value = converted_value >> 4;
						converted_value = converted_value * 10;
						converted_value = converted_value >> 4;

						LMS_Ctrl_Packet_Tx->Data_field[2 + (block * 4)] = (uint8_t)((converted_value >> 8) & 0xFF);//signed val, MSB byte
						LMS_Ctrl_Packet_Tx->Data_field[3 + (block * 4)] = (uint8_t)(converted_value & 0xFF);//signed val, LSB byte

						break;
						*/


					default:
						cmd_errors++;
						break;
					}
				}

				if (cmd_errors)
					LMS_Ctrl_Packet_Tx->Header.Status = STATUS_ERROR_CMD;
				else
					LMS_Ctrl_Packet_Tx->Header.Status = STATUS_COMPLETED_CMD;
				break;

				// COMMAND ANALOG VALUE WRITE

			case CMD_ANALOG_VAL_WR:
				if (Check_many_blocks(4))
					break;

				for (block = 0; block < LMS_Ctrl_Packet_Rx->Header.Data_blocks; block++)
				{
					switch (LMS_Ctrl_Packet_Rx->Data_field[0 + (block * 4)]) // do something according to channel
					{
					/*
					case 0:														  // TCXO DAC
						if (LMS_Ctrl_Packet_Rx->Data_field[1 + (block * 4)] == 0) // RAW units?
						{
							i2c_buf[0] = 0x30;											  // addr
							i2c_buf[1] = LMS_Ctrl_Packet_Rx->Data_field[2 + (block * 4)]; // MSB
							i2c_buf[2] = LMS_Ctrl_Packet_Rx->Data_field[3 + (block * 4)]; // LSB
							XIic_Send(XPAR_I2C_CORES_I2C1_BASEADDR, I2C_DAC_ADDR, i2c_buf, 3, XIIC_STOP);
						}
						else
							cmd_errors++;
						break;
					*/
					default:
						cmd_errors++;
						break;
					}
				}
				if (cmd_errors)
					LMS_Ctrl_Packet_Tx->Header.Status = STATUS_ERROR_CMD;
				else
					LMS_Ctrl_Packet_Tx->Header.Status = STATUS_COMPLETED_CMD;
				break;


			case CMD_MEMORY_WR:
				// Since the XTRX board does not have an eeprom to store permanent VCTCXO DAC value
				// a workaround is implemented that uses a sufficiently high address in the configuration flash
				// to store the DAC value
				// Since to write data to a flash, a whole sector needs to be erased, additional checks are included
				// to make sure this function is used ONLY to store VCTCXO DAC value
				// Reset spirez
				spirez = 0;
				data_cnt = LMS_Ctrl_Packet_Rx->Data_field[5];

				if ((LMS_Ctrl_Packet_Rx->Data_field[10] == 0) && (LMS_Ctrl_Packet_Rx->Data_field[11] == 3)) // TARGET = 3 (EEPROM)
				{
					// Since the XTRX board does not have an eeprom to store permanent VCTCXO DAC value
					// a workaround is implemented that uses a sufficiently high address in the configuration flash
					// to store the DAC value
					// Since to write data to a flash, a whole sector needs to be erased, additional checks are included
					// to make sure this function is used ONLY to store VCTCXO DAC value

					// Check if the user is trying to store VCTCXO DAC value, return error otherwise
					if (data_cnt == 2 && LMS_Ctrl_Packet_Rx->Data_field[8] == 0 && LMS_Ctrl_Packet_Rx->Data_field[9] == 16)
					{
						if (LMS_Ctrl_Packet_Rx->Data_field[0] == 0) // write data to EEPROM #1
						{
							LMS_Ctrl_Packet_Rx->Data_field[22] = LMS_Ctrl_Packet_Rx->Data_field[8];
							LMS_Ctrl_Packet_Rx->Data_field[23] = LMS_Ctrl_Packet_Rx->Data_field[9];
							spirez = spirez || FlashQspi_EraseSector(&CFG_QSPI, mem_write_offset);
							page_buffer[0] = LMS_Ctrl_Packet_Rx->Data_field[24];
							page_buffer[1] = LMS_Ctrl_Packet_Rx->Data_field[25];
							spirez = spirez || FlashQspi_ProgramPage(&CFG_QSPI, mem_write_offset, page_buffer);
							cmd_errors = cmd_errors + spirez;

							if (cmd_errors)
								LMS_Ctrl_Packet_Tx->Header.Status = STATUS_ERROR_CMD;
							else
								LMS_Ctrl_Packet_Tx->Header.Status = STATUS_COMPLETED_CMD;
						}
						else
							LMS_Ctrl_Packet_Tx->Header.Status = STATUS_ERROR_CMD;
					}
					else
						LMS_Ctrl_Packet_Tx->Header.Status = STATUS_ERROR_CMD;

				}
				else if ((LMS_Ctrl_Packet_Rx->Data_field[10] == 0) && (LMS_Ctrl_Packet_Rx->Data_field[11] == 2)) // TARGET = 2 (FPGA FLASH)
				{
					flash_page_addr = 	(LMS_Ctrl_Packet_Rx->Data_field[6] << 24) 	|
										(LMS_Ctrl_Packet_Rx->Data_field[7] << 16) 	|
										(LMS_Ctrl_Packet_Rx->Data_field[8] << 8) 	|
										(LMS_Ctrl_Packet_Rx->Data_field[9]);
					// Check if the user is trying to access USER sector in FLASH memory, return error otherwise
					if ( (flash_page_addr >= FLASH_USER_SECTOR_START_ADDR) && (flash_page_addr <= FLASH_USER_SECTOR_END_ADDR))
					{
						if (LMS_Ctrl_Packet_Rx->Data_field[0] == 0) // write data to FLASH
						{
							LMS_Ctrl_Packet_Rx->Data_field[22] = LMS_Ctrl_Packet_Rx->Data_field[8];
							LMS_Ctrl_Packet_Rx->Data_field[23] = LMS_Ctrl_Packet_Rx->Data_field[9];
							spirez = spirez || FlashQspi_EraseSector(&CFG_QSPI, FLASH_USER_SECTOR_START_ADDR);

							for (k=0; k<data_cnt; k++) {
								page_buffer[k] = LMS_Ctrl_Packet_Rx->Data_field[24+k];
							}

							spirez = spirez || FlashQspi_ProgramPage(&CFG_QSPI, FLASH_USER_SECTOR_START_ADDR, page_buffer);
							cmd_errors = cmd_errors + spirez;

							if (cmd_errors)
								LMS_Ctrl_Packet_Tx->Header.Status = STATUS_ERROR_CMD;
							else
								LMS_Ctrl_Packet_Tx->Header.Status = STATUS_COMPLETED_CMD;
						}
						else
							LMS_Ctrl_Packet_Tx->Header.Status = STATUS_ERROR_CMD;
					}
					else
						LMS_Ctrl_Packet_Tx->Header.Status = STATUS_ERROR_CMD;
				}
				else
					LMS_Ctrl_Packet_Tx->Header.Status = STATUS_ERROR_CMD;

				break;



			case CMD_MEMORY_RD:
				// Since the XTRX board does not have an eeprom to store permanent VCTCXO DAC value
				// a workaround is implemented that uses a sufficiently high address in the configuration flash
				// to store the DAC value
				// Since to write data to a flash, a whole sector needs to be erased, additional checks are included
				// to make sure this function is used ONLY to store VCTCXO DAC value
				// Reset spirez
				spirez = 0;
				data_cnt = LMS_Ctrl_Packet_Rx->Data_field[5];

				if ((LMS_Ctrl_Packet_Rx->Data_field[10] == 0) && (LMS_Ctrl_Packet_Rx->Data_field[11] == 3)) /// TARGET = 3 (EEPROM)
				{
					if (data_cnt == 2 || LMS_Ctrl_Packet_Rx->Data_field[8] == 0 || LMS_Ctrl_Packet_Rx->Data_field[9] == 16)
					{
						if (LMS_Ctrl_Packet_Rx->Data_field[0] == 0) // read data from EEPROM #1
						{
							spirez = spirez || FlashQspi_ReadPage(&CFG_QSPI, mem_write_offset, page_buffer);
							glEp0Buffer_Tx[32] = page_buffer[0];
							glEp0Buffer_Tx[33] = page_buffer[1];

							if (spirez)
								LMS_Ctrl_Packet_Tx->Header.Status = STATUS_ERROR_CMD;
							else
								LMS_Ctrl_Packet_Tx->Header.Status = STATUS_COMPLETED_CMD;
						}
						else
							LMS_Ctrl_Packet_Tx->Header.Status = STATUS_ERROR_CMD;
					}
					else
						LMS_Ctrl_Packet_Tx->Header.Status = STATUS_ERROR_CMD;
				}
				else if ((LMS_Ctrl_Packet_Rx->Data_field[10] == 0) && (LMS_Ctrl_Packet_Rx->Data_field[11] == 2)) // TARGET = 1 (FPGA FLASH)
				{
					flash_page_addr = 	(LMS_Ctrl_Packet_Rx->Data_field[6] << 24) 	|
										(LMS_Ctrl_Packet_Rx->Data_field[7] << 16) 	|
										(LMS_Ctrl_Packet_Rx->Data_field[8] << 8) 	|
										(LMS_Ctrl_Packet_Rx->Data_field[9]);
					// Check if the user is trying to access USER sector in FLASH memory, return error otherwise
					if ( (flash_page_addr >= FLASH_USER_SECTOR_START_ADDR) && (flash_page_addr <= FLASH_USER_SECTOR_END_ADDR))
					{
						if (LMS_Ctrl_Packet_Rx->Data_field[0] == 0) // read data from FLASH
						{
							spirez = spirez || FlashQspi_ReadPage(&CFG_QSPI, FLASH_USER_SECTOR_START_ADDR, page_buffer);

							for (k=0; k<data_cnt; k++) {
								LMS_Ctrl_Packet_Tx->Data_field[24+k] = page_buffer[k];
							}

							if (spirez)
								LMS_Ctrl_Packet_Tx->Header.Status = STATUS_ERROR_CMD;
							else
								LMS_Ctrl_Packet_Tx->Header.Status = STATUS_COMPLETED_CMD;
						}
						else
							LMS_Ctrl_Packet_Tx->Header.Status = STATUS_ERROR_CMD;
					}
				}
				else
					LMS_Ctrl_Packet_Tx->Header.Status = STATUS_ERROR_CMD;

				break;

			default:
				/* This is unknown request. */
				// isHandled = CyFalse;
				LMS_Ctrl_Packet_Tx->Header.Status = STATUS_UNKNOWN_CMD;
				break;
			};

			// Send response to the command
			for (int i = 0; i < 64 / sizeof(uint32_t); ++i)
			{
				AXI_TO_NATIVE_FIFO_mWriteReg(XPAR_AXI_TO_NATIVE_FIFO_0_S00_AXI_BASEADDR, AXI_TO_NATIVE_FIFO_S00_AXI_SLV_REG0_OFFSET, dest[i]);
			}
		}
	}

	// print("Hello World\n\r");

	cleanup_platform();
	return 0;
}
