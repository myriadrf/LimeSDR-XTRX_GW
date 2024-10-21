-- ----------------------------------------------------------------------------
-- FILE:          axis_pkg.vhd
-- DESCRIPTION:   Package for AXI Stream bus
-- DATE:          15:00 2024-05-28
-- AUTHOR(s):     Lime Microsystems
-- REVISIONS:
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- NOTES:
-- VHDL-2008
-- ----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- ----------------------------------------------------------------------------
-- Package declaration
-- ----------------------------------------------------------------------------
package axis_pkg is

   -- AXI Stream signal record
   -- tdata and tkeep must be constrained when declaring signal for e.g:
   -- signal axis_my_bus   : t_AXI_STREAM(tdata(127 downto 0), tkeep(15 downto 0));
   
   type t_AXI_STREAM is record
      tdata  : std_logic_vector;    -- Data
      tkeep  : std_logic_vector;    -- Byte enables (optional)
      tlast  : std_logic;           -- End of frame
      tvalid : std_logic;           -- Valid signal
      tready : std_logic;           -- Ready signal
   end record; 
   
end package axis_pkg;