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
        --      PERIPHCFG_START_ADDR : integer := 192;
        MEMCFG_START_ADDR    : integer := 65504
    );
    port (
        clk                  : in     std_logic;
        reset_n              : in     std_logic;
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
        spi_0_SS_n           : out    std_logic_vector(1 downto 0);
        -- I2C
        i2c_1_scl            : inout  std_logic;
        i2c_1_sda            : inout  std_logic;
        i2c_2_scl            : inout  std_logic;
        i2c_2_sda            : inout  std_logic;
        -- Configuration Flash SPI
        fpga_cfg_qspi_MISO   : in     std_logic;
        fpga_cfg_qspi_MOSI   : out    std_logic;
        fpga_cfg_qspi_SS_n   : out    std_logic;
        -- Genral purpose I/O
        gpi                  : in     std_logic_vector(7 downto 0);
        gpo                  : out    std_logic_vector(7 downto 0);
        xtrx_ctrl_gpio       : out STD_LOGIC_VECTOR (3 downto 0);
        -- VCTCXO tamer control
        vctcxo_tune_en       : in     std_logic;
        vctcxo_irq           : in     std_logic;
        -- PLL reconfiguration
        pll_rst              : out    std_logic_vector(31 downto 0);
        pll_axi_resetn_out   : out    std_logic_vector ( 0 to 0 );
        pll_from_axim        : out    t_FROM_AXIM_32x32;
        pll_to_axim          : in     t_TO_AXIM_32x32;
        pll_axi_sel          : out    std_logic_vector(3 downto 0);
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
        from_fpgacfg         : out    t_FROM_FPGACFG;
        to_fpgacfg           : in     t_TO_FPGACFG;
        from_pllcfg          : out    t_FROM_PLLCFG;
        to_pllcfg            : in     t_TO_PLLCFG;
        from_tstcfg          : out    t_FROM_TSTCFG;
        to_tstcfg            : in     t_TO_TSTCFG;
        to_tstcfg_from_rxtx  : in     t_TO_TSTCFG_FROM_RXTX;
        to_memcfg            : in     t_TO_MEMCFG;
        from_memcfg          : out    t_FROM_MEMCFG;

        smpl_cmp_en          : out    std_logic_vector ( 3 downto 0 );
        smpl_cmp_status      : in     std_logic_vector ( 1 downto 0 );
        smpl_cmp_sel         : out    std_logic_vector (0 downto 0)
    );
end cpu_top;

-- ----------------------------------------------------------------------------
-- Architecture
-- ----------------------------------------------------------------------------
architecture arch of cpu_top is
    --declare signals,  components here
    constant c_SPI0_FPGA_SS_NR       : integer := 0;
    signal smpl_cmp_status_sync         : std_logic_vector(1 downto 0);

    -- inst0
    signal inst0_spi_0_MISO          : std_logic;
    signal inst0_spi_0_MOSI          : std_logic;
    signal inst0_spi_0_SCLK          : std_logic;
    signal inst0_spi_0_SS_n          : std_logic_vector(1 downto 0);

    signal inst0_fpga_cfg_qspi_io0_i : std_logic;
    signal inst0_fpga_cfg_qspi_io0_o : std_logic;
    signal inst0_fpga_cfg_qspi_io0_t : std_logic;
    signal inst0_fpga_cfg_qspi_io1_i : std_logic;
    signal inst0_fpga_cfg_qspi_io1_o : std_logic;
    signal inst0_fpga_cfg_qspi_io1_t : std_logic;
    signal inst0_fpga_cfg_qspi_ss_o  : std_logic_vector(0 downto 0);
    signal inst0_fpga_cfg_qspi_ss_t  : std_logic_vector(0 downto 0);

    signal inst0_i2c_1_scl_o         : std_logic;
    signal inst0_i2c_1_scl_t         : std_logic;
    signal inst0_i2c_1_sda_o         : std_logic;
    signal inst0_i2c_1_sda_t         : std_logic;
    signal inst0_i2c_2_scl_o         : std_logic;
    signal inst0_i2c_2_scl_t         : std_logic;
    signal inst0_i2c_2_sda_o         : std_logic;
    signal inst0_i2c_2_sda_t         : std_logic;

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
    
    signal to_pllcfg_int          : t_TO_PLLCFG;

    --inst1
    signal inst1_sdout            : std_logic;
    signal inst1_pllcfg_sdout     : std_logic;

    signal vctcxo_tune_en_sync    : std_logic;
    signal vctcxo_irq_sync        : std_logic;

    signal vctcxo_tamer_0_irq_out_irq   : std_logic;
    signal vctcxo_tamer_0_ctrl_export   : std_logic_vector(3 downto 0);

    component cpu_design is
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
            I2C_1_scl_i                : in std_logic;
            I2C_1_scl_o                : out std_logic;
            I2C_1_scl_t                : out std_logic;
            I2C_1_sda_i                : in std_logic;
            I2C_1_sda_o                : out std_logic;
            I2C_1_sda_t                : out std_logic;
            I2C_2_scl_i                : in std_logic;
            I2C_2_scl_o                : out std_logic;
            I2C_2_scl_t                : out std_logic;
            I2C_2_sda_i                : in std_logic;
            I2C_2_sda_o                : out std_logic;
            I2C_2_sda_t                : out std_logic;
            pll_rst_tri_o              : out STD_LOGIC_VECTOR ( 31 downto 0 );
            --      pllcfg_cmd_tri_i           : in STD_LOGIC_VECTOR ( 3 downto 0 );
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
            spi_0_ss_i                 : in std_logic_vector ( 1 downto 0 );
            spi_0_ss_o                 : out std_logic_vector ( 1 downto 0 );
            spi_0_ss_t                 : out std_logic;
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
            xtrx_ctrl_gpio_tri_o       : out STD_LOGIC_VECTOR (3 downto 0)

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

    -- ----------------------------------------------------------------------------
    -- MicroBlaze instance
    -- ----------------------------------------------------------------------------
    inst0_mb_cpu : cpu_design
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
            xtrx_ctrl_gpio_tri_o     => xtrx_ctrl_gpio,
            --
            I2C_1_scl_i              => i2c_1_scl        ,
            I2C_1_scl_o              => inst0_i2c_1_scl_o,
            I2C_1_scl_t              => inst0_i2c_1_scl_t,
            I2C_1_sda_i              => i2c_1_sda        ,
            I2C_1_sda_o              => inst0_i2c_1_sda_o,
            I2C_1_sda_t              => inst0_i2c_1_sda_t,
            --
            I2C_2_scl_i              => i2c_2_scl        ,
            I2C_2_scl_o              => inst0_i2c_2_scl_o,
            I2C_2_scl_t              => inst0_i2c_2_scl_t,
            I2C_2_sda_i              => i2c_2_sda        ,
            I2C_2_sda_o              => inst0_i2c_2_sda_o,
            I2C_2_sda_t              => inst0_i2c_2_sda_t,
            --
            pll_rst_tri_o            => pll_rst,
            --      pllcfg_cmd_tri_i         => inst0_pllcfg_cmd_export,
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
            smpl_cmp_en_tri_o        => smpl_cmp_en,
            smpl_cmp_status_tri_i    => smpl_cmp_status_sync,
            smpl_cmp_sel_tri_o       => smpl_cmp_sel
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
        --      to_pllcfg_int.phcfg_done   <= inst0_pllcfg_stat_export(10);
        --      to_pllcfg_int.phcfg_error  <= inst0_pllcfg_stat_export(11);
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
            RXTSPCFG_START_ADDR  => RXTSPCFG_START_ADDR
            --      PERIPHCFG_START_ADDR => PERIPHCFG_START_ADDR
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
            to_fpgacfg           => to_fpgacfg,
            from_fpgacfg         => from_fpgacfg,
            to_pllcfg            => to_pllcfg_int,
            from_pllcfg          => from_pllcfg,
            to_tstcfg            => to_tstcfg,
            from_tstcfg          => from_tstcfg,
            to_tstcfg_from_rxtx  => to_tstcfg_from_rxtx,
            to_memcfg            => to_memcfg,
            from_memcfg          => from_memcfg
        );

    -- ----------------------------------------------------------------------------
    -- Output ports
    -- ----------------------------------------------------------------------------
    spi_0_SCLK <= inst0_spi_0_SCLK;
    spi_0_MOSI <= inst0_spi_0_MOSI;
    spi_0_SS_n <= inst0_spi_0_SS_n;

    fpga_cfg_qspi_MOSI <= inst0_fpga_cfg_qspi_io0_o;
    inst0_fpga_cfg_qspi_io1_i <= fpga_cfg_qspi_MISO;
    fpga_cfg_qspi_SS_n    <= inst0_fpga_cfg_qspi_ss_o(0);

    i2c_1_scl  <= inst0_i2c_1_scl_o when inst0_i2c_1_scl_t = '0' else 'Z';
    i2c_1_sda  <= inst0_i2c_1_sda_o when inst0_i2c_1_sda_t = '0' else 'Z';
    i2c_2_scl  <= inst0_i2c_2_scl_o when inst0_i2c_2_scl_t = '0' else 'Z';
    i2c_2_sda  <= inst0_i2c_2_sda_o when inst0_i2c_2_sda_t = '0' else 'Z';


    vctcxo_tamer_0_ctrl_export(0) <= vctcxo_tune_en_sync;
    vctcxo_tamer_0_ctrl_export(1) <= vctcxo_irq_sync;
    vctcxo_tamer_0_ctrl_export(2) <= '0';
    vctcxo_tamer_0_ctrl_export(3) <= '0';

end arch;

