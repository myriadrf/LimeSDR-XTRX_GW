-- ----------------------------------------------------------------------------
-- FILE:          nmea_parser_tb.vhd
-- DESCRIPTION:   
-- DATE:          4:49 PM Monday, February 26, 2018
-- AUTHOR(s):     Lime Microsystems
-- REVISIONS:
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- NOTES:
-- ----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.nmea_parser_pkg.all;

-- ----------------------------------------------------------------------------
-- Entity declaration
-- ----------------------------------------------------------------------------
entity nmea_parser_tb is
end nmea_parser_tb;

-- ----------------------------------------------------------------------------
-- Architecture
-- ----------------------------------------------------------------------------

architecture tb_behave of nmea_parser_tb is
   constant clk0_period    : time := 10 ns;
   constant clk1_period    : time := 10 ns; 
   --signals
   signal clk0,clk1        : std_logic;
   signal reset_n          : std_logic; 
   
   --
   signal nmea_data        : std_logic_vector(7 downto 0);
   signal nmea_data_v      : std_logic;
   
   --NOTE: str_to_slv function does not return <CR><LF> termination, they are aded at the end 
   signal IIENA_SENTENCE_EN  : std_logic_vector(103 downto 0):=str_to_slv("$IIENA,1*57") & x"0D" & x"0A";
   signal IIENA_SENTENCE_DIS  : std_logic_vector(103 downto 0):=str_to_slv("$IIENA,0*56") & x"0D" & x"0A";

   --signal IICFG_SENTENCE_1 : std_logic_vector(383 downto 0):=str_to_slv("$IICFG,30720000,1,307200000,3,3072000000,31*74") & x"0D" & x"0A";
   --signal IICFG_SENTENCE_2 : std_logic_vector(391 downto 0):=str_to_slv("$IICFG,30720000,15,307200000,3,3072000000,31*41") & x"0D" & x"0A";
   --signal IICFG_SENTENCE_3 : std_logic_vector(407 downto 0):=str_to_slv("$IICFG,30720000,18,307200000,39,3072000000,315*40") & x"0D" & x"0A";

   signal IICFG_SENTENCE_1 : std_logic_vector(423 downto 0):=str_to_slv("$IICFG,01D4C000,0001,124F8000,0003,B71B0000,001F*4A") & x"0D" & x"0A";
   signal IICFG_SENTENCE_2 : std_logic_vector(423 downto 0):=str_to_slv("$IICFG,01D4C000,0008,124F8000,0003,B71B0000,001F*43") & x"0D" & x"0A";
   signal IICFG_SENTENCE_3 : std_logic_vector(423 downto 0):=str_to_slv("$IICFG,01D4C000,0002,124F8000,0004,B71B0000,0040*3D") & x"0D" & x"0A";

   signal IIRST_SENTENCE_RST1 : std_logic_vector(103 downto 0):=str_to_slv("$IIRST,1*48") & x"0D" & x"0A";
   signal IIRST_SENTENCE_RST0 : std_logic_vector(103 downto 0):=str_to_slv("$IIRST,0*49") & x"0D" & x"0A";

   signal IIRST_SENTENCE_IRQ_00 : std_logic_vector(119 downto 0):=str_to_slv("$IIIRQ,0,0*4A") & x"0D" & x"0A";
   signal IIRST_SENTENCE_IRQ_10 : std_logic_vector(119 downto 0):=str_to_slv("$IIIRQ,1,0*4B") & x"0D" & x"0A";
   signal IIRST_SENTENCE_IRQ_11 : std_logic_vector(119 downto 0):=str_to_slv("$IIIRQ,1,1*4A") & x"0D" & x"0A";
   signal IIRST_SENTENCE_IRQ_01 : std_logic_vector(119 downto 0):=str_to_slv("$IIIRQ,0,1*4B") & x"0D" & x"0A";

   signal mm_rd_req       :   std_logic;
   signal mm_wr_req       :   std_logic;
   signal mm_addr         :   std_logic_vector(7 downto 0);
   signal mm_wr_data      :   std_logic_vector(7 downto 0);
   signal mm_rd_data      :   std_logic_vector(7 downto 0);
   signal mm_rd_datav     :   std_logic;
   signal mm_wait_req     :   std_logic;

   signal iiena_valid     : std_logic;
   signal iiena_en        : std_logic;

   signal iirst_valid      : std_logic;
   signal iirst_cnt        : std_logic;
   signal iiirq_valid      : std_logic;
   signal iiirq_en         : std_logic;
   signal iiirq_rst        : std_logic;




   procedure send_sentence (
      signal clk        : in std_logic;
      signal data       : out std_logic_vector(7 downto 0);
      signal data_v     : out std_logic;
      signal sentence   : in std_logic_vector
      ) is
      -- Internal variable
      variable tmp_sentence : std_logic_vector(sentence'HIGH downto 0); 
   begin 
      data_v <= '0'; 
      data <= (others=>'0');
      tmp_sentence := sentence;
      wait until rising_edge(clk);
      -- SEND Sentence
      for i in 0 to tmp_sentence'length/8 - 1 loop
         data <= tmp_sentence(tmp_sentence'HIGH downto tmp_sentence'HIGH-7);
         data_v <= '1';
         wait until rising_edge(clk);
         data_v <= '0';
         tmp_sentence := tmp_sentence(tmp_sentence'HIGH-8 downto 0) & x"00";
         wait until rising_edge(clk);
      end loop;
   end procedure;
  
begin 
  
      clock0: process is
   begin
      clk0 <= '0'; wait for clk0_period/2;
      clk0 <= '1'; wait for clk0_period/2;
   end process clock0;

      clock: process is
   begin
      clk1 <= '0'; wait for clk1_period/2;
      clk1 <= '1'; wait for clk1_period/2;
   end process clock;
   
      res: process is
   begin
      reset_n <= '0'; wait for 20 ns;
      reset_n <= '1'; wait;
   end process res;

-- ----------------------------------------------------------------------------
-- Sending sentences
-- ----------------------------------------------------------------------------
process is
begin
   nmea_data_v <= '0'; 
   nmea_data <= (others=>'0');
   wait until rising_edge(clk0) and reset_n='1';
   send_sentence(clk0, nmea_data, nmea_data_v, IIENA_SENTENCE_EN);
   send_sentence(clk0, nmea_data, nmea_data_v, IIENA_SENTENCE_DIS);
   send_sentence(clk0, nmea_data, nmea_data_v, IICFG_SENTENCE_1);
   send_sentence(clk0, nmea_data, nmea_data_v, IICFG_SENTENCE_2);
   send_sentence(clk0, nmea_data, nmea_data_v, IICFG_SENTENCE_3);

   send_sentence(clk0, nmea_data, nmea_data_v, IIRST_SENTENCE_RST1);
   send_sentence(clk0, nmea_data, nmea_data_v, IIRST_SENTENCE_RST0);
   send_sentence(clk0, nmea_data, nmea_data_v, IIRST_SENTENCE_IRQ_00);
   send_sentence(clk0, nmea_data, nmea_data_v, IIRST_SENTENCE_IRQ_10);
   send_sentence(clk0, nmea_data, nmea_data_v, IIRST_SENTENCE_IRQ_11);
   send_sentence(clk0, nmea_data, nmea_data_v, IIRST_SENTENCE_IRQ_10);
   send_sentence(clk0, nmea_data, nmea_data_v, IIRST_SENTENCE_IRQ_01);
   wait;

end process; 

-- ----------------------------------------------------------------------------
-- Unit under test
-- ----------------------------------------------------------------------------
nmea_parser_dut0 : entity work.nmea_parser
   port map(
      clk            => clk0,
      reset_n        => reset_n,
      data           => nmea_data,
      data_v         => nmea_data_v, 

      IIENA_valid    => iiena_valid, 
      IIENA_EN       => iiena_en,

      IIRST_valid    => iirst_valid, 
      IIRST_CNT      => iirst_cnt, 
      IIIRQ_valid    => iiirq_valid, 
      IIIRQ_EN       => iiirq_en, 
      IIIRQ_RST      => iiirq_rst
   );



   nmea_mm_driver_inst : entity work.nmea_mm_driver
      port map(
         clk             => clk0,
         reset_n         => reset_n,
  
         mm_rd_req       => mm_rd_req  ,
         mm_wr_req       => mm_wr_req  ,
         mm_addr         => mm_addr    ,
         mm_wr_data      => mm_wr_data ,
         mm_rd_data      => mm_rd_data ,
         mm_rd_datav     => mm_rd_datav,
         mm_wait_req     => mm_wait_req,
  
         mm_irq          => '0',
  
         IIENA_valid     => iiena_valid,
         IIENA_EN        => iiena_en,

         IIRST_valid     => iirst_valid,
         IIRST_CNT       => iirst_cnt, 
         IIIRQ_valid     => iiirq_valid,
         IIIRQ_EN        => iiirq_en, 
         IIIRQ_RST       => iiirq_rst
  
      );

   

end tb_behave;