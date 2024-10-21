-- ----------------------------------------------------------------------------
-- FILE:          uart_mux.vhd
-- DESCRIPTION:   describe file
-- DATE:          Jan 27, 2016
-- AUTHOR(s):     Lime Microsystems
-- REVISIONS:
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- NOTES:
-- ----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.axis_pkg.all;

-- ----------------------------------------------------------------------------
-- Entity declaration
-- ----------------------------------------------------------------------------
entity uart_mux is
   port (
      CLK                  : in  std_logic;
      RESET_N              : in  std_logic;
      -- Data 0
      DATA0_STREAM_IN      : in  std_logic_vector(7 downto 0);
      DATA0_STREAM_IN_STB  : in  std_logic;
      DATA0_STREAM_IN_ACK  : out std_logic := '0';
      -- Data 1
      DATA1_STREAM_IN      : in  std_logic_vector(7 downto 0);
      DATA1_STREAM_IN_STB  : in  std_logic;
      DATA1_STREAM_IN_ACK  : out std_logic := '0';
      -- MUXED Data
      DATA_STREAM_OUT      : out std_logic_vector(7 downto 0);
      DATA_STREAM_OUT_STB  : out std_logic;
      DATA_STREAM_OUT_ACK  : in  std_logic
   );
end uart_mux;

-- ----------------------------------------------------------------------------
-- Architecture
-- ----------------------------------------------------------------------------
architecture arch of uart_mux is
--declare signals,  components here

signal axis_data0_fifo  : t_AXI_STREAM(tdata(7 downto 0), tkeep( 0 downto 0));
signal data0_stream_in_tlast : std_logic;

signal axis_data1_fifo  : t_AXI_STREAM(tdata(7 downto 0), tkeep( 0 downto 0));
signal data1_stream_in_tlast : std_logic;

COMPONENT axis_switch_0
  PORT (
    aclk : IN STD_LOGIC;
    aresetn : IN STD_LOGIC;
    s_axis_tvalid : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    s_axis_tready : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    s_axis_tdata : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    s_axis_tlast : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    m_axis_tvalid : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    m_axis_tready : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    m_axis_tdata : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    m_axis_tlast : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    s_req_suppress : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    s_decode_err : OUT STD_LOGIC_VECTOR(1 DOWNTO 0) 
  );
END COMPONENT;


begin

-- ----------------------------------------------------------------------------
-- DATA0 FIFO
-- ----------------------------------------------------------------------------
   process (all)
   begin
      if DATA0_STREAM_IN_STB = '1' AND DATA0_STREAM_IN = x"0A" then 
         data0_stream_in_tlast <= '1';
      else 
         data0_stream_in_tlast <= '0';
      end if;
   end process;


   data0_fifo : entity work.fifo_axis_wrap
      generic map(
         g_CLOCKING_MODE       =>"independent_clock", -- "common_clock" or "independent_clock"
         g_PACKET_FIFO         =>"false",             -- Packet FIFO mode
         g_FIFO_DEPTH          => 128,
         g_TDATA_WIDTH         => DATA0_STREAM_IN'LENGTH,
         g_RD_DATA_COUNT_WIDTH => 1,
         g_WR_DATA_COUNT_WIDTH => 1
      )
      port map(
         s_axis_aresetn       => RESET_N,
         s_axis_aclk          => CLK,
         s_axis_tvalid        => DATA0_STREAM_IN_STB,
         s_axis_tready        => DATA0_STREAM_IN_ACK,
         s_axis_tdata         => DATA0_STREAM_IN,
         s_axis_tkeep         => (others=>'1'),
         s_axis_tlast         => data0_stream_in_tlast,
         m_axis_aclk          => CLK,
         m_axis_tvalid        => axis_data0_fifo.tvalid,
         m_axis_tready        => axis_data0_fifo.tready,
         m_axis_tdata         => axis_data0_fifo.tdata,
         m_axis_tkeep         => axis_data0_fifo.tkeep,
         m_axis_tlast         => axis_data0_fifo.tlast,
         almost_empty_axis    => open,
         almost_full_axis     => open,
         rd_data_count_axis   => open,
         wr_data_count_axis   => open
      );

      
-- ----------------------------------------------------------------------------
-- DATA1 FIFO
-- ----------------------------------------------------------------------------
process (all)
begin
   if DATA1_STREAM_IN_STB = '1' AND DATA1_STREAM_IN = x"0A" then 
      data1_stream_in_tlast <= '1';
   else 
      data1_stream_in_tlast <= '0';
   end if;
end process;


data1_fifo : entity work.fifo_axis_wrap
   generic map(
      g_CLOCKING_MODE       =>"independent_clock", -- "common_clock" or "independent_clock"
      g_PACKET_FIFO         =>"false",             -- Packet FIFO mode
      g_FIFO_DEPTH          => 128,
      g_TDATA_WIDTH         => DATA1_STREAM_IN'LENGTH,
      g_RD_DATA_COUNT_WIDTH => 1,
      g_WR_DATA_COUNT_WIDTH => 1
   )
   port map(
      s_axis_aresetn       => RESET_N,
      s_axis_aclk          => CLK,
      s_axis_tvalid        => DATA1_STREAM_IN_STB,
      s_axis_tready        => DATA1_STREAM_IN_ACK,
      s_axis_tdata         => DATA1_STREAM_IN,
      s_axis_tkeep         => (others=>'1'),
      s_axis_tlast         => data1_stream_in_tlast,
      m_axis_aclk          => CLK,
      m_axis_tvalid        => axis_data1_fifo.tvalid,
      m_axis_tready        => axis_data1_fifo.tready,
      m_axis_tdata         => axis_data1_fifo.tdata,
      m_axis_tkeep         => axis_data1_fifo.tkeep,
      m_axis_tlast         => axis_data1_fifo.tlast,
      almost_empty_axis    => open,
      almost_full_axis     => open,
      rd_data_count_axis   => open,
      wr_data_count_axis   => open
   );


   axis_switch_0_inst : axis_switch_0
   PORT MAP (
      aclk              => CLK,
      aresetn           => RESET_N,
      s_axis_tvalid     => axis_data1_fifo.tvalid & axis_data0_fifo.tvalid,
      s_axis_tready(0)  => axis_data0_fifo.tready,
      s_axis_tready(1)  => axis_data1_fifo.tready,
      s_axis_tdata      => axis_data1_fifo.tdata & axis_data0_fifo.tdata,
      s_axis_tlast      => axis_data1_fifo.tlast & axis_data0_fifo.tlast,
      m_axis_tvalid(0)  => DATA_STREAM_OUT_STB,
      m_axis_tready(0)  => DATA_STREAM_OUT_ACK,
      m_axis_tdata      => DATA_STREAM_OUT,
      m_axis_tlast      => open,
      s_req_suppress    => (others=>'0'),
      s_decode_err      => open
  );




  
end arch;   

