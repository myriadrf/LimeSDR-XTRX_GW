-- ----------------------------------------------------------------------------
-- FILE:          cpu_top.vhd
-- DESCRIPTION:   CPU top level
-- DATE:          10:52 AM Friday, May 11, 2018
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
use work.fpgacfg_pkg.all;
use work.pllcfg_pkg.all;
use work.tstcfg_pkg.all;
use work.txtspcfg_pkg.all;
use work.rxtspcfg_pkg.all;
use work.periphcfg_pkg.all;
use work.tamercfg_pkg.all;
use work.gnsscfg_pkg.all;
use work.memcfg_pkg.all;
use work.axi_pkg.all;
use work.cdcmcfg_pkg.all;
use work.fircfg_pkg.all;  --B.J.

-- ----------------------------------------------------------------------------
-- Entity declaration
-- ----------------------------------------------------------------------------
entity cpu_top is
   generic(
      -- CFG_START_ADDR has to be multiple of 32, because there are 32 addresses
      FPGACFG_START_ADDR   : integer := 0;
      PLLCFG_START_ADDR    : integer := 32;
      TSTCFG_START_ADDR    : integer := 96;
      TXTSPCFG_START_ADDR  : integer := 128;
      RXTSPCFG_START_ADDR  : integer := 160;
      PERIPHCFG_START_ADDR : integer := 192;
      TAMERCFG_START_ADDR  : integer := 224;
      GNSSCFG_START_ADDR   : integer := 256;
      FIRCFG_START_ADDRR   : integer := 288; -- B.J.
      RXTSPCFG_START_ADDR_3  : integer := 352; -- B.J.
      FIRCFG_TX    : integer := 704;  -- B.J. (for Transmitter equaliser)
      FIRCFG_RX    : integer := 704+32; -- B.J. (for Receiver equaliser)
      MEMCFG_START_ADDR    : integer := 65504
      );
   port (
      clk                  : in     std_logic;
      reset_n              : in     std_logic;
      --LMS1 clock
      --lms1_txpll_inclk     : in     std_logic;
      --lms1_txpll_c0        : out    std_logic;
      --lms1_txpll_c1        : out    std_logic;
      --lms1_txpll_locked    : out    std_logic;
      -- Control data FIFO
      exfifo_if_d          : in     std_logic_vector(31 downto 0);
      exfifo_if_rd         : out    std_logic;
      exfifo_if_rdempty    : in     std_logic;
      exfifo_of_d          : out    std_logic_vector(31 downto 0);
      exfifo_of_wr         : out    std_logic;
      exfifo_of_wrfull     : in     std_logic;
      exfifo_of_rst        : out    std_logic;
      -- SPI 0
      spi_0_MISO           : in     std_logic;
      spi_0_MOSI           : out    std_logic;
      spi_0_SCLK           : out    std_logic;
      spi_0_SS_n           : out    std_logic_vector(3 downto 0);
      -- SPI 1
      spi_1_MISO           : in     std_logic;
      spi_1_MOSI           : out    std_logic;
      spi_1_SCLK           : out    std_logic;
      spi_1_SS_n           : out    std_logic_vector(5 downto 0);
      -- SPI 2 
      spi_2_MISO           : in     std_logic;
      spi_2_MOSI           : out    std_logic;
      spi_2_SCLK           : out    std_logic;
      spi_2_SS_n           : out    std_logic_vector(3 downto 0); 
      -- I2C
      i2c_scl              : inout  std_logic;
      i2c_sda              : inout  std_logic;
	  -- Configuration Flash SPI
	  fpga_cfg_qspi_MISO   : in     std_logic;
	  fpga_cfg_qspi_MOSI   : out    std_logic;
	  fpga_cfg_qspi_SS_n   : out    std_logic;
      -- Genral purpose I/O
      gpi                  : in     std_logic_vector(7 downto 0);
      gpo                  : out    std_logic_vector(7 downto 0);
      -- LMS7002 control
      lms_ctr_gpio         : out    std_logic_vector(3 downto 0);
      -- VCTCXO tamer control
      vctcxo_tune_en       : in     std_logic;
      vctcxo_irq           : in     std_logic;
      -- PLL reconfiguration
      pll_rst              : out    std_logic_vector(31 downto 0);
      pll_axi_resetn_out   : out    std_logic_vector ( 0 to 0 );
      pll_from_axim        : out    t_FROM_AXIM_32x32;
      pll_to_axim          : in     t_TO_AXIM_32x32;
      pll_axi_sel          : out    std_logic_vector(3 downto 0);
      pll_rcfg_from_pll_0  : in     std_logic_vector(63 downto 0) := (others => '0');
      pll_rcfg_to_pll_0    : out    std_logic_vector(63 downto 0);
      pll_rcfg_from_pll_1  : in     std_logic_vector(63 downto 0) := (others => '0');
      pll_rcfg_to_pll_1    : out    std_logic_vector(63 downto 0);
      pll_rcfg_from_pll_2  : in     std_logic_vector(63 downto 0) := (others => '0');
      pll_rcfg_to_pll_2    : out    std_logic_vector(63 downto 0);
      pll_rcfg_from_pll_3  : in     std_logic_vector(63 downto 0) := (others => '0');
      pll_rcfg_to_pll_3    : out    std_logic_vector(63 downto 0);
      pll_rcfg_from_pll_4  : in     std_logic_vector(63 downto 0) := (others => '0');
      pll_rcfg_to_pll_4    : out    std_logic_vector(63 downto 0);
      pll_rcfg_from_pll_5  : in     std_logic_vector(63 downto 0) := (others => '0');
      pll_rcfg_to_pll_5    : out    std_logic_vector(63 downto 0);
      -- Avalon Slave port 0
      avmm_s0_address      : in     std_logic_vector(8 downto 0) := (others => 'X');  -- address
      avmm_s0_read         : in     std_logic                     := 'X';             -- read
      avmm_s0_readdata     : out    std_logic_vector(31 downto 0);                    -- readdata
      avmm_s0_write        : in     std_logic                     := 'X';             -- write
      avmm_s0_writedata    : in     std_logic_vector(31 downto 0) := (others => 'X'); -- writedata
      avmm_s0_waitrequest  : out    std_logic;                                        -- waitrequest
      -- Avalon Slave port 1
      avmm_s1_address      : in     std_logic_vector(8 downto 0) := (others => 'X');  -- address
      avmm_s1_read         : in     std_logic                     := 'X';             -- read
      avmm_s1_readdata     : out    std_logic_vector(31 downto 0);                    -- readdata
      avmm_s1_write        : in     std_logic                     := 'X';             -- write
      avmm_s1_writedata    : in     std_logic_vector(31 downto 0) := (others => 'X'); -- writedata
      avmm_s1_waitrequest  : out    std_logic;                                        -- waitrequest
      -- Avalon master
      avmm_m0_address      : out    std_logic_vector(7 downto 0);                     -- avmm_m0.address
      avmm_m0_read         : out    std_logic;                                        --       .read
      avmm_m0_waitrequest  : in     std_logic                     := '0';             --       .waitrequest
      avmm_m0_readdata     : in     std_logic_vector(7 downto 0)  := (others => '0'); --       .readdata
      avmm_m0_readdatavalid: in     std_logic                     := '0';             --       .readdatavalid
      avmm_m0_write        : out    std_logic;                                        --       .write
      avmm_m0_writedata    : out    std_logic_vector(7 downto 0);                     --       .writedata
      avmm_m0_clk_clk      : out    std_logic;                                        -- avm_m0_clk.clk
      avmm_m0_reset_reset  : out    std_logic;
      -- Configuration registers
      from_fpgacfg_0       : out    t_FROM_FPGACFG;
      to_fpgacfg_0         : in     t_TO_FPGACFG;
      from_fpgacfg_1       : out    t_FROM_FPGACFG;
      to_fpgacfg_1         : in     t_TO_FPGACFG;
      from_fpgacfg_2       : out    t_FROM_FPGACFG;
      to_fpgacfg_2         : in     t_TO_FPGACFG;
      from_pllcfg          : out    t_FROM_PLLCFG;
      to_pllcfg            : in     t_TO_PLLCFG;
      from_tstcfg          : out    t_FROM_TSTCFG;
      to_tstcfg            : in     t_TO_TSTCFG;
      to_tstcfg_from_rxtx  : in     t_TO_TSTCFG_FROM_RXTX;
      to_txtspcfg_0        : in     t_TO_TXTSPCFG;
      from_txtspcfg_0      : out    t_FROM_TXTSPCFG;
      to_txtspcfg_1        : in     t_TO_TXTSPCFG;
      from_txtspcfg_1      : out    t_FROM_TXTSPCFG;

      --to_rxtspcfg          : in     t_TO_RXTSPCFG;
      --from_rxtspcfg        : out    t_FROM_RXTSPCFG;

      to_rxtspcfg_2a          : in     t_TO_RXTSPCFG;  -- B.J.
      from_rxtspcfg_2a        : out    t_FROM_RXTSPCFG; -- B.J.
      to_rxtspcfg_2b          : in     t_TO_RXTSPCFG; -- B.J.
      from_rxtspcfg_2b        : out    t_FROM_RXTSPCFG; -- B.J.

      to_periphcfg         : in     t_TO_PERIPHCFG;
      from_periphcfg       : out    t_FROM_PERIPHCFG;
      to_tamercfg          : in     t_TO_TAMERCFG;
      from_tamercfg        : out    t_FROM_TAMERCFG;
      to_gnsscfg           : in     t_TO_GNSSCFG;
      from_gnsscfg         : out    t_FROM_GNSSCFG;
      to_memcfg            : in     t_TO_MEMCFG;
      from_memcfg          : out    t_FROM_MEMCFG;
      from_cdcmcfg         : out    t_FROM_CDCMCFG;     
      -- testing
      pll_c0               : out    std_logic;
      pll_c1               : out    std_logic;
      pll_locked           : out    std_logic;
      smpl_cmp_en          : out    std_logic_vector ( 3 downto 0 );
      smpl_cmp_status      : in     std_logic_vector ( 1 downto 0 );
      smpl_cmp_sel         : out    std_logic_vector (0 downto 0);

      to_rxtspcfg_3a       : in  t_TO_RXTSPCFG;    -- B.J.
      from_rxtspcfg_3a     : out t_FROM_RXTSPCFG;  -- B.J.
      to_rxtspcfg_3b       : in  t_TO_RXTSPCFG;    -- B.J.
      from_rxtspcfg_3b     : out t_FROM_RXTSPCFG;   -- B.J.

      from_fircfg_tx_a     : out    t_FROM_FIRCFG; -- B.J.
      from_fircfg_tx_b     : out    t_FROM_FIRCFG; -- B.J.
      from_fircfg_rx_a     : out    t_FROM_FIRCFG; -- B.J.
      from_fircfg_rx_b     : out    t_FROM_FIRCFG  -- B.J.
   );
end cpu_top;

-- ----------------------------------------------------------------------------
-- Architecture
-- ----------------------------------------------------------------------------
architecture arch of cpu_top is
--declare signals,  components here
   constant c_SPI0_FPGA_SS_NR       : integer := 0;

   signal to_pllcfg_int             : t_TO_PLLCFG;
   
   signal smpl_cmp_status_sync         : std_logic_vector(1 downto 0);

   -- inst0
   signal inst0_spi_0_MISO          : std_logic;
   signal inst0_spi_0_MOSI          : std_logic;
   signal inst0_spi_0_SCLK          : std_logic;
   signal inst0_spi_0_SS_n          : std_logic_vector(3 downto 0);
   
   signal inst0_spi_1_MISO          : std_logic;
   signal inst0_spi_1_MOSI          : std_logic;
   signal inst0_spi_1_SCLK          : std_logic;
   signal inst0_spi_1_SS_n          : std_logic_vector(5 downto 0);
   
   signal inst0_spi_2_MISO          : std_logic;
   signal inst0_spi_2_MOSI          : std_logic;
   signal inst0_spi_2_SCLK          : std_logic;
   signal inst0_spi_2_SS_n          : std_logic_vector(3 downto 0);
   
   signal inst0_fpga_cfg_qspi_io0_i : std_logic;
   signal inst0_fpga_cfg_qspi_io0_o : std_logic; 
   signal inst0_fpga_cfg_qspi_io0_t : std_logic; 
   signal inst0_fpga_cfg_qspi_io1_i : std_logic; 
   signal inst0_fpga_cfg_qspi_io1_o : std_logic; 
   signal inst0_fpga_cfg_qspi_io1_t : std_logic; 
   signal inst0_fpga_cfg_qspi_ss_o  : std_logic_vector(0 downto 0);
   signal inst0_fpga_cfg_qspi_ss_t  : std_logic_vector(0 downto 0);
   
   signal inst0_iic_0_scl_o         : std_logic;
   signal inst0_iic_0_scl_t         : std_logic;
   signal inst0_iic_0_sda_o         : std_logic;
   signal inst0_iic_0_sda_t         : std_logic;
   
   signal inst0_fpga_spi0_MISO      : std_logic;
   signal inst0_dac_spi1_SS_n       : std_logic;
   signal inst0_dac_spi1_MOSI       : std_logic;
   signal inst0_dac_spi1_SCLK       : std_logic;
   signal inst0_fpga_spi0_MOSI      : std_logic;
   signal inst0_fpga_spi0_SCLK      : std_logic;
   signal inst0_fpga_spi0_SS_n      : std_logic_vector(7 downto 0);
   signal inst0_pllcfg_spi_MOSI     : std_logic;
   signal inst0_pllcfg_spi_SCLK     : std_logic;
   signal inst0_pllcfg_spi_SS_n     : std_logic;
   signal inst0_pllcfg_cmd_export   : std_logic_vector(3 downto 0);
   signal inst0_pllcfg_stat_export  : std_logic_vector(11 downto 0);
   
   signal inst0_avmm_m0_address     : std_logic_vector(31 downto 0);
   signal inst0_avmm_m0_readdata    : std_logic_vector(31 downto 0);
   signal inst0_avmm_m0_writedata   : std_logic_vector(31 downto 0);
   
   
   --inst1
   signal inst1_sdout            : std_logic;
   signal inst1_pllcfg_sdout     : std_logic;
   
   signal avmm_s0_address_int    : std_logic_vector(31 downto 0);
   signal avmm_s1_address_int    : std_logic_vector(31 downto 0);
   
   signal vctcxo_tune_en_sync    : std_logic;
   signal vctcxo_irq_sync        : std_logic;
   
   signal vctcxo_tamer_0_irq_out_irq   : std_logic;
   signal vctcxo_tamer_0_ctrl_export   : std_logic_vector(3 downto 0);
       
   component mb_subsystem is
   port (
      clk                        : in std_logic;
      avmm_m0_address            : out STD_LOGIC_VECTOR ( 31 downto 0 );
      avmm_m0_read               : out STD_LOGIC;
      avmm_m0_readdata           : in STD_LOGIC_VECTOR ( 31 downto 0 );
      avmm_m0_readdatavalid      : in STD_LOGIC;
      avmm_m0_waitrequest        : in STD_LOGIC;
      avmm_m0_write              : out STD_LOGIC;
      avmm_m0_writedata          : out STD_LOGIC_VECTOR ( 31 downto 0 );
      fifo_read_0_almost_empty   : in std_logic;
      fifo_read_0_empty          : in std_logic;
      fifo_read_0_rd_data        : in std_logic_vector ( 31 downto 0 );
      fifo_read_0_rd_en          : out std_logic;
      fifo_write_0_aclr          : out std_logic;
      fifo_write_0_almost_full   : in std_logic;
      fifo_write_0_full          : in std_logic;
      fifo_write_0_wr_data       : out std_logic_vector ( 31 downto 0 );
      fifo_write_0_wr_en         : out std_logic;
      gpio_0_tri_i               : in std_logic_vector ( 7 downto 0 );
      gpio_1_tri_o               : out std_logic_vector ( 7 downto 0 );
      iic_0_scl_i                : in std_logic;
      iic_0_scl_o                : out std_logic;
      iic_0_scl_t                : out std_logic;
      iic_0_sda_i                : in std_logic;
      iic_0_sda_o                : out std_logic;
      iic_0_sda_t                : out std_logic;
      pll_rst_tri_o              : out STD_LOGIC_VECTOR ( 31 downto 0 );
      pllcfg_cmd_tri_i           : in STD_LOGIC_VECTOR ( 3 downto 0 );
      pllcfg_stat_tri_o          : out STD_LOGIC_VECTOR ( 11 downto 0 );
      reset_n                    : in std_logic;
      spi_0_io0_i                : in std_logic;
      spi_0_io0_o                : out std_logic;
      spi_0_io0_t                : out std_logic;
      spi_0_io1_i                : in std_logic;
      spi_0_io1_o                : out std_logic;
      spi_0_io1_t                : out std_logic;
      spi_0_sck_i                : in std_logic;
      spi_0_sck_o                : out std_logic;
      spi_0_sck_t                : out std_logic;
      spi_0_ss_i                 : in std_logic_vector ( 3 downto 0 );
      spi_0_ss_o                 : out std_logic_vector ( 3 downto 0 );
      spi_0_ss_t                 : out std_logic;
      spi_1_io0_i                : in std_logic;
      spi_1_io0_o                : out std_logic;
      spi_1_io0_t                : out std_logic;
      spi_1_io1_i                : in std_logic;
      spi_1_io1_o                : out std_logic;
      spi_1_io1_t                : out std_logic;
      spi_1_sck_i                : in std_logic;
      spi_1_sck_o                : out std_logic;
      spi_1_sck_t                : out std_logic;
      spi_1_ss_i                 : in std_logic_vector ( 5 downto 0 );
      spi_1_ss_o                 : out std_logic_vector ( 5 downto 0 );
      spi_1_ss_t                 : out std_logic;
      spi_2_io0_i                : in std_logic;
      spi_2_io0_o                : out std_logic;
      spi_2_io0_t                : out std_logic;
      spi_2_io1_i                : in std_logic;
      spi_2_io1_o                : out std_logic;
      spi_2_io1_t                : out std_logic;
      spi_2_sck_i                : in std_logic;
      spi_2_sck_o                : out std_logic;
      spi_2_sck_t                : out std_logic;
      spi_2_ss_i                 : in std_logic_vector ( 3 downto 0 );
      spi_2_ss_o                 : out std_logic_vector ( 3 downto 0 );
      spi_2_ss_t                 : out std_logic;
      fpga_cfg_qspi_io0_i        : in  std_logic;
      fpga_cfg_qspi_io0_o        : out std_logic; 
      fpga_cfg_qspi_io0_t        : out std_logic; 
      fpga_cfg_qspi_io1_i        : in  std_logic; 
      fpga_cfg_qspi_io1_o        : out std_logic; 
      fpga_cfg_qspi_io1_t        : out std_logic; 
      fpga_cfg_qspi_ss_i         : in  std_logic_vector(0 downto 0); 
      fpga_cfg_qspi_ss_o         : out std_logic_vector(0 downto 0); 
      fpga_cfg_qspi_ss_t         : out std_logic_vector(0 downto 0); 
      uart_0_rxd                 : in std_logic;
      uart_0_txd                 : out std_logic;
      extm_axi_resetn_out        : out STD_LOGIC_VECTOR ( 0 to 0 );
      extm_0_axi_araddr          : out STD_LOGIC_VECTOR ( 31 downto 0 );
      extm_0_axi_arprot          : out STD_LOGIC_VECTOR ( 2 downto 0 );
      extm_0_axi_arready         : in STD_LOGIC_VECTOR ( 0 to 0 );
      extm_0_axi_arvalid         : out STD_LOGIC_VECTOR ( 0 to 0 );
      extm_0_axi_awaddr          : out STD_LOGIC_VECTOR ( 31 downto 0 );
      extm_0_axi_awprot          : out STD_LOGIC_VECTOR ( 2 downto 0 );
      extm_0_axi_awready         : in STD_LOGIC_VECTOR ( 0 to 0 );
      extm_0_axi_awvalid         : out STD_LOGIC_VECTOR ( 0 to 0 );
      extm_0_axi_bready          : out STD_LOGIC_VECTOR ( 0 to 0 );
      extm_0_axi_bresp           : in STD_LOGIC_VECTOR ( 1 downto 0 );
      extm_0_axi_bvalid          : in STD_LOGIC_VECTOR ( 0 to 0 );
      extm_0_axi_rdata           : in STD_LOGIC_VECTOR ( 31 downto 0 );
      extm_0_axi_rready          : out STD_LOGIC_VECTOR ( 0 to 0 );
      extm_0_axi_rresp           : in STD_LOGIC_VECTOR ( 1 downto 0 );
      extm_0_axi_rvalid          : in STD_LOGIC_VECTOR ( 0 to 0 );
      extm_0_axi_wdata           : out STD_LOGIC_VECTOR ( 31 downto 0 );
      extm_0_axi_wready          : in STD_LOGIC_VECTOR ( 0 to 0 );
      extm_0_axi_wstrb           : out STD_LOGIC_VECTOR ( 3 downto 0 );
      extm_0_axi_wvalid          : out STD_LOGIC_VECTOR ( 0 to 0 ); 
      extm_0_axi_sel_tri_o       : out STD_LOGIC_VECTOR ( 3 downto 0 );
      smpl_cmp_en_tri_o          : out STD_LOGIC_VECTOR ( 3 downto 0 );
      smpl_cmp_status_tri_i      : in STD_LOGIC_VECTOR ( 1 downto 0 );
      smpl_cmp_sel_tri_o         : out STD_LOGIC_VECTOR ( 0 to 0 );
      vctcxo_tamer_0_ctrl_tri_i  : in STD_LOGIC_VECTOR ( 3 downto 0 );
      cdcm_read_start_tri_i      : in STD_LOGIC_VECTOR ( 0 downto 0 );
      cdcm_cfg_start_tri_i       : in STD_LOGIC_VECTOR ( 0 downto 0 );
      
      
      pll_c0                     : out STD_LOGIC;
      pll_c1                     : out STD_LOGIC;
      pll_locked                 : out STD_LOGIC
   );
   end component;
   

begin


-- ----------------------------------------------------------------------------
-- Synchronization registers
-- ---------------------------------------------------------------------------- 
   sync_reg0 : entity work.sync_reg 
   port map(clk, '1', vctcxo_tune_en, vctcxo_tune_en_sync);
   
   sync_reg1 : entity work.sync_reg 
   port map(clk, '1', vctcxo_irq, vctcxo_irq_sync);
   
   bus_sync_reg0 : entity work.bus_sync_reg
   generic map (2) 
   port map(clk, '1', smpl_cmp_status, smpl_cmp_status_sync);
   
   
   -- byte oriented address is shifted to be word aligned
   avmm_s0_address_int <=  "00000000000000000000000" & 
                           avmm_s0_address(8) & 
                           avmm_s0_address(5 downto 0) & 
                           "00"; -- address range   0 - 1FF
   avmm_s1_address_int <=  "00000000000000000000001" & 
                           avmm_s1_address(8) & 
                           avmm_s1_address(5 downto 0) & 
                           "00"; -- address range 200 - 3FF
   
-- ----------------------------------------------------------------------------
-- MicroBlaze instance
-- ----------------------------------------------------------------------------
   inst0_mb_cpu : mb_subsystem
   port map (
      clk                      => clk,
      avmm_m0_address          => inst0_avmm_m0_address,
      avmm_m0_read             => avmm_m0_read,
      avmm_m0_readdata         => inst0_avmm_m0_readdata,
      avmm_m0_readdatavalid    => avmm_m0_readdatavalid,
      avmm_m0_waitrequest      => avmm_m0_waitrequest,
      avmm_m0_write            => avmm_m0_write,
      avmm_m0_writedata        => inst0_avmm_m0_writedata,
      fifo_read_0_almost_empty => '0',
      fifo_read_0_empty        => exfifo_if_rdempty,
      fifo_read_0_rd_data      => exfifo_if_d,
      fifo_read_0_rd_en        => exfifo_if_rd,
      fifo_write_0_aclr        => exfifo_of_rst,
      fifo_write_0_almost_full => '0',
      fifo_write_0_full        => exfifo_of_wrfull,
      fifo_write_0_wr_data     => exfifo_of_d,
      fifo_write_0_wr_en       => exfifo_of_wr,
      gpio_0_tri_i             => gpi,
      gpio_1_tri_o             => gpo,
      iic_0_scl_i              => i2c_scl,
      iic_0_scl_o              => inst0_iic_0_scl_o,
      iic_0_scl_t              => inst0_iic_0_scl_t,
      iic_0_sda_i              => i2c_sda,
      iic_0_sda_o              => inst0_iic_0_sda_o,
      iic_0_sda_t              => inst0_iic_0_sda_t,
      pll_rst_tri_o            => pll_rst,
      pllcfg_cmd_tri_i         => inst0_pllcfg_cmd_export,
      pllcfg_stat_tri_o        => inst0_pllcfg_stat_export,
      reset_n                  => reset_n,
      spi_0_io0_i              => '0',
      spi_0_io0_o              => inst0_spi_0_MOSI,
      spi_0_io0_t              => open,
      spi_0_io1_i              => spi_0_MISO OR inst1_sdout,
      spi_0_io1_o              => open,
      spi_0_io1_t              => open,
      spi_0_sck_i              => '0',
      spi_0_sck_o              => inst0_spi_0_SCLK,
      spi_0_sck_t              => open,
      spi_0_ss_i               => (others=>'0'),
      spi_0_ss_o               => inst0_spi_0_SS_n,
      spi_0_ss_t               => open,
      
      spi_1_io0_i              => '0',
      spi_1_io0_o              => inst0_spi_1_MOSI,
      spi_1_io0_t              => open,
      spi_1_io1_i              => spi_1_MISO,
      spi_1_io1_o              => open,
      spi_1_io1_t              => open,
      spi_1_sck_i              => '0',
      spi_1_sck_o              => inst0_spi_1_SCLK,
      spi_1_sck_t              => open,
      spi_1_ss_i               => (others=>'0'),
      spi_1_ss_o               => inst0_spi_1_SS_n,
      spi_1_ss_t               => open,
      
      spi_2_io0_i              => '0',
      spi_2_io0_o              => inst0_spi_2_MOSI,
      spi_2_io0_t              => open,
      spi_2_io1_i              => spi_2_MISO,
      spi_2_io1_o              => open,
      spi_2_io1_t              => open,
      spi_2_sck_i              => '0',
      spi_2_sck_o              => inst0_spi_2_SCLK,
      spi_2_sck_t              => open,
      spi_2_ss_i               => (others=>'0'),
      spi_2_ss_o               => inst0_spi_2_SS_n,
      spi_2_ss_t               => open,
      uart_0_rxd               => '0',
      uart_0_txd               => open,
      
      fpga_cfg_qspi_io0_i      => inst0_fpga_cfg_qspi_io0_i,
      fpga_cfg_qspi_io0_o      => inst0_fpga_cfg_qspi_io0_o,
      fpga_cfg_qspi_io0_t      => inst0_fpga_cfg_qspi_io0_t,    
      fpga_cfg_qspi_io1_i      => inst0_fpga_cfg_qspi_io1_i,
      fpga_cfg_qspi_io1_o      => inst0_fpga_cfg_qspi_io1_o,
      fpga_cfg_qspi_io1_t      => inst0_fpga_cfg_qspi_io1_t,    
      fpga_cfg_qspi_ss_i       => (others => '0'),
      fpga_cfg_qspi_ss_o       => inst0_fpga_cfg_qspi_ss_o ,
      fpga_cfg_qspi_ss_t       => open,
      
      extm_axi_resetn_out      => pll_axi_resetn_out,
      extm_0_axi_araddr        => pll_from_axim.araddr,
      extm_0_axi_arprot        => pll_from_axim.arprot,
      extm_0_axi_arready       => pll_to_axim.arready,
      extm_0_axi_arvalid       => pll_from_axim.arvalid,
      extm_0_axi_awaddr        => pll_from_axim.awaddr,
      extm_0_axi_awprot        => pll_from_axim.awprot,
      extm_0_axi_awready       => pll_to_axim.awready,
      extm_0_axi_awvalid       => pll_from_axim.awvalid,
      extm_0_axi_bready        => pll_from_axim.bready,
      extm_0_axi_bresp         => pll_to_axim.bresp,
      extm_0_axi_bvalid        => pll_to_axim.bvalid,
      extm_0_axi_rdata         => pll_to_axim.rdata,
      extm_0_axi_rready        => pll_from_axim.rready,
      extm_0_axi_rresp         => pll_to_axim.rresp,
      extm_0_axi_rvalid        => pll_to_axim.rvalid,
      extm_0_axi_wdata         => pll_from_axim.wdata,
      extm_0_axi_wready        => pll_to_axim.wready,
      extm_0_axi_wstrb         => pll_from_axim.wstrb,
      extm_0_axi_wvalid        => pll_from_axim.wvalid, 
      extm_0_axi_sel_tri_o     => pll_axi_sel,
      vctcxo_tamer_0_ctrl_tri_i=> vctcxo_tamer_0_ctrl_export,
      
      -- tsting
      pll_c0                   => pll_c0, 
      pll_c1                   => pll_c1,
      pll_locked               => pll_locked,
      smpl_cmp_en_tri_o        => smpl_cmp_en,
      smpl_cmp_status_tri_i    => smpl_cmp_status_sync,
      smpl_cmp_sel_tri_o       => smpl_cmp_sel,
      
      cdcm_read_start_tri_i(0) => from_cdcmcfg.CDCM_READ_START,
      cdcm_cfg_start_tri_i(0)  => from_cdcmcfg.CDCM_RECONFIG_START
   );
   
   avmm_m0_clk_clk                     <= clk;
   avmm_m0_reset_reset                 <= NOT pll_axi_resetn_out(0);
   avmm_m0_address                     <= inst0_avmm_m0_address(7 downto 0);
   avmm_m0_writedata                   <= inst0_avmm_m0_writedata(7 downto 0);
   inst0_avmm_m0_readdata( 7 downto  0) <= avmm_m0_readdata;
   inst0_avmm_m0_readdata(15 downto  8) <= avmm_m0_readdata;
   inst0_avmm_m0_readdata(23 downto 16) <= avmm_m0_readdata;
   inst0_avmm_m0_readdata(31 downto 24) <= avmm_m0_readdata;

   
   

   inst0_pllcfg_cmd_export <= from_pllcfg.phcfg_mode & from_pllcfg.pllrst_start & 
                              from_pllcfg.phcfg_start & from_pllcfg.pllcfg_start;
                              
   process(to_pllcfg, inst0_pllcfg_stat_export)
   begin 
      to_pllcfg_int <= to_pllcfg;
      to_pllcfg_int.pllcfg_done  <= inst0_pllcfg_stat_export(0);
      to_pllcfg_int.pllcfg_busy  <= inst0_pllcfg_stat_export(1);
      to_pllcfg_int.pllcfg_err   <= inst0_pllcfg_stat_export(9 downto 2);
      to_pllcfg_int.phcfg_done   <= inst0_pllcfg_stat_export(10);
      to_pllcfg_int.phcfg_error  <= inst0_pllcfg_stat_export(11);
   end process;
   
-- ----------------------------------------------------------------------------
-- cfg_top instance
-- ----------------------------------------------------------------------------    
   cfg_top_inst1 : entity work.cfg_top
   generic map (
      FPGACFG_START_ADDR   => FPGACFG_START_ADDR,
      PLLCFG_START_ADDR    => PLLCFG_START_ADDR,
      TSTCFG_START_ADDR    => TSTCFG_START_ADDR,
      TXTSPCFG_START_ADDR  => TXTSPCFG_START_ADDR,
      RXTSPCFG_START_ADDR  => RXTSPCFG_START_ADDR,
      PERIPHCFG_START_ADDR => PERIPHCFG_START_ADDR,
      TAMERCFG_START_ADDR  => TAMERCFG_START_ADDR,
      GNSSCFG_START_ADDR   => GNSSCFG_START_ADDR,

      RXTSPCFG_START_ADDR_3  => RXTSPCFG_START_ADDR_3,  -- B.J.
      FIRCFG_TX    =>  FIRCFG_TX,  -- B.J. (for Transmitter)
      FIRCFG_RX    =>  FIRCFG_RX -- B.J. (for Receiver)
      )
   port map(
      -- Serial port IOs
      sdin                 => inst0_spi_0_MOSI,
      sclk                 => inst0_spi_0_SCLK,
      sen                  => inst0_spi_0_SS_n(c_SPI0_FPGA_SS_NR),
      sdout                => inst1_sdout, 
      pllcfg_sdin          => inst0_pllcfg_spi_MOSI,
      pllcfg_sclk          => inst0_pllcfg_spi_SCLK,
      pllcfg_sen           => inst0_pllcfg_spi_SS_n,
      pllcfg_sdout         => inst1_pllcfg_sdout, 
      -- Signals coming from the pins or top level serial interface
      lreset               => reset_n,   -- Logic reset signal, resets logic cells only  (use only one reset)
      mreset               => reset_n,   -- Memory reset signal, resets configuration memory only (use only one reset)          
      to_fpgacfg_0         => to_fpgacfg_0,
      from_fpgacfg_0       => from_fpgacfg_0,
      to_fpgacfg_1         => to_fpgacfg_1,
      from_fpgacfg_1       => from_fpgacfg_1,
      to_fpgacfg_2         => to_fpgacfg_2,
      from_fpgacfg_2       => from_fpgacfg_2,
      to_pllcfg            => to_pllcfg_int,
      from_pllcfg          => from_pllcfg,
      to_tstcfg            => to_tstcfg,
      from_tstcfg          => from_tstcfg,
      to_tstcfg_from_rxtx  => to_tstcfg_from_rxtx,
      to_txtspcfg_0        => to_txtspcfg_0,
      from_txtspcfg_0      => from_txtspcfg_0,
      to_txtspcfg_1        => to_txtspcfg_1,
      from_txtspcfg_1      => from_txtspcfg_1,
      
      -- to_rxtspcfg          => to_rxtspcfg,
      -- from_rxtspcfg        => from_rxtspcfg,

      to_rxtspcfg_2a          => to_rxtspcfg_2a, -- B.J.
      from_rxtspcfg_2a        => from_rxtspcfg_2a, -- B.J.
      to_rxtspcfg_2b          => to_rxtspcfg_2b, -- B.J.
      from_rxtspcfg_2b        => from_rxtspcfg_2b, -- B.J.
   
      to_periphcfg         => to_periphcfg,
      from_periphcfg       => from_periphcfg,
      to_tamercfg          => to_tamercfg,
      from_tamercfg        => from_tamercfg,
      to_gnsscfg           => to_gnsscfg,
      from_gnsscfg         => from_gnsscfg,
      to_memcfg            => to_memcfg,
      from_memcfg          => from_memcfg,
      from_cdcmcfg         => from_cdcmcfg,

      to_rxtspcfg_3a          => to_rxtspcfg_3a,   -- B.J.
      from_rxtspcfg_3a        => from_rxtspcfg_3a, -- B.J.
      to_rxtspcfg_3b          => to_rxtspcfg_3b,   -- B.J.
      from_rxtspcfg_3b        => from_rxtspcfg_3b,  -- B.J.

      from_fircfg_tx_a        => from_fircfg_tx_a, -- B.J.
      from_fircfg_tx_b        => from_fircfg_tx_b, -- B.J.
      from_fircfg_rx_a        => from_fircfg_rx_a, -- B.J.
      from_fircfg_rx_b        => from_fircfg_rx_b  -- B.J.

   );
   
-- ----------------------------------------------------------------------------
-- Output ports
-- ----------------------------------------------------------------------------
   spi_0_SCLK <= inst0_spi_0_SCLK;
   spi_0_MOSI <= inst0_spi_0_MOSI;
   spi_0_SS_n <= inst0_spi_0_SS_n;
   
   spi_1_SCLK <= inst0_spi_1_SCLK;
   spi_1_MOSI <= inst0_spi_1_MOSI;
   spi_1_SS_n <= inst0_spi_1_SS_n;
   
   spi_2_SCLK <= inst0_spi_2_SCLK;
   spi_2_MOSI <= inst0_spi_2_MOSI;
   spi_2_SS_n <= inst0_spi_2_SS_n;
   
   fpga_cfg_qspi_MOSI <= inst0_fpga_cfg_qspi_io0_o;
   inst0_fpga_cfg_qspi_io1_i <= fpga_cfg_qspi_MISO;
   fpga_cfg_qspi_SS_n    <= inst0_fpga_cfg_qspi_ss_o(0);
   
   i2c_scl <= inst0_iic_0_scl_o when inst0_iic_0_scl_t = '0' else 'Z';
   i2c_sda <= inst0_iic_0_sda_o when inst0_iic_0_sda_t = '0' else 'Z';
   
   vctcxo_tamer_0_ctrl_export(0) <= vctcxo_tune_en_sync;
   vctcxo_tamer_0_ctrl_export(1) <= vctcxo_irq_sync;
   vctcxo_tamer_0_ctrl_export(2) <= '0';
   vctcxo_tamer_0_ctrl_export(3) <= '0';
   
end arch;   

