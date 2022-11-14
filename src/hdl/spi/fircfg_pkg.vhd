-- ----------------------------------------------------------------------------
-- FILE:          fircfg_pkg.vhd
-- DESCRIPTION:   Package for fircfg module
-- DATE:          2020/05/19
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
PACKAGE fircfg_pkg IS

   -- Outputs from the 
   TYPE t_FROM_FIRCFG IS RECORD

      -- I coefficients
      H0 : STD_LOGIC_VECTOR(17 DOWNTO 0);
      H1 : STD_LOGIC_VECTOR(17 DOWNTO 0);
      H2 : STD_LOGIC_VECTOR(17 DOWNTO 0);
      H3 : STD_LOGIC_VECTOR(17 DOWNTO 0);
      H4 : STD_LOGIC_VECTOR(17 DOWNTO 0);
      H5 : STD_LOGIC_VECTOR(17 DOWNTO 0);
      H6 : STD_LOGIC_VECTOR(17 DOWNTO 0);
      H7 : STD_LOGIC_VECTOR(17 DOWNTO 0);
      H8 : STD_LOGIC_VECTOR(17 DOWNTO 0);
      H9 : STD_LOGIC_VECTOR(17 DOWNTO 0);
      HA : STD_LOGIC_VECTOR(17 DOWNTO 0);
      HB : STD_LOGIC_VECTOR(17 DOWNTO 0);
      HC : STD_LOGIC_VECTOR(17 DOWNTO 0);
      HD : STD_LOGIC_VECTOR(17 DOWNTO 0);
      HE : STD_LOGIC_VECTOR(17 DOWNTO 0);
      HF : STD_LOGIC_VECTOR(17 DOWNTO 0);

      --Q coefficients	
      H10 : STD_LOGIC_VECTOR(17 DOWNTO 0);
      H11 : STD_LOGIC_VECTOR(17 DOWNTO 0);
      H12 : STD_LOGIC_VECTOR(17 DOWNTO 0);
      H13 : STD_LOGIC_VECTOR(17 DOWNTO 0);
      H14 : STD_LOGIC_VECTOR(17 DOWNTO 0);
      H15 : STD_LOGIC_VECTOR(17 DOWNTO 0);
      H16 : STD_LOGIC_VECTOR(17 DOWNTO 0);
      H17 : STD_LOGIC_VECTOR(17 DOWNTO 0);
      H18 : STD_LOGIC_VECTOR(17 DOWNTO 0);
      H19 : STD_LOGIC_VECTOR(17 DOWNTO 0);
      H1A : STD_LOGIC_VECTOR(17 DOWNTO 0);
      H1B : STD_LOGIC_VECTOR(17 DOWNTO 0);
      H1C : STD_LOGIC_VECTOR(17 DOWNTO 0);
      H1D : STD_LOGIC_VECTOR(17 DOWNTO 0);
      H1E : STD_LOGIC_VECTOR(17 DOWNTO 0);
      H1F : STD_LOGIC_VECTOR(17 DOWNTO 0);

   END RECORD t_FROM_FIRCFG;

END PACKAGE fircfg_pkg;