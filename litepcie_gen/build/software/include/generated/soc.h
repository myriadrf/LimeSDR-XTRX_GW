//--------------------------------------------------------------------------------
// Auto-generated by LiteX (c8343879) on 2023-01-12 18:00:51
//--------------------------------------------------------------------------------
#ifndef __GENERATED_SOC_H
#define __GENERATED_SOC_H
#define CONFIG_CLOCK_FREQUENCY 125000000
#define CONFIG_CPU_TYPE_NONE
#define CONFIG_CPU_VARIANT_STANDARD
#define CONFIG_CPU_HUMAN_NAME "Unknown"
#define DMA_CHANNELS 1
#define PCIE_DMA0_READER_INTERRUPT 0
#define PCIE_DMA0_WRITER_INTERRUPT 1
#define CONFIG_CSR_DATA_WIDTH 32
#define CONFIG_CSR_ALIGNMENT 32
#define CONFIG_BUS_STANDARD "WISHBONE"
#define CONFIG_BUS_DATA_WIDTH 32
#define CONFIG_BUS_ADDRESS_WIDTH 32
#define CONFIG_BUS_BURSTING 0

#ifndef __ASSEMBLER__
static inline int config_clock_frequency_read(void) {
	return 125000000;
}
static inline const char * config_cpu_human_name_read(void) {
	return "Unknown";
}
static inline int dma_channels_read(void) {
	return 1;
}
static inline int pcie_dma0_reader_interrupt_read(void) {
	return 0;
}
static inline int pcie_dma0_writer_interrupt_read(void) {
	return 1;
}
static inline int config_csr_data_width_read(void) {
	return 32;
}
static inline int config_csr_alignment_read(void) {
	return 32;
}
static inline const char * config_bus_standard_read(void) {
	return "WISHBONE";
}
static inline int config_bus_data_width_read(void) {
	return 32;
}
static inline int config_bus_address_width_read(void) {
	return 32;
}
static inline int config_bus_bursting_read(void) {
	return 0;
}
#endif // !__ASSEMBLER__

#endif