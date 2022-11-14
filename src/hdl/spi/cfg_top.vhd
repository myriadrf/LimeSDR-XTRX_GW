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
use work.periphcfg_pkg.all;
use work.tamercfg_pkg.all;
use work.gnsscfg_pkg.all;
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
      PERIPHCFG_START_ADDR : integer := 192;
      TAMERCFG_START_ADDR  : integer := 224;
      GNSSCFG_START_ADDR   : integer := 256;
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
      to_fpgacfg_0         : in  t_TO_FPGACFG;
      from_fpgacfg_0       : out t_FROM_FPGACFG;
      to_fpgacfg_1         : in  t_TO_FPGACFG;
      from_fpgacfg_1       : out t_FROM_FPGACFG;
      to_fpgacfg_2         : in  t_TO_FPGACFG;
      from_fpgacfg_2       : out t_FROM_FPGACFG;
      to_pllcfg            : in  t_TO_PLLCFG;
      from_pllcfg          : out t_FROM_PLLCFG;
      to_tstcfg            : in  t_TO_TSTCFG;
      to_tstcfg_from_rxtx  : in  t_TO_TSTCFG_FROM_RXTX;
      from_tstcfg          : out t_FROM_TSTCFG;
      to_txtspcfg_0        : in  t_TO_TXTSPCFG;
      from_txtspcfg_0      : out t_FROM_TXTSPCFG;  
      to_txtspcfg_1        : in  t_TO_TXTSPCFG;
      from_txtspcfg_1      : out t_FROM_TXTSPCFG; 
      --to_rxtspcfg          : in  t_TO_RXTSPCFG;
      --from_rxtspcfg        : out t_FROM_RXTSPCFG;

      to_rxtspcfg_2a          : in  t_TO_RXTSPCFG; -- B.J.
      from_rxtspcfg_2a        : out t_FROM_RXTSPCFG;  -- B.J.       
      to_rxtspcfg_2b          : in  t_TO_RXTSPCFG; -- B.J.
      from_rxtspcfg_2b        : out t_FROM_RXTSPCFG;  -- B.J. 

      to_periphcfg         : in  t_TO_PERIPHCFG;
      from_periphcfg       : out t_FROM_PERIPHCFG;
      to_tamercfg          : in  t_TO_TAMERCFG;
      from_tamercfg        : out t_FROM_TAMERCFG;
      to_gnsscfg           : in  t_TO_GNSSCFG;
      from_gnsscfg         : out t_FROM_GNSSCFG;
      to_memcfg            : in  t_TO_MEMCFG;
      from_memcfg          : out t_FROM_MEMCFG;
      from_cdcmcfg         : out t_FROM_CDCMCFG;
      
      to_rxtspcfg_3a       : in  t_TO_RXTSPCFG;    -- B.J.
      from_rxtspcfg_3a     : out t_FROM_RXTSPCFG;  -- B.J.
      to_rxtspcfg_3b       : in  t_TO_RXTSPCFG;    -- B.J.
      from_rxtspcfg_3b     : out t_FROM_RXTSPCFG;   -- B.J.
      from_fircfg_tx_a, from_fircfg_tx_b : out t_FROM_FIRCFG;  -- B.J.
      from_fircfg_rx_a, from_fircfg_rx_b : out t_FROM_FIRCFG   -- B.J.
   );
end cfg_top;

-- ----------------------------------------------------------------------------
-- Architecture
-- ----------------------------------------------------------------------------
architecture arch of cfg_top is
--declare signals,  components here
--inst0_0
signal inst0_0_sen     : std_logic; 
signal inst0_0_sdout   : std_logic;

--inst0_1
signal inst0_1_sen     : std_logic;
signal inst0_1_sdout   : std_logic;

--inst0_2
signal inst0_2_sen     : std_logic;
signal inst0_2_sdout   : std_logic;

--inst1
signal inst1_sdoutA  : std_logic;

--inst3
signal inst3_sdout   : std_logic;

--inst4_0
signal inst4_0_sen     : std_logic; 
signal inst4_0_sdout   : std_logic;

--inst4_1
signal inst4_1_sen     : std_logic; 
signal inst4_1_sdout   : std_logic;

--inst5
signal inst5_sen, inst5_sen_b     : std_logic;
signal inst5_sdout, inst5_sdout_b   : std_logic;

--inst6
signal inst6_sdout   : std_logic;

--inst7
signal inst7_sdout   : std_logic;

--inst8
signal inst8_sdout   : std_logic;

--inst255
signal inst255_sdout         : std_logic;
signal inst255_to_memcfg     : t_TO_MEMCFG;
signal inst255_from_memcfg   : t_FROM_MEMCFG;

signal inst9_sen, inst9_sdout, inst10_sen, inst10_sdout : std_logic;  -- B.J.
signal inst11_sen_a, inst11_sen_b, inst12_sen_a, inst12_sen_b: std_logic;  -- B.J.
signal inst11_sdout_a, inst11_sdout_b, inst12_sdout_a, inst12_sdout_b: std_logic; -- B.J.

begin

inst255_to_memcfg <= to_memcfg;
from_memcfg       <= inst255_from_memcfg;
-- ----------------------------------------------------------------------------
-- fpgacfg instance
-- ----------------------------------------------------------------------------
   inst0_0_sen <= sen when inst255_from_memcfg.mac(0)='1' else '1';

      
   inst0_0_fpgacfg : entity work.fpgacfg
   port map(
      -- Address and location of this module
      -- Will be hard wired at the top level
      maddress    => std_logic_vector(to_unsigned(FPGACFG_START_ADDR/32,10)),
      mimo_en     => '1',   
      -- Serial port IOs
      sdin        => sdin,
      sclk        => sclk,
      sen         => inst0_0_sen,
      sdout       => inst0_0_sdout,  
      -- Signals coming from the pins or top level serial interface
      lreset      => lreset,   -- Logic reset signal, resets logic cells only  (use only one reset)
      mreset      => mreset,   -- Memory reset signal, resets configuration memory only (use only one reset)      
      oen         => open,
      stateo      => open,      
      to_fpgacfg  => to_fpgacfg_0,
      from_fpgacfg=> from_fpgacfg_0
   );
   
   
   inst0_1_sen <= sen when inst255_from_memcfg.mac(1)='1' else '1';
   
   inst0_1_fpgacfg : entity work.fpgacfg
   port map(
      -- Address and location of this module
      -- Will be hard wired at the top level
      maddress    => std_logic_vector(to_unsigned(FPGACFG_START_ADDR/32,10)),
      mimo_en     => '1',   
      -- Serial port IOs
      sdin        => sdin,
      sclk        => sclk,
      sen         => inst0_1_sen,
      sdout       => inst0_1_sdout,  
      -- Signals coming from the pins or top level serial interface
      lreset      => lreset,   -- Logic reset signal, resets logic cells only  (use only one reset)
      mreset      => mreset,   -- Memory reset signal, resets configuration memory only (use only one reset)      
      oen         => open,
      stateo      => open,      
      to_fpgacfg  => to_fpgacfg_1,
      from_fpgacfg=> from_fpgacfg_1
   );
   
   inst0_2_sen <= sen when inst255_from_memcfg.mac(2)='1' else '1';
   
   inst0_2_fpgacfg : entity work.fpgacfg
   port map(
      -- Address and location of this module
      -- Will be hard wired at the top level
      maddress    => std_logic_vector(to_unsigned(FPGACFG_START_ADDR/32,10)),
      mimo_en     => '1',   
      -- Serial port IOs
      sdin        => sdin,
      sclk        => sclk,
      sen         => inst0_2_sen,
      sdout       => inst0_2_sdout,  
      -- Signals coming from the pins or top level serial interface
      lreset      => lreset,   -- Logic reset signal, resets logic cells only  (use only one reset)
      mreset      => mreset,   -- Memory reset signal, resets configuration memory only (use only one reset)      
      oen         => open,
      stateo      => open,      
      to_fpgacfg  => to_fpgacfg_2,
      from_fpgacfg=> from_fpgacfg_2
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
-- txtspcfg instance
-- ----------------------------------------------------------------------------
   inst4_0_sen <= sen when inst255_from_memcfg.mac(0)='1' else '1';
    
   inst4_0_txtsp : entity work.txtspcfg
   port map(
      -- Address and location of this module
      -- Will be hard wired at the top level
      maddress       => std_logic_vector(to_unsigned(TXTSPCFG_START_ADDR/32,10)),
      mimo_en        => '1', -- MIMO enable, from TOP SPI
   
      -- Serial port IOs
      sdin           => sdin, -- Data in
      sclk           => sclk, -- Data clock
      sen            => inst4_0_sen,  -- Enable signal (active low)
      sdout          => inst4_0_sdout,   -- Data out
      -- Signals coming from the pins or top level serial interface
      lreset         => lreset, -- Logic reset signal, resets logic cells only
      mreset         => mreset, -- Memory reset signal, resets configuration memory only    
      oen            => open,
      stateo         => open,
      
      to_txtspcfg    => to_txtspcfg_0,
      from_txtspcfg  => from_txtspcfg_0

   );
   
   inst4_1_sen <= sen when inst255_from_memcfg.mac(1)='1' else '1';
      
   inst4_1_txtsp : entity work.txtspcfg
   port map(
      -- Address and location of this module
      -- Will be hard wired at the top level
      maddress       => std_logic_vector(to_unsigned(TXTSPCFG_START_ADDR/32,10)),
      mimo_en        => '1', -- MIMO enable, from TOP SPI
   
      -- Serial port IOs
      sdin           => sdin, -- Data in
      sclk           => sclk, -- Data clock
      sen            => inst4_1_sen,  -- Enable signal (active low)
      sdout          => inst4_1_sdout,   -- Data out
      -- Signals coming from the pins or top level serial interface
      lreset         => lreset, -- Logic reset signal, resets logic cells only
      mreset         => mreset, -- Memory reset signal, resets configuration memory only    
      oen            => open,
      stateo         => open,
      
      to_txtspcfg    => to_txtspcfg_1,
      from_txtspcfg  => from_txtspcfg_1

   );
-- ----------------------------------------------------------------------------
-- rxtspcfg instance
-- ---------------------------------------------------------------------------- 
   inst5_sen <= sen when inst255_from_memcfg.mac(0)='1' else '1';
   
   inst5_rxtspcfg : entity work.rxtspcfg
   port map(
      -- Address and location of this module
      -- Will be hard wired at the top level
      maddress             => std_logic_vector(to_unsigned(RXTSPCFG_START_ADDR/32,10)),
      mimo_en              => '1',   
      -- Serial port IOs
      sdin                 => sdin,
      sclk                 => sclk,
      sen                  => inst5_sen,
      sdout                => inst5_sdout,  
      -- Signals coming from the pins or top level serial interface
      lreset               => lreset,   -- Logic reset signal, resets logic cells only  (use only one reset)
      mreset               => mreset,   -- Memory reset signal, resets configuration memory only (use only one reset)      
      oen                  => open,
      stateo               => open,    
      to_rxtspcfg          => to_rxtspcfg_2a,
      from_rxtspcfg        => from_rxtspcfg_2a
   );

   inst5_sen_b <= sen when inst255_from_memcfg.mac(1)='1' else '1';
   
   inst5_rxtspcfg_b : entity work.rxtspcfg
   port map(
      -- Address and location of this module
      -- Will be hard wired at the top level
      maddress             => std_logic_vector(to_unsigned(RXTSPCFG_START_ADDR/32,10)),
      mimo_en              => '1',   
      -- Serial port IOs
      sdin                 => sdin,
      sclk                 => sclk,
      sen                  => inst5_sen_b,
      sdout                => inst5_sdout_b,  
      -- Signals coming from the pins or top level serial interface
      lreset               => lreset,   -- Logic reset signal, resets logic cells only  (use only one reset)
      mreset               => mreset,   -- Memory reset signal, resets configuration memory only (use only one reset)      
      oen                  => open,
      stateo               => open,    
      to_rxtspcfg          => to_rxtspcfg_2b,
      from_rxtspcfg        => from_rxtspcfg_2b
   );
   
-- ----------------------------------------------------------------------------
-- periphcfg instance
-- ----------------------------------------------------------------------------    
   inst6_periphcfg : entity work.periphcfg
   port map(
      -- Address and location of this module
      -- Will be hard wired at the top level
      maddress    => std_logic_vector(to_unsigned(PERIPHCFG_START_ADDR/32,10)),
      mimo_en     => '1',   
      -- Serial port IOs
      sdin        => sdin,
      sclk        => sclk,
      sen         => sen,
      sdout       => inst6_sdout,  
      -- Signals coming from the pins or top level serial interface
      lreset      => lreset,   -- Logic reset signal, resets logic cells only  (use only one reset)
      mreset      => mreset,   -- Memory reset signal, resets configuration memory only (use only one reset)      
      oen         => open,
      stateo      => open,    
      to_periphcfg   => to_periphcfg,
      from_periphcfg => from_periphcfg
   );
   
-- ----------------------------------------------------------------------------
-- cdcmcfg1 instance
-- ----------------------------------------------------------------------------    
   inst7_cdcmcfg1 : entity work.cdcmcfg
   generic map(
    CDCM_REG_0_DEFAULT  => x"01b1",
    CDCM_REG_1_DEFAULT  => x"0000",
    CDCM_REG_2_DEFAULT  => x"0018",
    CDCM_REG_3_DEFAULT  => x"00f0",
    CDCM_REG_4_DEFAULT  => x"20ff",
    CDCM_REG_5_DEFAULT  => x"0023",
    CDCM_REG_6_DEFAULT  => x"0018",
    CDCM_REG_7_DEFAULT  => x"0023",
    CDCM_REG_8_DEFAULT  => x"0018",
    CDCM_REG_9_DEFAULT  => x"0003",
    CDCM_REG_10_DEFAULT => x"0180",
    CDCM_REG_11_DEFAULT => x"0000",
    CDCM_REG_12_DEFAULT => x"0003",
    CDCM_REG_13_DEFAULT => x"0180",
    CDCM_REG_14_DEFAULT => x"0000",
    CDCM_REG_15_DEFAULT => x"0003",
    CDCM_REG_16_DEFAULT => x"0180",
    CDCM_REG_17_DEFAULT => x"0000",
    CDCM_REG_18_DEFAULT => x"0003",
    CDCM_REG_19_DEFAULT => x"0180",
    CDCM_REG_20_DEFAULT => x"0000"
   )
   port map(
      -- Address and location of this module
      -- Will be hard wired at the top level
      maddress    => std_logic_vector(to_unsigned(CDCMCFG_START_ADDR/32,10)),
      mimo_en     => '1',   
      -- Serial port IOs
      sdin        => sdin,
      sclk        => sclk,
      sen         => sen,
      sdout       => inst7_sdout,  
      -- Signals coming from the pins or top level serial interface
      lreset      => lreset,   -- Logic reset signal, resets logic cells only  (use only one reset)
      mreset      => mreset,   -- Memory reset signal, resets configuration memory only (use only one reset)      
      oen         => open,
      stateo      => open,
--      to_cdcmcfg   => to_cdcmcfg1,
      from_cdcmcfg => from_cdcmcfg
   );
   
-- ----------------------------------------------------------------------------
-- tamercfg instance
-- ----------------------------------------------------------------------------    
--  inst7_tamercfg : entity work.tamercfg
--  port map(
--     -- Address and location of this module
--     -- Will be hard wired at the top level
--     maddress    => std_logic_vector(to_unsigned(TAMERCFG_START_ADDR/32,10)),
--     mimo_en     => '1',   
--     -- Serial port IOs
--     sdin        => sdin,
--     sclk        => sclk,
--     sen         => sen,
--     sdout       => inst7_sdout,  
--     -- Signals coming from the pins or top level serial interface
--     lreset      => lreset,   -- Logic reset signal, resets logic cells only  (use only one reset)
--     mreset      => mreset,   -- Memory reset signal, resets configuration memory only (use only one reset)      
--     oen         => open,
--     stateo      => open,    
--     to_tamercfg    => to_tamercfg,
--     from_tamercfg  => from_tamercfg
--  );
   
-- ----------------------------------------------------------------------------
-- gnsscfg instance
-- ----------------------------------------------------------------------------    
--   inst8_gnsscfg : entity work.gnsscfg
--   port map(
--      -- Address and location of this module
--      -- Will be hard wired at the top level
--      maddress    => std_logic_vector(to_unsigned(GNSSCFG_START_ADDR/32,10)),
--      mimo_en     => '1',   
--      -- Serial port IOs
--      sdin        => sdin,
--      sclk        => sclk,
--      sen         => sen,
--      sdout       => inst8_sdout,  
--      -- Signals coming from the pins or top level serial interface
--      lreset      => lreset,   -- Logic reset signal, resets logic cells only  (use only one reset)
--      mreset      => mreset,   -- Memory reset signal, resets configuration memory only (use only one reset)      
--      oen         => open,
--      stateo      => open,    
--      to_gnsscfg     => to_gnsscfg,
--      from_gnsscfg   => from_gnsscfg
--   );
   
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

-----  B.J. 
-- ----------------------------------------------------------------------------
-- rxtspcfg instance
-- ---------------------------------------------------------------------------- 
inst9_sen <= sen when inst255_from_memcfg.mac(0)='1' else '1';
   
inst9_rxtspcfg : entity work.rxtspcfg
port map(
   -- Address and location of this module
   -- Will be hard wired at the top level
   maddress             => std_logic_vector(to_unsigned(RXTSPCFG_START_ADDR_3/32,10)),
   mimo_en              => '1',   
   -- Serial port IOs
   sdin                 => sdin,
   sclk                 => sclk,
   sen                  => inst9_sen,
   sdout                => inst9_sdout,  
   -- Signals coming from the pins or top level serial interface
   lreset               => lreset,   -- Logic reset signal, resets logic cells only  (use only one reset)
   mreset               => mreset,   -- Memory reset signal, resets configuration memory only (use only one reset)      
   oen                  => open,
   stateo               => open,    
   to_rxtspcfg          => to_rxtspcfg_3a,
   from_rxtspcfg        => from_rxtspcfg_3a
);

-- ----------------------------------------------------------------------------
-- rxtspcfg instance
-- ---------------------------------------------------------------------------- 
inst10_sen <= sen when inst255_from_memcfg.mac(1)='1' else '1';
   
inst10_rxtspcfg : entity work.rxtspcfg
port map(
   -- Address and location of this module
   -- Will be hard wired at the top level
   maddress             => std_logic_vector(to_unsigned(RXTSPCFG_START_ADDR_3/32,10)),
   mimo_en              => '1',   
   -- Serial port IOs
   sdin                 => sdin,
   sclk                 => sclk,
   sen                  => inst10_sen,
   sdout                => inst10_sdout,  
   -- Signals coming from the pins or top level serial interface
   lreset               => lreset,   -- Logic reset signal, resets logic cells only  (use only one reset)
   mreset               => mreset,   -- Memory reset signal, resets configuration memory only (use only one reset)      
   oen                  => open,
   stateo               => open,    
   to_rxtspcfg          => to_rxtspcfg_3b,
   from_rxtspcfg        => from_rxtspcfg_3b
);
----- end B.J.

----------------------------------------------------------------
--- B.J.
inst11_sen_a <= sen when inst255_from_memcfg.mac(0)='1' else '1';    
inst11_fircfg_a : entity work.fircfg
   port map(
      -- Address and location of this module
      -- Will be hard wired at the top level
      maddress       => std_logic_vector(to_unsigned(FIRCFG_TX/32,10)),
      mimo_en        => '1', -- MIMO enable, from TOP SPI
   
      -- Serial port IOs
      sdin           => sdin, -- Data in
      sclk           => sclk, -- Data clock
      sen            => inst11_sen_a,  -- Enable signal (active low)
      sdout          => inst11_sdout_a,   -- Data out
      -- Signals coming from the pins or top level serial interface
      lreset         => lreset, -- Logic reset signal, resets logic cells only
      mreset         => mreset, -- Memory reset signal, resets configuration memory only    
      oen            => open,
      stateo         => open,      
      from_fircfg  => from_fircfg_tx_a -- B.J.
);

inst11_sen_b <= sen when inst255_from_memcfg.mac(1)='1' else '1';
inst11_fircfg_b : entity work.fircfg
   port map(
      -- Address and location of this module
      -- Will be hard wired at the top level
      maddress       => std_logic_vector(to_unsigned(FIRCFG_TX/32,10)),
      mimo_en        => '1', -- MIMO enable, from TOP SPI
   
      -- Serial port IOs
      sdin           => sdin, -- Data in
      sclk           => sclk, -- Data clock
      sen            => inst11_sen_b,  -- Enable signal (active low)
      sdout          => inst11_sdout_b,   -- Data out
      -- Signals coming from the pins or top level serial interface
      lreset         => lreset, -- Logic reset signal, resets logic cells only
      mreset         => mreset, -- Memory reset signal, resets configuration memory only    
      oen            => open,
      stateo         => open,      
      from_fircfg  => from_fircfg_tx_b -- B.J.
   );
----- end B.J.
----------------------------------------------------------------
--- B.J.
inst12_sen_a <= sen when inst255_from_memcfg.mac(0)='1' else '1';    
inst12_fircfg_a : entity work.fircfg
   port map(
      -- Address and location of this module
      -- Will be hard wired at the top level
      maddress       => std_logic_vector(to_unsigned(FIRCFG_RX/32,10)),
      mimo_en        => '1', -- MIMO enable, from TOP SPI
   
      -- Serial port IOs
      sdin           => sdin, -- Data in
      sclk           => sclk, -- Data clock
      sen            => inst12_sen_a,  -- Enable signal (active low)
      sdout          => inst12_sdout_a,   -- Data out
      -- Signals coming from the pins or top level serial interface
      lreset         => lreset, -- Logic reset signal, resets logic cells only
      mreset         => mreset, -- Memory reset signal, resets configuration memory only    
      oen            => open,
      stateo         => open,      
      from_fircfg  => from_fircfg_rx_a -- B.J.
);

inst12_sen_b <= sen when inst255_from_memcfg.mac(1)='1' else '1';
inst12_fircfg_b : entity work.fircfg
   port map(
      -- Address and location of this module
      -- Will be hard wired at the top level
      maddress       => std_logic_vector(to_unsigned(FIRCFG_RX/32,10)),
      mimo_en        => '1', -- MIMO enable, from TOP SPI
   
      -- Serial port IOs
      sdin           => sdin, -- Data in
      sclk           => sclk, -- Data clock
      sen            => inst12_sen_b,  -- Enable signal (active low)
      sdout          => inst12_sdout_b,   -- Data out
      -- Signals coming from the pins or top level serial interface
      lreset         => lreset, -- Logic reset signal, resets logic cells only
      mreset         => mreset, -- Memory reset signal, resets configuration memory only    
      oen            => open,
      stateo         => open,      
      from_fircfg  => from_fircfg_rx_b -- B.J.
   );   
----- end B.J.

-- ----------------------------------------------------------------------------
-- Output ports
-- ----------------------------------------------------------------------------    
   sdout <= inst0_0_sdout OR inst0_1_sdout OR inst0_2_sdout OR inst1_sdoutA OR 
            inst3_sdout OR inst4_0_sdout OR inst4_1_sdout OR inst5_sdout OR inst5_sdout_b OR
            inst6_sdout OR inst7_sdout OR inst255_sdout OR
            inst9_sdout OR inst10_sdout OR  -- B.J.
            inst11_sdout_a OR inst11_sdout_b OR inst12_sdout_a OR inst12_sdout_b; -- B.J.
            
            
      inst255_to_memcfg <= to_memcfg;
      from_memcfg       <= inst255_from_memcfg;
  
end arch;   


