/*
 * pll_rcfg.h
 *
 *  Created on: Mar 25, 2016
 *      Author: zydrunas
 */

#ifndef PLL_RCFG_H_
#define PLL_RCFG_H_

//#include "alt_types.h"
//#include "io.h"
#include <stdint.h>
#include <string.h>

/* Multiply Reconfig Register with 4 when you use IOWR_32DIRECT*/
#define MODE      		0x00//
#define STATUS    		0x04
#define START     		0x08
#define N_COUNTER 		0x0C//
#define M_COUNTER 		0x10//
#define C_COUNTER 		0x14//
#define DPS_COUNTER		0x18
#define FRAC_COUNTER 	0x1C//
#define BS_COUNTER		0x20//
#define CPS_COUNTER		0x24//
#define VCO_DIV			0x70//
#define C0_COUNTER 		0x28
#define C1_COUNTER 		0x2C
#define C2_COUNTER 		0x30
#define C3_COUNTER 		0x34
#define C4_COUNTER 		0x38
#define C5_COUNTER 		0x3C

/* Xilinx Clock Configuration Registers*/
#define XIL_CCR_RESET 		0x000	// Software Reset Register (SRR)
#define XIL_CCR_STATUS 		0x004	// Status Register (SR)
#define XIL_CCR_CM_STATUS 	0x008	// Clock Monitor Error Status Register
#define XIL_CCR_INT			0x00C   // Interrupt Status
#define XIL_CCR_INT_EN		0x010   // Interrupt Enable
#define XIL_CCR_0			0x200   // Clock Configuration Register 0
#define XIL_CCR_1			0x204   // Clock Configuration Register 1
#define XIL_CCR_2			0x208   // Clock Configuration Register 2
#define XIL_CCR_3			0x20C   // Clock Configuration Register 3
#define XIL_CCR_4			0x210   // Clock Configuration Register 4
#define XIL_CCR_5			0x214   // Clock Configuration Register 5
#define XIL_CCR_6			0x218   // Clock Configuration Register 6
#define XIL_CCR_7			0x21C   // Clock Configuration Register 7
#define XIL_CCR_8			0x220   // Clock Configuration Register 8
#define XIL_CCR_9			0x224   // Clock Configuration Register 9
#define XIL_CCR_10			0x228   // Clock Configuration Register 10
#define XIL_CCR_11			0x22C   // Clock Configuration Register 11
#define XIL_CCR_12			0x230   // Clock Configuration Register 12
#define XIL_CCR_13			0x234   // Clock Configuration Register 13
#define XIL_CCR_14			0x238   // Clock Configuration Register 14
#define XIL_CCR_15			0x23C   // Clock Configuration Register 15
#define XIL_CCR_16			0x240   // Clock Configuration Register 16
#define XIL_CCR_17			0x244   // Clock Configuration Register 17
#define XIL_CCR_18			0x248   // Clock Configuration Register 18
#define XIL_CCR_19			0x24C   // Clock Configuration Register 19
#define XIL_CCR_20			0x250   // Clock Configuration Register 20
#define XIL_CCR_21			0x254   // Clock Configuration Register 21
#define XIL_CCR_22			0x258   // Clock Configuration Register 22
#define XIL_CCR_23			0x25C   // Clock Configuration Register 23


/* Xilinx DPR Configuration Register */
#define POWER 			0x0300
#define CLKOUT0_REG1	0x0304
#define CLKOUT0_REG2	0x0308
#define CLKOUT1_REG1	0x030C
#define CLKOUT1_REG2	0x0310
#define CLKOUT2_REG1	0x0314
#define CLKOUT2_REG2	0x0318
#define CLKOUT3_REG1	0x031C
#define CLKOUT3_REG2	0x0320
#define CLKOUT4_REG1	0x0324
#define CLKOUT4_REG2	0x0328
#define CLKOUT5_REG1	0x032C
#define CLKOUT5_REG2	0x0330
#define CLKOUT6_REG1	0x0334
#define CLKOUT6_REG2	0x0338
#define DIVCLK			0x033C
#define CLKFBOUT_REG1	0x0340
#define CLKFBOUT_REG2	0x0344
#define LOCK_REG1		0x0348
#define LOCK_REG2		0x034C
#define LOCK_REG3		0x0350
#define FILTER_REG1		0x0354
#define FILTER_REG2		0x0358
#define CLK_CONFIG		0x035C




// PLL configuration status defines
#define PLLCFG_DONE 1
#define PLLCFG_BUSY 2
#define PHCFG_DONE 	0x01
#define PHCFG_ERROR 0x03

// PLL configuration error codes
#define PLLCFG_NOERR 0x00
#define PLLCFG_TIMEOUT 100000
#define PLLCFG_PLL_TIMEOUT 0x09
#define PLLCFG_CX_TIMEOUT 0x0A
#define PLLCFG_PH_TIMEOUT 0x0B

// Get values according to the PLL SPI memory map
#define PLL_IND(lsb) ((lsb >> 3) & 0x1F)
#define PH_DIR(msb) ((msb >> 5) & 0x01)
#define CX_IND(msb) (msb & 0x1F)
#define CX_PHASE(msb, lsb) ((msb << 8) | lsb)
#define N_CNT_DIVBYP(lsb) ((lsb & 0x03) << 16)
#define M_CNT_DIVBYP(lsb) ((lsb & 0x0C) << 14)
#define N_CNT(msb, lsb) ((msb << 8) | lsb)
#define M_CNT(msb, lsb) ((msb << 8) | lsb)
#define MFRAC_CNT_LSB(msb, lsb) ((msb << 8) | lsb)
#define MFRAC_CNT_MSB(msb, lsb) (((msb << 8) | lsb) << 16)
#define BS_CNT(msb) ((msb >> 3) & 0x0F)
#define CPS_CNT(msb) (msb & 0x07)
#define VCO_DIVSEL(lsb) ((lsb >> 7) & 0x01)
#define CX_DIVBYP(msb, lsb) ((msb << 8) | lsb)
#define C_CNT(msb, lsb) ((msb << 8) | lsb)

	typedef struct
	{
		uint32_t M_cnt;
		uint32_t MFrac_cnt;
		uint32_t N_cnt;
		uint32_t C_cnt;
		uint32_t DPS_cnt;
		uint32_t BS_cnt;
		uint32_t CPS_cnt;
		uint32_t VCO_div;
	} tPLL_CFG;

	typedef struct
	{
		uint32_t DIVCLK_DIVIDE;
		uint32_t CLKFBOUT_MULT;
		uint32_t CLKFBOUT_FRAC;
		uint32_t CLKFBOUT_PHASE;

		uint32_t CLKOUT0_DIVIDE;
		uint32_t CLKOUT0_FRAC;
		int32_t CLKOUT0_PHASE;
		uint32_t CLKOUT0_DUTY;

		uint32_t CLKOUT1_DIVIDE;
		uint32_t CLKOUT1_PHASE;
		uint32_t CLKOUT1_DUTY;

		uint32_t CLKOUT2_DIVIDE;
		uint32_t CLKOUT2_PHASE;
		uint32_t CLKOUT2_DUTY;

		uint32_t CLKOUT3_DIVIDE;
		uint32_t CLKOUT3_PHASE;
		uint32_t CLKOUT3_DUTY;

		uint32_t CLKOUT4_DIVIDE;
		uint32_t CLKOUT4_PHASE;
		uint32_t CLKOUT4_DUTY;

		uint32_t CLKOUT5_DIVIDE;
		uint32_t CLKOUT5_PHASE;
		uint32_t CLKOUT5_DUTY;

		uint32_t CLKOUT6_DIVIDE;
		uint32_t CLKOUT6_PHASE;
		uint32_t CLKOUT6_DUTY;

	} tXPLL_CFG;


	// Functions
	void get_pll_config(uint32_t PLL_BASE, tPLL_CFG *pll_cfg);
	uint8_t set_pll_config(uint32_t PLL_BASE, tPLL_CFG *pll_cfg);
	uint8_t set_xpll_config(uint32_t PLL_BASE, tXPLL_CFG *pll_cfg);

	//void set_CxCnt(uint32_t PLL_BASE, uint32_t Cx, uint32_t val);
	uint8_t set_CxCnt(uint32_t PLL_BASE, uint32_t CxVal);

	uint8_t set_Phase(uint32_t PLL_BASE, uint32_t Cx, uint32_t val, uint32_t dir);

	uint8_t start_Reconfig(uint32_t PLL_BASE);
	uint8_t start_XReconfig(uint32_t PLL_BASE);

#endif /* PLL_RCFG_H_ */
