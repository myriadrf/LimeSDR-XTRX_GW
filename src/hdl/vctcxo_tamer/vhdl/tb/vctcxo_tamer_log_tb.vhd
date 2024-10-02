-- ----------------------------------------------------------------------------
-- FILE:          vctcxo_tamer_log_tb.vhd
-- DESCRIPTION:   
-- DATE:          Feb 13, 2014
-- AUTHOR(s):     Lime Microsystems
-- REVISIONS:
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- NOTES:
-- ----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- ----------------------------------------------------------------------------
-- Entity declaration
-- ----------------------------------------------------------------------------
entity vctcxo_tamer_log_tb is
end vctcxo_tamer_log_tb;

-- ----------------------------------------------------------------------------
-- Architecture
-- ----------------------------------------------------------------------------

architecture tb_behave of vctcxo_tamer_log_tb is
   constant clk0_period    : time := 10 ns;
   constant clk1_period    : time := 10 ns; 
   --signals
   signal clk0,clk1        : std_logic;
   signal reset_n          : std_logic; 
   
   signal dut0_pps_1s_count_v    : std_logic;
   signal dut0_uart_data_in_stb  : std_logic;
   signal dut0_uart_data_in_ack  : std_logic;

   signal pps_1s_error_v   : std_logic;  
   signal pps_1s_error     : std_logic_vector(31 downto 0);
   signal pps_10s_error_v  : std_logic;
   signal pps_10s_error    : std_logic_vector(31 downto 0);
   signal pps_100s_error_v : std_logic;
   signal pps_100s_error   : std_logic_vector(31 downto 0);

   signal irq              : std_logic;

  
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
   
   
   process is 
   begin
      irq              <= '0';
      pps_1s_error_v   <= '0';
      pps_1s_error     <= (others=>'0');
      pps_10s_error_v  <= '0';
      pps_10s_error    <= (others=>'0');
      pps_100s_error_v <= '0';
      pps_100s_error   <= (others=>'0');
      wait until rising_edge(clk0) and reset_n = '1';
      irq            <= '1';
      pps_1s_error_v <= '1';
      pps_1s_error   <= x"7fffffff";
      pps_10s_error_v <= '1';
      pps_10s_error   <= x"7fffffff";
      pps_100s_error_v <= '1';
      pps_100s_error   <= x"00000003";

      for i in 0 to 256 loop
         wait until rising_edge(clk0);
      end loop;
      irq            <= '0';
      for i in 0 to 7 loop
         wait until rising_edge(clk0);
      end loop;

      irq            <= '1';
      pps_1s_error_v <= '0';
      pps_1s_error   <= x"7fffffff";
      pps_10s_error_v <= '1';
      pps_10s_error   <= x"7fffffff";
      pps_100s_error_v <= '1';
      pps_100s_error   <= x"00000003";


      for i in 0 to 256 loop
         wait until rising_edge(clk0);
      end loop;
      irq            <= '0';
      for i in 0 to 7 loop
         wait until rising_edge(clk0);
      end loop;

      irq            <= '1';
      pps_1s_error_v <= '0';
      pps_1s_error   <= x"7fffffff";
      pps_10s_error_v <= '0';
      pps_10s_error   <= x"7fffffff";
      pps_100s_error_v <= '1';
      pps_100s_error   <= x"00000003";
      



      wait;
   end process;
   
      
   dut0 : entity work.vctcxo_tamer_log
   port map(
      clk                  => clk0,
      reset_n              => reset_n,
         
      irq                  => irq, 

      --Data to log 
      pps_1s_error_v       => pps_1s_error_v,  
      pps_1s_error         => pps_1s_error,    
      pps_10s_error_v      => pps_10s_error_v, 
      pps_10s_error        => pps_10s_error,   
      pps_100s_error_v     => pps_100s_error_v,
      pps_100s_error       => pps_100s_error,  
      
      --To uart module
      uart_data_in         => open,
      uart_data_in_stb     => dut0_uart_data_in_stb,
      uart_data_in_ack     => dut0_uart_data_in_ack
     
      );

      process (clk0)
      begin
         if rising_edge(clk0) then
            if dut0_uart_data_in_stb = '1' then 
               dut0_uart_data_in_ack <= '1';
            else
               dut0_uart_data_in_ack <= '0';
            end if;
         end if;
      end process;

end tb_behave;

