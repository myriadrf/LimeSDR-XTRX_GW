/*
-- ----------------------------------------------------------------------------
-- FILE:	LP8758.h
-- DESCRIPTION:	Functions to abstract LP8758 control
-- DATE:	2023/01/04
-- AUTHOR(s):	Lime Microsystems
-- REVISION: v0r0
-- ----------------------------------------------------------------------------
*/
#define LP8758_ADDR 0x60
#ifndef SRC_LP8758_H_
#define SRC_LP8758_H_



#include "xiic.h"


unsigned LP8758_WR_REG(UINTPTR I2C_CORE_ADDRESS, uint8_t reg_addr, uint8_t reg_val);
unsigned LP8758_RD_REG(UINTPTR I2C_CORE_ADDRESS, uint8_t reg_addr, uint8_t* reg_val);


#endif /* SRC_LP8758_H_ */
