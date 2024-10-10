-- ----------------------------------------------------------------------------
-- FILE:          nmea_parser.vhd
-- DESCRIPTION:   parser for nmea messages
-- DATE:          11:07 AM Tuesday, February 27, 2018
-- AUTHOR(s):     Lime Microsystems
-- REVISIONS:
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- NOTES:
-- Talker Senctence Format:
--    $ttsss,d1,d2,...*hh<CR><LF>
-- Sentence Explanation:
--    $ - Sentence start, tt - Talker ID, sss - Sentence ID, dx - Data Fields, 
--    * - Checksum delimiter, hh - checksum
-- ----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.nmea_parser_pkg.all;

-- ----------------------------------------------------------------------------
-- Entity declaration
-- ----------------------------------------------------------------------------
entity nmea_parser is
   port (
      clk         : in std_logic;
      reset_n     : in std_logic;
      data        : in std_logic_vector(7 downto 0);  --NMEA data character
      data_v      : in std_logic;                     --NMEA data valid
      
      --Parsed NMEA sentences (Binary format)
      IIENA_valid : out std_logic;
      IIENA_EN    : out std_logic;

      IIRST_valid : out std_logic;
      IIRST_CNT   : out std_logic;

      IIIRQ_valid : out std_logic;
      IIIRQ_EN    : out std_logic;
      IIIRQ_RST   : out std_logic;

      IICFG_valid       : out std_logic;
      IICFG_1S_TARGET   : out std_logic_vector(31 downto 0);
      IICFG_1S_TOL      : out std_logic_vector(31 downto 0);
      IICFG_10S_TARGET  : out std_logic_vector(31 downto 0);
      IICFG_10S_TOL     : out std_logic_vector(31 downto 0);
      IICFG_100S_TARGET : out std_logic_vector(31 downto 0);
      IICFG_100S_TOL    : out std_logic_vector(31 downto 0)

   );
end nmea_parser;

-- ----------------------------------------------------------------------------
-- Architecture
-- ----------------------------------------------------------------------------
architecture arch of nmea_parser is
--declare signals,  components here

type state_type is (idle, GET_TALKER_ID, GET_SENTENCE_ID, PARSE_SENTENCE, GET_CHECKSUM, CHECK_CHECKSUM);
signal current_state, next_state : state_type;

signal state_cnt           : unsigned(7 downto 0);
signal data_field_cnt      : unsigned(7 downto 0);
signal char_cnt            : unsigned(7 downto 0);

signal nmea_talker_id      : std_logic_vector(15 downto 0);
signal nmea_sentence_id    : std_logic_vector(23 downto 0);
signal nmea_checksum       : std_logic_vector(7 downto 0);

signal checksum            : std_logic_vector(7 downto 0);
signal checksum_reg        : std_logic_vector(7 downto 0);
signal checksum_valid      : std_logic;

--IIENA
signal iiena_valid_int     : std_logic;
signal iiena_en_int        : std_logic_vector(7 downto 0);

--IIRST
signal iirst_valid_int     : std_logic;
signal iirst_cntrst_int    : std_logic_vector(7 downto 0);

--IIIRQ
signal iiirq_valid_int     : std_logic;
signal iiirq_en_int        : std_logic_vector(7 downto 0);
signal iiirq_rst_int       : std_logic_vector(7 downto 0);

--IICFG
signal iicfg_valid_int        : std_logic;
signal iicfg_1s_target_int    : std_logic_vector(iicfg_1s_target_max_char*8-1 downto 0);
signal iicfg_1s_tol_int       : std_logic_vector(iicfg_1s_tol_max_char*8-1 downto 0);
signal iicfg_10s_target_int   : std_logic_vector(iicfg_10s_target_max_char*8-1 downto 0);
signal iicfg_10s_tol_int      : std_logic_vector(iicfg_10s_tol_max_char*8-1 downto 0);
signal iicfg_100s_target_int  : std_logic_vector(iicfg_100s_target_max_char*8-1 downto 0);
signal iicfg_100s_tol_int     : std_logic_vector(iicfg_100s_tol_max_char*8-1 downto 0);
  
begin

-- ----------------------------------------------------------------------------
-- Various counters
-- ----------------------------------------------------------------------------
-- Count when FSM is in same state
   process(clk, reset_n)
   begin
      if reset_n = '0' then 
         state_cnt <= (others=>'0');
      elsif (clk'event AND clk='1') then 
         if current_state = next_state AND data_v = '1' then 
            state_cnt <= state_cnt + 1;
         elsif current_state = next_state AND data_v = '0' then 
            state_cnt <= state_cnt;
         else 
            state_cnt <= (others=>'0');
         end if;
      end if;
   end process;
   
-- Data field counter. Data fields are separated with comma symbol. 
-- Counter is reset to 0 at sentence beginning
   process(clk, reset_n)
   begin
      if reset_n = '0' then 
         data_field_cnt <= (others=>'0');
      elsif (clk'event AND clk='1') then 
         if data = C_comma AND data_v = '1' then 
            data_field_cnt <= data_field_cnt + 1;
         elsif data = C_dollar AND data_v = '1' then 
            data_field_cnt <= (others=>'0');
         else 
            data_field_cnt <= data_field_cnt;
         end if;
      end if;
   end process;
   
-- Character counter in data fields. Counter is reset when comma is received 
   process(clk, reset_n)
   begin
      if reset_n = '0' then 
         char_cnt <= (others=>'0');
      elsif (clk'event AND clk='1') then 
         if data = C_comma AND data_v = '1' then 
            char_cnt <= (others=>'0');
         elsif data_v = '1' then 
            char_cnt <= char_cnt + 1;
         else 
            char_cnt <= char_cnt;
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
fsm : process(current_state, data, data_v, state_cnt) begin
	next_state <= current_state;
	case current_state is
	  
		when idle => --idle state
         if data_v = '1' then 
            if data = C_dollar then       -- Sentence start delimiter
               next_state <= GET_TALKER_ID;
            else 
               next_state <= idle;
            end if;
         end if;
      
      when GET_TALKER_ID =>
         if data_v = '1' then 
            if state_cnt = talker_id_len - 1 then 
               next_state <= GET_SENTENCE_ID;
            else 
               next_state <= GET_TALKER_ID;
            end if;
         end if;
              
      when GET_SENTENCE_ID =>
         if data_v = '1' then 
            if state_cnt = sentence_id_len - 1 then 
               next_state <= PARSE_SENTENCE;
            else 
               next_state <= GET_SENTENCE_ID;
            end if;
         end if;
         
      when PARSE_SENTENCE =>
         if data_v = '1' then
            if data = C_asterisk then 
               next_state <= GET_CHECKSUM;
            else 
               next_state <= PARSE_SENTENCE;
            end if;
         end if; 
      
      when GET_CHECKSUM =>
         if data_v = '1' then 
            if state_cnt = checksum_len - 1 then 
               next_state <= CHECK_CHECKSUM;
            else 
               next_state <= GET_CHECKSUM;
            end if;
         end if;
      
      when CHECK_CHECKSUM => 
         next_state <= idle;
         
		when others => 
			next_state <= idle;
	end case;
end process;


-- ----------------------------------------------------------------------------
-- NMEA talker_id, sentence_id and checksum registers registers
-- ----------------------------------------------------------------------------
process(clk)
begin
   if (clk'event AND clk='1') then
      if data_v = '1' then 
      
         --talker id reg
         if current_state = GET_TALKER_ID then
            if state_cnt = 0 then 
               nmea_talker_id(15 downto 8) <= data;
            elsif state_cnt = 1 then 
               nmea_talker_id(7 downto 0) <= data;
            else 
               nmea_talker_id <= nmea_talker_id;
            end if;
         end if;
         
         --sentence id reg
         if current_state = GET_SENTENCE_ID then 
            if state_cnt = 0 then 
               nmea_sentence_id(23 downto 16) <= data;
            elsif state_cnt = 1 then 
               nmea_sentence_id(15 downto 8) <= data;
            elsif state_cnt = 2 then 
               nmea_sentence_id(7 downto 0) <= data;
            else 
               nmea_sentence_id <= nmea_sentence_id;
            end if;
         end if;
         
         --checksum value reg
         if current_state = GET_CHECKSUM then 
            if state_cnt = 0 then
               nmea_checksum(7 downto 4) <= hex_to_slv(data);
            elsif state_cnt = 1 then
               nmea_checksum(3 downto 0) <= hex_to_slv(data);
            else
               nmea_checksum <= nmea_checksum;
            end if;
         end if;
      end if;
   end if;
end process;

-- ----------------------------------------------------------------------------
-- Checksum
-- ----------------------------------------------------------------------------
process(clk, reset_n)
begin
   if reset_n = '0' then 
      checksum       <= (others=>'0');
      checksum_reg   <= (others=>'0');
      checksum_valid <= '0';
   elsif (clk'event AND clk='1') then 
      if data_v = '1' then
         -- Calculate checksum 
         if data = C_dollar then 
            checksum <= (others=>'0');
         else 
            checksum <= checksum XOR data;
         end if;
         --Reset checksum_reg at beggining of sentence
         if data = C_asterisk then 
            checksum_reg <= checksum;
         else 
            checksum_reg <= checksum_reg;
         end if;
      end if;
      
      -- checksum valid signal=1 when all sentence is received and calculated crc is valid,
      -- parsed data is valid only when checksum_valid = 1
      if current_state = CHECK_CHECKSUM AND checksum_reg = nmea_checksum then
         checksum_valid <= '1';
      else 
         checksum_valid <= '0';
      end if;
      
   end if;
end process;

-- ----------------------------------------------------------------------------
-- IIENA messages
-- ----------------------------------------------------------------------------
IIENA_proc : process (clk)
begin
   if reset_n = '0' then 
      iiena_valid_int <= '0';
      iiena_en_int    <= x"30";
   elsif rising_edge(clk) then
      --IIENA message valid 
      if (nmea_talker_id & nmea_sentence_id) = str_to_slv("IIENA") AND checksum_valid = '1' then 
         iiena_valid_int <= '1';
      else 
         iiena_valid_int <= '0';
      end if;
      
      --d0 field
      if data /= C_comma AND data/=C_asterisk AND data_v = '1' AND current_state=PARSE_SENTENCE then 
         if data_field_cnt = iiena_en_d0 then 
            iiena_en_int <= data;
         else 
            iiena_en_int <= iiena_en_int;
         end if;
      else 
         iiena_en_int <= iiena_en_int;
      end if;

   end if;
end process;

-- ----------------------------------------------------------------------------
-- IIRST messages
-- ----------------------------------------------------------------------------
IIRST_proc : process (clk)
begin
   if reset_n = '0' then 
      iirst_valid_int   <= '0';
      iirst_cntrst_int  <= x"30";
   elsif rising_edge(clk) then
      --IIENA message valid 
      if (nmea_talker_id & nmea_sentence_id) = str_to_slv("IIRST") AND checksum_valid = '1' then 
         iirst_valid_int <= '1';
      else 
         iirst_valid_int <= '0';
      end if;
      
      --d0 field
      if data /= C_comma AND data/=C_asterisk AND data_v = '1' AND current_state=PARSE_SENTENCE then 
         if data_field_cnt = iirst_cntrst_d0 then 
            iirst_cntrst_int <= data;
         else 
            iirst_cntrst_int <= iirst_cntrst_int;
         end if;
      else 
         iirst_cntrst_int <= iirst_cntrst_int;
      end if;

   end if;
end process;

-- ----------------------------------------------------------------------------
-- IIRST messages
-- ----------------------------------------------------------------------------
IIIRQ_proc : process (clk)
begin
   if reset_n = '0' then 
      iiirq_valid_int   <= '0';
      iiirq_en_int      <= x"30";
      iiirq_rst_int     <= x"30";
   elsif rising_edge(clk) then
      --IIENA message valid 
      if (nmea_talker_id & nmea_sentence_id) = str_to_slv("IIIRQ") AND checksum_valid = '1' then 
         iiirq_valid_int <= '1';
      else 
         iiirq_valid_int <= '0';
      end if;
      
      --d0 field
      if data /= C_comma AND data/=C_asterisk AND data_v = '1' AND current_state=PARSE_SENTENCE then 
         if data_field_cnt = iiirq_en_d0 then 
            iiirq_en_int <= data;
         else 
            iiirq_en_int <= iiirq_en_int;
         end if;
      else 
         iiirq_en_int <= iiirq_en_int;
      end if;

      --d1 field
      if data /= C_comma AND data/=C_asterisk AND data_v = '1' AND current_state=PARSE_SENTENCE then 
         if data_field_cnt = iiirq_rst_d1 then 
            iiirq_rst_int <= data;
         else 
            iiirq_rst_int <= iiirq_rst_int;
         end if;
      else 
         iiirq_rst_int <= iiirq_rst_int;
      end if;

   end if;
end process;

-- ----------------------------------------------------------------------------
-- IICFG messages
-- ----------------------------------------------------------------------------
IICFG_proc : process (clk)
begin
   if reset_n = '0' then 
      iicfg_valid_int <= '0';
      iicfg_1s_target_int     <=x"3030303030303030";
      iicfg_1s_tol_int        <=x"30303030";
      iicfg_10s_target_int    <=x"3030303030303030";
      iicfg_10s_tol_int       <=x"30303030";
      iicfg_100s_target_int   <=x"3030303030303030";
      iicfg_100s_tol_int      <=x"30303030";
   elsif rising_edge(clk) then
      --IIENA message valid 
      if (nmea_talker_id & nmea_sentence_id) = str_to_slv("IICFG") AND checksum_valid = '1' then 
         iicfg_valid_int <= '1';
      else 
         iicfg_valid_int <= '0';
      end if;
      
      if data = C_dollar AND data_v = '1' then
         iicfg_1s_target_int     <=x"3030303030303030";
         iicfg_1s_tol_int        <=x"30303030";
         iicfg_10s_target_int    <=x"3030303030303030";
         iicfg_10s_tol_int       <=x"30303030";
         iicfg_100s_target_int   <=x"3030303030303030";
         iicfg_100s_tol_int      <=x"30303030";
      elsif data /= C_comma AND data/=C_asterisk AND data_v = '1' AND current_state=PARSE_SENTENCE then 
         --d0 field
         if data_field_cnt = iicfg_1s_target_d0 then 
            iicfg_1s_target_int <= iicfg_1s_target_int(iicfg_1s_target_max_char*8-1-8 downto 0) & data;
         else 
            iicfg_1s_target_int <= iicfg_1s_target_int;
         end if;
         --d1 field
         if data_field_cnt = iicfg_1s_tol_d1 then 
            iicfg_1s_tol_int <= iicfg_1s_tol_int(iicfg_1s_tol_max_char*8-1-8 downto 0) & data;
         else 
            iicfg_1s_tol_int <= iicfg_1s_tol_int;
         end if;

         --d2 field
         if data_field_cnt = iicfg_10s_target_d2 then 
            iicfg_10s_target_int <= iicfg_10s_target_int(iicfg_10s_target_max_char*8-1-8 downto 0) & data;
         else 
            iicfg_10s_target_int <= iicfg_10s_target_int;
         end if;
         --d3 field
         if data_field_cnt = iicfg_10s_tol_d3 then 
            iicfg_10s_tol_int <= iicfg_10s_tol_int(iicfg_10s_tol_max_char*8-1-8 downto 0) & data;
         else 
            iicfg_10s_tol_int <= iicfg_10s_tol_int;
         end if;

          --d4 field
          if data_field_cnt = iicfg_100s_target_d4 then 
            iicfg_100s_target_int <= iicfg_100s_target_int(iicfg_100s_target_max_char*8-1-8 downto 0) & data;
         else 
            iicfg_100s_target_int <= iicfg_100s_target_int;
         end if;
         --d5 field
         if data_field_cnt = iicfg_100s_tol_d5 then 
            iicfg_100s_tol_int <= iicfg_100s_tol_int(iicfg_100s_tol_max_char*8-1-8 downto 0) & data;
         else 
            iicfg_100s_tol_int <= iicfg_100s_tol_int;
         end if;        

      else 
         iicfg_1s_target_int     <= iicfg_1s_target_int;
         iicfg_1s_tol_int        <= iicfg_1s_tol_int;
         iicfg_10s_target_int    <= iicfg_10s_target_int;
         iicfg_10s_tol_int       <= iicfg_10s_tol_int;
         iicfg_100s_target_int   <= iicfg_100s_target_int;
         iicfg_100s_tol_int      <= iicfg_100s_tol_int;
      end if;

   end if;
end process;


-- ----------------------------------------------------------------------------
-- IIENA Output registers
-- ----------------------------------------------------------------------------
process (clk)
begin
   if reset_n = '0' then 
      IIENA_valid <= '0';
      IIENA_EN    <= '0';
   elsif rising_edge(clk) then

      if iiena_valid_int = '1' then 
         if iiena_en_int=x"31" then 
            IIENA_EN <= '1';
         else 
            IIENA_EN <= '0';
         end if;
      end if;

      IIENA_valid <= iiena_valid_int;
      
   end if;
end process;

-- ----------------------------------------------------------------------------
-- IIRST Output registers
-- ----------------------------------------------------------------------------
process (clk)
begin
   if reset_n = '0' then 
      IIRST_valid <= '0';
      IIRST_CNT    <= '0';
   elsif rising_edge(clk) then

      if iirst_valid_int = '1' then 
         if iirst_cntrst_int=x"31" then 
            IIRST_CNT <= '1';
         else 
            IIRST_CNT <= '0';
         end if;
      end if;

      IIRST_valid <= iirst_valid_int;
      
   end if;
end process;

-- ----------------------------------------------------------------------------
-- IIIRQ Output registers
-- ----------------------------------------------------------------------------
process (clk)
begin
   if reset_n = '0' then 
      IIIRQ_valid <= '0';
      IIIRQ_EN    <= '0';
      IIIRQ_RST   <= '0';
   elsif rising_edge(clk) then

      if iiirq_valid_int = '1' then 
         if iiirq_en_int=x"31" then 
            IIIRQ_EN <= '1';
         else 
            IIIRQ_EN <= '0';
         end if;

         if iiirq_rst_int=x"31" then 
            IIIRQ_RST <= '1';
         else 
            IIIRQ_RST <= '0';
         end if;

      end if;

      IIIRQ_valid <= iiirq_valid_int;
      
   end if;
end process;

-- ----------------------------------------------------------------------------
-- IIENA Output registers
-- ----------------------------------------------------------------------------
process (clk)
begin
   if reset_n = '0' then 
      IICFG_valid       <= '0';
      IICFG_1S_TARGET   <=(others=> '0');
      IICFG_1S_TOL      <=(others=> '0');
      IICFG_10S_TARGET  <=(others=> '0');
      IICFG_10S_TOL     <=(others=> '0');
      IICFG_100S_TARGET <=(others=> '0');
      IICFG_100S_TOL    <=(others=> '0');
   elsif rising_edge(clk) then

      if iicfg_valid_int = '1' then 
         IICFG_1S_TARGET   <= ascii_hex_to_std_logic_vector(iicfg_1s_target_int);
         IICFG_1S_TOL      <= ascii_hex_to_std_logic_vector(x"00000000" & iicfg_1s_tol_int);
         IICFG_10S_TARGET  <= ascii_hex_to_std_logic_vector(iicfg_10s_target_int);
         IICFG_10S_TOL     <= ascii_hex_to_std_logic_vector(x"00000000" & iicfg_10s_tol_int);
         IICFG_100S_TARGET <= ascii_hex_to_std_logic_vector(iicfg_100s_target_int);
         IICFG_100S_TOL    <= ascii_hex_to_std_logic_vector(x"00000000" & iicfg_100s_tol_int);
      end if;

      IICFG_valid <= iicfg_valid_int; 
      
   end if;
end process;


 



  
end arch;   


