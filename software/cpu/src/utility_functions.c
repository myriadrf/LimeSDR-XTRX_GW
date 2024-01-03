#ifndef UTILITIES
#define UTILITIES

#include "utility_functions.h"



#define sbi(p,n) ((p) |= (1UL << (n)))
#define cbi(p,n) ((p) &= ~(1 << (n)))

//// buffer structure
//////////////////////
// [0] - address MSB
// [1] - address LSB
// [2] - data MSB
// [3] - data LSB

void Board_SPI_Write(uint8_t* buffer, XSpi* Spi, uint8_t slave_nr)
{
    sbi(buffer[0], 7); //set write bit (MSB)
    XSpi_SetSlaveSelect(Spi, slave_nr);
    XSpi_Transfer(Spi, buffer, NULL, 4);
}

//// buffer structure
//////////////////////
// [0] - address MSB
// [1] - address LSB
// [2] - dont care
// [3] - dont care
//// recv buffer
// [0] - dont care
// [1] - dont care
// [2] - data MSB
// [3] - data LSB

void Board_SPI_Read(uint8_t* buffer, uint8_t* recv_buffer, XSpi* Spi, uint8_t slave_nr)
{
    cbi(buffer[0], 7);  //clear write bit (MSB)
    XSpi_SetSlaveSelect(Spi, slave_nr);
    XSpi_Transfer(Spi, buffer, recv_buffer, 4);
}


#endif
