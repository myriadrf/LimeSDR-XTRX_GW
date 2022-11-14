-- ----------------------------------------------------------------------------
-- FILE:          txtspcfg_pkg.vhd
-- DESCRIPTION:   Package for tamercfg module
-- DATE:          11:13 AM Friday, May 11, 2018
-- AUTHOR(s):     Lime Microsystems
-- REVISIONS:
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
--NOTES:
-- ----------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

-- ----------------------------------------------------------------------------
-- Package declaration
-- ----------------------------------------------------------------------------
PACKAGE txtspcfg_pkg IS

   -- Outputs from the 
   TYPE t_FROM_TXTSPCFG IS RECORD
      -- Control lines  
      en : STD_LOGIC; -- B.J.
      gcorri : STD_LOGIC_VECTOR(10 DOWNTO 0); -- B.J.
      gcorrq : STD_LOGIC_VECTOR(10 DOWNTO 0); -- B.J.
      iqcorr : STD_LOGIC_VECTOR(11 DOWNTO 0); -- B.J.
      dccorri : STD_LOGIC_VECTOR(15 DOWNTO 0); -- B.J.
      dccorrq : STD_LOGIC_VECTOR(15 DOWNTO 0); -- B.J.
      nco_fcv : STD_LOGIC_VECTOR(31 DOWNTO 0);
      cfr_threshold : STD_LOGIC_VECTOR(15 DOWNTO 0); -- B.J.
      cfr_gain : STD_LOGIC_VECTOR(15 DOWNTO 0); -- B.J.

      -- ovr         : std_logic_vector(2 downto 0);	--HBI interpolation ratio 
      -- gfir1l      : std_logic_vector(2 downto 0);    --Length of GPFIR1
      -- gfir1n      : std_logic_vector(7 downto 0);    --Clock division ratio of GPFIR1
      -- gfir2l      : std_logic_vector(2 downto 0);    --Length of GPFIR2
      -- gfir2n      : std_logic_vector(7 downto 0);    --Clock division ratio of GPFIR2
      -- gfir3l      : std_logic_vector(2 downto 0);    --Length of GPFIR3
      -- gfir3n      : std_logic_vector(7 downto 0);    --Clock division ratio of GPFIR3
      -- dc_reg      : std_logic_vector(15 downto 0);   --DC level to drive DACI
      insel : STD_LOGIC;
      --gfir1_byp   : std_logic;  -- unused
      --gfir2_byp   : std_logic;  -- unused     
      --gfir3_byp   : std_logic; -- unused 
      --cmix_sc     : std_logic; -- unused 
      hbi_byp : STD_LOGIC;
      hbi_del : STD_LOGIC; --cmix_byp

      cfr_sleep : STD_LOGIC;
      cfr_byp : STD_LOGIC;
      cfr_odd : STD_LOGIC;

      cfr_gain_byp : STD_LOGIC;

      fir_sleep : STD_LOGIC;
      fir_byp : STD_LOGIC;
      fir_odd : STD_LOGIC;

      ph_byp : STD_LOGIC;
      gc_byp : STD_LOGIC;
      dc_byp : STD_LOGIC;

      isinc_byp : STD_LOGIC;
      equaliser_byp : STD_LOGIC;      
      invertq : STD_LOGIC;

      --cmix_gain   : std_logic_vector(2 downto 0);
      bstart : STD_LOGIC; -- BIST start flag
      tsgfcw : STD_LOGIC_VECTOR(8 DOWNTO 7);
      tsgdcldq : STD_LOGIC;
      tsgdcldi : STD_LOGIC;
      tsgswapiq : STD_LOGIC;
      tsgmode : STD_LOGIC;
      tsgfc : STD_LOGIC;
   END RECORD t_FROM_TXTSPCFG;

   -- Inputs to the 
   TYPE t_TO_TXTSPCFG IS RECORD
      txen : STD_LOGIC; -- Power down all modules when txen=0
      bstate : STD_LOGIC; -- BIST state flag
      bsigi : STD_LOGIC_VECTOR(22 DOWNTO 0); -- BIST signature, channel I
      bsigq : STD_LOGIC_VECTOR(22 DOWNTO 0); -- BIST signature, channel Q
   END RECORD t_TO_TXTSPCFG;

END PACKAGE txtspcfg_pkg;