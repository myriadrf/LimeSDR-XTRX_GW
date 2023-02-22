-- ----------------------------------------------------------------------------
-- FILE:          tstcfg_pkg.vhd
-- DESCRIPTION:   Package for tstcfg module
-- DATE:          9:57 AM Monday, May 14, 2018
-- AUTHOR(s):     Lime Microsystems
-- REVISIONS:
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
--NOTES:
-- ----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- ----------------------------------------------------------------------------
-- Package declaration
-- ----------------------------------------------------------------------------
package tstcfg_pkg is
   
   -- Outputs from the 
   type t_FROM_TSTCFG is record
      TX_TST_I					: std_logic_vector(15 downto 0);
	  TX_TST_Q					: std_logic_vector(15 downto 0);
   end record t_FROM_TSTCFG;
  
   -- Inputs to the .
   type t_TO_TSTCFG is record
    placeholder : std_logic;
   end record t_TO_TSTCFG;   

end package tstcfg_pkg;