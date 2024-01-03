/*
 * pll_rcfg.c
 *
 *  Created on: Mar 25, 2016
 *      Author: zydrunas
 */

#include "pll_rcfg.h"
#include "xil_io.h"
//#include "system.h"

// Reads main PLL configuration
void get_pll_config(uint32_t PLL_BASE, tPLL_CFG *pll_cfg)
{
	pll_cfg->M_cnt = IORD_32DIRECT(PLL_BASE, M_COUNTER);

	pll_cfg->MFrac_cnt = IORD_32DIRECT(PLL_BASE, FRAC_COUNTER);

	pll_cfg->N_cnt = IORD_32DIRECT(PLL_BASE, N_COUNTER);

	pll_cfg->DPS_cnt = IORD_32DIRECT(PLL_BASE, DPS_COUNTER);

	pll_cfg->BS_cnt = IORD_32DIRECT(PLL_BASE, BS_COUNTER);

	pll_cfg->CPS_cnt = IORD_32DIRECT(PLL_BASE, CPS_COUNTER);

	pll_cfg->VCO_div = IORD_32DIRECT(PLL_BASE, VCO_DIV);
}

// Writes main PLL configuration
uint8_t set_pll_config(uint32_t PLL_BASE, tPLL_CFG *pll_cfg)
{

	//printf(" \n Full Reconfiguration Selected \n");

	//M
	IOWR_32DIRECT(PLL_BASE, M_COUNTER, pll_cfg->M_cnt);

	//MFrac
	IOWR_32DIRECT(PLL_BASE, FRAC_COUNTER, pll_cfg->MFrac_cnt);

	//N
	IOWR_32DIRECT(PLL_BASE, N_COUNTER, pll_cfg->N_cnt);

	//Bandwidth
	//IOWR_32DIRECT(PLL_BASE, BS_COUNTER, pll_cfg->BS_cnt);

	//Charge Pump Setting
	//IOWR_32DIRECT(PLL_BASE, CPS_COUNTER, pll_cfg->CPS_cnt);

	//
	IOWR_32DIRECT(PLL_BASE, VCO_DIV, pll_cfg->VCO_div);


	return PLLCFG_NOERR; //start_Reconfig(PLL_BASE);

	//printf(" \n Full configuration is completed !! Verify with Scope \n");
}

// Writes main Xilinx PLL configuration
uint8_t set_xpll_config(uint32_t PLL_BASE, tXPLL_CFG *pll_cfg)
{
	static uint8_t i=0;
	i++;
	i=i%20;

	// Clock Configuration Register 0
	Xil_Out32(PLL_BASE + XIL_CCR_0, 0x00000000 | pll_cfg->CLKFBOUT_FRAC << 16 | pll_cfg->CLKFBOUT_MULT << 8 | pll_cfg->DIVCLK_DIVIDE );

	// Clock Configuration Register 1
	Xil_Out32(PLL_BASE + XIL_CCR_1, pll_cfg->CLKFBOUT_PHASE);

	// Clock Configuration Register 2,3,4
	Xil_Out32(PLL_BASE + XIL_CCR_2, 0x00000000 | pll_cfg->CLKOUT0_FRAC << 8 | pll_cfg->CLKOUT0_DIVIDE );
	Xil_Out32(PLL_BASE + XIL_CCR_3, pll_cfg->CLKOUT0_PHASE);
	Xil_Out32(PLL_BASE + XIL_CCR_4, pll_cfg->CLKOUT0_DUTY);

	// Clock Configuration Register 5,6,7
	Xil_Out32(PLL_BASE + XIL_CCR_5, 0x00000000 | pll_cfg->CLKOUT1_DIVIDE );
	Xil_Out32(PLL_BASE + XIL_CCR_6, pll_cfg->CLKOUT1_PHASE);
	Xil_Out32(PLL_BASE + XIL_CCR_7, pll_cfg->CLKOUT1_DUTY);

	// Clock Configuration Register 8,9,10
	Xil_Out32(PLL_BASE + XIL_CCR_8, pll_cfg->CLKOUT2_DIVIDE);
	Xil_Out32(PLL_BASE + XIL_CCR_9, pll_cfg->CLKOUT2_PHASE);
	Xil_Out32(PLL_BASE + XIL_CCR_10, pll_cfg->CLKOUT2_DUTY);

	// Clock Configuration Register 11,12,13
	Xil_Out32(PLL_BASE + XIL_CCR_11, pll_cfg->CLKOUT3_DIVIDE);
	Xil_Out32(PLL_BASE + XIL_CCR_12, pll_cfg->CLKOUT3_PHASE);
	Xil_Out32(PLL_BASE + XIL_CCR_13, pll_cfg->CLKOUT3_DUTY);

	// Clock Configuration Register 14,15,16
	Xil_Out32(PLL_BASE + XIL_CCR_14, pll_cfg->CLKOUT4_DIVIDE);
	Xil_Out32(PLL_BASE + XIL_CCR_15, pll_cfg->CLKOUT4_PHASE);
	Xil_Out32(PLL_BASE + XIL_CCR_16, pll_cfg->CLKOUT4_DUTY);

	// Clock Configuration Register 17,18,19
	Xil_Out32(PLL_BASE + XIL_CCR_17, pll_cfg->CLKOUT5_DIVIDE);
	Xil_Out32(PLL_BASE + XIL_CCR_18, pll_cfg->CLKOUT5_PHASE);
	Xil_Out32(PLL_BASE + XIL_CCR_19, pll_cfg->CLKOUT5_DUTY);

	// Clock Configuration Register 20,21,22
	Xil_Out32(PLL_BASE + XIL_CCR_20, pll_cfg->CLKOUT6_DIVIDE);
	Xil_Out32(PLL_BASE + XIL_CCR_21, pll_cfg->CLKOUT6_PHASE);
	Xil_Out32(PLL_BASE + XIL_CCR_22, pll_cfg->CLKOUT6_DUTY);

	return PLLCFG_NOERR; //start_Reconfig(PLL_BASE);


}



uint8_t set_CxCnt(uint32_t PLL_BASE, uint32_t CxVal)
{

 	//IOWR_32DIRECT(PLL_BASE, C_COUNTER, val | (Cx << 18));
	IOWR_32DIRECT(PLL_BASE, C_COUNTER, CxVal);

	return PLLCFG_NOERR;
}

uint8_t set_Phase(uint32_t PLL_BASE, uint32_t Cx, uint32_t val, uint32_t dir)
{
	uint32_t dps;

	dps = val;
	dps = dps | ((Cx & 0x1F) << 16);
	dps = dps | ((dir & 0x01) << 21);

 	IOWR_32DIRECT(PLL_BASE, DPS_COUNTER, dps);

	return PLLCFG_NOERR;
}

uint8_t start_Reconfig(uint32_t PLL_BASE)
{
	unsigned int status_reconfig, timeout;

	//Write anything to Start Register to Reconfiguration
	IOWR_32DIRECT(PLL_BASE, START, 0x01);

	timeout = 0;
	do
	{
	  	status_reconfig = IORD_32DIRECT(PLL_BASE, STATUS);
	  	if (timeout++ > PLLCFG_TIMEOUT) return PLLCFG_CX_TIMEOUT;
	}
	while ((!status_reconfig) & 0x01);

	return PLLCFG_NOERR;
}

uint8_t start_XReconfig(uint32_t PLL_BASE)
{
	unsigned int status_reconfig, timeout;

	timeout = 0;
	timeout = 0;
	do
	{
	  	status_reconfig = Xil_In32(PLL_BASE + XIL_CCR_STATUS);
	  	if (timeout++ > PLLCFG_TIMEOUT) return PLLCFG_CX_TIMEOUT;
	}
	while (!(status_reconfig & 0x01));


	//Loads Clock Configuration Registers (Bit[0] = LOAD / SEN, Bit[1] = SADDR)
	Xil_Out32(PLL_BASE + XIL_CCR_23, 0x3);

	timeout = 0;
	do
	{
	  	status_reconfig = Xil_In32(PLL_BASE + XIL_CCR_23);
	  	if (timeout++ > PLLCFG_TIMEOUT) return PLLCFG_CX_TIMEOUT;
	}
	while (status_reconfig & 0x01);

//	Reset commented out because it reseting after configuration
//	causes the PLL to lose configuration on lock loss
//	Xil_Out32(PLL_BASE + XIL_CCR_RESET, 0xA);



	return PLLCFG_NOERR;
}

