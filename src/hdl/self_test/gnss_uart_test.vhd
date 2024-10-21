-- ----------------------------------------------------------------------------	
-- FILE: 	gnss_uart_test.vhd
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
entity gnss_uart_test is
  generic (
        G_CLK_FREQUENCY : integer := 125000000; --! CLK clock frequency, in Hz
        G_BAUD_RATE     : integer := 9600 --! Baud rate of GNSS UART
  );
  port (
        --input ports 
        CLK           	: in std_logic; --! Clock signal
        TEST_EN			: in std_logic; --! Test enable
		  
		  TEST_COMPLETE	: out std_logic; --! Test complete
		  TEST_PASS_FAIL	: out std_logic; --! Test pass, active high
		  
		  UART_RX         : in  std_logic; --! GNSS chip uart rx port
		  UART_TX         : out std_logic --! GNSS chip uart tx port
     
        );
end gnss_uart_test;


architecture arch of gnss_uart_test is

   signal data_stream_in      : std_logic_vector(7 downto 0);
   signal data_stream_in_stb  : std_logic;
   signal data_stream_in_ack  : std_logic;
   signal data_stream_out     : std_logic_vector(7 downto 0);
   signal data_stream_out_stb : std_logic;
   signal data_stream_out_ack : std_logic;


begin

   inst0_data_gen : entity work.gnss_data_gen
   port map
   (
   CLK           	     => CLK    ,
   RESET_N			     => TEST_EN,
                       
   TEST_COMPLETE	     => TEST_COMPLETE ,
   TEST_PASS_FAIL	     => TEST_PASS_FAIL,
                        
   DATA_STREAM_IN      => DATA_STREAM_IN     ,
   DATA_STREAM_IN_STB  => DATA_STREAM_IN_STB ,
   DATA_STREAM_IN_ACK  => DATA_STREAM_IN_ACK ,
   DATA_STREAM_OUT     => DATA_STREAM_OUT    ,
   DATA_STREAM_OUT_STB => DATA_STREAM_OUT_STB,
   DATA_STREAM_OUT_ACK => DATA_STREAM_OUT_ACK
   );


   
   inst1_uart : entity work.uart
   generic map
   (
      BAUD_RATE       => G_BAUD_RATE,
      CLOCK_FREQUENCY => G_CLK_FREQUENCY
   )
   port map
   (
      CLOCK                     => CLK,
      RESET                     => not TEST_EN,
      DATA_STREAM_IN            => data_stream_in     ,
      DATA_STREAM_IN_STB        => data_stream_in_stb ,
      DATA_STREAM_IN_ACK        => data_stream_in_ack ,
      DATA_STREAM_OUT           => data_stream_out    ,
      DATA_STREAM_OUT_STB       => data_stream_out_stb,
      DATA_STREAM_OUT_ACK       => data_stream_out_ack,
      TX                        => UART_TX,                 
      RX                        => UART_RX                 

   );


end arch;
