-- ----------------------------------------------------------------------------
-- FILE:          memcfg_pkg.vhd
-- DESCRIPTION:   Package for memcfg module
-- DATE:          11:13 AM Friday, May 11, 2018
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
package memcfg_pkg is
   
   -- Outputs from the 
   type t_FROM_MEMCFG is record
      mac   : std_logic_vector(15 downto 0);
      LMS1_tx_pct_rst : std_logic; 
      LMS1_tx_drp_rst : std_logic;
      LMS2_tx_pct_rst : std_logic;
      LMS2_tx_drp_rst : std_logic;
   end record t_FROM_MEMCFG;
  
   -- Inputs to the 
   type t_TO_MEMCFG is record
      LMS1_tx_pct_cnt : std_logic_vector(31 downto 0);
      LMS1_tx_drp_cnt : std_logic_vector(31 downto 0);
      LMS2_tx_pct_cnt : std_logic_vector(31 downto 0);
      LMS2_tx_drp_cnt : std_logic_vector(31 downto 0);
   end record t_TO_MEMCFG;
   

      
end package memcfg_pkg;