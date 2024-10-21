-- ----------------------------------------------------------------------------
-- FILE:          vctcxo_tamer_log.vhd
-- DESCRIPTION:   VCTCXO tamer data logger with uart module interface
-- DATE:          2:47 PM Wednesday, March 21, 2018
-- AUTHOR(s):     Lime Microsystems
-- REVISIONS:
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
--NOTES:
-- ----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.string_pkg.all;

-- ----------------------------------------------------------------------------
-- Entity declaration
-- ----------------------------------------------------------------------------
entity vctcxo_tamer_log is
   port (
      clk                  : in  std_logic;
      reset_n              : in  std_logic;
         
      irq                  : in  std_logic;
      --Data to log 
      pps_1s_error_v       : in  std_logic; 
      pps_1s_error         : in  std_logic_vector(31 downto 0);
      pps_10s_error_v      : in  std_logic; 
      pps_10s_error        : in  std_logic_vector(31 downto 0);
      pps_100s_error_v     : in  std_logic; 
      pps_100s_error       : in  std_logic_vector(31 downto 0);

      pps_100s_count_v     : in  std_logic;
      
      --To uart module
      uart_data_in         : out std_logic_vector(7 downto 0);
      uart_data_in_stb     : out std_logic;
      uart_data_in_ack     : in  std_logic
      
      );
end vctcxo_tamer_log;

-- ----------------------------------------------------------------------------
-- Architecture
-- ----------------------------------------------------------------------------
architecture arch of vctcxo_tamer_log is
--declare signals,  components here
constant c_comma           : std_logic_vector(7 downto 0) := x"2C";
constant c_CR              : std_logic_vector(7 downto 0) := x"0D";
constant c_LF              : std_logic_vector(7 downto 0) := x"0A";
constant c_message_bytes         : integer := 38;
constant c_NMEA_START_CHAR_POS   : integer := 38;
constant c_NMEA_START_CHAR_LENGT : integer := 1;
constant c_crc_pos               : integer := 33;

signal shift_en      : std_logic;
signal ack_cnt       : unsigned(7 downto 0);

signal data_reg                  : std_logic_vector(c_message_bytes*8-1 downto 0);
signal iista_message_reg         : std_logic_vector(c_message_bytes*8-1 downto 0);
alias  a_IISTA_START             : std_logic_vector( 7 downto 0) is iista_message_reg(303 downto 296);
alias  a_IISTA_TID_SID           : std_logic_vector(39 downto 0) is iista_message_reg(295 downto 256);
alias  a_IISTA_D0_SEP            : std_logic_vector( 7 downto 0) is iista_message_reg(255 downto 248);
alias  a_IISTA_D0                : std_logic_vector(63 downto 0) is iista_message_reg(247 downto 184);
alias  a_IISTA_D1_SEP            : std_logic_vector( 7 downto 0) is iista_message_reg(183 downto 176);
alias  a_IISTA_D1                : std_logic_vector(63 downto 0) is iista_message_reg(175 downto 112);
alias  a_IISTA_D2_SEP            : std_logic_vector( 7 downto 0) is iista_message_reg(111 downto 104);
alias  a_IISTA_D2                : std_logic_vector(63 downto 0) is iista_message_reg(103 downto  40);
alias  a_IISTA_CRC_SEP           : std_logic_vector( 7 downto 0) is iista_message_reg( 39 downto  32);
alias  a_IISTA_CRC               : std_logic_vector(15 downto 0) is iista_message_reg( 31 downto  16);
alias  a_IISTA_END               : std_logic_vector(15 downto 0) is iista_message_reg( 15 downto   0);
signal data_reg_leftmost_byte    : std_logic_vector(7 downto 0);

type state_type is (idle, capture_message, calc_crc, set_stb, stb_ack);
signal current_state, next_state : state_type;

signal irq_reg    : std_logic;

signal crc_cnt    : unsigned(7 downto 0);
signal crc        : std_logic_vector(7 downto 0);

constant zero_32b_vector : std_logic_vector(31 downto 0) :=x"00000000";

signal pps_100s_count_v_reg : std_logic;

begin

-- Input register for irq
process (clk, reset_n)
begin
   if reset_n = '0' then
      irq_reg <= '0'; 
      pps_100s_count_v_reg <= '0';
   elsif rising_edge(clk) then
      irq_reg <= irq;  
      pps_100s_count_v_reg <= pps_100s_count_v;   
   end if;
end process;

process(clk)
begin
   if (clk'event and clk = '1') then
      if irq = '1' AND irq_reg = '0' then 
         a_IISTA_START     <= str_to_slv("$");
         a_IISTA_TID_SID   <= str_to_slv("IIERR");
         a_IISTA_D0_SEP    <= str_to_slv(",");     
         a_IISTA_D1_SEP    <= str_to_slv(",");
         a_IISTA_D2_SEP    <= str_to_slv(",");    
         a_IISTA_CRC_SEP   <= str_to_slv("*");
         a_IISTA_CRC       <= str_to_slv("00");
         a_IISTA_END       <= c_CR & c_LF;
      elsif pps_100s_count_v = '1' AND pps_100s_count_v_reg = '0' AND current_state = idle then 
         a_IISTA_START     <= str_to_slv("$");
         a_IISTA_TID_SID   <= str_to_slv("IISTA");
         a_IISTA_D0_SEP    <= str_to_slv(",");     
         a_IISTA_D1_SEP    <= str_to_slv(",");
         a_IISTA_D2_SEP    <= str_to_slv(",");    
         a_IISTA_CRC_SEP   <= str_to_slv("*");
         a_IISTA_CRC       <= str_to_slv("00");
         a_IISTA_END       <= c_CR & c_LF;
      end if;
   end if;
end process;

process(clk)
begin
   if (clk'event and clk = '1') then
      if irq = '1' AND irq_reg = '0' AND pps_1s_error_v = '0'  then 
         a_IISTA_D0 <= conv_slv_to_char(zero_32b_vector);
      elsif (irq = '1' AND irq_reg = '0' AND pps_1s_error_v = '1') OR (pps_100s_count_v = '1' AND pps_100s_count_v_reg = '0' AND current_state = idle) then
         a_IISTA_D0 <= conv_slv_to_char(pps_1s_error);
      end if;
   end if;
end process;

process(clk)
begin
   if (clk'event and clk = '1') then
      if irq = '1' AND irq_reg = '0' AND (pps_1s_error_v = '1' OR pps_10s_error_v = '0')  then 
         a_IISTA_D1 <= conv_slv_to_char(zero_32b_vector);
      elsif (irq = '1' AND irq_reg = '0' AND pps_10s_error_v = '1') OR (pps_100s_count_v = '1' AND pps_100s_count_v_reg = '0' AND current_state = idle) then
         a_IISTA_D1 <= conv_slv_to_char(pps_10s_error);
      end if;
   end if;
end process;

process(clk)
begin
   if (clk'event and clk = '1') then
      if irq = '1' AND irq_reg = '0' AND (pps_1s_error_v = '1' OR pps_10s_error_v = '1' OR pps_100s_error_v = '0')  then 
         a_IISTA_D2 <= conv_slv_to_char(zero_32b_vector);
      elsif (irq = '1' AND irq_reg = '0' AND pps_100s_error_v = '1') OR (pps_100s_count_v = '1' AND pps_100s_count_v_reg = '0' AND current_state = idle) then
         a_IISTA_D2 <= conv_slv_to_char(pps_100s_error);
      end if;
   end if;
end process;

--Capture all characters to one array on rising edge of irq
process(reset_n, clk)
   begin
   if reset_n='0' then
      data_reg<=(others=>'0');  
   elsif (clk'event and clk = '1') then
      if current_state = capture_message then 
         data_reg <= iista_message_reg;   
      elsif shift_en = '1' then
         if ack_cnt = c_crc_pos then
            -- Adding calculated CRC and CR LF characters
            data_reg(data_reg'left downto data_reg'left - 31) <= conv_slv_to_char(crc) & c_CR & c_LF;
         else  
            data_reg <= data_reg(data_reg'left-8 downto 0) & x"00"; 
         end if;
      else 
         data_reg <= data_reg;
      end if;
   end if;
end process;

data_reg_leftmost_byte <= data_reg(data_reg'left downto data_reg'left - 7);


--Calculate CRC
process(clk, reset_n)
begin
   if reset_n = '0' then 
      crc      <= (others => '0');
   elsif (clk'event AND clk='1') then 
      if current_state = idle then 
         crc <= (others => '0');
      -- Start $ charackter is not included into CRC. CRC is being calculated until CRC character position 
      elsif current_state=stb_ack AND data_reg_leftmost_byte /= x"24" AND ack_cnt < c_crc_pos then 
         crc <= crc XOR data_reg_leftmost_byte;
      else 
         crc <= crc;
      end if;

   end if;
end process;


--Count ack signal from UART
process(clk, reset_n)
begin
   if reset_n = '0' then 
      ack_cnt <= (others => '0');
   elsif (clk'event AND clk='1') then 
      if current_state = stb_ack then 
         ack_cnt <= ack_cnt + 1;
      elsif current_state = idle then 
         ack_cnt <= (others => '0');
      else 
         ack_cnt <= ack_cnt;
      end if;
   end if;
end process;


-- ----------------------------------------------------------------------------
-- state machine
-- ----------------------------------------------------------------------------
fsm_f : process(clk, reset_n)begin
	if(reset_n = '0')then
		current_state <= idle;
	elsif(clk'event and clk = '1')then 
		current_state <= next_state;
	end if;	
end process;

-- ----------------------------------------------------------------------------
-- state machine combo
-- ----------------------------------------------------------------------------
fsm : process(all) begin
	next_state <= current_state;
	case current_state is
	  
		when idle =>         -- idle state waiting for capture enable
         if (irq='1' AND irq_reg = '0') OR (pps_100s_count_v = '1' AND pps_100s_count_v_reg = '0') then 
            next_state <= capture_message;
         else 
            next_state <= idle;
         end if;
      
      when capture_message => 
         next_state <= set_stb;
         
      when set_stb =>      -- send one character
         if uart_data_in_ack = '1' then 
            next_state <= stb_ack;
         else 
            next_state <= set_stb;
         end if;
         
      when stb_ack =>      -- check if this is last character
         if ack_cnt < c_message_bytes - 1 then 
            next_state <= set_stb;
         else 
            next_state <= idle;
         end if;

		when others => 
			next_state <= idle;
	end case;
end process;


--Generate UART stb signal
process(clk, reset_n)
begin
   if reset_n = '0' then 
      uart_data_in_stb <= '0';
   elsif (clk'event AND clk='1') then 
      --if current_state = set_stb AND uart_data_in_ack= '0' then 
      if current_state = set_stb then
         uart_data_in_stb <= '1';
      else 
         uart_data_in_stb <= '0';
      end if;
   end if;
end process;

-- Enable signal for data_reg shift register
shift_en <= '1' when current_state = stb_ack else '0';

-- ----------------------------------------------------------------------------
-- Output ports
-- ----------------------------------------------------------------------------
uart_data_in <= data_reg(data_reg'left downto data_reg'left - 7);


end arch;   


