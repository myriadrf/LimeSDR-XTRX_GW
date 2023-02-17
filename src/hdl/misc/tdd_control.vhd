-- ----------------------------------------------------------------------------
-- FILE:          tdd_control.vhd
-- DESCRIPTION:   Module for controlling LimeSDR-XTRX board's TDD signals
-- DATE:          10:56 AM Friday, February 17, 2023
-- AUTHOR(s):     Lime Microsystems
-- REVISIONS:
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
--NOTES:
-- ----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--! Local libraries
library work;

--! Entity/Package Description
entity tdd_control is
   port (
        MANUAL_VALUE    : in std_logic; -- Value to be used in manual mode
        AUTO_ENABLE     : in std_logic; -- 0: manual mode 1: auto mode
        AUTO_IN         : in std_logic; -- Signal to be used for manual control
        AUTO_INVERT     : in std_logic; -- 0: don't invert auto input 1: invert auto input
        --
        TDD_OUT         : out std_logic -- Output
   );
end entity tdd_control;

architecture rtl of tdd_control is

    signal auto_muxed : std_logic;

begin

    auto_muxed <= AUTO_IN when AUTO_INVERT = '0' else NOT AUTO_IN;
    TDD_OUT    <= auto_muxed when AUTO_ENABLE = '1' else MANUAL_VALUE;

end architecture rtl;