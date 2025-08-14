-- ----------------------------------------------------------------------------
-- FILE:          litepcie_top.vhd
-- DESCRIPTION:   Top module for litepcie core
-- DATE:          09:34 AM Thursday, June 27, 2019
-- AUTHOR(s):     Lime Microsystems
-- REVISIONS:
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
--NOTES:
-- ----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.litepcie_pkg.all;

Library UNISIM;
use UNISIM.vcomponents.all;

-- ----------------------------------------------------------------------------
-- Entity declaration
-- ----------------------------------------------------------------------------
entity litepcie_top is
   port (
      -- Internal clock
      clk125               : out std_logic;
      -- PCIe 
      pcie_rst_n           : in  std_logic;
      pcie_refclk_p        : in  std_logic;
      pcie_refclk_n        : in  std_logic;
      pcie_rx_p            : in  std_logic_vector(0 downto 0);
      pcie_rx_n            : in  std_logic_vector(0 downto 0);
      pcie_tx_p            : out std_logic_vector(0 downto 0);
      pcie_tx_n            : out std_logic_vector(0 downto 0);
      -- DMA endpoints
         -- dma_writer = HOST -> FPGA, dma_reader = FPGA->HOST
      to_dma_writer0       : in  t_TO_DMA_WRITER;
      from_dma_writer0     : out t_FROM_DMA_WRITER; 
      to_dma_reader0       : in  t_TO_DMA_READER;
      from_dma_reader0     : out t_FROM_DMA_READER;
      -- Control registers
         -- cntrl_writer = HOST -> FPGA, cntrl_reader = FPGA->HOST
      cntrl_enable         : out std_logic;      
      cntrl_writer_data    : out std_logic_vector(c_CNTRL_DATA_WIDTH-1 downto 0);
      cntrl_writer_valid   : out std_logic;       
      cntrl_reader_data    : in  std_logic_vector(c_CNTRL_DATA_WIDTH-1 downto 0);
      cntrl_reader_valid   : in  std_logic
   );
end litepcie_top;

-- ----------------------------------------------------------------------------
-- Architecture
-- ----------------------------------------------------------------------------
architecture arch of litepcie_top is
--declare signals,  components here

signal refclk : std_logic;


   -- Verilog component declaration
   component litepcie_core
   port (
      clk                  : out std_logic;
      pcie_rst_n           : in  std_logic;
      pcie_clk_p           : in  std_logic;
      pcie_clk_n           : in  std_logic;
      pcie_rx_p            : in  std_logic_vector(0 downto 0);
      pcie_rx_n            : in  std_logic_vector(0 downto 0);
      pcie_tx_p            : out std_logic_vector(0 downto 0); 
      pcie_tx_n            : out std_logic_vector(0 downto 0); 
      
      dma0_writer_axi_tvalid      : out std_logic;
      dma0_writer_axi_tready      : in  std_logic;
      dma0_writer_axi_tlast       : out std_logic;
      dma0_writer_axi_tdata       : out std_logic_vector(c_DMA_DATA_WIDTH-1 downto 0);
      dma0_status_writer_enable   : out std_logic;
      
      dma0_reader_axi_tvalid      : in  std_logic;
      dma0_reader_axi_tready      : out std_logic;
      dma0_reader_axi_tlast       : in  std_logic;
      dma0_reader_axi_tdata       : in  std_logic_vector(c_DMA_DATA_WIDTH-1 downto 0);
      dma0_status_reader_enable   : out std_logic;
      
      cntrl_enable         : out std_logic;      
      cntrl_writer_data    : out std_logic_vector(c_CNTRL_DATA_WIDTH-1 downto 0);
      cntrl_writer_valid   : out std_logic;       
      cntrl_reader_data    : in  std_logic_vector(c_CNTRL_DATA_WIDTH-1 downto 0);
      cntrl_reader_valid   : in  std_logic;
      
      msi_irqs             : in  std_logic_vector(15 downto 0)     
   );
   end component;  

  
begin

-- ----------------------------------------------------------------------------
-- litepcie instance
-- ----------------------------------------------------------------------------
   inst0_litepcie_core : litepcie_core
   port map (
      clk                  => clk125,
      pcie_rst_n           => pcie_rst_n,
      pcie_clk_p           => pcie_refclk_p, 
      pcie_clk_n           => pcie_refclk_n,
      pcie_rx_p            => pcie_rx_p,
      pcie_rx_n            => pcie_rx_n,
      pcie_tx_p            => pcie_tx_p,
      pcie_tx_n            => pcie_tx_n,
      
      -- HOST -> FPGA
      dma0_writer_axi_tvalid    => from_dma_writer0.valid,
      dma0_writer_axi_tready    => to_dma_writer0.ready,
      dma0_writer_axi_tlast     => from_dma_writer0.last,
      dma0_writer_axi_tdata     => from_dma_writer0.data,
      dma0_status_writer_enable => from_dma_writer0.enable,
      -- FPGA -> HOST
      dma0_reader_axi_tvalid    => to_dma_reader0.valid,
      dma0_reader_axi_tready    => from_dma_reader0.ready,
      dma0_reader_axi_tlast     => to_dma_reader0.last,
      dma0_reader_axi_tdata     => to_dma_reader0.data,
      dma0_status_reader_enable => from_dma_reader0.enable,     
      cntrl_enable         => cntrl_enable, 
      -- HOST -> FPGA
      cntrl_writer_data    => cntrl_writer_data,
      cntrl_writer_valid   => cntrl_writer_valid,
      -- FPGA -> HOST
      cntrl_reader_data    => cntrl_reader_data,
      cntrl_reader_valid   => cntrl_reader_valid,
      msi_irqs             => (others => '0')
   );
   
  
end arch;   


