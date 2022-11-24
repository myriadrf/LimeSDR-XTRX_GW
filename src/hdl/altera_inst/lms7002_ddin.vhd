-- ----------------------------------------------------------------------------   
-- FILE:    lms7002_ddin.vhd
-- DESCRIPTION:   takes data from lms7002 in double data rate
-- DATE:   Mar 14, 2016
-- AUTHOR(s):   Lime Microsystems
-- REVISIONS:
-- Apr 17, 2019 - Added Xilinx support
-- ----------------------------------------------------------------------------   
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

LIBRARY altera_mf; --altera
USE altera_mf.all;
Library UNISIM;
use UNISIM.vcomponents.all;

-- ----------------------------------------------------------------------------
-- Entity declaration
-- ----------------------------------------------------------------------------
entity lms7002_ddin is
   generic( 
            vendor                 : string  := "XILINX"; -- valid vals are "ALTERA" or "XILINX"
            dev_family             : string  := "Cyclone IV E";
            iq_width               : integer := 12;
            invert_input_clocks    : string  := "ON"
   );
   port (
      --input ports 
      clk             : in std_logic;
      reset_n         : in std_logic;
      rxiq            : in std_logic_vector(iq_width-1 downto 0);
      rxiqsel         : in std_logic;
      --output ports 
      data_out_h      : out std_logic_vector(iq_width downto 0);
      data_out_l      : out std_logic_vector(iq_width downto 0)
      
        );
end lms7002_ddin;

-- ----------------------------------------------------------------------------
-- Architecture
-- ----------------------------------------------------------------------------
architecture arch of lms7002_ddin is
--declare signals,  components here
signal aclr         : std_logic;
signal datain       : std_logic_vector(iq_width downto 0);
signal int_data_Q1  : std_logic_vector(iq_width downto 0);
signal int_data_Q2  : std_logic_vector(iq_width downto 0);

component altddio_in
   generic (
      intended_device_family       :   string := "unused";
      implement_input_in_lcell     :   string := "ON";
      invert_input_clocks          :   string := "OFF";
      power_up_high                :   string := "OFF";
      width                        :   natural;
      lpm_hint                     :   string := "UNUSED";
      lpm_type                     :   string := "altddio_in"
   );
   port(
      aclr                         :   in std_logic := '0';
      aset                         :   in std_logic := '0';
      datain                       :   in std_logic_vector(width-1 downto 0);
      dataout_h                    :   out std_logic_vector(width-1 downto 0);
      dataout_l                    :   out std_logic_vector(width-1 downto 0);
      inclock                      :   in std_logic;
      inclocken                    :   in std_logic := '1';
      sclr                         :   in std_logic := '0';
      sset                         :   in std_logic := '0'
   );
end component;

--component IDDR 
--   generic (
--      DDR_CLK_EDGE :string     := "SAME_EDGE_PIPELINED"; -- "OPPOSITE_EDGE", "SAME_EDGE" 
--                                                     -- or "SAME_EDGE_PIPELINED" 
--      INIT_Q1     : std_logic  :=  '0';              -- Initial value of Q1: '0' or '1'
--      INIT_Q2     : std_logic  :=  '0';              -- Initial value of Q2: '0' or '1'
--      SRTYPE      : string     := "SYNC"             -- Set/Reset type: "SYNC" or "ASYNC"
--      ); 
--   port (
--      Q1          : out std_logic ;  -- 1-bit output for positive edge of clock 
--      Q2          : out std_logic ;  -- 1-bit output for negative edge of clock
--      C           : in  std_logic ;  -- 1-bit clock input
--      CE          : in  std_logic ;  -- 1-bit clock enable input
--      D           : in  std_logic ;  -- 1-bit DDR data input
--      R           : in  std_logic ;  -- 1-bit reset
--      S           : in  std_logic    -- 1-bit set
--      );
--end component;


begin

datain<=rxiqsel & rxiq;

aclr<=not reset_n;

ALTERA_DDR_IN : if vendor = "ALTERA" generate
   ALTDDIO_IN_component : ALTDDIO_IN
   GENERIC MAP (
      intended_device_family    => dev_family,
      invert_input_clocks       => invert_input_clocks,
      lpm_hint                  => "UNUSED",
      lpm_type                  => "altddio_in",
      power_up_high             => "OFF",
      width                     => iq_width+1
   )
   PORT MAP (
      aclr                      => aclr,
      datain                    => datain,
      inclock                   => clk,
      dataout_h                 => data_out_h,
      dataout_l                 => data_out_l
   );
end generate;

XILINX_DDR_IN : if vendor = "XILINX" generate

   XILINX_DDR_IN_REG : for i in 0 to iq_width generate
      IDDR_inst : IDDR
      GENERIC MAP(
         DDR_CLK_EDGE   => "SAME_EDGE_PIPELINED",
         INIT_Q1        => '0',
         INIT_Q2        => '0',
         SRTYPE         => "ASYNC" 
      )
      PORT MAP(
         Q1             => int_data_Q1(i),
         Q2             => int_data_Q2(i),
         C              => clk,
         CE             => '1',
         D              => datain(i),
         R              => aclr,
         S              => '0'      
      );
   end generate;
   
   data_out_h <= int_data_Q1 when invert_input_clocks = "OFF" else int_data_Q2;
   data_out_l <= int_data_Q2 when invert_input_clocks = "OFF" else int_data_Q1;
end generate;
  
end arch;   

