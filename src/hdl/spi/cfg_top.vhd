-- ----------------------------------------------------------------------------
-- FILE:          cfg_top.vhd
-- DESCRIPTION:   Wrapper file for SPI configuration memories
-- DATE:          11:09 AM Friday, May 11, 2018
-- AUTHOR(s):     Lime Microsystems
-- REVISIONS:
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
--NOTES:
-- ----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fpgacfg_pkg.all;
use work.pllcfg_pkg.all;
use work.tstcfg_pkg.all;
use work.txtspcfg_pkg.all;
use work.rxtspcfg_pkg.all;
use work.memcfg_pkg.all;
use work.cdcmcfg_pkg.all;

use work.fircfg_pkg.all; -- B.J.

-- ----------------------------------------------------------------------------
-- Entity declaration
-- ----------------------------------------------------------------------------
entity cfg_top is
   generic(
      -- CFG_START_ADDR has to be multiple of 32, because there are 32 addresses
      FPGACFG_START_ADDR   : integer := 0;
      PLLCFG_START_ADDR    : integer := 32;
      TSTCFG_START_ADDR    : integer := 96;
      TXTSPCFG_START_ADDR  : integer := 128;
      RXTSPCFG_START_ADDR  : integer := 160;
      CDCMCFG_START_ADDR   : integer := 320;
   
      RXTSPCFG_START_ADDR_3  : integer := 352; -- B.J.
      FIRCFG_TX    : integer := 704;  -- BJ (for Transmitter)
      FIRCFG_RX    : integer := 704+32; -- BJ (for Receiver)

      MEMCFG_START_ADDR    : integer := 65504
      );
   port (
      -- Serial port IOs
      sdin                 : in  std_logic;  -- Data in
      sclk                 : in  std_logic;  -- Data clock
      sen                  : in  std_logic;  -- Enable signal (active low)
      sdout                : out std_logic;  -- Data out
      
      pllcfg_sdin          : in  std_logic;  -- Data in
      pllcfg_sclk          : in  std_logic;  -- Data clock
      pllcfg_sen           : in  std_logic;  -- Enable signal (active low)
      pllcfg_sdout         : out std_logic;  -- Data out
      
      -- Signals coming from the pins or top level serial interface
      lreset               : in  std_logic;   -- Logic reset signal, resets logic cells only  (use only one reset)
      mreset               : in  std_logic;   -- Memory reset signal, resets configuration memory only (use only one reset)
      to_fpgacfg         : in  t_TO_FPGACFG;
      from_fpgacfg       : out t_FROM_FPGACFG;
      to_pllcfg            : in  t_TO_PLLCFG;
      from_pllcfg          : out t_FROM_PLLCFG;
      to_tstcfg            : in  t_TO_TSTCFG;
      to_tstcfg_from_rxtx  : in  t_TO_TSTCFG_FROM_RXTX;
      from_tstcfg          : out t_FROM_TSTCFG;
      to_memcfg            : in  t_TO_MEMCFG;
      from_memcfg          : out t_FROM_MEMCFG
   );
end cfg_top;

-- ----------------------------------------------------------------------------
-- Architecture
-- ----------------------------------------------------------------------------
architecture arch of cfg_top is
--declare signals,  components here
--inst0_0
signal inst0_sdout   : std_logic;

--inst1
signal inst1_sdoutA  : std_logic;

--inst3
signal inst3_sdout   : std_logic;

--inst255
signal inst255_sdout         : std_logic;
signal inst255_to_memcfg     : t_TO_MEMCFG;
signal inst255_from_memcfg   : t_FROM_MEMCFG;



begin

-- ----------------------------------------------------------------------------
-- fpgacfg instance
-- ----------------------------------------------------------------------------
      
   inst0_0_fpgacfg : entity work.fpgacfg
   port map(
      -- Address and location of this module
      -- Will be hard wired at the top level
      maddress    => std_logic_vector(to_unsigned(FPGACFG_START_ADDR/32,10)),
      mimo_en     => '1',   
      -- Serial port IOs
      sdin        => sdin,
      sclk        => sclk,
      sen         => sen,
      sdout       => inst0_sdout,  
      -- Signals coming from the pins or top level serial interface
      lreset      => lreset,   -- Logic reset signal, resets logic cells only  (use only one reset)
      mreset      => mreset,   -- Memory reset signal, resets configuration memory only (use only one reset)      
      oen         => open,
      stateo      => open,      
      to_fpgacfg  => to_fpgacfg,
      from_fpgacfg=> from_fpgacfg
   );
 
   
-- ----------------------------------------------------------------------------
-- pllcfg instance
-- ----------------------------------------------------------------------------  
   inst1_pllcfg : entity work.pllcfg
   port map(
      -- Address and location of this module
      -- Will be hard wired at the top level
      maddress       => std_logic_vector(to_unsigned(PLLCFG_START_ADDR/32,10)),
      mimo_en        => '1',      
      -- Serial port A IOs
      sdinA          => sdin,
      sclkA          => sclk,
      senA           => sen,
      sdoutA         => inst1_sdoutA,    
      oenA           => open,     
      -- Serial port B IOs
      sdinB          => pllcfg_sdin,
      sclkB          => pllcfg_sclk,
      senB           => pllcfg_sen,
      sdoutB         => pllcfg_sdout,    
      oenB           => open,       
      -- Signals coming from the pins or top level serial interface
      lreset         => lreset, -- Logic reset signal, resets logic cells only  (use only one reset)
      mreset         => mreset,-- Memory reset signal, resets configuration memory only (use only one reset)      
      to_pllcfg      => to_pllcfg,
      from_pllcfg    => from_pllcfg
   );
   
-- ----------------------------------------------------------------------------
-- tstcfg instance
-- ----------------------------------------------------------------------------    
   inst3_tstcfg : entity work.tstcfg
   port map(
      -- Address and location of this module
      -- Will be hard wired at the top level
      maddress             => std_logic_vector(to_unsigned(TSTCFG_START_ADDR/32,10)),
      mimo_en              => '1',   
      -- Serial port IOs
      sdin                 => sdin,
      sclk                 => sclk,
      sen                  => sen,
      sdout                => inst3_sdout,  
      -- Signals coming from the pins or top level serial interface
      lreset               => lreset,   -- Logic reset signal, resets logic cells only  (use only one reset)
      mreset               => mreset,   -- Memory reset signal, resets configuration memory only (use only one reset)      
      oen                  => open,
      stateo               => open,    
      to_tstcfg            => to_tstcfg,
      to_tstcfg_from_rxtx  => to_tstcfg_from_rxtx,
      from_tstcfg          => from_tstcfg
   );
 
-- ----------------------------------------------------------------------------
-- memcfg instance
-- ----------------------------------------------------------------------------     
   inst255_memcfg : entity work.memcfg
   port map(
      -- Address and location of this module
      -- Will be hard wired at the top level
      maddress    => std_logic_vector(to_unsigned(MEMCFG_START_ADDR/32,10)),
      mimo_en     => '1',   
      -- Serial port IOs
      sdin        => sdin,
      sclk        => sclk,
      sen         => sen,
      sdout       => inst255_sdout,  
      -- Signals coming from the pins or top level serial interface
      lreset      => lreset,   -- Logic reset signal, resets logic cells only  (use only one reset)
      mreset      => mreset,   -- Memory reset signal, resets configuration memory only (use only one reset)      
      oen         => open,
      stateo      => open,      
      to_memcfg   => inst255_to_memcfg,
      from_memcfg => inst255_from_memcfg
   );
   
inst255_to_memcfg <= to_memcfg;
from_memcfg       <= inst255_from_memcfg;

-- ----------------------------------------------------------------------------
-- Output ports
-- ----------------------------------------------------------------------------    
   sdout <= inst0_sdout OR inst1_sdoutA OR 
            inst3_sdout OR inst255_sdout;
            
  
end arch;   


