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
use work.fpgacfg_pkg.all;
use work.pllcfg_pkg.all;
use work.tstcfg_pkg.all;
use work.periphcfg_pkg.all;
use work.memcfg_pkg.all;
use work.axi_pkg.all;

Library UNISIM;
use UNISIM.vcomponents.all;

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
      g_MEMCFG_START_ADDR     : integer := 65504;
      -- TX interface 
      g_TX_N_BUFF             : integer := 2;      -- N 4KB buffers in TX interface (2 OR 4)
      g_TX_PCT_SIZE           : integer := 4096;   -- TX packet size in bytes
      g_TX_IN_PCT_HDR_SIZE    : integer := 16
   );
   port (
   --PCIe ports
   PCI_EXP_TXP      : out  std_logic_vector(1 downto 0);
   PCI_EXP_TXN      : out  std_logic_vector(1 downto 0);
   PCI_EXP_RXP      : in   std_logic_vector(1 downto 0);
   PCI_EXP_RXN      : in   std_logic_vector(1 downto 0);
   --pseudo - GPIO
   FPGA_LED1        : out  std_logic;
   FPGA_LED2        : out  std_logic;
   OPTION           : in   std_logic;
   PCI_REF_CLK_p    : in   std_logic;
   PCI_REF_CLK_n    : in   std_logic;
   PERST            : in   std_logic;
   --LMS SPI               
   FPGA_SPI_MOSI    : out  std_logic;
   FPGA_SPI_SCLK    : out  std_logic;
   FPGA_SPI_MISO    : in   std_logic;
   FPGA_SPI_LMS_SS  : out  std_logic;
   --LMS generic           
   LMS_RESET        : out  std_logic;
   LMS_RXEN         : out  std_logic;
   LMS_TXEN         : out  std_logic;
   LMS_CORE_LDO_EN  : out  std_logic;
   --LMS port1 - TX
   LMS_TXNRX1       : out   std_logic;
   LMS_MCLK1        : in    std_logic;
   LMS_FCLK1        : out   std_logic; 
   LMS_EN_IQSEL1    : out   std_logic;
   LMS_DIQ1_D       : out   std_logic_vector(11 downto 0);
   --LMS port2 - RX
   LMS_TXNRX2       : out   std_logic;
   LMS_MCLK2        : in    std_logic;
   LMS_FCLK2        : out   std_logic;
   LMS_EN_IQSEL2    : in    std_logic;
   LMS_DIQ2_D       : in    std_logic_vector(11 downto 0);
   --AUX
   EN_TCXO          : out   std_logic;
   EXT_CLK          : out   std_logic;      
   EN_GPIO          : out   std_logic;           
   FPGA_CLK         : in    std_logic;
   BOM_VER          : in    std_logic_vector(2 downto 0);
   HW_VER           : in    std_logic_vector(2 downto 0);
   --GPS
   GNSS_1PPS        : in    std_logic;
   GNSS_TXD         : out   std_logic;
   GNSS_RXD         : in    std_logic;
   GNSS_HW_S        : out   std_logic; --FIX
   GNSS_HW_R        : out   std_logic; --FIX
   GNSS_FIX         : in    std_logic; --FIX
   --GPIO
   PPSI_GPIO1       : inout std_logic;   
   PPSO_GPIO2       : inout std_logic;
   TDD_GPIO3_P      : inout std_logic;
   TDD_GPIO3_N      : inout std_logic;
   LED_WWAN_GPIO5   : inout std_logic;
   LED_WLAN_GPIO6   : inout std_logic;
   LED_WPAN_GPIO7   : inout std_logic;
   GPIO8            : inout std_logic;
   GPIO9_P          : inout std_logic;
   GPIO9_N          : inout std_logic;
   GPIO11_P         : inout std_logic;
   GPIO11_N         : inout std_logic;
   GPIO13           : inout std_logic;
   --I2C BUS1 (3v3: TMP108, LTC26x6, LP8758 [FPGA])
   FPGA_I2C1_SDA    : inout std_logic;
   FPGA_I2C1_SCL    : inout std_logic;
   --I2C BUS2 (vio: LP8758 [LMS])
   FPGA_I2C_SDA     : inout std_logic;
   FPGA_I2C_SCL     : inout std_logic;
   --TX/RX SWITCH
   TX_SW            : out   std_logic; 
   RX_SW3           : out   std_logic;
   RX_SW2           : out   std_logic;
   --FLASH & BOOT
   FPGA_CFG_D       : inout std_logic_vector(3 downto 0);    
   FPGA_CFG_CS      : out   std_logic;
   --SIM
   SIM_MOD          : out   std_logic;
   SIM_ENA          : out   std_logic;
   SIM_CLK          : out   std_logic;
   SIM_RST          : out   std_logic;
   SIM_DIO          : inout std_logic;
   --USB2 PHY
   USB_D            : inout std_logic_vector(7 downto 0);
   USB_CLK          : in    std_logic;
   USB_NRST         : out   std_logic;
   USB_26M          : out   std_logic;
   USB_DIR          : in    std_logic;
   USB_STP          : inout std_logic;
   USB_NXT          : in    std_logic
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

signal sys_clk      : std_logic;
signal global_rst_n : std_logic;
signal rx_switches  : std_logic_vector(1 downto 0);

--pcie

     --Control endpoint FIFO (Host->FPGA)
signal      inst0_H2F_C0_rdclk              :  std_logic;
signal      inst0_H2F_C0_rd                 :  std_logic;
signal      inst0_H2F_C0_rdata              :  std_logic_vector(c_H2F_C0_RWIDTH-1 downto 0);
signal      inst0_H2F_C0_rempty             :  std_logic;
      --Control endpoint FIFO (FPGA->Host)
signal      inst0_F2H_C0_wclk               :  std_logic;
signal      inst0_F2H_C0_aclrn              :  std_logic;
signal      inst0_F2H_C0_wr                 :  std_logic;
signal      inst0_F2H_C0_wdata              :  std_logic_vector(c_F2H_C0_WWIDTH-1 downto 0);
signal      inst0_F2H_C0_wfull              :  std_logic;
       --Stream endpoint FIFO (Host->FPGA)
signal      inst0_s0_dma_en                 :  std_logic;
signal      inst0_s0_rdclk                  :  std_logic;
signal      inst0_s0_raclrn                 :  std_logic;
signal      inst0_s0_rd                     :  std_logic;
signal      inst0_s0_rdata                  :  std_logic_vector(127 downto 0);
signal      inst0_s0_rempty                 :  std_logic;
signal      inst0_s0_rdusedw                :  std_logic_vector(c_H2F_S0_0_RDUSEDW_WIDTH-1 downto 0);
       --Stream endpoint FIFO (FPGA->Host)
signal      inst0_s0_wclk                   :  std_logic;
signal      inst0_s0_wfull                  :  std_logic;
signal      inst0_s0_waclrn                 :  std_logic;
signal      inst0_s0_wr                     :  std_logic;
signal      inst0_s0_wdata                  :  std_logic_vector(63 downto 0);           
signal      inst0_s0_wrusedw                :  std_logic_vector(c_F2H_S0_WRUSEDW_WIDTH-1 downto 0);
                
--cpu
signal      inst1_spi_0_MISO                : std_logic;
signal      inst1_spi_0_MOSI                : std_logic;
signal      inst1_spi_0_SCLK                : std_logic;
signal      inst1_spi_0_SS_n                : std_logic_vector(1 downto 0);
signal      inst1_pll_rst                   : std_logic_vector(1 downto 0);
signal      inst1_from_fpgacfg              : t_FROM_FPGACFG;
signal      inst1_to_fpgacfg                : t_TO_FPGACFG;
signal      inst1_from_pllcfg               : t_FROM_PLLCFG;
signal      inst1_to_pllcfg                 : t_TO_PLLCFG;
signal      inst1_from_tstcfg               : t_FROM_TSTCFG;
signal      inst1_to_tstcfg                 : t_TO_TSTCFG;
signal      inst1_from_periphcfg            : t_FROM_PERIPHCFG;
signal      inst1_to_periphcfg              : t_TO_PERIPHCFG;
signal      inst1_to_memcfg                 : t_TO_MEMCFG;
signal      inst1_from_memcfg               : t_FROM_MEMCFG;
signal      inst1_pll_from_axim             : t_FROM_AXIM_32x32;
signal      inst1_pll_axi_sel               : std_logic_vector(3 downto 0);
signal      inst1_pll_axi_resetn_out        : std_logic_vector(0 downto 0);
signal      inst1_smpl_cmp_en               : std_logic_vector(0 downto 0);
signal      inst1_smpl_cmp_status           : std_logic_vector(1 downto 0);
signal      inst1_lms_reset_cpu             : std_logic;
--rxtx_top
signal      inst3_rx_smpl_cnt_en            : std_logic;
----tx interface
signal      inst3_tx_samplefifo_wrreq       : std_logic;
signal      inst3_tx_samplefifo_wrfull      : std_logic;
signal      inst3_tx_samplefifo_wrusedw     : std_logic_vector(8   downto 0);
signal      inst3_tx_samplefifo_data        : std_logic_vector(127 downto 0);
----rx interface
signal      inst3_rx_samplefifo_wrreq       : std_logic;   
signal      inst3_rx_samplefifo_data        : std_logic_vector(47  downto 0);



--placeholders
signal      inst1_lms1_txpll_c1             : std_logic;
signal      inst1_lms1_txpll_locked         : std_logic;
signal      inst1_lms1_txpll_rcnfg_from_pll : std_logic_vector(63 downto 0);
signal      inst1_lms1_rxpll_c1             : std_logic;
signal      inst1_lms1_rxpll_locked         : std_logic;
signal      inst1_lms1_rxpll_rcnfg_from_pll : std_logic_vector(63 downto 0);
            
signal      inst1_lms2_txpll_rcnfg_from_pll : std_logic_vector(63 downto 0);
signal      inst1_rcnfg_to_axim             : t_TO_AXIM_32x32;

signal      inst4_txant_en                  : std_logic;
            
signal      inst4_rx_smpl_cmp_done          : std_logic; 
signal      inst4_rx_smpl_cmp_err           : std_logic; 
signal      inst4_rx_smpl_cmp_start         : std_logic;
signal      inst4_rx_smpl_cmp_cnt           : std_logic_vector(15 downto 0);
signal      inst4_lms_reset                 : std_logic;

signal      pps_internal                    : std_logic;

signal      usb_serial_rx_o : std_logic;
signal      usb_serial_tx_i : std_logic;

signal uart_data_stream_in       : std_logic_vector(7 downto 0);
signal uart_data_stream_in_stb   : std_logic;
signal uart_data_stream_in_ack   : std_logic;

signal uart_data_stream_out      : std_logic_vector(7 downto 0);
signal uart_data_stream_out_stb  : std_logic;
signal uart_data_stream_out_ack  : std_logic;


--attribute KEEP : string;
--attribute KEEP of uart_data_stream_out: signal is "TRUE";
--attribute KEEP of uart_data_stream_out_stb: signal is "TRUE";
--attribute KEEP of uart_data_stream_out_ack: signal is "TRUE";

signal usb_clk_g : std_logic;

--attribute MARK_DEBUG : string;
--attribute MARK_DEBUG of uart_data_stream_out: signal is "TRUE";
--attribute MARK_DEBUG of uart_data_stream_out_stb: signal is "TRUE";
--attribute MARK_DEBUG of uart_data_stream_out_ack: signal is "TRUE";
--
--attribute MARK_DEBUG of uart_data_stream_in: signal is "TRUE";
--attribute MARK_DEBUG of uart_data_stream_in_stb: signal is "TRUE";
--attribute MARK_DEBUG of uart_data_stream_in_ack: signal is "TRUE";



signal fpga_led1_int    : std_logic;
signal fpga_led1_reg    : std_logic;
signal fpga_led1_rising : std_logic;

signal fpga_led1_sync_usb_clk : std_logic_vector(1 downto 0);

type t_ARRAY_10x8b is array (0 to 11) of std_logic_vector(7 downto 0);

constant c_ASCII_ARRAY : t_ARRAY_10x8b := (x"30", x"31", x"32", x"33", x"34", x"35", x"36", x"37", x"38", x"39", x"0D", x"0A");

signal ascii_cnt : unsigned(3 downto 0);

signal usb_reset_out : std_logic;
--attribute MARK_DEBUG of usb_reset_out: signal is "TRUE";

signal iiena_valid   : std_logic;
signal iiena_en      : std_logic_vector(7 downto 0);
--attribute MARK_DEBUG of iiena_valid : signal is "TRUE";
--attribute MARK_DEBUG of iiena_en    : signal is "TRUE";

signal iicfg_valid   : std_logic;
signal iicfg_1s_tol  : std_logic_vector(15 downto 0);
signal iicfg_10s_tol  : std_logic_vector(23 downto 0);
signal iicfg_100s_tol  : std_logic_vector(31 downto 0);

--attribute MARK_DEBUG of iicfg_valid    : signal is "TRUE";
--attribute MARK_DEBUG of iicfg_1s_tol   : signal is "TRUE";
--attribute MARK_DEBUG of iicfg_10s_tol  : signal is "TRUE";
--attribute MARK_DEBUG of iicfg_100s_tol : signal is "TRUE";


component usb_serial is 
generic (
    BAUDRATE         : integer := 9600
);
port(
    -- Serial
    uart_rx_o : out std_logic;
    uart_tx_i : in  std_logic;

    --ULPI Interface
    ulpi_reset_o        : out std_logic;
    ulpi_data_io        : inout std_logic_vector(7 downto 0);
    ulpi_stp_o          : out std_logic;
    ulpi_nxt_i          : in std_logic;
    ulpi_dir_i          : in std_logic;
    ulpi_clk60_i        : in std_logic;
    reset_out           : out std_logic
);
end component;


begin

   --placeholder assignment
   global_rst_n <= PERST;

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
                clk              => sys_clk     ,
                reset_n          => global_rst_n,
                
                pcie_perstn      => PERST  ,
                pcie_refclk_p    => PCI_REF_CLK_p  ,
                pcie_refclk_n    => PCI_REF_CLK_n  ,
                pcie_rx_p        => pci_exp_rxp,
                pcie_rx_n        => pci_exp_rxn,
                pcie_tx_p        => pci_exp_txp,
                pcie_tx_n        => pci_exp_txn,
                
                H2F_S0_sel       => '0',
                
                H2F_S0_dma_en    => inst0_s0_dma_en ,
                H2F_S0_0_rdclk   => inst0_s0_rdclk  ,
                H2F_S0_0_aclrn   => inst0_s0_raclrn ,
                H2F_S0_0_rd      => inst0_s0_rd     ,
                H2F_S0_0_rdata   => inst0_s0_rdata  ,
                H2F_S0_0_rempty  => inst0_s0_rempty ,
                H2F_S0_0_rdusedw => inst0_s0_rdusedw,
                
                H2F_S0_1_rdclk   => '0'  ,--H2F_S0_1_rdclk,
                H2F_S0_1_aclrn   => '0'  ,--H2F_S0_1_aclrn,
                H2F_S0_1_rd      => '0'  ,--H2F_S0_1_rd,
                H2F_S0_1_rdata   => open ,--H2F_S0_1_rdata,
                H2F_S0_1_rempty  => open ,--H2F_S0_1_rempty,
                H2F_S0_1_rdusedw => open ,--H2F_S0_1_rdusedw,
                
                F2H_S0_wclk      => inst0_s0_wclk   ,
                F2H_S0_aclrn     => inst0_s0_waclrn ,
                F2H_S0_wr        => inst0_s0_wr     ,
                F2H_S0_wdata     => inst0_s0_wdata  ,
                F2H_S0_wfull     => inst0_s0_wfull  ,
                F2H_S0_wrusedw   => inst0_s0_wrusedw,
                
                H2F_C0_rdclk     => inst0_H2F_C0_rdclk     ,
                H2F_C0_aclrn     => global_rst_n           ,
                H2F_C0_rd        => inst0_H2F_C0_rd        ,
                H2F_C0_rdata     => inst0_H2F_C0_rdata     ,
                H2F_C0_rempty    => inst0_H2F_C0_rempty    ,
                F2H_C0_wclk      => inst0_F2H_C0_wclk      ,
                F2H_C0_aclrn     => not inst0_F2H_C0_aclrn ,
                F2H_C0_wr        => inst0_F2H_C0_wr        ,
                F2H_C0_wdata     => inst0_F2H_C0_wdata     ,
                F2H_C0_wfull     => inst0_F2H_C0_wfull     ,
                
                S0_rx_en         => '0',--S0_rx_en,
                F2H_S0_open      => open--F2H_S0_open
   );
   
   inst0_s0_rdclk     <= inst1_lms1_txpll_c1;
   inst0_s0_wclk      <= inst1_lms1_rxpll_c1;
   inst0_H2F_C0_rdclk <= sys_clk;
   inst0_F2H_C0_wclk  <= sys_clk;
   
   -- ----------------------------------------------------------------------------
-- Microblaze CPU instance.
-- CPU is responsible for communication interfaces and control logic
-- ----------------------------------------------------------------------------   
   inst1_cpu : entity work.cpu_top
   generic map (
      FPGACFG_START_ADDR   => g_FPGACFG_START_ADDR,
      PLLCFG_START_ADDR    => g_PLLCFG_START_ADDR,
      TSTCFG_START_ADDR    => g_TSTCFG_START_ADDR,
      PERIPHCFG_START_ADDR => g_PERIPHCFG_START_ADDR
   )
   port map(
      clk                        => sys_clk,
      reset_n                    => global_rst_n,
      -- Control data FIFO
      exfifo_if_d                => inst0_H2F_C0_rdata,
      exfifo_if_rd               => inst0_H2F_C0_rd, 
      exfifo_if_rdempty          => inst0_H2F_C0_rempty,
      exfifo_of_d                => inst0_F2H_C0_wdata, 
      exfifo_of_wr               => inst0_F2H_C0_wr, 
      exfifo_of_wrfull           => inst0_F2H_C0_wfull,
      exfifo_of_rst              => inst0_F2H_C0_aclrn, 
      -- SPI 0 
      spi_0_MISO                 => inst1_spi_0_MISO,
      spi_0_MOSI                 => inst1_spi_0_MOSI,
      spi_0_SCLK                 => inst1_spi_0_SCLK,
      spi_0_SS_n                 => inst1_spi_0_SS_n,
      -- Config QSPI
      fpga_cfg_qspi_MOSI         => FPGA_CFG_D(0),--FPGA_CFG_MOSI,
      fpga_cfg_qspi_MISO         => FPGA_CFG_D(1),--FPGA_CFG_MISO,
      fpga_cfg_qspi_SS_n         => FPGA_CFG_CS,--FPGA_CFG_CS,     
      -- I2C
      i2c_1_scl                  => FPGA_I2C1_SCL,
      i2c_1_sda                  => FPGA_I2C1_SDA,
      i2c_2_scl                  => FPGA_I2C_SCL,
      i2c_2_sda                  => FPGA_I2C_SDA,
      -- Genral purpose I/O
      gpi                        => "00000000",--"0000" & FPGA_SW,
      gpo                        => open,--inst0_gpo, 
      -- VCTCXO tamer control
      vctcxo_tune_en             => '0',--inst12_en,
      vctcxo_irq                 => '0',--inst12_mm_irq,
      -- PLL reconfiguration
      pll_rst                    => inst1_pll_rst,
      pll_axi_resetn_out         => inst1_pll_axi_resetn_out,
      pll_from_axim              => inst1_pll_from_axim,
      pll_to_axim                => inst1_rcnfg_to_axim, 
      pll_axi_sel                => inst1_pll_axi_sel,
      -- Avalon master
      avmm_m0_address            => open,           --inst0_avmm_m0_address,
      avmm_m0_read               => open,           --inst0_avmm_m0_read,
      avmm_m0_waitrequest        => '0',            --inst12_mm_wait_req,
      avmm_m0_readdata           => (others => '0'),--inst12_mm_rd_data,
      avmm_m0_readdatavalid      => '0',            --inst12_mm_rd_datav,
      avmm_m0_write              => open,           --inst0_avmm_m0_write,
      avmm_m0_writedata          => open,           --inst0_avmm_m0_writedata,
      avmm_m0_clk_clk            => open,           --inst0_avmm_m0_clk_clk,
      avmm_m0_reset_reset        => open,           --inst0_avmm_m0_reset_reset,
      -- Configuration registers
      from_fpgacfg               => inst1_from_fpgacfg,
      to_fpgacfg                 => inst1_to_fpgacfg,
      from_pllcfg                => inst1_from_pllcfg,
      to_pllcfg                  => inst1_to_pllcfg,
      from_tstcfg                => inst1_from_tstcfg,
      to_tstcfg                  => inst1_to_tstcfg,
      from_periphcfg             => inst1_from_periphcfg,
      to_periphcfg               => inst1_to_periphcfg,
      to_memcfg                  => inst1_to_memcfg,
      from_memcfg                => inst1_from_memcfg,
      smpl_cmp_en                => inst1_smpl_cmp_en, 
      smpl_cmp_status            => inst1_smpl_cmp_status
   );
   
   -- Connect HW_VER and BOM_VER to fpgacfg registers
   inst1_to_fpgacfg.HW_VER    <= '0' & HW_VER;
   inst1_to_fpgacfg.BOM_VER   <= '0' & BOM_VER; 
   inst1_to_fpgacfg.PWR_SRC   <= '0';
   
   inst1_spi_0_MISO  <= FPGA_SPI_MISO;
   FPGA_SPI_MOSI     <= inst1_spi_0_MOSI;
   FPGA_SPI_SCLK     <= inst1_spi_0_SCLK;
   FPGA_SPI_LMS_SS   <= inst1_spi_0_SS_n(1);
   

   
   
   
-- ----------------------------------------------------------------------------
-- pll_top instance.
-- Clock source for LMS
-- ---------------------------------------------------------------------------- 
   inst2_pll_top : entity work.pll_top
   generic map(
      INTENDED_DEVICE_FAMILY  => g_DEV_FAMILY,
      N_PLL                   => 2,
      -- TX pll parameters
      LMS1_TXPLL_DRCT_C0_NDLY => 1,
      LMS1_TXPLL_DRCT_C1_NDLY => 2,
      -- RX pll parameters
      LMS1_RXPLL_DRCT_C0_NDLY => 1,
      LMS1_RXPLL_DRCT_C1_NDLY => 2
   )
   port map(
      -- LMS#1 TX PLL 0 ports
      lms1_txpll_inclk           => LMS_MCLK1,
      lms1_txpll_reconfig_clk    => sys_clk,
      lms1_txpll_logic_reset_n   => not inst1_pll_rst(0),
      lms1_txpll_clk_ena         => "00",-- UNUSED PORT inst1_from_fpgacfg.CLK_ENA(1 downto 0),
      lms1_txpll_drct_clk_en     => inst1_from_fpgacfg.drct_clk_en(0) & inst1_from_fpgacfg.drct_clk_en(0),
      lms1_txpll_c0              => LMS_FCLK1,
      lms1_txpll_c1              => inst1_lms1_txpll_c1,
      lms1_txpll_locked          => inst1_lms1_txpll_locked,
      -- LMS#1 RX PLL ports
      lms1_rxpll_inclk           => LMS_MCLK2,
      lms1_rxpll_reconfig_clk    => sys_clk,
      lms1_rxpll_logic_reset_n   => not inst1_pll_rst(1),
      lms1_rxpll_clk_ena         => "00",-- UNUSED PORT inst1_from_fpgacfg.CLK_ENA(3 downto 2),
      lms1_rxpll_drct_clk_en     => inst1_from_fpgacfg.drct_clk_en(1) & inst1_from_fpgacfg.drct_clk_en(1),
      lms1_rxpll_c0              => LMS_FCLK2,
      lms1_rxpll_c1              => inst1_lms1_rxpll_c1,
      lms1_rxpll_locked          => inst1_lms1_rxpll_locked,
      -- Sample comparing ports from LMS#1 RX interface
      lms1_smpl_cmp_en           => open,--inst4_rx_smpl_cmp_start,
      lms1_smpl_cmp_done         => '0',--inst4_rx_smpl_cmp_done,
      lms1_smpl_cmp_error        => '0',--inst4_rx_smpl_cmp_err,
      lms1_smpl_cmp_cnt          => open,--inst4_rx_smpl_cmp_cnt,--, 
      -- Reconfiguration AXI ports
      rcnfg_axi_clk              => sys_clk,
      rcnfg_axi_reset_n          => inst1_pll_axi_resetn_out(0),
      rcnfg_from_axim            => inst1_pll_from_axim, 
      rcnfg_to_axim              => inst1_rcnfg_to_axim,
      rcnfg_sel                  => inst1_pll_axi_sel, 
      -- pllcfg ports
      from_pllcfg                => inst1_from_pllcfg,
      to_pllcfg                  => inst1_to_pllcfg
   );
   
   
-- ----------------------------------------------------------------------------
-- rxtx_top instance.
-- Handle rx/tx streams, packets
-- ---------------------------------------------------------------------------- 
--inst3_rxtx_top : entity work.rxtx_top
--generic map(
--   index                   => 1,
--   DEV_FAMILY              => g_DEV_FAMILY,
--   -- TX parameters
--   TX_IQ_WIDTH             => 12,
--   TX_N_BUFF               => g_TX_N_BUFF,              -- 2,4 valid values
--   TX_IN_PCT_SIZE          => g_TX_PCT_SIZE,
--   TX_IN_PCT_HDR_SIZE      => g_TX_IN_PCT_HDR_SIZE,
--   TX_IN_PCT_DATA_W        => c_H2F_S0_0_RWIDTH,      -- 
--   TX_IN_PCT_RDUSEDW_W     => c_H2F_S0_0_RDUSEDW_WIDTH,
--   TX_HIGHSPEED_BUS        => false,
--   
--   -- RX parameters
--   RX_DATABUS_WIDTH        => c_F2H_S0_WWIDTH,
--   RX_IQ_WIDTH             => 12,
--   RX_INVERT_INPUT_CLOCKS  => "ON",
--   RX_PCT_BUFF_WRUSEDW_W   => c_F2H_S0_WRUSEDW_WIDTH --bus width in bits 
--   
--)
--port map(        
--   sys_clk                 => sys_clk,                                     
--   from_fpgacfg            => inst1_from_fpgacfg,
--   to_fpgacfg              => open,  
--   from_memcfg             => inst1_from_memcfg,
--   to_memcfg               => inst1_to_memcfg,
--   -- TX module signals
--   tx_clk                  => inst1_lms1_txpll_c1,      
--   tx_clk_reset_n          => inst1_lms1_txpll_locked,
--   tx_pct_loss_flg         => open,
--   --Tx interface data 
--   tx_smpl_fifo_wrreq      => inst3_tx_samplefifo_wrreq,
--   tx_smpl_fifo_wrfull     => inst3_tx_samplefifo_wrfull,
--   tx_smpl_fifo_wrusedw    => inst3_tx_samplefifo_wrusedw,
--   tx_smpl_fifo_data       => inst3_tx_samplefifo_data,
--   --TX packet FIFO ports
--   tx_in_pct_reset_n_req   => inst0_s0_raclrn,
--   tx_in_pct_rdreq         => inst0_s0_rd,
--   tx_in_pct_data          => inst0_s0_rdata,
--   tx_in_pct_rdempty       => inst0_s0_rempty,
--   tx_in_pct_rdusedw       => inst0_s0_rdusedw,     
--   -- RX path
--   rx_clk                  => inst1_lms1_rxpll_c1,
--   rx_clk_reset_n          => inst1_lms1_rxpll_locked,
--   --RX FIFO for IQ samples   
--   rx_smpl_fifo_wrreq      => inst3_rx_samplefifo_wrreq,
--   rx_smpl_fifo_data       => inst3_rx_samplefifo_data,
--   rx_smpl_fifo_wrfull     => open,
--   --RX Packet FIFO ports
--   rx_pct_fifo_aclrn_req   => inst0_s0_waclrn,
--   rx_pct_fifo_wusedw      => inst0_s0_wrusedw,
--   rx_pct_fifo_wrreq       => inst0_s0_wr,
--   rx_pct_fifo_wdata       => inst0_s0_wdata,
--   -- RX sample nr count enable
--   rx_smpl_nr_cnt_en       => inst3_rx_smpl_cnt_en,
--   
--   ext_rx_en => '0',--dpd_tx_en,   
--   tx_dma_en => inst0_s0_dma_en
--);   

-- ----------------------------------------------------------------------------
-- lms7002m_top instance.
-- Receive and transmit interface for LMS7002
-- ----------------------------------------------------------------------------    
   
      inst4_lms7002_top : entity work.lms7002_top
      generic map (
                   g_DEV_FAMILY             => g_DEV_FAMILY,
                   g_IQ_WIDTH               => 12,
                   g_INV_INPUT_CLK          => "ON",
                   g_TX_SMPL_FIFO_0_WRUSEDW => 9,
                   g_TX_SMPL_FIFO_0_DATAW   => 128,
                   g_TX_SMPL_FIFO_1_WRUSEDW => 9,
                   g_TX_SMPL_FIFO_1_DATAW   => 128
   )
      port map (
                -- Configuration registers
                from_fpgacfg       => inst1_from_fpgacfg,
                from_tstcfg        => inst1_from_tstcfg,
                from_memcfg        => inst1_from_memcfg,
                -- Memory module reset
                mem_reset_n        => global_rst_n,
                -- PORT1 interface
                MCLK1              => inst1_lms1_txpll_c1,
                MCLK1_2x           => '0',
                FCLK1              => open,
                -- DIQ1
                DIQ1               => LMS_DIQ1_D,
                ENABLE_IQSEL1      => LMS_EN_IQSEL1,
                TXNRX1             => LMS_TXNRX1,
                -- PORT2 interface
                MCLK2              => inst1_lms1_rxpll_c1,
                FCLK2              => open,
                -- DIQ2
                DIQ2               => LMS_DIQ2_D,
                ENABLE_IQSEL2      => LMS_EN_IQSEL2,
                TXNRX2             => LMS_TXNRX2,
                -- MISC
                RESET              => inst4_lms_reset,
                TXEN               => LMS_TXEN,
                RXEN               => LMS_RXEN,
                CORE_LDO_EN        => open,
                -- Internal TX ports
                tx_reset_n         => inst1_lms1_txpll_locked,
                tx_fifo_0_wrclk    => inst1_lms1_txpll_c1,
                tx_fifo_0_reset_n  => inst1_from_fpgacfg.rx_en,
                tx_fifo_0_wrreq    => inst3_tx_samplefifo_wrreq,
                tx_fifo_0_data     => inst3_tx_samplefifo_data,
                tx_fifo_0_wrfull   => inst3_tx_samplefifo_wrfull,
                tx_fifo_0_wrusedw  => inst3_tx_samplefifo_wrusedw,
                tx_fifo_1_wrclk    => '0',--tx_fifo_1_wrclk,
                tx_fifo_1_reset_n  => '0',--tx_fifo_1_reset_n,
                tx_fifo_1_wrreq    => '0',--tx_fifo_1_wrreq,
                tx_fifo_1_data     => (others => '0'),--tx_fifo_1_data,
                tx_fifo_1_wrfull   => open,--tx_fifo_1_wrfull,
                tx_fifo_1_wrusedw  => open,--tx_fifo_1_wrusedw,
                tx_ant_en          => inst4_txant_en,
                -- Internal RX ports
                rx_reset_n         => inst1_lms1_rxpll_locked,
                rx_diq_h           => open,
                rx_diq_l           => open,
                rx_data_valid      => inst3_rx_samplefifo_wrreq,
                rx_data            => inst3_rx_samplefifo_data,
                rx_smpl_cmp_start  => inst4_rx_smpl_cmp_start,
                rx_smpl_cmp_length => inst1_from_pllcfg.auto_phcfg_smpls,
                rx_smpl_cmp_done   => inst4_rx_smpl_cmp_done,
                rx_smpl_cmp_err    => inst4_rx_smpl_cmp_err,
                rx_smpl_cnt_en     => inst3_rx_smpl_cnt_en
   );

   inst4_rx_smpl_cmp_start    <= inst1_smpl_cmp_en(0)  ;-- when inst1_smpl_cmp_sel(0)='0' else '0';
   inst1_smpl_cmp_status(0)   <= inst4_rx_smpl_cmp_done;   
   inst1_smpl_cmp_status(1)   <= inst4_rx_smpl_cmp_err ;
   
   
   LMS_RESET <= inst4_lms_reset and inst1_from_fpgacfg.LMS_RST;--inst1_lms_reset_cpu; -- reset is active low, so any module can reset the LMS
   --en_tcxo    <= inst1_from_fpgacfg.TCXO_EN;--'1'; --tcxo enabled
   --ext_clk    <= inst1_from_fpgacfg.EXT_CLK;--'0'; --internal clock used
   
   en_tcxo    <= '0';--'1'; --tcxo disabled
   ext_clk    <= '1';--'0'; --external clock used

   LMS_CORE_LDO_EN <= inst1_from_fpgacfg.CORE_LDO_EN;
   
-- ----------------------------------------------------------------------------
-- tdd_control instance.
-- Simple module for TDD signal control
-- ----------------------------------------------------------------------------    
    inst5_tdd_control : entity work.tdd_control
      port map (
                MANUAL_VALUE       => inst1_from_fpgacfg.tdd_manual,
                AUTO_ENABLE        => inst1_from_fpgacfg.tdd_auto_en,
                AUTO_IN            => inst4_txant_en,
                AUTO_INVERT        => inst1_from_fpgacfg.tdd_invert,
                --
                RX_RF_SW_IN        => inst1_from_fpgacfg.rx_rf_sw,
                TX_RF_SW_IN        => inst1_from_fpgacfg.tx_rf_sw,
                RF_SW_AUTO_ENANBLE => inst1_from_fpgacfg.rf_sw_auto_en,
                --
                TDD_OUT            => TDD_GPIO3_N, --This GPIO is used for TDD control
                RX_RF_SW_OUT       => rx_switches,
                TX_RF_SW_OUT       => TX_SW
   );
   
   RX_SW3       <= rx_switches(0);
   RX_SW2       <= rx_switches(1);
   EN_GPIO      <= '0';
   
   
   
-- ----------------------------------------------------------------------------
-- tst_top instance.
-- Clock test logic
-- ----------------------------------------------------------------------------
   inst6_tst_top : entity work.tst_top
   port map(
      --input ports 
      sys_clk           => FPGA_CLK,
      reset_n           => '1',    
      LMS_TX_CLK        => FPGA_CLK,
      
      GNSS_UART_RX      => GNSS_RXD,
      GNSS_UART_TX      => GNSS_TXD,
   
      -- To configuration memory
      to_tstcfg         => inst1_to_tstcfg,
      from_tstcfg       => inst1_from_tstcfg
   );
   
   GNSS_HW_S <= '1';
   GNSS_HW_R <= '1';


  usb_clk_mmcm_inst : entity work.usb_clk_mmcm
   port map (
      clk_in1  => sys_clk,
      resetn   => global_rst_n,
      clk_out1 => USB_26M,
      locked   => open
   );
   
   BUFG_inst : BUFG
   port map (
      O => usb_clk_g, -- 1-bit output: Clock output
      I => USB_CLK  -- 1-bit input: Clock input
   );

-- ----------------------------------------------------------------------------
-- vctcxo_tamer instance.
-- ----------------------------------------------------------------------------  
vctcxo_tamer_top_inst : entity work. vctcxo_tamer_top
      generic map ( 
         G_UART_BAUD_RATE        => 9600,
         G_USB_CLK_FREQUENCY     => 60000000,
         MM_CLOCK_FREQUENCY      => 100000000
      )
      port map (
         --USB to serial ULPI interface
         USB_NRST => USB_NRST,
         USB_D    => USB_D,
         USB_STP  => USB_STP,
         USB_NXT  => USB_NXT,
         USB_DIR  => USB_DIR,
         USB_CLK  => usb_clk_g,
   
         -- Physical VCXO tamer Interface
         tune_ref     => PPSI_GPIO1,
         vctcxo_clock => FPGA_CLK
   );
--    -- ----------------------------------------------------------------------------
--    -- vctcxo_tamer instance.
--    -- ----------------------------------------------------------------------------
--       vctcxo_tamer_inst : entity work.vctcxo_tamer
--       port map(
--          -- Physical Interface
--          tune_ref           => GNSS_1PPS,
--          vctcxo_clock       => FPGA_CLK,
--    
--          -- Avalon-MM Interface
--          mm_clock           => sys_clk, 
--          mm_reset           => '0',
--          mm_rd_req          => '0',
--          mm_wr_req          => '0',
--          mm_addr            => (others=>'0'),
--          mm_wr_data         => (others=>'0'),
--          mm_rd_data         => open,
--          mm_rd_datav        => open,
--          mm_wait_req        => open,
--          -- Avalon Interrupts
--          mm_irq             => open,
--        
--          PPS_1S_ERROR_TOL   => (others=>'0'),
--          PPS_10S_ERROR_TOL  => (others=>'0'),
--          PPS_100S_ERROR_TOL => (others=>'0'),
--        
--          -- Status registers
--          pps_1s_error       => open,
--          pps_10s_error      => open,
--          pps_100s_error     => open,
--          accuracy           => open,
--          state              => open,
--          dac_tuned_val      => open,
--          pps_1s_count_v     => open,
--          pps_10s_count_v    => open,
--          pps_100s_count_v   => open
--        );
--       
--        BUFG_inst : BUFG
--        port map (
--           O => usb_clk_g, -- 1-bit output: Clock output
--           I => USB_CLK  -- 1-bit input: Clock input
--        );
--    
--    
--    usb_serial_inst : usb_serial 
--    generic map(
--        BAUDRATE => 9600
--    )
--    port map(
--        -- Serial
--        uart_rx_o => usb_serial_rx_o,
--        uart_tx_i => usb_serial_tx_i,
--    
--        --ULPI Interface
--        ulpi_reset_o        => USB_NRST,
--        ulpi_data_io        => USB_D,
--        ulpi_stp_o          => USB_STP,
--        ulpi_nxt_i          => USB_NXT,
--        ulpi_dir_i          => USB_DIR,
--        ulpi_clk60_i        => usb_clk_g,
--        reset_out           => usb_reset_out
--    );
--    
--    
--    inst1_uart : entity work.uart
--    generic map
--    (
--       BAUD_RATE       => 9600,
--       CLOCK_FREQUENCY => 60000000
--    )
--    port map
--    (
--       CLOCK                     => usb_clk_g,
--       RESET                     => usb_reset_out,
--       DATA_STREAM_IN            => uart_data_stream_in,
--       DATA_STREAM_IN_STB        => uart_data_stream_in_stb,
--       DATA_STREAM_IN_ACK        => uart_data_stream_in_ack,
--       DATA_STREAM_OUT           => uart_data_stream_out    ,
--       DATA_STREAM_OUT_STB       => uart_data_stream_out_stb,
--       DATA_STREAM_OUT_ACK       => uart_data_stream_out_ack,
--       TX                        => usb_serial_tx_i,                 
--       RX                        => usb_serial_rx_o                 
--    );
--    
--    process(usb_clk_g)
--    begin
--       if (usb_clk_g'event and usb_clk_g = '1') then
--          if uart_data_stream_out_stb = '1' AND uart_data_stream_out_ack = '0' then 
--             uart_data_stream_out_ack <= '1';
--          else 
--             uart_data_stream_out_ack <= '0';
--          end if;
--       end if;
--    end process;
--    
--    process(usb_clk_g, usb_reset_out)
--    begin
--       if usb_reset_out = '1' then 
--          uart_data_stream_in_stb <= '0';
--       elsif (usb_clk_g'event and usb_clk_g = '1') then
--          if fpga_led1_rising = '1' AND uart_data_stream_in_ack = '0' then 
--             uart_data_stream_in_stb <= '1';
--          elsif uart_data_stream_in_ack = '1' then
--             uart_data_stream_in_stb <= '0';
--          else 
--             uart_data_stream_in_stb <= uart_data_stream_in_stb;
--          end if;
--       end if;
--    end process;
--    
--    process (all)
--    begin
--       uart_data_stream_in <= c_ASCII_ARRAY(to_integer(ascii_cnt));
--    end process;
--    
--    nmea_parser_inst : entity work.nmea_parser
--       port map (
--          clk         => usb_clk_g,
--          reset_n     => NOT usb_reset_out,
--          data        => uart_data_stream_out,  --NMEA data character
--          data_v      => uart_data_stream_out_stb AND uart_data_stream_out_ack,  --NMEA data valid
--          
--          --Parsed NMEA sentences (ASCII format)
--    
--          IIENA_valid       => iiena_valid,
--          IIENA_EN          => iiena_en,
--    
--          IICFG_valid       => iicfg_valid,
--          IICFG_1S_TARGET   => open,
--          IICFG_1S_TOL      => iicfg_1s_tol,
--          IICFG_10S_TARGET  => open,
--          IICFG_10S_TOL     => iicfg_10s_tol,
--          IICFG_100S_TARGET => open,
--          IICFG_100S_TOL    => iicfg_100s_tol
--       );


-- ----------------------------------------------------------------------------
-- LED control module
-- 
-- ---------------------------------------------------------------------------- 
   inst7_led_ctrl : entity work.led_ctrl
   port map(
   CLK1 => FPGA_CLK,
   CLK2 => sys_clk, 
   LED1 => fpga_led1_int,
   LED2 => FPGA_LED2
   );

   FPGA_LED1 <=fpga_led1_int;

   process (usb_clk_g)
   begin
      if rising_edge(usb_clk_g) then 
         fpga_led1_sync_usb_clk <= fpga_led1_sync_usb_clk(0) & fpga_led1_int;
      end if;
   end process;



   process(usb_clk_g)
   begin 
      if rising_edge(usb_clk_g) then 
         fpga_led1_reg <= fpga_led1_sync_usb_clk(1);

         if fpga_led1_reg = '0' AND fpga_led1_sync_usb_clk(1) = '1' then 
            fpga_led1_rising <= '1';
         else 
            fpga_led1_rising <= '0';
         end if;
      end if;
   end process;

   process (usb_clk_g, usb_reset_out)
   begin
      if usb_reset_out = '1' then 
         ascii_cnt <= (others=>'0');
      elsif rising_edge(usb_clk_g) then 
         if fpga_led1_rising = '1' then 
            if ascii_cnt >= 11 then 
               ascii_cnt <= (others =>'0');
            else 
               ascii_cnt <= ascii_cnt + 1;
            end if;
         end if;
      end if;
   end process;





-- ----------------------------------------------------------------------------
-- GPIOs
-- 
-- ----------------------------------------------------------------------------
-- PPSO_GPIO2 is overriden by user and set to High Z by default. 
-- To pass trough GNSS_1PPS: set 0x00C0(1) to '0'.
   PPSO_GPIO2 <=  pps_internal                           when inst1_from_periphcfg.BOARD_GPIO_OVRD(1) = '0' else  
                  inst1_from_periphcfg.BOARD_GPIO_VAL(1) when inst1_from_periphcfg.BOARD_GPIO_DIR(1)= '1' else 
                  'Z';
               
-- Option to select pps between GPS and externaly connected PPS
   pps_internal <= PPSI_GPIO1 when inst1_from_periphcfg.PERIPH_INPUT_SEL_0(1 downto 0) = "01" else GNSS_1PPS;


end architecture Structural;