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
      g_FPGA2HOST_C0_0_SIZE   : integer := 1024   -- Control, FPGA->Host, FIFO size in bytes
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



end architecture Structural;