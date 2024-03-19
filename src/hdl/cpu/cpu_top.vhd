-- ----------------------------------------------------------------------------
-- FILE:          cpu_top.vhd
-- DESCRIPTION:   CPU top level
-- DATE:          10:52 AM Friday, May 11, 2018
-- AUTHOR(s):     Lime Microsystems
-- REVISIONS:
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- NOTES:
-- ----------------------------------------------------------------------------
-- altera vhdl_input_version vhdl_2008

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;
   use work.fpgacfg_pkg.all;
   use work.pllcfg_pkg.all;
   use work.tstcfg_pkg.all;
   use work.memcfg_pkg.all;
   use work.axi_pkg.all;
   
   Library UNISIM;
   use UNISIM.vcomponents.all;

-- ----------------------------------------------------------------------------
-- Entity declaration
-- ----------------------------------------------------------------------------

entity CPU_TOP is
   generic (
      -- CFG_START_ADDR has to be multiple of 32, because there are 32 addresses
      FPGACFG_START_ADDR   : integer := 0;    --! FPGACFG register start address
      PLLCFG_START_ADDR    : integer := 32;   --! PLLCFG register start address
      TSTCFG_START_ADDR    : integer := 96;   --! TSTCFG register start address
      --      PERIPHCFG_START_ADDR : integer := 192;
      MEMCFG_START_ADDR    : integer := 65504 --! MEMCFG register start address
   );
   port (
      CLK                   : in    std_logic;                                        --! Clock
      RESET_N               : in    std_logic;                                        --! Reset, active low

      ---- Control data FIFO
      --! @virtualbus EXFIFO_IF @dir in Control packet fifo Host -> FPGA
      EXFIFO_IF_D           : in    std_logic_vector(31 downto 0);                    --! Read data
      EXFIFO_IF_RD          : out   std_logic;                                        --! Read enable
      EXFIFO_IF_RDEMPTY     : in    std_logic;                                        --! Read empty @end

      --! @virtualbus EXFIFO_OF @dir out Control packet fifo FPGA -> HOST
      EXFIFO_OF_D           : out   std_logic_vector(31 downto 0);                    --! Write data
      EXFIFO_OF_WR          : out   std_logic;                                        --! Write enable
      EXFIFO_OF_WRFULL      : in    std_logic;                                        --! Write full
      EXFIFO_OF_RST         : out   std_logic;                                        --! Reset, active high @end

      ---- SPI 0
      --! @virtualbus SPI_0 @dir out SPI interface 0, used for internal registers and LMS7002
      SPI_0_MISO            : in    std_logic;                                        --! Master In Slave Out
      SPI_0_MOSI            : out   std_logic;                                        --! Master Out Slave In
      SPI_0_SCLK            : out   std_logic;                                        --! Clock output
      SPI_0_SS_N            : out   std_logic_vector(1 downto 0);                     --! Slave Select, active low [0] - internal registers, [1] - LMS7002 @end

      ---- I2C
      --! @virtualbus I2C_1 @dir out I2C interface 1, used for Temperature sensor, XO DAC, Switching voltage regulator 1 (IC22) 
      I2C_1_SCL             : inout std_logic;                                        --! Clock signal
      I2C_1_SDA             : inout std_logic;                                        --! Data signal @end

      --! @virtualbus I2C_2 @dir out I2C interface 2, used for Switching voltage regulator 2 (IC31)
      I2C_2_SCL             : inout std_logic;                                        --! Clock signal
      I2C_2_SDA             : inout std_logic;                                        --! Data signal @end

      ---- Configuration Flash SPI
      --! @virtualbus FPGA_CFG @dir out SPI interface for configuration flash
      FPGA_CFG_QSPI_MISO    : in    std_logic;                                        --! Master In Slave Out
      FPGA_CFG_QSPI_MOSI    : out   std_logic;                                        --! Master Out Slave In
      FPGA_CFG_QSPI_SS_N    : out   std_logic;                                        --! Slave Select, active low @end

      -- General purpose I/O
      GPI                   : in    std_logic_vector(7 downto 0);                     --! General purpose inputs (UNUSED)
      GPO                   : out   std_logic_vector(7 downto 0);                     --! General purpose outputs (UNUSED)
      -- VCTCXO tamer control
      VCTCXO_TUNE_EN        : in    std_logic;                                        --! Unused
      VCTCXO_IRQ            : in    std_logic;                                        --! Unused
      -- PLL reconfiguration
      PLL_RST               : out   std_logic_vector(1 downto 0);                     --! PLL reset
      PLL_AXI_RESETN_OUT    : out   std_logic_vector( 0 to 0);                        --! PLL Axi interface reset
      PLL_FROM_AXIM         : out   t_FROM_AXIM_32x32;                                --! PLL AXI interface CPU -> PLL
      PLL_TO_AXIM           : in    t_TO_AXIM_32x32;                                  --! PLL AXI interface PLL -> CPU
      PLL_AXI_SEL           : out   std_logic_vector(3 downto 0);                     --! PLL AXI slave select

      ---- Avalon master
      --! @virtualbus AVMM_M0 @dir out Avalon master interface (UNUSED)
      AVMM_M0_ADDRESS       : out   std_logic_vector(7 downto 0);                     --! Adress
      AVMM_M0_READ          : out   std_logic;                                        --! Read
      AVMM_M0_WAITREQUEST   : in    std_logic                     := '0';             --! Wait request
      AVMM_M0_READDATA      : in    std_logic_vector(7 downto 0)  := (others => '0'); --! Read data
      AVMM_M0_READDATAVALID : in    std_logic                     := '0';             --! Read data valid
      AVMM_M0_WRITE         : out   std_logic;                                        --! Write
      AVMM_M0_WRITEDATA     : out   std_logic_vector(7 downto 0);                     --! Write data
      AVMM_M0_CLK_CLK       : out   std_logic;                                        --! Clock
      AVMM_M0_RESET_RESET   : out   std_logic;                                        --! Reset @end

      -- Configuration registers
      FROM_FPGACFG          : out   t_FROM_FPGACFG;                                   --! FPGACFG register bus Registers -> Modules
      TO_FPGACFG            : in    t_TO_FPGACFG;                                     --! FPGACFG register bus Modules -> Registers
      FROM_PLLCFG           : out   t_FROM_PLLCFG;                                    --! PLLCFG register bus Registers -> Modules
      TO_PLLCFG             : in    t_TO_PLLCFG;                                      --! PLLCFG register bus Modules -> Registers
      FROM_TSTCFG           : out   t_FROM_TSTCFG;                                    --! TSTCFG register bus Registers -> Modules
      TO_TSTCFG             : in    t_TO_TSTCFG;                                      --! TSTCFG register bus Modules -> Registers
      TO_MEMCFG             : in    t_TO_MEMCFG;                                      --! MEMCFG register bus Registers -> Modules
      FROM_MEMCFG           : out   t_FROM_MEMCFG;                                    --! MEMCFG register bus Modules -> Registers

      SMPL_CMP_EN           : out   std_logic_vector( 0 downto 0);                    --! Sample compare module enable
      SMPL_CMP_STATUS       : in    std_logic_vector( 1 downto 0)                     --! Sample compare module status
   );
end entity CPU_TOP;

-- ----------------------------------------------------------------------------
-- Architecture
-- ----------------------------------------------------------------------------

architecture ARCH of CPU_TOP is

   -- declare signals,  components here
   constant C_SPI0_FPGA_SS_NR            : integer := 0;
   signal   smpl_cmp_status_sync         : std_logic_vector(1 downto 0);

   -- inst0
   signal inst0_spi_0_miso               : std_logic;
   signal inst0_spi_0_mosi               : std_logic;
   signal inst0_spi_0_sclk               : std_logic;
   signal inst0_spi_0_ss_n               : std_logic_vector(1 downto 0);

   signal inst0_fpga_cfg_qspi_io0_i      : std_logic;
   signal inst0_fpga_cfg_qspi_io0_o      : std_logic;
   signal inst0_fpga_cfg_qspi_io0_t      : std_logic;
   signal inst0_fpga_cfg_qspi_io1_i      : std_logic;
   signal inst0_fpga_cfg_qspi_io1_o      : std_logic;
   signal inst0_fpga_cfg_qspi_io1_t      : std_logic;
   signal inst0_fpga_cfg_qspi_ss_o       : std_logic_vector(0 downto 0);
   signal inst0_fpga_cfg_qspi_ss_t       : std_logic_vector(0 downto 0);

   signal inst0_i2c_1_scl_o              : std_logic;
   signal inst0_i2c_1_scl_t              : std_logic;
   signal inst0_i2c_1_sda_o              : std_logic;
   signal inst0_i2c_1_sda_t              : std_logic;
   signal inst0_i2c_2_scl_o              : std_logic;
   signal inst0_i2c_2_scl_t              : std_logic;
   signal inst0_i2c_2_sda_o              : std_logic;
   signal inst0_i2c_2_sda_t              : std_logic;

   signal inst0_fpga_spi0_miso           : std_logic;
   signal inst0_dac_spi1_ss_n            : std_logic;
   signal inst0_dac_spi1_mosi            : std_logic;
   signal inst0_dac_spi1_sclk            : std_logic;
   signal inst0_fpga_spi0_mosi           : std_logic;
   signal inst0_fpga_spi0_sclk           : std_logic;
   signal inst0_fpga_spi0_ss_n           : std_logic_vector(7 downto 0);
   signal inst0_pllcfg_spi_mosi          : std_logic;
   signal inst0_pllcfg_spi_sclk          : std_logic;
   signal inst0_pllcfg_spi_ss_n          : std_logic;
   signal inst0_pllcfg_cmd_export        : std_logic_vector(3 downto 0);
   signal inst0_pllcfg_stat_export       : std_logic_vector(11 downto 0);

   signal inst0_avmm_m0_address          : std_logic_vector(31 downto 0);
   signal inst0_avmm_m0_readdata         : std_logic_vector(31 downto 0);
   signal inst0_avmm_m0_writedata        : std_logic_vector(31 downto 0);

   signal to_pllcfg_int                  : t_TO_PLLCFG;

   -- inst1
   signal inst1_sdout                    : std_logic;
   signal inst1_pllcfg_sdout             : std_logic;

   signal vctcxo_tune_en_sync            : std_logic;
   signal vctcxo_irq_sync                : std_logic;

   signal vctcxo_tamer_0_irq_out_irq     : std_logic;
   signal vctcxo_tamer_0_ctrl_export     : std_logic_vector(3 downto 0);
   
   signal efuseusr                       : std_logic_vector(31 downto 0);
 

   component CPU_DESIGN is
      port (
         CLK                        : in    std_logic;
         AVMM_M0_ADDRESS            : out   std_logic_vector( 31 downto 0);
         AVMM_M0_READ               : out   std_logic;
         AVMM_M0_READDATA           : in    std_logic_vector( 31 downto 0);
         AVMM_M0_READDATAVALID      : in    std_logic;
         AVMM_M0_WAITREQUEST        : in    std_logic;
         AVMM_M0_WRITE              : out   std_logic;
         AVMM_M0_WRITEDATA          : out   std_logic_vector( 31 downto 0);
         FIFO_READ_0_ALMOST_EMPTY   : in    std_logic;
         FIFO_READ_0_EMPTY          : in    std_logic;
         FIFO_READ_0_RD_DATA        : in    std_logic_vector( 31 downto 0);
         FIFO_READ_0_RD_EN          : out   std_logic;
         FIFO_WRITE_0_ACLR          : out   std_logic;
         FIFO_WRITE_0_ALMOST_FULL   : in    std_logic;
         FIFO_WRITE_0_FULL          : in    std_logic;
         FIFO_WRITE_0_WR_DATA       : out   std_logic_vector( 31 downto 0);
         FIFO_WRITE_0_WR_EN         : out   std_logic;
         GPIO_0_TRI_I               : in    std_logic_vector( 7 downto 0);
         GPIO_1_TRI_O               : out   std_logic_vector( 7 downto 0);
         I2C_1_SCL_I                : in    std_logic;
         I2C_1_SCL_O                : out   std_logic;
         I2C_1_SCL_T                : out   std_logic;
         I2C_1_SDA_I                : in    std_logic;
         I2C_1_SDA_O                : out   std_logic;
         I2C_1_SDA_T                : out   std_logic;
         I2C_2_SCL_I                : in    std_logic;
         I2C_2_SCL_O                : out   std_logic;
         I2C_2_SCL_T                : out   std_logic;
         I2C_2_SDA_I                : in    std_logic;
         I2C_2_SDA_O                : out   std_logic;
         I2C_2_SDA_T                : out   std_logic;
         SERIAL_IN_tri_i            : in    std_logic_vector(31 downto 0);
         PLL_LOCKED_TRI_I           : in    std_logic_vector(1 downto 0):="11";
         PLL_RST_TRI_O              : out   std_logic_vector( 1 downto 0);
         PLLCFG_CMD_TRI_I           : in    std_logic_vector( 3 downto 0);
         PLLCFG_STAT_TRI_O          : out   std_logic_vector( 11 downto 0);
         RESET_N                    : in    std_logic;
         SPI_0_IO0_I                : in    std_logic;
         SPI_0_IO0_O                : out   std_logic;
         SPI_0_IO0_T                : out   std_logic;
         SPI_0_IO1_I                : in    std_logic;
         SPI_0_IO1_O                : out   std_logic;
         SPI_0_IO1_T                : out   std_logic;
         SPI_0_SCK_I                : in    std_logic;
         SPI_0_SCK_O                : out   std_logic;
         SPI_0_SCK_T                : out   std_logic;
         SPI_0_SS_I                 : in    std_logic_vector( 1 downto 0);
         SPI_0_SS_O                 : out   std_logic_vector( 1 downto 0);
         SPI_0_SS_T                 : out   std_logic;
         FPGA_CFG_QSPI_IO0_I        : in    std_logic;
         FPGA_CFG_QSPI_IO0_O        : out   std_logic;
         FPGA_CFG_QSPI_IO0_T        : out   std_logic;
         FPGA_CFG_QSPI_IO1_I        : in    std_logic;
         FPGA_CFG_QSPI_IO1_O        : out   std_logic;
         FPGA_CFG_QSPI_IO1_T        : out   std_logic;
         FPGA_CFG_QSPI_SS_I         : in    std_logic_vector(0 downto 0);
         FPGA_CFG_QSPI_SS_O         : out   std_logic_vector(0 downto 0);
         FPGA_CFG_QSPI_SS_T         : out   std_logic_vector(0 downto 0);
         UART_0_RXD                 : in    std_logic;
         UART_0_TXD                 : out   std_logic;
         EXTM_AXI_RESETN_OUT        : out   std_logic_vector( 0 to 0);
         EXTM_0_AXI_ARADDR          : out   std_logic_vector( 31 downto 0);
         EXTM_0_AXI_ARPROT          : out   std_logic_vector( 2 downto 0);
         EXTM_0_AXI_ARREADY         : in    std_logic_vector( 0 to 0);
         EXTM_0_AXI_ARVALID         : out   std_logic_vector( 0 to 0);
         EXTM_0_AXI_AWADDR          : out   std_logic_vector( 31 downto 0);
         EXTM_0_AXI_AWPROT          : out   std_logic_vector( 2 downto 0);
         EXTM_0_AXI_AWREADY         : in    std_logic_vector( 0 to 0);
         EXTM_0_AXI_AWVALID         : out   std_logic_vector( 0 to 0);
         EXTM_0_AXI_BREADY          : out   std_logic_vector( 0 to 0);
         EXTM_0_AXI_BRESP           : in    std_logic_vector( 1 downto 0);
         EXTM_0_AXI_BVALID          : in    std_logic_vector( 0 to 0);
         EXTM_0_AXI_RDATA           : in    std_logic_vector( 31 downto 0);
         EXTM_0_AXI_RREADY          : out   std_logic_vector( 0 to 0);
         EXTM_0_AXI_RRESP           : in    std_logic_vector( 1 downto 0);
         EXTM_0_AXI_RVALID          : in    std_logic_vector( 0 to 0);
         EXTM_0_AXI_WDATA           : out   std_logic_vector( 31 downto 0);
         EXTM_0_AXI_WREADY          : in    std_logic_vector( 0 to 0);
         EXTM_0_AXI_WSTRB           : out   std_logic_vector( 3 downto 0);
         EXTM_0_AXI_WVALID          : out   std_logic_vector( 0 to 0);
         EXTM_0_AXI_SEL_TRI_O       : out   std_logic_vector( 3 downto 0);
         SMPL_CMP_EN_TRI_O          : out   std_logic_vector( 0 downto 0);
         SMPL_CMP_STATUS_TRI_I      : in    std_logic_vector( 1 downto 0);
         VCTCXO_TAMER_0_CTRL_TRI_I  : in    std_logic_vector( 3 downto 0)
      );
   end component;

begin

   -- ----------------------------------------------------------------------------
   -- Synchronization registers
   -- ----------------------------------------------------------------------------
   sync_reg0 : entity work.sync_reg
      port map (
         CLK      => CLK,
         RESET_N  => '1',
         ASYNC_IN => VCTCXO_TUNE_EN,
         SYNC_OUT => vctcxo_tune_en_sync
      );

   sync_reg1 : entity work.sync_reg
      port map (
         CLK      => CLK,
         RESET_N  => '1',
         ASYNC_IN => VCTCXO_IRQ,
         SYNC_OUT => vctcxo_irq_sync
      );

   bus_sync_reg0 : entity work.bus_sync_reg
      generic map (
         BUS_WIDTH => 2
      )
      port map (
         CLK      => CLK,
         RESET_N  => '1',
         ASYNC_IN => SMPL_CMP_STATUS,
         SYNC_OUT => smpl_cmp_status_sync
      );
      
      
   EFUSE_USR_inst : EFUSE_USR
   generic map (
      SIM_EFUSE_VALUE => X"00000000"  -- Value of the 32-bit non-volatile value used in simulation
   )
   port map (
      EFUSEUSR => efuseusr  -- 32-bit output: User eFUSE register value output
   );

   -- ----------------------------------------------------------------------------
   -- MicroBlaze instance
   -- ----------------------------------------------------------------------------
   inst0_mb_cpu : CPU_DESIGN
      port map (
         CLK                      => CLK,
         AVMM_M0_ADDRESS          => inst0_avmm_m0_address,
         AVMM_M0_READ             => AVMM_M0_READ,
         AVMM_M0_READDATA         => inst0_avmm_m0_readdata,
         AVMM_M0_READDATAVALID    => AVMM_M0_READDATAVALID,
         AVMM_M0_WAITREQUEST      => AVMM_M0_WAITREQUEST,
         AVMM_M0_WRITE            => AVMM_M0_WRITE,
         AVMM_M0_WRITEDATA        => inst0_avmm_m0_writedata,
         FIFO_READ_0_ALMOST_EMPTY => '0',
         FIFO_READ_0_EMPTY        => EXFIFO_IF_RDEMPTY,
         FIFO_READ_0_RD_DATA      => EXFIFO_IF_D,
         FIFO_READ_0_RD_EN        => EXFIFO_IF_RD,
         FIFO_WRITE_0_ACLR        => EXFIFO_OF_RST,
         FIFO_WRITE_0_ALMOST_FULL => '0',
         FIFO_WRITE_0_FULL        => EXFIFO_OF_WRFULL,
         FIFO_WRITE_0_WR_DATA     => EXFIFO_OF_D,
         FIFO_WRITE_0_WR_EN       => EXFIFO_OF_WR,
         GPIO_0_TRI_I             => GPI,
         GPIO_1_TRI_O             => GPO,
         --
         I2C_1_SCL_I => I2C_1_SCL,
         I2C_1_SCL_O => inst0_i2c_1_scl_o,
         I2C_1_SCL_T => inst0_i2c_1_scl_t,
         I2C_1_SDA_I => I2C_1_SDA,
         I2C_1_SDA_O => inst0_i2c_1_sda_o,
         I2C_1_SDA_T => inst0_i2c_1_sda_t,
         --
         I2C_2_SCL_I => I2C_2_SCL,
         I2C_2_SCL_O => inst0_i2c_2_scl_o,
         I2C_2_SCL_T => inst0_i2c_2_scl_t,
         I2C_2_SDA_I => I2C_2_SDA,
         I2C_2_SDA_O => inst0_i2c_2_sda_o,
         I2C_2_SDA_T => inst0_i2c_2_sda_t,
         --
         SERIAL_IN_tri_i   => efuseusr,
         --
         PLL_RST_TRI_O     => PLL_RST,
         PLLCFG_CMD_TRI_I  => inst0_pllcfg_cmd_export,
         PLLCFG_STAT_TRI_O => inst0_pllcfg_stat_export,
         RESET_N           => RESET_N,
         SPI_0_IO0_I       => '0',
         SPI_0_IO0_O       => inst0_spi_0_mosi,
         SPI_0_IO0_T       => open,
         SPI_0_IO1_I       => SPI_0_MISO OR inst1_sdout,
         SPI_0_IO1_O       => open,
         SPI_0_IO1_T       => open,
         SPI_0_SCK_I       => '0',
         SPI_0_SCK_O       => inst0_spi_0_sclk,
         SPI_0_SCK_T       => open,
         SPI_0_SS_I        => (others=>'0'),
         SPI_0_SS_O        => inst0_spi_0_ss_n,
         SPI_0_SS_T        => open,

         UART_0_RXD => '0',
         UART_0_TXD => open,

         FPGA_CFG_QSPI_IO0_I => inst0_fpga_cfg_qspi_io0_i,
         FPGA_CFG_QSPI_IO0_O => inst0_fpga_cfg_qspi_io0_o,
         FPGA_CFG_QSPI_IO0_T => inst0_fpga_cfg_qspi_io0_t,
         FPGA_CFG_QSPI_IO1_I => inst0_fpga_cfg_qspi_io1_i,
         FPGA_CFG_QSPI_IO1_O => inst0_fpga_cfg_qspi_io1_o,
         FPGA_CFG_QSPI_IO1_T => inst0_fpga_cfg_qspi_io1_t,
         FPGA_CFG_QSPI_SS_I  => (others => '0'),
         FPGA_CFG_QSPI_SS_O  => inst0_fpga_cfg_qspi_ss_o,
         FPGA_CFG_QSPI_SS_T  => open,

         EXTM_AXI_RESETN_OUT       => PLL_AXI_RESETN_OUT,
         EXTM_0_AXI_ARADDR         => pll_from_axim.araddr,
         EXTM_0_AXI_ARPROT         => pll_from_axim.arprot,
         EXTM_0_AXI_ARREADY        => pll_to_axim.arready,
         EXTM_0_AXI_ARVALID        => pll_from_axim.arvalid,
         EXTM_0_AXI_AWADDR         => pll_from_axim.awaddr,
         EXTM_0_AXI_AWPROT         => pll_from_axim.awprot,
         EXTM_0_AXI_AWREADY        => pll_to_axim.awready,
         EXTM_0_AXI_AWVALID        => pll_from_axim.awvalid,
         EXTM_0_AXI_BREADY         => pll_from_axim.bready,
         EXTM_0_AXI_BRESP          => pll_to_axim.bresp,
         EXTM_0_AXI_BVALID         => pll_to_axim.bvalid,
         EXTM_0_AXI_RDATA          => pll_to_axim.rdata,
         EXTM_0_AXI_RREADY         => pll_from_axim.rready,
         EXTM_0_AXI_RRESP          => pll_to_axim.rresp,
         EXTM_0_AXI_RVALID         => pll_to_axim.rvalid,
         EXTM_0_AXI_WDATA          => pll_from_axim.wdata,
         EXTM_0_AXI_WREADY         => pll_to_axim.wready,
         EXTM_0_AXI_WSTRB          => pll_from_axim.wstrb,
         EXTM_0_AXI_WVALID         => pll_from_axim.wvalid,
         EXTM_0_AXI_SEL_TRI_O      => PLL_AXI_SEL,
         VCTCXO_TAMER_0_CTRL_TRI_I => vctcxo_tamer_0_ctrl_export,

         -- tsting
         SMPL_CMP_EN_TRI_O     => SMPL_CMP_EN,
         SMPL_CMP_STATUS_TRI_I => smpl_cmp_status_sync
      );

   AVMM_M0_CLK_CLK                      <= CLK;
   AVMM_M0_RESET_RESET                  <= NOT PLL_AXI_RESETN_OUT(0);
   AVMM_M0_ADDRESS                      <= inst0_avmm_m0_address(7 downto 0);
   AVMM_M0_WRITEDATA                    <= inst0_avmm_m0_writedata(7 downto 0);
   inst0_avmm_m0_readdata( 7 downto  0) <= AVMM_M0_READDATA;
   inst0_avmm_m0_readdata(15 downto  8) <= AVMM_M0_READDATA;
   inst0_avmm_m0_readdata(23 downto 16) <= AVMM_M0_READDATA;
   inst0_avmm_m0_readdata(31 downto 24) <= AVMM_M0_READDATA;

   inst0_pllcfg_cmd_export <= from_pllcfg.phcfg_mode & from_pllcfg.pllrst_start &
                              from_pllcfg.phcfg_start & from_pllcfg.pllcfg_start;

   process (TO_PLLCFG, inst0_pllcfg_stat_export) is
   begin

      to_pllcfg_int             <= TO_PLLCFG;
      to_pllcfg_int.pllcfg_done <= inst0_pllcfg_stat_export(0);
      to_pllcfg_int.pllcfg_busy <= inst0_pllcfg_stat_export(1);
      to_pllcfg_int.pllcfg_err  <= inst0_pllcfg_stat_export(9 downto 2);
      to_pllcfg_int.phcfg_done  <= inst0_pllcfg_stat_export(10);
      to_pllcfg_int.phcfg_error <= inst0_pllcfg_stat_export(11);

   end process;

   -- ----------------------------------------------------------------------------
   -- cfg_top instance
   -- ----------------------------------------------------------------------------
   inst1_cfg_top : entity work.cfg_top
      generic map (
         FPGACFG_START_ADDR => FPGACFG_START_ADDR,
         PLLCFG_START_ADDR  => PLLCFG_START_ADDR,
         TSTCFG_START_ADDR  => TSTCFG_START_ADDR,
         MEMCFG_START_ADDR  => MEMCFG_START_ADDR
      --      PERIPHCFG_START_ADDR => PERIPHCFG_START_ADDR
      )
      port map (
         -- Serial port IOs
         SDIN         => inst0_spi_0_mosi,
         SCLK         => inst0_spi_0_sclk,
         SEN          => inst0_spi_0_ss_n(C_SPI0_FPGA_SS_NR),
         SDOUT        => inst1_sdout,
         PLLCFG_SDIN  => inst0_pllcfg_spi_mosi,
         PLLCFG_SCLK  => inst0_pllcfg_spi_sclk,
         PLLCFG_SEN   => inst0_pllcfg_spi_ss_n,
         PLLCFG_SDOUT => inst1_pllcfg_sdout,
         -- Signals coming from the pins or top level serial interface
         LRESET       => RESET_N,
         MRESET       => RESET_N,
         TO_FPGACFG   => TO_FPGACFG,
         FROM_FPGACFG => FROM_FPGACFG,
         TO_PLLCFG    => to_pllcfg_int,
         FROM_PLLCFG  => FROM_PLLCFG,
         TO_TSTCFG    => TO_TSTCFG,
         FROM_TSTCFG  => FROM_TSTCFG,
         TO_MEMCFG    => TO_MEMCFG,
         FROM_MEMCFG  => FROM_MEMCFG
      );

   -- ----------------------------------------------------------------------------
   -- Output ports
   -- ----------------------------------------------------------------------------
   SPI_0_SCLK <= inst0_spi_0_sclk;
   SPI_0_MOSI <= inst0_spi_0_mosi;
   SPI_0_SS_N <= inst0_spi_0_ss_n;

   FPGA_CFG_QSPI_MOSI        <= inst0_fpga_cfg_qspi_io0_o;
   inst0_fpga_cfg_qspi_io1_i <= FPGA_CFG_QSPI_MISO;
   FPGA_CFG_QSPI_SS_N        <= inst0_fpga_cfg_qspi_ss_o(0);

   I2C_1_SCL <= inst0_i2c_1_scl_o when inst0_i2c_1_scl_t = '0' else
                'Z';
   I2C_1_SDA <= inst0_i2c_1_sda_o when inst0_i2c_1_sda_t = '0' else
                'Z';
   I2C_2_SCL <= inst0_i2c_2_scl_o when inst0_i2c_2_scl_t = '0' else
                'Z';
   I2C_2_SDA <= inst0_i2c_2_sda_o when inst0_i2c_2_sda_t = '0' else
                'Z';

   vctcxo_tamer_0_ctrl_export(0) <= vctcxo_tune_en_sync;
   vctcxo_tamer_0_ctrl_export(1) <= vctcxo_irq_sync;
   vctcxo_tamer_0_ctrl_export(2) <= '0';
   vctcxo_tamer_0_ctrl_export(3) <= '0';

end architecture ARCH;

