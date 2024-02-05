-- ----------------------------------------------------------------------------
-- FILE:          tst_top.vhd
-- DESCRIPTION:   Test module
-- DATE:          10:55 AM Monday, May 14, 2018?
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
   use work.tstcfg_pkg.all;

-- ----------------------------------------------------------------------------
-- Entity declaration
-- ----------------------------------------------------------------------------

entity TST_TOP is
   port (
      -- input ports
      SYS_CLK              : in    std_logic;    --! System clock
      RESET_N              : in    std_logic;    --! Reset, active low

      LMS_TX_CLK           : in    std_logic;    --! LMS7002 tx clock

      -- gnss
      GNSS_UART_RX         : in    std_logic;    --! GNSS chip's uart rx signal
      GNSS_UART_TX         : out   std_logic;    --! GNSS chip's uart rx signal

      -- To configuration memory
      TO_TSTCFG            : out   t_TO_TSTCFG;  --! Configuration register bus Module -> Registers
      FROM_TSTCFG          : in    t_FROM_TSTCFG --! Configuration register bus Registers -> Module
   );
end entity TST_TOP;

-- ----------------------------------------------------------------------------
-- Architecture
-- ----------------------------------------------------------------------------

architecture ARCH of TST_TOP is

   signal test_enable   : std_logic_vector(4 downto 0);
   signal test_complete : std_logic_vector(4 downto 0);
   signal test_result   : std_logic_vector(4 downto 0);

begin

   -- ----------------------------------------------------------------------------
   -- clock_test instance
   -- ----------------------------------------------------------------------------
   inst0_clock_test : entity work.clock_test
      port map (
         -- input ports
         SYS_CLK        => SYS_CLK,
         RESET_N        => RESET_N,
         TEST_EN        => test_enable(1 downto 0),
         TEST_CMPLT     => test_complete(1 downto 0),
         TEST_REZ       => test_result(1 downto 0),
         LMS_TX_CLK     => LMS_TX_CLK,
         SYS_CLK_CNT    => to_tstcfg.SYS_CLK_CNT,
         LMS_TX_CLK_CNT => to_tstcfg.LMS_TX_CLK_CNT
      );

   -- ----------------------------------------------------------------------------
   -- GNSS module test instance
   -- ----------------------------------------------------------------------------

   inst1_gnss_test : entity work.gnss_uart_test
      generic map (
         G_CLK_FREQUENCY => 125000000,
         G_BAUD_RATE     => 9600
      )
      port map (
         CLK     => SYS_CLK,
         TEST_EN => test_enable(2),

         TEST_COMPLETE  => test_complete(2),
         TEST_PASS_FAIL => test_result(2),

         UART_RX => GNSS_UART_RX,
         UART_TX => GNSS_UART_TX

      );

   test_enable(0)          <= from_tstcfg.TEST_EN(0);
   test_enable(1)          <= from_tstcfg.TEST_EN(2);
   test_enable(2)          <= from_tstcfg.TEST_EN(4);
   to_tstcfg.TEST_CMPLT(0) <= test_complete(0);
   to_tstcfg.TEST_CMPLT(2) <= test_complete(1);
   to_tstcfg.TEST_CMPLT(4) <= test_complete(2);
   to_tstcfg.TEST_REZ(0)   <= test_result(0);
   to_tstcfg.TEST_REZ(2)   <= test_result(1);
   to_tstcfg.TEST_REZ(4)   <= test_result(2);

end architecture ARCH;


