#include <stdint.h>
#include "xspi.h"		/* SPI device driver */
#include "LMS64C_protocol.h"

//// buffer structure
//////////////////////
// [0] - address MSB
// [1] - address LSB
// [2] - data MSB
// [3] - data LSB
void Board_SPI_Write(uint8_t *buffer, XSpi *Spi, uint8_t slave_nr);

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
void Board_SPI_Read(uint8_t* buffer, uint8_t* recv_buffer, XSpi* Spi, uint8_t slave_nr);

