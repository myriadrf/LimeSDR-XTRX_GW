-- ----------------------------------------------------------------------------	
-- FILE: 	clock_test.vhd
-- DESCRIPTION:	clock test module
-- DATE:	Sep 5, 2016
-- AUTHOR(s):	Lime Microsystems
-- REVISIONS:
-- ----------------------------------------------------------------------------	
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- ----------------------------------------------------------------------------
-- Entity declaration
-- ----------------------------------------------------------------------------
entity clock_test is
  port (
        --input ports 
        sys_clk       		: in std_logic;
        reset_n   	 		: in std_logic;
		  test_en				: in std_logic_vector(1 downto 0);
		  test_cmplt			: out std_logic_vector(1 downto 0);
		  test_rez				: out std_logic_vector(1 downto 0);
		  
		  LMS_TX_CLK		 	: in std_logic;
		  
		  sys_clk_cnt   		: out std_logic_vector(15 downto 0);
		  LMS_TX_CLK_cnt		: out std_logic_vector(23 downto 0)
        
        );
end clock_test;

-- ----------------------------------------------------------------------------
-- Architecture
-- ----------------------------------------------------------------------------
architecture arch of clock_test is
--declare signals,  components here

component clk_no_ref_test is
  port (
        --input ports 
        clk       		: in std_logic;
        reset_n   		: in std_logic;
		  test_en			: in std_logic;
		  test_cnt			: out std_logic_vector(15 downto 0);
		  test_complete	: out std_logic;
		  test_pass_fail	: out std_logic    
        );
end component;

component singl_clk_with_ref_test is
  port (
        --input ports 
        refclk       	: in std_logic;
        reset_n   		: in std_logic;
		  clk0				: in std_logic;
		  
		  test_en			: in std_logic;
		  test_cnt0			: out std_logic_vector(23 downto 0);
		  test_complete	: out std_logic;
		  test_pass_fail	: out std_logic
     
        );
end component;


begin

sys_clk_test : clk_no_ref_test
  port map(
        clk       		=> sys_clk,
        reset_n   		=> reset_n,
		  test_en			=> test_en(0),
		  test_cnt			=> sys_clk_cnt,
		  test_complete	=> test_cmplt(0),
		  test_pass_fail	=> test_rez(0)   
        );
		  

		  
LML_CLK_test : singl_clk_with_ref_test
  port map (
        --input ports 
        refclk       	=> sys_clk,
        reset_n   		=> reset_n,
		  clk0				=> LMS_TX_CLK,		  
		  test_en			=> test_en(1),
		  test_cnt0			=> LMS_TX_CLK_cnt,
		  test_complete	=> test_cmplt(1),
		  test_pass_fail	=> test_rez(1)   
        );
	


end arch;





