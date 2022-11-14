-- ----------------------------------------------------------------------------
-- FILE:          cdcmcfg_pkg.vhd
-- DESCRIPTION:   Package for fpgacfg module
-- DATE:          March 16, 2021
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
package cdcmcfg_pkg is
   
   -- Outputs from the fpgacfg.
   type t_FROM_CDCMCFG is record
      CDCM_RECONFIG_START : std_logic;
      CDCM_RECONFIG_DONE : std_logic;
      CDCM_READ_START    : std_logic;
   end record t_FROM_CDCMCFG;
  
   -- Inputs to the fpgacfg.
   type t_TO_CDCMCFG is record
      placeholder : std_logic;
   end record t_TO_CDCMCFG;
   

      
end package cdcmcfg_pkg;
