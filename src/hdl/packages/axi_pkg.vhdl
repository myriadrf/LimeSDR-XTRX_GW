-- ----------------------------------------------------------------------------
-- FILE:          axi_pkg.vhd
-- DESCRIPTION:   Package for AXI bus
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
package axi_pkg is
   
   -- Outputs from the AXI master.
   type t_FROM_AXIM_32x32 is record
      araddr   : STD_LOGIC_VECTOR ( 31 downto 0 );
      arprot   : STD_LOGIC_VECTOR ( 2 downto 0 );
      arvalid  : STD_LOGIC_VECTOR ( 0 to 0 );
      awaddr   : STD_LOGIC_VECTOR ( 31 downto 0 );
      awprot   : STD_LOGIC_VECTOR ( 2 downto 0 );
      awvalid  : STD_LOGIC_VECTOR ( 0 to 0 );
      bready   : STD_LOGIC_VECTOR ( 0 to 0 );
      rready   : STD_LOGIC_VECTOR ( 0 to 0 );
      wdata    : STD_LOGIC_VECTOR ( 31 downto 0 );
      wstrb    : STD_LOGIC_VECTOR ( 3 downto 0 );
      wvalid   : STD_LOGIC_VECTOR ( 0 to 0 );
   end record t_FROM_AXIM_32x32;
  
   -- Inputs to the AXI master.
   type t_TO_AXIM_32x32 is record
      arready  : STD_LOGIC_VECTOR ( 0 to 0 );
      awready  : STD_LOGIC_VECTOR ( 0 to 0 );
      bresp    : STD_LOGIC_VECTOR ( 1 downto 0 );
      bvalid   : STD_LOGIC_VECTOR ( 0 to 0 );
      rdata    : STD_LOGIC_VECTOR ( 31 downto 0 );
      rresp    : STD_LOGIC_VECTOR ( 1 downto 0 );
      rvalid   : STD_LOGIC_VECTOR ( 0 to 0 );
      wready   : STD_LOGIC_VECTOR ( 0 to 0 );
   end record t_TO_AXIM_32x32;
   
   constant c_FROM_AXIM_32x32_ZERO : t_FROM_AXIM_32x32 := (
      araddr   => (others=>'0'),
      arprot   => (others=>'0'),
      arvalid  => (others=>'0'),
      awaddr   => (others=>'0'),
      awprot   => (others=>'0'),
      awvalid  => (others=>'0'),
      bready   => (others=>'0'),
      rready   => (others=>'0'),
      wdata    => (others=>'0'),
      wstrb    => (others=>'0'),
      wvalid   => (others=>'0')
      );
   
   constant c_TO_AXIM_32x32_ZERO : t_TO_AXIM_32x32 := (
      arready  => (others=>'0'),
      awready  => (others=>'0'),
      bresp    => (others=>'0'),
      bvalid   => (others=>'0'),
      rdata    => (others=>'0'),
      rresp    => (others=>'0'),
      rvalid   => (others=>'0'),
      wready   => (others=>'0')
      );

end package axi_pkg;