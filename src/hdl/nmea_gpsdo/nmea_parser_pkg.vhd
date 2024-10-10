-- ----------------------------------------------------------------------------
-- FILE:          nmea_parser_pkg.vhd
-- DESCRIPTION:   parser constants and functions for nmea_parser
-- DATE:          11:07 AM Tuesday, February 27, 2018
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
package nmea_parser_pkg is
   
   --Converts string to std_logic_vector
   function str_to_slv(s: string) 
      return std_logic_vector;
      
   --Converts std_logic_vector in string representation 
   function hex_to_slv(h: std_logic_vector)
      return std_logic_vector;

   -- Function to convert 8 ASCII hex characters to a 32-bit std_logic_vector
   function ascii_hex_to_std_logic_vector(ascii_hex : in std_logic_vector(8*8-1 downto 0)) 
      return std_logic_vector;

   function str_to_decimal_slv(input_str : std_logic_vector) 
      return std_logic_vector;
      
   -- Constants
   constant C_dollar       : std_logic_vector(7 downto 0);  -- Sentence start delimiter
   constant C_comma        : std_logic_vector(7 downto 0);  -- Comma, data field separator
   constant C_asterisk     : std_logic_vector(7 downto 0);  -- Asterisk, Checksum separator
   constant C_GP           : std_logic_vector(15 downto 0); -- Talker ID = GPS
   constant C_GN           : std_logic_vector(15 downto 0); -- Talker ID = Multi-GNSS
   
   constant C_GSA          : std_logic_vector(23 downto 0); -- Sentence ID = GNSS DOP and Active Satellites
   
   constant C_GAGSA        : std_logic_vector(39 downto 0);
   constant C_GBGSA        : std_logic_vector(39 downto 0);
   constant C_GLGSA        : std_logic_vector(39 downto 0);
   constant C_GNGSA        : std_logic_vector(39 downto 0);
   constant C_GPGSA        : std_logic_vector(39 downto 0);
   constant C_GNGGA        : std_logic_vector(39 downto 0);
   constant C_GNRMC        : std_logic_vector(39 downto 0);
   
   
   constant talker_id_len  : integer := 2;
   constant sentence_id_len: integer := 3;
   constant checksum_len   : integer := 2;
   
   -- sentence data field numbers starts from 1
   constant gsa_fix_d    : integer := 2; 
   constant gga_utc_d    : integer := 1;
   --RMC Recommended Minimum Specific GNSS Data field numbers
   constant rmc_utc_d      : integer := 1;
   constant rmc_stat_d     : integer := 2;
   constant rmc_lat_d0     : integer := 3;
   constant rmc_lat_d1     : integer := 4;
   constant rmc_long_d0    : integer := 5;
   constant rmc_long_d1    : integer := 6;
   constant rmc_speed_d    : integer := 7;
   constant rmc_course_d   : integer := 8;
   constant rmc_date_d     : integer := 9;
   constant rmc_mag_var_d0 : integer := 10;
   constant rmc_mag_var_d1 : integer := 11;
   constant rmc_mag_var_d2 : integer := 12;
   
   constant rmc_utc_max_char      : integer := 10;
   constant rmc_stat_max_char     : integer := 1;
   constant rmc_lat_max_char      : integer := 11;
   constant rmc_long_max_char     : integer := 12;
   constant rmc_speed_max_char    : integer := 7;
   constant rmc_course_max_char   : integer := 6;
   constant rmc_date_max_char     : integer := 6;
   constant rmc_mag_var_max_char  : integer := 2;

   constant iiena_en_d0 : integer := 1;

   constant iirst_cntrst_d0 : integer := 1;

   constant iiirq_en_d0    : integer := 1;
   constant iiirq_rst_d1   : integer := 2;

   constant iicfg_1s_target_d0   : integer :=1;
   constant iicfg_1s_tol_d1      : integer :=2;
   constant iicfg_10s_target_d2  : integer :=3;
   constant iicfg_10s_tol_d3     : integer :=4;
   constant iicfg_100s_target_d4 : integer :=5;
   constant iicfg_100s_tol_d5    : integer :=6;

   constant iicfg_1s_target_max_char   : integer:=8;
   constant iicfg_1s_tol_max_char      : integer:=4;
   constant iicfg_10s_target_max_char  : integer:=8;
   constant iicfg_10s_tol_max_char     : integer:=4;
   constant iicfg_100s_target_max_char : integer:=8;
   constant iicfg_100s_tol_max_char    : integer:=4;

   
   --types
   type talker_id_t is array (0 to 1) of std_logic_vector(7 downto 0);
   type sentence_id_t is array (0 to 2) of std_logic_vector(7 downto 0);
   
   
end  nmea_parser_pkg;

-- ----------------------------------------------------------------------------
-- Package body
-- ----------------------------------------------------------------------------
package body nmea_parser_pkg is

-- ----------------------------------------------------------------------------
-- Convert string to std_logic_vector
-- ----------------------------------------------------------------------------
function str_to_slv(s: string) return std_logic_vector is 
   constant ss: string(1 to s'length) := s; 
   variable answer: std_logic_vector(1 to 8 * s'length); 
   variable p: integer; 
   variable c: integer; 
begin 
   for i in ss'range loop
      p := 8 * i;
      c := character'pos(ss(i));
      answer(p - 7 to p) := std_logic_vector(to_unsigned(c,8)); 
   end loop; 
   return answer;
end function;

function hex_to_slv(h : std_logic_vector) return std_logic_vector is
   constant hh : std_logic_vector(7 downto 0) := h;
begin 
   case hh is 
      when x"30" => 
         return x"0";
      when x"31" => 
         return x"1";
      when x"32" => 
         return x"2";
      when x"33" => 
         return x"3";         
      when x"34" => 
         return x"4";
      when x"35" => 
         return x"5";
      when x"36" => 
         return x"6";
      when x"37" => 
         return x"7";
      when x"38" => 
         return x"8";
      when x"39" => 
         return x"9";
      when x"41" | x"61" => 
         return x"A";
      when x"42" | x"62"=> 
         return x"B";
      when x"43" | x"63"=> 
         return x"C";             
      when x"44" | x"64"=> 
         return x"D";
      when x"45" | x"65"=> 
         return x"E"; 
      when x"46" | x"66"=> 
         return x"F";
      when others=> 
         return x"0";
   end case;
end function;

-- Function to convert 8 ASCII hex characters to a 32-bit std_logic_vector
function ascii_hex_to_std_logic_vector(ascii_hex : in std_logic_vector(8*8-1 downto 0)) return std_logic_vector is
   variable result : std_logic_vector(31 downto 0);
begin
   result(31 downto 28) := hex_to_slv(ascii_hex(63 downto 56));  -- Most significant ASCII character
   result(27 downto 24) := hex_to_slv(ascii_hex(55 downto 48));
   result(23 downto 20) := hex_to_slv(ascii_hex(47 downto 40));
   result(19 downto 16) := hex_to_slv(ascii_hex(39 downto 32));
   result(15 downto 12) := hex_to_slv(ascii_hex(31 downto 24));
   result(11 downto 8)  := hex_to_slv(ascii_hex(23 downto 16));
   result(7 downto 4)   := hex_to_slv(ascii_hex(15 downto 8));
   result(3 downto 0)   := hex_to_slv(ascii_hex(7 downto 0));    -- Least significant ASCII character
   return result;
end function;

-- Function to convert a std_logic_vector containing ASCII characters representing a decimal number 
-- into a 32-bit std_logic_vector representing the binary value of the decimal number
function str_to_decimal_slv(input_str : std_logic_vector) return std_logic_vector is
   variable result : unsigned(31 downto 0) := (others => '0');  -- 32-bit result initialized to 0
   variable temp_digit : integer;
   constant ASCII_ZERO : integer := character'pos('0');  -- ASCII value of '0'
   variable dec_value : unsigned(31 downto 0) := (others => '0');  -- Variable to accumulate the decimal value
   variable len : integer := input_str'length / 8;  -- Length of input string in characters
begin
   -- Iterate over the input string in chunks of 8 bits (1 byte) representing ASCII characters
   for i in 0 to len - 1 loop
       -- Convert the ASCII character at position i into its decimal digit (starting from most significant character)
       temp_digit := to_integer(unsigned(input_str((len - 1 - i) * 8 + 7 downto (len - 1 - i) * 8)));  -- Extract 8-bit ASCII value

       -- Subtract ASCII '0' to get the actual integer value of the digit
       temp_digit := temp_digit - ASCII_ZERO;

       -- Check if the character was indeed a valid digit (0-9)
       if temp_digit >= 0 and temp_digit <= 9 then
           -- Multiply the current result by 10 (decimal shift) and add the new digit
           dec_value := resize(dec_value * 10, 32) + to_unsigned(temp_digit, 32);
       end if;
   end loop;

   -- Return the result as a std_logic_vector
   result := dec_value;
   return std_logic_vector(result);
end function;


-- ----------------------------------------------------------------------------
-- Deferred constants
-- ----------------------------------------------------------------------------
constant C_dollar    : std_logic_vector(7 downto 0) := str_to_slv("$");
constant C_comma     : std_logic_vector(7 downto 0) := str_to_slv(",");
constant C_asterisk  : std_logic_vector(7 downto 0) := str_to_slv("*");


constant C_GP        : std_logic_vector(15 downto 0) := str_to_slv("GP");
constant C_GN        : std_logic_vector(15 downto 0) := str_to_slv("GN");

constant C_GSA       : std_logic_vector(23 downto 0) := str_to_slv("GSA");

constant C_GAGSA     : std_logic_vector(39 downto 0) := str_to_slv("GAGSA");
constant C_GBGSA     : std_logic_vector(39 downto 0) := str_to_slv("GBGSA");
constant C_GLGSA     : std_logic_vector(39 downto 0) := str_to_slv("GLGSA");
constant C_GNGSA     : std_logic_vector(39 downto 0) := str_to_slv("GNGSA");
constant C_GPGSA     : std_logic_vector(39 downto 0) := str_to_slv("GPGSA");
constant C_GNGGA     : std_logic_vector(39 downto 0) := str_to_slv("GNGGA");
constant C_GNRMC     : std_logic_vector(39 downto 0) := str_to_slv("GNRMC");
   
   
end nmea_parser_pkg;
      
      