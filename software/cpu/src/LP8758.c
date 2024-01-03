/*
-- ----------------------------------------------------------------------------
-- FILE:	LP8758.c
-- DESCRIPTION:	Functions to abstract LP8758 control
-- DATE:	2023/01/04
-- AUTHOR(s):	Lime Microsystems
-- REVISION: v0r0
-- ----------------------------------------------------------------------------
*/

#include "LP8758.h"



unsigned LP8758_WR_REG(UINTPTR I2C_CORE_ADDRESS, uint8_t reg_addr, uint8_t reg_val)
{
	uint8_t i2c_buf[2];
	i2c_buf[0] = reg_addr;
	i2c_buf[1] = reg_val;
	return XIic_Send(I2C_CORE_ADDRESS,LP8758_ADDR, i2c_buf, 2, XIIC_STOP);
}

unsigned LP8758_RD_REG(UINTPTR I2C_CORE_ADDRESS, uint8_t reg_addr, uint8_t* reg_val)
{
    XIic_Send(I2C_CORE_ADDRESS, LP8758_ADDR, &reg_addr , 1,XIIC_REPEATED_START );
    return XIic_Recv(I2C_CORE_ADDRESS, LP8758_ADDR, reg_val, 1,XIIC_STOP);
}


