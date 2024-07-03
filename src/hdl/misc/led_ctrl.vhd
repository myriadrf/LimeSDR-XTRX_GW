-- ----------------------------------------------------------------------------
-- FILE:          led_ctrl.vhd
-- DESCRIPTION:   Basic blinker module for two LEDs to indicate clock activity
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

-- ----------------------------------------------------------------------------
-- Entity declaration
-- ----------------------------------------------------------------------------

entity led_ctrl is
  port (
    clk1 : in    std_logic;
    clk2 : in    std_logic;
    led1 : out   std_logic;
    led2 : out   std_logic
  );
end entity led_ctrl;

-- ----------------------------------------------------------------------------
-- Architecture
-- ----------------------------------------------------------------------------

architecture arch of led_ctrl is

begin

  blinker_proc_clk1 : process (clk1) is

    variable blink_counter : unsigned(25 downto 0) := (others => '0');

  begin

    if rising_edge(clk1) then
      blink_counter := blink_counter + 1;
    end if;

    led1 <= blink_counter(blink_counter'left);

  end process blinker_proc_clk1;

     blinker_proc_clk2 : process (clk2) is

    variable blink_counter : unsigned(25 downto 0) := (others => '0');

  begin

    if rising_edge(clk2) then
      blink_counter := blink_counter + 1;
    end if;

    led2 <= blink_counter(blink_counter'left);

  end process blinker_proc_clk2;

end architecture arch;
