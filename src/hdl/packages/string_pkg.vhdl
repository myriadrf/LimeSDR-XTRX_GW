-- ----------------------------------------------------------------------------
-- FILE:          string_pkg.vhd
-- DESCRIPTION:   Functions for string manipulation
-- DATE:          11:07 AM Thursday, September 26, 2024
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
package string_pkg is

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

-- Function to convert a signed 32-bit binary number to its decimal string representation.
function bin_to_dec(input_bin: std_logic_vector(31 downto 0)) 
   return std_logic_vector;

-- Function to convert std_logic_vector in HEX representation to 
-- String characters in std_logic_vector
function slv_to_char(h : std_logic_vector) 
   return std_logic_vector;

-- Function to convert std_logic_vector in HEX representation to 
-- String characters in std_logic_vector
function conv_slv_to_char( d : std_logic_vector)
   return std_logic_vector;

end  string_pkg;

-- ----------------------------------------------------------------------------
-- Package body
-- ----------------------------------------------------------------------------
package body string_pkg is

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

-- Function to convert a signed 32-bit binary number to its decimal string representation.
function bin_to_dec(input_bin: std_logic_vector(31 downto 0)) return std_logic_vector is
   -- Internal variables
   variable temp_bin : signed(31 downto 0);   -- signed version of the input binary
   variable is_negative : boolean := false;   -- flag for negative numbers
   variable abs_value : integer;              -- absolute integer value
   variable decimal_str : string(1 to 10);    -- string to store the decimal number
   variable result_vector : std_logic_vector(79 downto 0); -- 10 characters, 8 bits each
   constant zero_char : character := '0';     -- ASCII '0'
   constant max_length : integer := 10;       -- maximum length of the decimal string

begin
   -- Convert the input std_logic_vector to a signed type
   temp_bin := signed(input_bin);

   -- Check if the number is negative
   if temp_bin < 0 then
       is_negative := true;
       abs_value := abs(to_integer(temp_bin)); -- Get the absolute value of the signed integer
   else
       abs_value := to_integer(temp_bin);      -- Convert to integer
   end if;

   -- Initialize decimal string to zeros
   decimal_str := (others => zero_char);

   -- Convert the absolute value to decimal characters
   for i in 1 to max_length loop
       decimal_str(max_length - i + 1) := character'val(abs_value mod 10 + character'pos(zero_char));
       abs_value := abs_value / 10;
       if abs_value = 0 then
           exit;
       end if;
   end loop;

   -- If the number was negative, add '-' to the start of the string
   if is_negative then
       decimal_str(1) := '-';
   end if;

   -- Convert the string to a std_logic_vector (ASCII encoding)
   for i in 1 to max_length loop
       result_vector((i * 8) - 1 downto (i - 1) * 8) := std_logic_vector(to_unsigned(character'pos(decimal_str(max_length - i + 1 )), 8));
   end loop;

   -- Return the final 32-character std_logic_vector
   return result_vector(max_length*8-1 downto 0);  -- Adjust the slice to return a 32-bit vector
end function;


-- Function to convert std_logic_vector in HEX representation to 
-- String characters in std_logic_vector
function slv_to_char(h : std_logic_vector) return std_logic_vector is
   constant  hh : std_logic_vector(3 downto 0) := h;
begin 
   case hh is 
      when x"0" => 
         return x"30";
      when x"1" => 
         return x"31";
      when x"2" => 
         return x"32";
      when x"3" => 
         return x"33";         
      when x"4" => 
         return x"34";
      when x"5" => 
         return x"35";
      when x"6" => 
         return x"36";
      when x"7" => 
         return x"37";
      when x"8" => 
         return x"38";
      when x"9" => 
         return x"39";
      when x"A" => 
         return x"41";
      when x"B" => 
         return x"42";
      when x"C" => 
         return x"43";             
      when x"D" => 
         return x"44";
      when x"E" => 
         return x"45"; 
      when x"F" => 
         return x"46";
      when others=> 
         return x"00";
   end case;
end function;

-- Function to convert std_logic_vector in HEX representation to 
-- String characters in std_logic_vector
function conv_slv_to_char( d : std_logic_vector)
   return std_logic_vector is 
   variable tmp : std_logic_vector(2*d'length-1 downto 0); 
begin 
   for i in 0 to d'length/4-1 loop
      tmp(i*8+7 downto i*8) := slv_to_char(d(i*4+3 downto i*4));
   end loop;
   
   return std_logic_vector(tmp);
   
end function;
   
   
end string_pkg;
      
      