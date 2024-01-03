-- ----------------------------------------------------------------------------
-- FILE:          tst_top.vhd
-- DESCRIPTION:   Test module
-- DATE:          10:55 AM Monday, May 14, 2018?
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
use work.tstcfg_pkg.all;

-- ----------------------------------------------------------------------------
-- Entity declaration
-- ----------------------------------------------------------------------------
entity tst_top is
   port (
      --input ports 
      sys_clk              : in std_logic;
      reset_n              : in std_logic;
      
      LMS_TX_CLK           : in std_logic;
      
      --gnss
      GNSS_UART_RX         : in std_logic;
      GNSS_UART_TX         : out std_logic;
      
      -- To configuration memory
      to_tstcfg            : out t_TO_TSTCFG;
      from_tstcfg          : in t_FROM_TSTCFG
   );
end tst_top;

-- ----------------------------------------------------------------------------
-- Architecture
-- ----------------------------------------------------------------------------
architecture arch of tst_top is

begin

-- ----------------------------------------------------------------------------
-- clock_test instance
-- ----------------------------------------------------------------------------
   clock_test_inst0 : entity work.clock_test
   port map(
      --input ports 
      sys_clk           => sys_clk,
      reset_n           => reset_n,
      test_en           => from_tstcfg.TEST_EN(1 downto 0),
      test_cmplt        => to_tstcfg.TEST_CMPLT(1 downto 0),
      test_rez          => to_tstcfg.TEST_REZ(1 downto 0),      
      LMS_TX_CLK        => LMS_TX_CLK,    
      sys_clk_cnt       => to_tstcfg.SYS_CLK_CNT,
      LMS_TX_CLK_cnt    => to_tstcfg.LMS_TX_CLK_CNT
   );
   
-- ----------------------------------------------------------------------------
-- GNSS module test instance
-- ----------------------------------------------------------------------------

   gnss_test_inst1 : entity work.gnss_uart_test
   generic map(
      G_CLK_FREQUENCY => 125000000,
      G_BAUD_RATE     => 9600
   )
   port map(
      CLK                 => sys_clk,
      TEST_EN             => from_tstcfg.TEST_EN(2),     
      
      TEST_COMPLETE       => to_tstcfg.TEST_CMPLT(2),
      TEST_PASS_FAIL      => to_tstcfg.TEST_REZ(2),  
      
      UART_RX             => GNSS_UART_RX,
      UART_TX             => GNSS_UART_TX

   );
  
end arch;   


