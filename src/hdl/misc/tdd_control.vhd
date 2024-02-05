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
        MANUAL_VALUE        : in std_logic; --! Value to be used for TDD_OUT if AUTO_ENABLE = '0'
        AUTO_ENABLE         : in std_logic; --! Enable automatic TDD_OUT control
        AUTO_IN             : in std_logic; --! RF status. '1': transmitting, '0': not transmitting
        AUTO_INVERT         : in std_logic; --! Invert TDD_OUT signal
        --
        RX_RF_SW_IN         : in std_logic_vector(1 downto 0); --! RF RX switch configuration to be used when receiving
        TX_RF_SW_IN         : in std_logic; --! RF TX switch configuration to be used when transmitting
        RF_SW_AUTO_ENANBLE  : in std_logic; --! Enable automatic TDD RF RX/TX switch control
        --
        TDD_OUT             : out std_logic; --! Output signal for external TDD modules
        RX_RF_SW_OUT        : out std_logic_vector(1 downto 0); --! RF RX switch control output
        TX_RF_SW_OUT        : out std_logic --! RF TX switch control output
   );
end entity tdd_control;

architecture rtl of tdd_control is

    signal auto_muxed : std_logic;
    signal rx_sw_muxed : std_logic_vector(1 downto 0);
    signal tx_sw_muxed : std_logic;
    
--    attribute MARK_DEBUG : string;
--    attribute MARK_DEBUG of rx_sw_muxed  : signal is "TRUE";
--    attribute MARK_DEBUG of tx_sw_muxed  : signal is "TRUE";
--    attribute MARK_DEBUG of RX_RF_SW_OUT : signal is "TRUE";
--    attribute MARK_DEBUG of TX_RF_SW_OUT : signal is "TRUE";
--    attribute MARK_DEBUG of AUTO_IN      : signal is "TRUE";
--    attribute MARK_DEBUG of RX_RF_SW_IN  : signal is "TRUE";
--    attribute MARK_DEBUG of TX_RF_SW_IN  : signal is "TRUE";
--    attribute MARK_DEBUG of RF_SW_AUTO_ENANBLE  : signal is "TRUE";

begin

    auto_muxed   <= AUTO_IN     when AUTO_INVERT = '0'        else NOT AUTO_IN;
    TDD_OUT      <= auto_muxed  when AUTO_ENABLE = '1'        else MANUAL_VALUE;
    
    rx_sw_muxed  <= RX_RF_SW_IN when AUTO_IN = '0'            else "11";
    tx_sw_muxed  <= TX_RF_SW_IN when AUTO_IN = '1'            else not TX_RF_SW_IN;
    
    RX_RF_SW_OUT <= RX_RF_SW_IN when RF_SW_AUTO_ENANBLE = '0' else rx_sw_muxed;
    TX_RF_SW_OUT <= TX_RF_SW_IN when RF_SW_AUTO_ENANBLE = '0' else tx_sw_muxed;
    
    

end architecture rtl;