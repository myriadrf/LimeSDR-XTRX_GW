-- ----------------------------------------------------------------------------
-- FILE:          pcie_top.vhd
-- DESCRIPTION:   Top module for PCIe connection
-- DATE:          11:11 AM Thursday, June 28, 2018
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
use work.litepcie_pkg.all;

LIBRARY altera_mf;
USE altera_mf.all;
-- ----------------------------------------------------------------------------
-- Entity declaration
-- ----------------------------------------------------------------------------
entity pcie_top is
   generic(
      g_DEV_FAMILY               : string := "Cyclone V GX"; --! Device family 
      g_S0_DATA_WIDTH            : integer := 32;  --! Stream 0 data width
      g_C0_DATA_WIDTH            : integer := 8;   --! Control 0 data width
      -- Stream (Host->FPGA) 
      g_H2F_S0_0_RDUSEDW_WIDTH   : integer := 11;  --! Stream 0_0 FIFO read used words width
      g_H2F_S0_0_RWIDTH          : integer := 32;  --! Stream 0_0 FIFO read data with
      g_H2F_S0_1_RDUSEDW_WIDTH   : integer := 11;  --! Stream 0_1 FIFO read used words width  
      g_H2F_S0_1_RWIDTH          : integer := 32;  --! Stream 0_1 FIFO read data with
      -- Stream (FPGA->Host)
      g_F2H_S0_WRUSEDW_WIDTH     : integer := 10;  --! Stream 0 FIFO write used words width
      g_F2H_S0_WWIDTH            : integer := 64;  --! Stream 0 FIFO write width
      -- Control (Host->FPGA)
      g_H2F_C0_RDUSEDW_WIDTH     : integer := 11;  --! Control 0 FIFO read used words wdth
      g_H2F_C0_RWIDTH            : integer := 8;   --! Control 0 FIFO read width
      -- Control (FPGA->Host)
      g_F2H_C0_WRUSEDW_WIDTH     : integer := 11;  --! Control 0 FIFO write used words width
      g_F2H_C0_WWIDTH            : integer := 8    --! Control 0 FIFO write width
      
   );
   port (
      clk                  : out  std_logic;    --! Internal logic clock (125Mhz)
      reset_n              : in  std_logic;     --! Active low reset
      --PCIE external pins
      pcie_perstn          : in  std_logic;     --! PCIe fundamental reset
      pcie_refclk_p        : in  std_logic;     --! PCIe reference clock 
      pcie_refclk_n        : in  std_logic;     --! PCIe reference clock  
      pcie_rx_p            : in  std_logic_vector(1 downto 0); --! PCIe receiver 
      pcie_rx_n            : in  std_logic_vector(1 downto 0); --! PCIe receiver
      pcie_tx_p            : out std_logic_vector(1 downto 0); --! PCIe transmitter
      pcie_tx_n            : out std_logic_vector(1 downto 0); --! PCIe transmitter
      -- FIFO buffers
      H2F_S0_sel           : in std_logic;   --! Stream select: 0 - S0_0, 1 - S0_1 
      H2F_S0_dma_en        : out std_logic;  --! Host->FPGA stream ready
      --! @virtualbus H2F_S0_0 @dir in Stream 0 endpoint FIFO 0 (Host->FPGA)
      --! Read clock
      H2F_S0_0_rdclk       : in std_logic;
      H2F_S0_0_aclrn       : in std_logic;   --! Asynchronous clear
      H2F_S0_0_rd          : in std_logic;   --! Read enable
      H2F_S0_0_rdata       : out std_logic_vector(g_H2F_S0_0_RWIDTH-1 downto 0);          --! Read data
      H2F_S0_0_rempty      : out std_logic;  --! Read empty
      H2F_S0_0_rdusedw     : out std_logic_vector(g_H2F_S0_0_RDUSEDW_WIDTH-1 downto 0);   --! Read used words @end
      --! @virtualbus H2F_S0_1 @dir in Stream 0 endpoint FIFO 1 (Host->FPGA)
      H2F_S0_1_rdclk       : in std_logic;   --! Read clock 
      H2F_S0_1_aclrn       : in std_logic;   --! Asynchronous clear
      H2F_S0_1_rd          : in std_logic;   --! Read enable
      H2F_S0_1_rdata       : out std_logic_vector(g_H2F_S0_1_RWIDTH-1 downto 0);          --! Read data
      H2F_S0_1_rempty      : out std_logic;  --! Read empty
      H2F_S0_1_rdusedw     : out std_logic_vector(g_H2F_S0_1_RDUSEDW_WIDTH-1 downto 0);   --! Read used words @end
      --! @virtualbus F2H_S0 @dir out Stream 0 endpoint FIFO (FPGA->Host)
      --! Write clock
      F2H_S0_wclk          : in std_logic;   
      F2H_S0_aclrn         : in std_logic;   --! Asynchronous clear
      F2H_S0_wr            : in std_logic;   --! Write enable
      F2H_S0_wdata         : in std_logic_vector(g_F2H_S0_WWIDTH-1 downto 0);             --! Write data
      F2H_S0_wfull         : out std_logic;  --! Write full
      F2H_S0_wrusedw       : out std_logic_vector(g_F2H_S0_WRUSEDW_WIDTH-1 downto 0);     --! Write used words @end
      --! @virtualbus H2F_C0 Control endpoint FIFO (Host->FPGA)
      --! Read clock
      H2F_C0_rdclk         : in std_logic;
      H2F_C0_aclrn         : in std_logic;   --! Asynchronous clear
      H2F_C0_rd            : in std_logic;   --! Read enable
      H2F_C0_rdata         : out std_logic_vector(g_H2F_C0_RWIDTH-1 downto 0);            --! Read data
      H2F_C0_rempty        : out std_logic;  --! Read empty @end
      --! @virtualbus F2H_C0 @dir out Control endpoint FIFO (FPGA->Host)
      --! Write clock   
      F2H_C0_wclk          : in std_logic;
      F2H_C0_aclrn         : in std_logic;   --! Asynchronous clear
      F2H_C0_wr            : in std_logic;   --! Write enable
      F2H_C0_wdata         : in std_logic_vector(g_F2H_C0_WWIDTH-1 downto 0);             --! Write data
      F2H_C0_wfull         : out std_logic;  --! Write full @end
     
      S0_rx_en             : in std_logic;   --! Stream 0 enable
      F2H_S0_open          : out std_logic   --! FPGA->Host stream 0 ready 
      
   );
end pcie_top;

-- ----------------------------------------------------------------------------
-- Architecture
-- ----------------------------------------------------------------------------
architecture arch of pcie_top is
--declare signals,  components here
   -- Module constants  
   constant c_H2F_S0_0_RDUSEDW_WIDTH   : integer := g_H2F_S0_0_RDUSEDW_WIDTH; 
   constant c_H2F_S0_1_RDUSEDW_WIDTH   : integer := g_H2F_S0_1_RDUSEDW_WIDTH;

   constant c_H2F_C0_RDUSEDW_WIDTH     : integer := g_H2F_C0_RDUSEDW_WIDTH; 
   
   constant c_F2H_S0_WRUSEDW_WIDTH     : integer := g_F2H_S0_WRUSEDW_WIDTH;
   
   constant c_F2H_C0_WRUSEDW_WIDTH     : integer := g_F2H_C0_WRUSEDW_WIDTH;
  
   signal H2F_S0_sel_sync              : std_logic;
   signal H2F_S0_sel_sync_r            : std_logic;
   signal H2F_S0_sel_int               : std_logic;
      
   signal S0_rx_en_sync                : std_logic;
   signal S0_rx_en_sync_r              : std_logic;

   signal H2F_S0_0_sclrn               : std_logic;
   signal H2F_S0_1_sclrn               : std_logic;
 
   --inst1   
   signal inst1_to_dma_writer0         : t_TO_DMA_WRITER;
   signal inst1_from_dma_writer0       : t_FROM_DMA_WRITER;
   signal inst1_to_dma_reader0         : t_TO_DMA_READER;
   signal inst1_from_dma_reader0       : t_FROM_DMA_READER;
   
   signal inst1_cntrl_enable           : std_logic;
   signal inst1_cntrl_writer_data      : std_logic_vector(c_CNTRL_DATA_WIDTH-1 downto 0); 
   signal inst1_cntrl_writer_valid     : std_logic := '0';  
   signal inst1_cntrl_reader_data      : std_logic_vector(c_CNTRL_DATA_WIDTH-1 downto 0); 
   signal inst1_cntrl_reader_valid     : std_logic; 

   signal clk125                       : std_logic;
   
begin
    clk <= clk125;
-- ----------------------------------------------------------------------------
-- Reset logic
-- ----------------------------------------------------------------------------  
   -- Reset signal with synchronous removal to clk clock domain, 
   sync_reg0 : entity work.sync_reg 
   port map(clk125, H2F_S0_0_aclrn, '1', H2F_S0_0_sclrn);
   
   sync_reg1 : entity work.sync_reg 
   port map(clk125, H2F_S0_1_aclrn, '1', H2F_S0_1_sclrn); 
     
-- ----------------------------------------------------------------------------
-- Sync registers
-- ----------------------------------------------------------------------------   
   sync_reg6 : entity work.sync_reg 
   port map(clk125, reset_n, H2F_S0_sel, H2F_S0_sel_sync);
   
   sync_reg9 : entity work.sync_reg 
   port map(clk125, '1', S0_rx_en, S0_rx_en_sync);
   
-- ----------------------------------------------------------------------------
-- Input registers
-- ----------------------------------------------------------------------------

   process(clk125, reset_n)
   begin 
      if reset_n = '0' then
         H2F_S0_sel_sync_r <= '0';
         
         S0_rx_en_sync_r   <= '0';
      elsif rising_edge(clk125) then 
         H2F_S0_sel_sync_r <= H2F_S0_sel_sync;
         
         S0_rx_en_sync_r   <= S0_rx_en_sync;
         
      end if; 
   end process;
   
-- ----------------------------------------------------------------------------
-- Litepcie core
-- ---------------------------------------------------------------------------- 
   inst1_litepcie_top : entity work.litepcie_top
   port map (
      -- Internal clock
      clk125               => clk125,
      -- PCIe 
      pcie_rst_n           => pcie_perstn,
      pcie_refclk_p        => pcie_refclk_p,
      pcie_refclk_n        => pcie_refclk_n,
      pcie_rx_p            => pcie_rx_p,
      pcie_rx_n            => pcie_rx_n,
      pcie_tx_p            => pcie_tx_p,
      pcie_tx_n            => pcie_tx_n,
      -- DMA endpoints
         -- dma_writer = HOST -> FPGA, dma_reader = FPGA->HOST
      to_dma_writer0       => inst1_to_dma_writer0,
      from_dma_writer0     => inst1_from_dma_writer0, 
      to_dma_reader0       => inst1_to_dma_reader0,
      from_dma_reader0     => inst1_from_dma_reader0,
      -- Control registers
         -- cntrl_writer = HOST -> FPGA, cntrl_reader = FPGA->HOST
      cntrl_enable         => inst1_cntrl_enable,      
      cntrl_writer_data    => inst1_cntrl_writer_data,
      cntrl_writer_valid   => inst1_cntrl_writer_valid,      
      cntrl_reader_data    => inst1_cntrl_reader_data,
      cntrl_reader_valid   => inst1_cntrl_reader_valid
   );
   
-- ----------------------------------------------------------------------------
-- Host->FPGA buffer selection
-- ----------------------------------------------------------------------------
   -- Host to FPGA buffer swith is swithed only on rising edges of select signal
   -- and RX enable. 
   -- This is to ensure that buffer is not swithed while loading WFM data.
   process(clk125, reset_n)
   begin 
      if reset_n = '0' then
         H2F_S0_sel_int <= '0';
      elsif rising_edge(clk125) then
      
         if H2F_S0_sel_sync_r = '0' AND H2F_S0_sel_sync = '1' then 
            H2F_S0_sel_int <= '1';
         elsif S0_rx_en_sync_r = '0' AND S0_rx_en_sync = '1' then 
            H2F_S0_sel_int <= '0';
         else 
            H2F_S0_sel_int <= H2F_S0_sel_int;
         end if;
         
      end if;
   end process;

-- ----------------------------------------------------------------------------
-- For Stream S0 endpoint, Host->FPGA
-- There are two FIFO buffers for this endpoint. Buffer is selected with H2F_S0_0_sel
-- ----------------------------------------------------------------------------
   inst2_H2F_S0_FIFO : entity work.wr_stream_buff
   generic map (
      g_DEV_FAMILY            => g_DEV_FAMILY,
      g_BUFF_0_RWIDTH         => g_H2F_S0_0_RWIDTH,
      g_BUFF_0_RDUSEDW_WIDTH  => c_H2F_S0_0_RDUSEDW_WIDTH,
      g_BUFF_1_RWIDTH         => g_H2F_S0_1_RWIDTH,
      g_BUFF_1_RDUSEDW_WIDTH  => c_H2F_S0_1_RDUSEDW_WIDTH
   )
   port map(
      clk               => clk125,
      reset_n           => inst1_from_dma_writer0.enable,
      --DMA 
      to_dma_writer     => inst1_to_dma_writer0,
      from_dma_writer   => inst1_from_dma_writer0,
      -- FIFO Buffers
      buff_sel          => H2F_S0_sel_int,
         --Buffer 0
      buff_0_rdclk      => H2F_S0_0_rdclk,
      buff_0_aclrn      => H2F_S0_0_sclrn,
      buff_0_rd         => H2F_S0_0_rd,
      buff_0_rdata      => H2F_S0_0_rdata,
      buff_0_rempty     => H2F_S0_0_rempty,
      buff_0_rdusedw    => H2F_S0_0_rdusedw,
         --Buffer 1
      buff_1_rdclk      => H2F_S0_1_rdclk,
      buff_1_aclrn      => H2F_S0_1_sclrn,
      buff_1_rd         => H2F_S0_1_rd,
      buff_1_rdata      => H2F_S0_1_rdata,
      buff_1_rempty     => H2F_S0_1_rempty,
      buff_1_rdusedw    => H2F_S0_1_rdusedw 
   );
   
-- ----------------------------------------------------------------------------
-- For C0 Control endpoint, Host->FPGA
-- ----------------------------------------------------------------------------
   inst5_H2F_C0_FIFO : entity work.wr_control_buff
   generic map(
      g_DEV_FAMILY         => g_DEV_FAMILY,
      g_BUFF_RWIDTH        => g_H2F_C0_RWIDTH,
      g_BUFF_RDUSEDW_WIDTH => c_H2F_C0_RDUSEDW_WIDTH     
   )
   port map(
      clk            => clk125,
      reset_n        => reset_n,
      -- Control endpoint
      cntrl_valid    => inst1_cntrl_writer_valid,
      cntrl_data     => inst1_cntrl_writer_data,
      cntrl_ready    => open,
      -- Control Buffer FIFO
      buff_rdclk     => H2F_C0_rdclk,
      buff_rd        => H2F_C0_rd,
      buff_rdata     => H2F_C0_rdata,
      buff_rempty    => H2F_C0_rempty,
      buff_rdusedw   => open
   );
   
-- ----------------------------------------------------------------------------
-- For S0 stream endpoint, FPGA->Host
-- ----------------------------------------------------------------------------
   inst6_F2H_S0_FIFO : entity work.rd_stream_buff
   generic map(
      g_DEV_FAMILY         => g_DEV_FAMILY,
      g_BUFF_WRWIDTH       => g_F2H_S0_WWIDTH,
      g_BUFF_WRUSEDW_WIDTH => c_F2H_S0_WRUSEDW_WIDTH  
   )
   port map(
      clk               => clk125,
      reset_n           => inst1_from_dma_reader0.enable,
      --DMA 
      to_dma_reader     => inst1_to_dma_reader0,
      from_dma_reader   => inst1_from_dma_reader0,
      --Buffer
      buff_wrclk        => F2H_S0_wclk,
      buff_aclrn        => '1', 
      buff_wr           => F2H_S0_wr,
      buff_wrdata       => F2H_S0_wdata,
      buff_wrfull       => F2H_S0_wfull,
      buff_wrusedw      => F2H_S0_wrusedw
   );
   
-- ----------------------------------------------------------------------------
-- For C0 control endpoint, FPGA->Host
-- ----------------------------------------------------------------------------
   inst9_rd_control_buff : entity work.rd_control_buff
   generic map(
      g_DEV_FAMILY         => g_DEV_FAMILY,
      g_BUFF_WRWIDTH       => g_F2H_C0_WWIDTH,
      g_BUFF_WRUSEDW_WIDTH => c_F2H_C0_WRUSEDW_WIDTH   
   )
   port map(
      clk            => clk125,
      reset_n        => reset_n,
      -- Control endpoint
      cntrl_valid    => inst1_cntrl_reader_valid,
      cntrl_data     => inst1_cntrl_reader_data,
      cntrl_ready    => '1', 
      -- Control Buffer FIFO
      buff_wrdclk    => F2H_C0_wclk,
      buff_wr        => F2H_C0_wr,
      buff_wrdata    => F2H_C0_wdata,
      buff_wrfull    => F2H_C0_wfull,
      buff_wrdusedw  => open
   );
 
-- ----------------------------------------------------------------------------
-- Output ports
-- ----------------------------------------------------------------------------    
   F2H_S0_open <= inst1_from_dma_reader0.enable;
   H2F_S0_dma_en <= inst1_from_dma_writer0.enable;
   
end arch;
