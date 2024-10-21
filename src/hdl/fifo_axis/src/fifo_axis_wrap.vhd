-- ----------------------------------------------------------------------------
-- FILE:          fifo_axis_wrap.vhd
-- DESCRIPTION:   Wrapper for AXIS FIFO
-- DATE:          09:45 2023-05-15
-- AUTHOR(s):     Lime Microsystems
-- REVISIONS:
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- NOTES:
-- ----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

Library xpm;
use xpm.vcomponents.all;

-- ----------------------------------------------------------------------------
-- Entity declaration
-- ----------------------------------------------------------------------------
entity fifo_axis_wrap is
   generic(
      g_CLOCKING_MODE      : string := "independent_clock"; -- "common_clock" or "independent_clock"
      g_PACKET_FIFO        : string := "false";             -- Packet FIFO mode
      g_FIFO_DEPTH         : integer := 256;
      g_TDATA_WIDTH        : integer := 32;
      g_RD_DATA_COUNT_WIDTH: integer := 1;
      g_WR_DATA_COUNT_WIDTH: integer := 1
   );
   port (
      s_axis_aresetn       : in  std_logic;
      s_axis_aclk          : in  std_logic;
      s_axis_tvalid        : in  std_logic;
      s_axis_tready        : out std_logic;
      s_axis_tdata         : in  std_logic_vector(g_TDATA_WIDTH-1 downto 0);
      s_axis_tkeep         : in  std_logic_vector(g_TDATA_WIDTH/8-1 downto 0) := (others=>'1');
      s_axis_tlast         : in  std_logic;
      m_axis_aclk          : in  std_logic;
      m_axis_tvalid        : out std_logic;
      m_axis_tready        : in  std_logic;
      m_axis_tdata         : out std_logic_vector(g_TDATA_WIDTH-1 downto 0);
      m_axis_tkeep         : out std_logic_vector(g_TDATA_WIDTH/8-1 downto 0);
      m_axis_tlast         : out std_logic;
      almost_empty_axis    : out std_logic;
      almost_full_axis     : out std_logic;
      rd_data_count_axis   : out std_logic_vector(g_RD_DATA_COUNT_WIDTH-1 downto 0);
      wr_data_count_axis   : out std_logic_vector(g_WR_DATA_COUNT_WIDTH-1 downto 0)
   );
end fifo_axis_wrap;

-- ----------------------------------------------------------------------------
-- Architecture
-- ----------------------------------------------------------------------------
architecture arch of fifo_axis_wrap is
--declare signals,  components here

begin 
      -- xpm_fifo_axis: AXI Stream FIFO
      -- Xilinx Parameterized Macro, version 2022.2

      xpm_fifo_axis_inst : xpm_fifo_axis
      generic map (
         CASCADE_HEIGHT       => 0,                -- DECIMAL
         CDC_SYNC_STAGES      => 2,                -- DECIMAL
         CLOCKING_MODE        => g_CLOCKING_MODE,  -- String
         ECC_MODE             => "no_ecc",         -- String
         FIFO_DEPTH           => g_FIFO_DEPTH,     -- DECIMAL
         FIFO_MEMORY_TYPE     => "auto",           -- String
         PACKET_FIFO          => g_PACKET_FIFO,    -- String
         PROG_EMPTY_THRESH    => 10,               -- DECIMAL
         PROG_FULL_THRESH     => 10,               -- DECIMAL
         RD_DATA_COUNT_WIDTH  => g_RD_DATA_COUNT_WIDTH,  -- DECIMAL
         RELATED_CLOCKS       => 0,                      -- DECIMAL
         SIM_ASSERT_CHK       => 0,                      -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
         TDATA_WIDTH          => g_TDATA_WIDTH,          -- DECIMAL
         TDEST_WIDTH          => 1,                      -- DECIMAL
         TID_WIDTH            => 1,                      -- DECIMAL
         TUSER_WIDTH          => 1,                      -- DECIMAL
         USE_ADV_FEATURES     => "1C0C",                 -- String
         WR_DATA_COUNT_WIDTH  => g_WR_DATA_COUNT_WIDTH   -- DECIMAL
      )
      port map (
         almost_empty_axis => almost_empty_axis,   -- 1-bit output: Almost Empty : When asserted, this signal
                                                   -- indicates that only one more read can be performed before
                                                   -- the FIFO goes to empty.
      
         almost_full_axis => almost_full_axis,     -- 1-bit output: Almost Full: When asserted, this signal
                                                   -- indicates that only one more write can be performed before
                                                   -- the FIFO is full.
      
         dbiterr_axis => open,                     -- 1-bit output: Double Bit Error- Indicates that the ECC
                                                   -- decoder detected a double-bit error and data in the FIFO
                                                   -- core is corrupted.
      
         m_axis_tdata => m_axis_tdata,             -- TDATA_WIDTH-bit output: TDATA: The primary payload that is
                                                   -- used to provide the data that is passing across the
                                                   -- interface. The width of the data payload is an integer
                                                   -- number of bytes.
      
         m_axis_tdest => open,                     -- TDEST_WIDTH-bit output: TDEST: Provides routing information
                                                   -- for the data stream.
      
         m_axis_tid => open,                       -- TID_WIDTH-bit output: TID: The data stream identifier that
                                                   -- indicates different streams of data.
      
         m_axis_tkeep => m_axis_tkeep,             -- TDATA_WIDTH/8-bit output: TKEEP: The byte qualifier that
                                                   -- indicates whether the content of the associated byte of
                                                   -- TDATA is processed as part of the data stream. Associated
                                                   -- bytes that have the TKEEP byte qualifier deasserted are null
                                                   -- bytes and can be removed from the data stream. For a 64-bit
                                                   -- DATA, bit 0 corresponds to the least significant byte on
                                                   -- DATA, and bit 7 corresponds to the most significant byte.
                                                   -- For example: KEEP[0] = 1b, DATA[7:0] is not a NULL byte
                                                   -- KEEP[7] = 0b, DATA[63:56] is a NULL byte
      
         m_axis_tlast => m_axis_tlast,             -- 1-bit output: TLAST: Indicates the boundary of a packet.
         m_axis_tstrb => open,                     -- TDATA_WIDTH/8-bit output: TSTRB: The byte qualifier that
                                                   -- indicates whether the content of the associated byte of
                                                   -- TDATA is processed as a data byte or a position byte. For a
                                                   -- 64-bit DATA, bit 0 corresponds to the least significant byte
                                                   -- on DATA, and bit 0 corresponds to the least significant byte
                                                   -- on DATA, and bit 7 corresponds to the most significant byte.
                                                   -- For example: STROBE[0] = 1b, DATA[7:0] is valid STROBE[7] =
                                                   -- 0b, DATA[63:56] is not valid
      
         m_axis_tuser => open,                     -- TUSER_WIDTH-bit output: TUSER: The user-defined sideband
                                                   -- information that can be transmitted alongside the data
                                                   -- stream.
      
         m_axis_tvalid => m_axis_tvalid,           -- 1-bit output: TVALID: Indicates that the master is driving a
                                                   -- valid transfer. A transfer takes place when both TVALID and
                                                   -- TREADY are asserted
      
         prog_empty_axis => open,                  -- 1-bit output: Programmable Empty- This signal is asserted
                                                   -- when the number of words in the FIFO is less than or equal
                                                   -- to the programmable empty threshold value. It is de-asserted
                                                   -- when the number of words in the FIFO exceeds the
                                                   -- programmable empty threshold value.
      
         prog_full_axis => open,                   -- 1-bit output: Programmable Full: This signal is asserted
                                                   -- when the number of words in the FIFO is greater than or
                                                   -- equal to the programmable full threshold value. It is
                                                   -- de-asserted when the number of words in the FIFO is less
                                                   -- than the programmable full threshold value.
      
         rd_data_count_axis => rd_data_count_axis, -- RD_DATA_COUNT_WIDTH-bit output: Read Data Count- This bus
                                                   -- indicates the number of words available for reading in the
                                                   -- FIFO.
      
         s_axis_tready => s_axis_tready,           -- 1-bit output: TREADY: Indicates that the slave can accept a
                                                   -- transfer in the current cycle.
      
         sbiterr_axis => open,                     -- 1-bit output: Single Bit Error- Indicates that the ECC
                                                   -- decoder detected and fixed a single-bit error.
      
         wr_data_count_axis => wr_data_count_axis, -- WR_DATA_COUNT_WIDTH-bit output: Write Data Count: This bus
                                                   -- indicates the number of words written into the FIFO.
      
         injectdbiterr_axis => '0',               -- 1-bit input: Double Bit Error Injection- Injects a double
                                                   -- bit error if the ECC feature is used.
      
         injectsbiterr_axis => '0',                -- 1-bit input: Single Bit Error Injection- Injects a single
                                                   -- bit error if the ECC feature is used.
      
         m_aclk => m_axis_aclk,                    -- 1-bit input: Master Interface Clock: All signals on master
                                                   -- interface are sampled on the rising edge of this clock.
      
         m_axis_tready => m_axis_tready,           -- 1-bit input: TREADY: Indicates that the slave can accept a
                                                   -- transfer in the current cycle.
      
         s_aclk => s_axis_aclk,                    -- 1-bit input: Slave Interface Clock: All signals on slave
                                                   -- interface are sampled on the rising edge of this clock.
      
         s_aresetn => s_axis_aresetn,              -- 1-bit input: Active low asynchronous reset.
         s_axis_tdata => s_axis_tdata,             -- TDATA_WIDTH-bit input: TDATA: The primary payload that is
                                                   -- used to provide the data that is passing across the
                                                   -- interface. The width of the data payload is an integer
                                                   -- number of bytes.
      
         s_axis_tdest => "0",                      -- TDEST_WIDTH-bit input: TDEST: Provides routing information
                                                   -- for the data stream.
      
         s_axis_tid => "0",                        -- TID_WIDTH-bit input: TID: The data stream identifier that
                                                   -- indicates different streams of data.
      
         s_axis_tkeep => s_axis_tkeep,            -- TDATA_WIDTH/8-bit input: TKEEP: The byte qualifier that
                                                   -- indicates whether the content of the associated byte of
                                                   -- TDATA is processed as part of the data stream. Associated
                                                   -- bytes that have the TKEEP byte qualifier deasserted are null
                                                   -- bytes and can be removed from the data stream. For a 64-bit
                                                   -- DATA, bit 0 corresponds to the least significant byte on
                                                   -- DATA, and bit 7 corresponds to the most significant byte.
                                                   -- For example: KEEP[0] = 1b, DATA[7:0] is not a NULL byte
                                                   -- KEEP[7] = 0b, DATA[63:56] is a NULL byte
      
         s_axis_tlast => s_axis_tlast,             -- 1-bit input: TLAST: Indicates the boundary of a packet.
         s_axis_tstrb => (others=>'1'),            -- TDATA_WIDTH/8-bit input: TSTRB: The byte qualifier that
                                                   -- indicates whether the content of the associated byte of
                                                   -- TDATA is processed as a data byte or a position byte. For a
                                                   -- 64-bit DATA, bit 0 corresponds to the least significant byte
                                                   -- on DATA, and bit 0 corresponds to the least significant byte
                                                   -- on DATA, and bit 7 corresponds to the most significant byte.
                                                   -- For example: STROBE[0] = 1b, DATA[7:0] is valid STROBE[7] =
                                                   -- 0b, DATA[63:56] is not valid
      
         s_axis_tuser => "0",                      -- TUSER_WIDTH-bit input: TUSER: The user-defined sideband
                                                   -- information that can be transmitted alongside the data
                                                   -- stream.
      
         s_axis_tvalid => s_axis_tvalid            -- 1-bit input: TVALID: Indicates that the master is driving a
                                                   -- valid transfer. A transfer takes place when both TVALID and
                                                   -- TREADY are asserted
      
      );
      -- End of xpm_fifo_axis_inst instantiation
  
end arch;   


