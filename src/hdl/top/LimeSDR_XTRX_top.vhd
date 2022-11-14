-- ----------------------------------------------------------------------------
-- FILE:          LimeSDR-XTRX_top.vhd
-- DESCRIPTION:   Top level file for LimeSDR-XTRX board
-- DATE:          10:06 AM Friday, May 11, 2018
-- AUTHOR(s):     Lime Microsystems
-- REVISIONS:
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
--NOTES:
-- ----------------------------------------------------------------------------
-- altera vhdl_input_version vhdl_2008
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.FIFO_PACK.all;

--! Local libraries
library work;

--! Entity/Package Description
entity LimeSDR_XTRX_top is
   generic (
      -- General parameters
      g_DEV_FAMILY            : string := "Cyclone V";
      -- Resource saving
      g_DISABLE_BITPACKING_14B: boolean := true;  -- 14bit samples are incompatible with 4kB packets, as such
                                                   -- this function remains unused and may be disabled to save resources
                                                   -- SET THIS TO TRUE, IF 128BIT bus is used for RX
      -- Host related
      g_HOST2FPGA_S0_0_SIZE   : integer := 4096;   -- Stream, Host->FPGA, TX FIFO size in bytes, 
      g_HOST2FPGA_S0_1_SIZE   : integer := 4096;   -- Stream, Host->FPGA, WFM FIFO size in bytes
      g_FPGA2HOST_S0_0_SIZE   : integer := 8192;   -- Stream, FPGA->Host, FIFO size in bytes
      g_HOST2FPGA_C0_0_SIZE   : integer := 1024;   -- Control, Host->FPGA, FIFO size in bytes
      g_FPGA2HOST_C0_0_SIZE   : integer := 1024;   -- Control, FPGA->Host, FIFO size in bytes
      
      -- Internal configuration memory 
      g_FPGACFG_START_ADDR    : integer := 0;
      g_PLLCFG_START_ADDR     : integer := 32;
      g_TSTCFG_START_ADDR     : integer := 96;
      g_TXTSPCFG_START_ADDR   : integer := 128;
      g_RXTSPCFG_START_ADDR   : integer := 160;
      g_PERIPHCFG_START_ADDR  : integer := 192;
      g_TAMERCFG_START_ADDR   : integer := 224;
      g_GNSSCFG_START_ADDR    : integer := 256
   );
   port (
   --PCIe ports
   pci_exp_txp     : out  std_logic_vector(1 downto 0);
   pci_exp_txn     : out  std_logic_vector(1 downto 0);
   pci_exp_rxp     : in   std_logic_vector(1 downto 0);
   pci_exp_rxn     : in   std_logic_vector(1 downto 0);
   --pseudo - GPIO
   led_2	       : out  std_logic;
   option		   : in   std_logic;
   sys_clk_p       : in   std_logic;
   sys_clk_n       : in   std_logic;
   sys_rst_n       : in   std_logic;
   --LMS SPI               
   lms_io_sdio     : out  std_logic;
   lms_i_sclk      : out  std_logic;
   lms_o_sdo       : in   std_logic;
   lms_i_saen      : out  std_logic;
   --LMS generic           
   lms_i_reset     : out  std_logic;
   lms_i_rxen      : out  std_logic;
   lms_i_txen      : out  std_logic;
   lms_i_gpwrdwn   : out  std_logic;
   --LMS port1 - TX
   lms_i_txnrx1    : out   std_logic;
   lms_o_mclk1     : in    std_logic;
   lms_i_fclk1     : out   std_logic; 
   lms_io_iqsel1   : in    std_logic;
   lms_diq1        : in    std_logic_vector(11 downto 0);
   --LMS port2 - RX
   lms_i_txnrx2    : out   std_logic;
   lms_o_mclk2     : in    std_logic;
   lms_i_fclk2     : out   std_logic;
   lms_io_iqsel2   : inout std_logic;
   lms_diq2        : inout std_logic_vector(11 downto 0);
   --AUX
   en_tcxo         : out   std_logic;
   ext_clk         : out   std_logic;      
   en_gps          : out   std_logic;
   iovcc_sel       : out   std_logic;
   en_smsigio      : out   std_logic;           
   fpga_clk_vctcxo : in    std_logic;
   --GPS
   gps_pps         : in    std_logic;
   gps_txd         : in    std_logic;
   gps_rxd         : out   std_logic;
   --GPIO
   gpio            : inout std_logic_vector(11 downto 0); 
   gpio13          : inout std_logic;
   --I2C BUS1 (3v3: TMP108, LTC26x6, LP8758 [FPGA])
   i2c1_sda        : inout std_logic;
   i2c1_scl        : inout std_logic;
   --I2C BUS2 (vio: LP8758 [LMS])
   i2c2_sda        : inout std_logic;
   i2c2_scl        : inout std_logic;
   --TX/RX SWITCH
   tx_switch       : out   std_logic; 
   rx_switch_1     : out   std_logic;
   rx_switch_2     : out   std_logic;
   --FLASH & BOOT
   flash_d         : inout std_logic_vector(3 downto 0);    
   flash_fcs_b     : out   std_logic;
   --SIM
   sim_mode        : out   std_logic;
   sim_enable      : out   std_logic;
   sim_clk         : out   std_logic;
   sim_reset       : out   std_logic;
   sim_data        : inout std_logic;
   --USB2 PHY
   usb_d           : inout std_logic_vector(7 downto 0);
   usb_clk         : in    std_logic;
   usb_nrst        : out   std_logic;
   usb_26m         : out   std_logic;
   usb_dir         : in    std_logic;
   usb_stp         : inout std_logic;
   usb_nxt         : in    std_logic
   );
end entity LimeSDR_XTRX_top;

architecture Structural of LimeSDR_XTRX_top is

--declare signals,  components here

constant c_S0_DATA_WIDTH            : integer := 32;     -- Stream data width
constant c_C0_DATA_WIDTH            : integer := 32;     -- Control data width
constant c_H2F_S0_0_RWIDTH          : integer := 128;    -- Host->FPGA stream, FIFO rd width, FIFO number - 0
constant c_H2F_S0_1_RWIDTH          : integer := 64;     -- Host->FPGA stream, FIFO rd width, FIFO number - 1
constant c_F2H_S0_WWIDTH            : integer := 64;     -- FPGA->Host stream, FIFO wr width
constant c_H2F_C0_RWIDTH            : integer := 32;     -- Host->FPGA control, rd width
constant c_F2H_C0_WWIDTH            : integer := 32;     -- FPGA->Host control, wr width 

constant c_H2F_S0_0_RDUSEDW_WIDTH: integer := FIFO_WORDS_TO_Nbits(g_HOST2FPGA_S0_0_SIZE/(c_H2F_S0_0_RWIDTH/8),true);
constant c_H2F_S0_1_RDUSEDW_WIDTH: integer := FIFO_WORDS_TO_Nbits(g_HOST2FPGA_S0_1_SIZE/(c_H2F_S0_1_RWIDTH/8),true);
constant c_F2H_S0_WRUSEDW_WIDTH  : integer := FIFO_WORDS_TO_Nbits(g_FPGA2HOST_S0_0_SIZE/(c_F2H_S0_WWIDTH/8),true);
constant c_H2F_C0_RDUSEDW_WIDTH  : integer := FIFO_WORDS_TO_Nbits(g_HOST2FPGA_C0_0_SIZE/(c_H2F_C0_RWIDTH/8),true);
constant c_F2H_C0_WRUSEDW_WIDTH  : integer := FIFO_WORDS_TO_Nbits(g_FPGA2HOST_C0_0_SIZE/(c_F2H_C0_WWIDTH/8),true);


attribute DONT_TOUCH : string;
attribute DONT_TOUCH of inst0: label is "TRUE";

signal pcie_clk : std_logic;
signal pcie_rst : std_logic;				
				

begin

   inst0 : entity work.pcie_top
  generic map(
     g_DEV_FAMILY               => g_DEV_FAMILY,
     g_S0_DATA_WIDTH            => c_S0_DATA_WIDTH,
     g_C0_DATA_WIDTH            => c_C0_DATA_WIDTH,
     -- Stream (Host->FPGA) 
     g_H2F_S0_0_RDUSEDW_WIDTH   => c_H2F_S0_0_RDUSEDW_WIDTH,
     g_H2F_S0_0_RWIDTH          => c_H2F_S0_0_RWIDTH,
     g_H2F_S0_1_RDUSEDW_WIDTH   => c_H2F_S0_1_RDUSEDW_WIDTH,
     g_H2F_S0_1_RWIDTH          => c_H2F_S0_1_RWIDTH,
     -- Stream (FPGA->Host)
     g_F2H_S0_WRUSEDW_WIDTH     => c_F2H_S0_WRUSEDW_WIDTH,
     g_F2H_S0_WWIDTH            => c_F2H_S0_WWIDTH,
     -- Control (Host->FPGA)
     g_H2F_C0_RDUSEDW_WIDTH     => c_H2F_C0_RDUSEDW_WIDTH,
     g_H2F_C0_RWIDTH            => c_H2F_C0_RWIDTH,
     -- Control (FPGA->Host)
     g_F2H_C0_WRUSEDW_WIDTH     => c_F2H_C0_WRUSEDW_WIDTH,
     g_F2H_C0_WWIDTH            => c_F2H_C0_WWIDTH 
  )
      port map (
                clk              => pcie_clk,--
                reset_n          => pcie_rst,--
                pcie_perstn      => sys_rst_n,--
                pcie_refclk_p    => sys_clk_p,
                pcie_refclk_n    => sys_clk_n,
                pcie_rx_p        => pci_exp_rxp,
                pcie_rx_n        => pci_exp_rxn,
                pcie_tx_p        => pci_exp_txp,
                pcie_tx_n        => pci_exp_txn,
                H2F_S0_sel       => '0',
                H2F_S0_dma_en    => open,--H2F_S0_dma_en,
                H2F_S0_0_rdclk   => '0',--H2F_S0_0_rdclk,
                H2F_S0_0_aclrn   => '0',--H2F_S0_0_aclrn,
                H2F_S0_0_rd      => '0',--H2F_S0_0_rd,
                H2F_S0_0_rdata   => open,--H2F_S0_0_rdata,
                H2F_S0_0_rempty  => open,--H2F_S0_0_rempty,
                H2F_S0_0_rdusedw => open,--H2F_S0_0_rdusedw,
                H2F_S0_1_rdclk   => '0',--H2F_S0_1_rdclk,
                H2F_S0_1_aclrn   => '0',--H2F_S0_1_aclrn,
                H2F_S0_1_rd      => '0',--H2F_S0_1_rd,
                H2F_S0_1_rdata   => open,--H2F_S0_1_rdata,
                H2F_S0_1_rempty  => open,--H2F_S0_1_rempty,
                H2F_S0_1_rdusedw => open,--H2F_S0_1_rdusedw,
                F2H_S0_wclk      => '0',--F2H_S0_wclk,
                F2H_S0_aclrn     => '0',--F2H_S0_aclrn,
                F2H_S0_wr        => '0',--F2H_S0_wr,
                F2H_S0_wdata     => (others => '0'),--F2H_S0_wdata,
                F2H_S0_wfull     => open,--F2H_S0_wfull,
                F2H_S0_wrusedw   => open,--F2H_S0_wrusedw,
                H2F_C0_rdclk     => '0',--H2F_C0_rdclk,
                H2F_C0_aclrn     => '0',--H2F_C0_aclrn,
                H2F_C0_rd        => '0',--H2F_C0_rd,
                H2F_C0_rdata     => open,--H2F_C0_rdata,
                H2F_C0_rempty    => open,--H2F_C0_rempty,
                F2H_C0_wclk      => '0',--F2H_C0_wclk,
                F2H_C0_aclrn     => '0',--F2H_C0_aclrn,
                F2H_C0_wr        => '0',--F2H_C0_wr,
                F2H_C0_wdata     => (others=>'0'),--F2H_C0_wdata,
                F2H_C0_wfull     => open,--F2H_C0_wfull,
                S0_rx_en         => '0',--S0_rx_en,
                F2H_S0_open      => open--F2H_S0_open
   );
   
   
   -- ----------------------------------------------------------------------------
-- Microblaze CPU instance.
-- CPU is responsible for communication interfaces and control logic
-- ----------------------------------------------------------------------------   
--   inst0_cpu : entity work.cpu_top
--   generic map (
--      FPGACFG_START_ADDR   => g_FPGACFG_START_ADDR,
--      PLLCFG_START_ADDR    => g_PLLCFG_START_ADDR,
--      TSTCFG_START_ADDR    => g_TSTCFG_START_ADDR,
--      TXTSPCFG_START_ADDR  => g_TXTSPCFG_START_ADDR,
--      RXTSPCFG_START_ADDR  => g_RXTSPCFG_START_ADDR,
--      PERIPHCFG_START_ADDR => g_PERIPHCFG_START_ADDR,
--      TAMERCFG_START_ADDR  => g_TAMERCFG_START_ADDR,
--      GNSSCFG_START_ADDR   => g_GNSSCFG_START_ADDR,
--      MEMCFG_START_ADDR    => g_MEMCFG_START_ADDR
--   )
--   port map(
--      clk                        => CLK100_FPGA,
--      reset_n                    => reset_n_clk100_fpga,
--      -- Control data FIFO
--      exfifo_if_d                => inst2_H2F_C0_rdata,
--      exfifo_if_rd               => inst0_exfifo_if_rd, 
--      exfifo_if_rdempty          => inst2_H2F_C0_rempty,
--      exfifo_of_d                => inst0_exfifo_of_d, 
--      exfifo_of_wr               => inst0_exfifo_of_wr, 
--      exfifo_of_wrfull           => inst2_F2H_C0_wfull,
--      exfifo_of_rst              => inst0_exfifo_of_rst, 
--      -- SPI 0 
--      spi_0_MISO                 => inst0_spi_0_MISO OR inst6_sdout OR inst12_sdout,
--      spi_0_MOSI                 => inst0_spi_0_MOSI,
--      spi_0_SCLK                 => inst0_spi_0_SCLK,
--      spi_0_SS_n                 => inst0_spi_0_SS_n,
--      -- SPI 1
--      spi_1_MISO                 => FPGA_SPI1_MISO OR FPGA_SPI1_MISO_BB_ADC,
--      spi_1_MOSI                 => inst0_spi_1_MOSI,
--      spi_1_SCLK                 => inst0_spi_1_SCLK,
--      spi_1_SS_n                 => inst0_spi_1_SS_n,
--      -- SPI 1
--      spi_2_MISO                 => '0',
--      spi_2_MOSI                 => inst0_spi_2_MOSI,
--      spi_2_SCLK                 => inst0_spi_2_SCLK,
--      spi_2_SS_n                 => inst0_spi_2_SS_n,
--      -- Config QSPI
--      fpga_cfg_qspi_MOSI	     =>FPGA_CFG_MOSI,
--      fpga_cfg_qspi_MISO	     =>FPGA_CFG_MISO,
--      fpga_cfg_qspi_SS_n         =>FPGA_CFG_CS,
--      -- I2C
--      i2c_scl                    => FPGA_I2C_SCL,
--      i2c_sda                    => FPGA_I2C_SDA,
--      -- Genral purpose I/O
--      gpi                        => "00000000",--"0000" & FPGA_SW,
--      gpo                        => inst0_gpo, 
--      -- LMS7002 control 
--      lms_ctr_gpio               => inst0_lms_ctr_gpio,
--      -- VCTCXO tamer control
--      vctcxo_tune_en             => inst12_en,
--      vctcxo_irq                 => inst12_mm_irq,
--      -- PLL reconfiguration
--      pll_rst                    => inst0_pll_rst,
--      pll_axi_resetn_out         => inst0_pll_axi_resetn_out,
--      pll_from_axim              => inst0_pll_from_axim,
--      pll_to_axim                => inst1_rcnfg_to_axim, 
--      pll_axi_sel                => inst0_pll_axi_sel,
--      pll_rcfg_from_pll_0        => inst1_lms1_txpll_rcnfg_from_pll,
--      pll_rcfg_to_pll_0          => inst0_pll_rcfg_to_pll_0,
--      pll_rcfg_from_pll_1        => inst1_lms1_rxpll_rcnfg_from_pll,
--      pll_rcfg_to_pll_1          => inst0_pll_rcfg_to_pll_1,
--      pll_rcfg_from_pll_2        => inst1_lms2_txpll_rcnfg_from_pll,
--      pll_rcfg_to_pll_2          => inst0_pll_rcfg_to_pll_2,
--      pll_rcfg_from_pll_3        => inst1_lms2_rxpll_rcnfg_from_pll,
--      pll_rcfg_to_pll_3          => inst0_pll_rcfg_to_pll_3,
--      pll_rcfg_from_pll_4        => inst1_pll_0_rcnfg_from_pll,
--      pll_rcfg_to_pll_4          => inst0_pll_rcfg_to_pll_4,
--      pll_rcfg_from_pll_5        => (others=>'0'),
--      pll_rcfg_to_pll_5          => inst0_pll_rcfg_to_pll_5,
--      -- Avalon Slave port 0
--      avmm_s0_address            => inst1_rcnfg_0_mgmt_address,
--      avmm_s0_read               => inst1_rcnfg_0_mgmt_read,
--      avmm_s0_readdata           => inst0_avmm_s0_readdata, 
--      avmm_s0_write              => inst1_rcnfg_0_mgmt_write,
--      avmm_s0_writedata          => inst1_rcnfg_0_mgmt_writedata, 
--      avmm_s0_waitrequest        => inst0_avmm_s0_waitrequest,
--      -- Avalon Slave port 1
--      avmm_s1_address            => inst1_rcnfg_1_mgmt_address,
--      avmm_s1_read               => inst1_rcnfg_1_mgmt_read,
--      avmm_s1_readdata           => inst0_avmm_s1_readdata,
--      avmm_s1_write              => inst1_rcnfg_1_mgmt_write,
--      avmm_s1_writedata          => inst1_rcnfg_1_mgmt_writedata, 
--      avmm_s1_waitrequest        => inst0_avmm_s1_waitrequest,
--      -- Avalon master
--      avmm_m0_address            => inst0_avmm_m0_address,
--      avmm_m0_read               => inst0_avmm_m0_read,
--      avmm_m0_waitrequest        => inst12_mm_wait_req,
--      avmm_m0_readdata           => inst12_mm_rd_data,
--      avmm_m0_readdatavalid      => inst12_mm_rd_datav,
--      avmm_m0_write              => inst0_avmm_m0_write,
--      avmm_m0_writedata          => inst0_avmm_m0_writedata,
--      avmm_m0_clk_clk            => inst0_avmm_m0_clk_clk,
--      avmm_m0_reset_reset        => inst0_avmm_m0_reset_reset,
--      -- Configuration registers
--      from_fpgacfg               => inst0_from_fpgacfg,
--      to_fpgacfg                 => inst0_to_fpgacfg,
--      from_pllcfg                => inst0_from_pllcfg,
--      to_pllcfg                  => inst0_to_pllcfg,
--      from_tstcfg                => inst0_from_tstcfg,
--      to_tstcfg                  => inst0_to_tstcfg,
--      to_tstcfg_from_rxtx        => inst7_to_tstcfg_from_rxtx,
--      from_txtspcfg_0            => inst0_from_txtspcfg_0,
--      to_txtspcfg_0              => inst0_to_txtspcfg_0, 
--      from_txtspcfg_1            => inst0_from_txtspcfg_1,
--      to_txtspcfg_1              => inst0_to_txtspcfg_1,      
      
--      from_periphcfg             => inst0_from_periphcfg,
--      to_periphcfg               => inst0_to_periphcfg,
--      from_tamercfg              => inst0_from_tamercfg,
--      to_tamercfg                => inst0_to_tamercfg,
--      from_gnsscfg               => inst0_from_gnsscfg,
--      to_gnsscfg                 => inst0_to_gnsscfg,
--      to_memcfg                  => inst0_to_memcfg,
--      from_memcfg                => inst0_from_memcfg,
--      pll_c0                     => inst0_pll_c0,
--      pll_c1                     => inst0_pll_c1,
--      pll_locked                 => inst0_pll_locked,
--      smpl_cmp_sel               => inst0_smpl_cmp_sel,
--      smpl_cmp_en                => inst0_smpl_cmp_en, 
--      smpl_cmp_status            => inst0_smpl_cmp_status
--   );
   
   



end architecture Structural;