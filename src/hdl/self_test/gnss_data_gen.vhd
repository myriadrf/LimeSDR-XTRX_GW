-- ----------------------------------------------------------------------------	
-- FILE: 	gnss_data_gen.vhd
-- DESCRIPTION:	Sends a test command via UART to gnss module and checks the response 
-- DATE:	Jan 2, 2024
-- AUTHOR(s):	Lime Microsystems
-- REVISIONS:
-- ----------------------------------------------------------------------------	
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- ----------------------------------------------------------------------------
-- Entity declaration
-- ----------------------------------------------------------------------------
entity gnss_data_gen is
  generic (
        G_CLK_FREQUENCY : integer := 125000000; --! CLK clock frequency, in Hz
        G_BAUD_RATE     : integer := 9600 --! Baud rate of GNSS UART
  );
  port (
        --input ports 
        CLK           	    : in std_logic; --! Clock signal
        RESET_N			    : in std_logic; --! Reset, active low
		  
		  TEST_COMPLETE	    : out std_logic; --! Test complete
		  TEST_PASS_FAIL	    : out std_logic; --! Test pass, active high, equal to TEST_COMPLETE
		  
		  DATA_STREAM_IN      : out std_logic_vector(7 downto 0); --! Outgoing data to UART module
		  DATA_STREAM_IN_STB  : out std_logic; --! Outgoing data strobe signal
        DATA_STREAM_IN_ACK  : in  std_logic; --! Outgoing data acknowledge signal
        DATA_STREAM_OUT     : in  std_logic_vector(7 downto 0); --! Incoming data from UART module
        DATA_STREAM_OUT_STB : in  std_logic; --! Incoming data strobe signal
        DATA_STREAM_OUT_ACK : out std_logic --! Incoming data acknowledge signal
     
        );
end gnss_data_gen;



architecture arch of gnss_data_gen is



				
				

   type T_MESSAGE is array (integer range <>) of std_logic_vector(7 downto 0);
   --000 PMTK_TEST COMMAND
   constant C_TX_MESSAGE : T_MESSAGE(102 downto 0) :=
   (
      --  PMTK_API_SET_NMEA_OUTPUT Disable all sentences except RMC
      0 => 8x"24", --$ 
      1 => 8x"50", --P 
      2 => 8x"4D", --M 
      3 => 8x"54", --T
      4 => 8x"4B", --K 
      5 => 8x"33", --3
      6 => 8x"31", --1
      7 => 8x"34", --4
      8 => 8x"2C", --,
      9 => 8x"31", --1 
      10 => 8x"2C", --,
      11 => 8x"31", --1 
      12 => 8x"2C", --,
      13 => 8x"31", --1 
      14 => 8x"2C", --,
      15 => 8x"31", --1 
      16 => 8x"2C", --,
      17 => 8x"31", --1 
      18 => 8x"2C", --,
      19 => 8x"35", --5 
      20 => 8x"2C", --,
      21 => 8x"30", --0 
      22 => 8x"2C", --,
      23 => 8x"30", --0 
      24 => 8x"2C", --,
      25 => 8x"30", --0 
      26 => 8x"2C", --,
      27 => 8x"30", --0 
      28 => 8x"2C", --,
      29 => 8x"30", --0 
      30 => 8x"2C", --,
      31 => 8x"30", --0 
      32 => 8x"2C", --,
      33 => 8x"30", --0 
      34 => 8x"2C", --,
      35 => 8x"30", --0 
      36 => 8x"2C", --,
      37 => 8x"30", --0 
      38 => 8x"2C", --,
      39 => 8x"30", --0 
      40 => 8x"2C", --,
      41 => 8x"30", --0 
      42 => 8x"2C", --,
      43 => 8x"31", --1 
      44 => 8x"2C", --,
      45 => 8x"30", --0 
      46 => 8x"2A", --*
      47 => 8x"32", --2
      48 => 8x"44", --D
      49 => 8x"0D", --<CR> 
      50 => 8x"0A", --<LF> 

      51 => 8x"0D", --<CR> 
      52 => 8x"0A", --<LF> 

      -- Enable PPS
      53 => 8x"24", --$ 
      54 => 8x"50", --P 
      55 => 8x"4D", --M 
      56 => 8x"54", --T
      57 => 8x"4B", --K 
      58 => 8x"32", --2
      59 => 8x"35", --5
      60 => 8x"35", --5
      61 => 8x"2C", --,
      62 => 8x"31", --1
      63 => 8x"2A", --*
      64 => 8x"32", --2
      65 => 8x"44", --D
      66 => 8x"0D", --<CR> 
      67 => 8x"0A", --<LF> 

      68 => 8x"0D", --<CR> 
      69 => 8x"0A", --<LF> 


      -- PMTK_SET_NMEA_BAUDRATE to 9600
      70 => 8x"24", --$ 
      71 => 8x"50", --P 
      72 => 8x"4D", --M 
      73 => 8x"54", --T
      74 => 8x"4B", --K 
      75 => 8x"32", --2
      76 => 8x"35", --5
      77 => 8x"31", --1
      78 => 8x"2C", --,
      79 => 8x"39", --9
      80 => 8x"36", --6
      81 => 8x"30", --0
      82 => 8x"30", --0
      83 => 8x"2A", --*
      84 => 8x"31", --1
      85 => 8x"37", --7
      86 => 8x"0D", --<CR> 
      87 => 8x"0A", --<LF> 

      88 => 8x"0D", --<CR> 
      89 => 8x"0A", --<LF> 


      -- PMTK test
      90 => 8x"24", --$ 
      91 => 8x"50", --P 
      92 => 8x"4D", --M 
      93 => 8x"54", --T
      94 => 8x"4B", --K 
      95 => 8x"30", --0 
      -- these seem to be optional
      -- 6  => 8x"30", --0
      -- 7  => 8x"30", --0
      96 => 8x"2A", --*
      97 => 8x"33", --3
      98 => 8x"32", --2
      99 => 8x"0D", --<CR> 
      100 => 8x"0A",  --<LF> 

      101 => 8x"0D", --<CR> 
      102 => 8x"0A" --<LF> 


   ); 
      
   -- 001 PMTK_ACK COMMAND
   constant C_RX_MESSAGE : T_MESSAGE(14 downto 0) :=
   (
      0   => 8x"24", --$ 
      1   => 8x"50", --P 
      2   => 8x"4D", --M 
      3   => 8x"54", --T
      4   => 8x"4B", --K 
      5   => 8x"30", --0 
      6   => 8x"30", --0   
      7   => 8x"31", --1
      8   => 8x"2C", --,
      9   => 8x"30", --0 
      -- GNSS module seems to omit these in its response
      -- 10  => 8x"30", --0
      -- 11  => 8x"30", --0
      10  => 8x"2C", --,
      11  => 8x"33", --3
      12  => 8x"2A", --*  
      13  => 8x"33", --3
      14  => 8x"30"  --0
   ); --No checksum or packet end checking
 
   signal tx_counter : integer range 0 to C_TX_MESSAGE'LEFT := 0;
   signal tx_done    : std_logic := '0';
   signal rx_counter : integer range 0 to C_RX_MESSAGE'LEFT := 0;
   signal rx_done    : std_logic := '0';
   signal rx_stb_reg : std_logic;
   
begin

   --handle sending test message
   TX_PROCESS : process(CLK,RESET_N)
   begin
      if RESET_N = '0' then
         tx_counter         <= 0;
         tx_done            <= '0';
         DATA_STREAM_IN_STB <= '0';
      elsif rising_edge(CLK) then
         if tx_done = '0' then
            DATA_STREAM_IN     <= C_TX_MESSAGE(tx_counter);
            DATA_STREAM_IN_STB <= '1';
            if DATA_STREAM_IN_ACK = '1' then
               DATA_STREAM_IN_STB <= '0';
               if tx_counter >= C_TX_MESSAGE'left then
                  tx_done <= '1';
               else
                  tx_counter         <= tx_counter + 1;
               end if;
            end if;
         else --tx_done = '1' 
            DATA_STREAM_IN_STB <= '0';
         end if;
      end if;
   end process;
   
   --register relevant inputs`
   reg_proc : process(CLK,RESET_N)
   begin
      if RESET_N = '0' then
         rx_stb_reg <= '0';
      elsif rising_edge(CLK) then
         rx_stb_reg <= DATA_STREAM_OUT_STB;
      end if;
   end process;
   
   --handle receiving test response
   RX_PROCESS : process(CLK,RESET_N)
   begin
      if RESET_N = '0' then
         rx_counter <= 0;
         rx_done    <= '0';
      elsif rising_edge(CLK) then
         if rx_done = '0' then
            if rx_counter >= C_RX_MESSAGE'LEFT then
               rx_done <= '1';
            else
               --rising edge of valid data
               if DATA_STREAM_OUT_STB = '1' and rx_stb_reg = '0' then
                  if DATA_STREAM_OUT = C_RX_MESSAGE(rx_counter) then
                     rx_counter <= rx_counter + 1;
                  else
                     rx_counter <= 0;
                  end if;
               end if;
            end if;
         end if;
      end if;
   end process;

   TEST_COMPLETE  <= rx_done;
   TEST_PASS_FAIL <= rx_done;


end arch;