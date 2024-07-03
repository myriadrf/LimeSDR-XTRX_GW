-- ----------------------------------------------------------------------------	
-- file: 	revisions_golden.vhd
-- description:	project revision constants, changed for golden image. 
-- date:	July 01, 2024
-- author(s):	lime microsystems
-- revisions:
-- ----------------------------------------------------------------------------	
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

package revisions is
	constant major_rev : integer := 57005; 
	constant minor_rev : integer := 57005;
	constant beta_rev : integer := 57005;
	constant compile_rev : integer := 57005;
	constant compile_year_stamp : integer := 24;
	constant compile_month_stamp : integer := 06;
	constant compile_day_stamp : integer := 27;
	constant compile_hour_stamp : integer := 14;
	
	constant magic_num : std_logic_vector(31 downto 0) := x"d8a5f009";
   constant board_id : std_logic_vector(15 downto 0) := 16d"27";
end revisions;

