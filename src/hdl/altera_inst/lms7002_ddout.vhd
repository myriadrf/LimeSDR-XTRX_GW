-- ----------------------------------------------------------------------------   
-- FILE:    lms7002_ddout.vhd
-- DESCRIPTION:   takes data in SDR and ouputs double data rate
-- DATE:   Mar 14, 2016
-- AUTHOR(s):   Lime Microsystems
-- REVISIONS:
-- Apr 17, 2019 - added Xilinx support
-- ----------------------------------------------------------------------------   
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fpgacfg_pkg.all;

LIBRARY altera_mf;
USE altera_mf.all;
Library UNISIM;
use UNISIM.vcomponents.all;

-- ----------------------------------------------------------------------------
-- Entity declaration
-- ----------------------------------------------------------------------------
entity lms7002_ddout is
   generic(
      vendor        : string := "XILINX"; -- valid vals are "ALTERA", "XILINX"
      dev_family    : string := "Cyclone IV E";
      iq_width      : integer:= 12
   );
   port (
      from_fpgacfg  : in  t_FROM_FPGACFG;
      --input ports 
      clk           : in std_logic;
      reset_n       : in std_logic;
      data_in_h     : in std_logic_vector(iq_width downto 0);
      data_in_l     : in std_logic_vector(iq_width downto 0);
      --output ports 
      txiq          : out std_logic_vector(iq_width-1 downto 0);
      txiqsel       : out std_logic
      
        );
end lms7002_ddout;

-- ----------------------------------------------------------------------------
-- Architecture
-- ----------------------------------------------------------------------------
architecture arch of lms7002_ddout is
--declare signals,  components here

signal aclr            : std_logic;
signal datout          : std_logic_vector(iq_width downto 0);
signal dataout_delayed : std_logic_vector(iq_width-1 downto 0);
type sel_array_type is array (0 to 11) of std_logic_vector(1 downto 0);
signal dly_sel_array :  sel_array_type;

signal data_reg_l : std_logic_vector(iq_width downto 0);
signal data_reg_h : std_logic_vector(iq_width downto 0);

signal data_l_muxed : std_logic_vector(iq_width downto 0);
signal data_h_muxed : std_logic_vector(iq_width downto 0);

signal tx_hi_freq_mode_reg : std_logic;



COMPONENT ALTDDIO_OUT
GENERIC(
      intended_device_family   :   string := "unused";
      extend_oe_disable        :   string := "OFF";
      invert_output            :   string := "OFF";
      oe_reg                   :   string := "UNREGISTERED";
      power_up_high            :   string := "OFF";
      width                    :   natural;
      lpm_hint                 :   string := "UNUSED";
      lpm_type                 :   string := "altddio_out"
);
PORT(
      aclr         :   in std_logic := '0';
      aset         :   in std_logic := '0';
      datain_h     :   in std_logic_vector(width-1 downto 0);
      datain_l     :   in std_logic_vector(width-1 downto 0);
      dataout      :   out std_logic_vector(width-1 downto 0);
      oe           :   in std_logic := '1';
      oe_out       :   out std_logic_vector(width-1 downto 0);
      outclock     :   in std_logic;
      outclocken   :   in std_logic := '1';
      sclr         :   in std_logic := '0';
      sset         :   in std_logic := '0'
);
END COMPONENT;

-- XILINX DDR OUTPUT REGISTER
--COMPONENT ODDR
--GENERIC(
--   DDR_CLK_EDGE   : string    := "SAME_EDGE";
--   INIT           : std_logic := '0';
--   SRTYPE         : string    := "ASYNC"
--);
--PORT(
--Q   : out std_Logic;
--C   : in  std_Logic;
--CE  : in  std_Logic;
--D1  : in  std_Logic;
--D2  : in  std_Logic;
--R   : in  std_Logic;
--S   : in  std_Logic
--);
--END COMPONENT;


begin

      process(clk)
      begin
        if rising_edge(clk) then
            data_reg_l <= data_in_l;
            data_reg_h <= data_in_h;
            
            if tx_hi_freq_mode_reg = '1' then
                data_l_muxed <= data_in_h(12) & data_in_l(11) & data_in_h(10 downto 0);
                data_h_muxed <= data_in_l(12) & data_in_h(11) & data_reg_l(10 downto 0);
            else
                data_l_muxed <= data_in_l;
                data_h_muxed <= data_in_h;
            end if;
        end if;      
      end process;

    sync_inst0 : entity work.sync_reg
    port map(
       clk     => clk,
      reset_n  => reset_n,   
      async_in => from_fpgacfg.TX_HI_FREQ_MODE,   
      sync_out => tx_hi_freq_mode_reg
    );


   aclr<=not reset_n;

   ALTERA_DDR_OUT : if vendor = "ALTERA" generate
   
      ALTDDIO_OUT_component : ALTDDIO_OUT
      GENERIC MAP (
         extend_oe_disable         => "OFF",
         intended_device_family    => "Cyclone IV E",
         invert_output             => "OFF",
         lpm_hint                  => "UNUSED",
         lpm_type                  => "altddio_out",
         oe_reg                    => "UNREGISTERED",
         power_up_high             => "OFF",
         width                     => iq_width+1
      )
      PORT MAP (
         aclr          => aclr,
         datain_h      => data_in_h,
         datain_l      => data_in_l,
         outclock      => clk,
         dataout       => datout
      );
   end generate;
   
   
   XILINX_DDR_OUT : if vendor = "XILINX" generate
   

      
      XILINX_DDR_OUT_REG : for i in 0 to iq_width generate
         ODDR_inst : ODDR
         GENERIC MAP(
            DDR_CLK_EDGE => "SAME_EDGE", -- "OPPOSITE_EDGE" or "SAME_EDGE" 
            INIT         => '0',   -- Initial value for Q port ('1' or '0')
            SRTYPE       => "ASYNC" -- Reset Type ("ASYNC" or "SYNC"
         )
         PORT MAP(
            Q  => datout(i),   -- 1-bit DDR output
            C  => clk,    -- 1-bit clock input
            CE => '1',  -- 1-bit clock enable input
            D1 => data_h_muxed(i),--data_reg_h(i),--data_in_h(i),  -- 1-bit data input (positive edge)
            D2 => data_l_muxed(i),--data_reg_l(i),--data_in_l(i),  -- 1-bit data input (negative edge)
            R  => aclr,    -- 1-bit reset input
            S  => '0'     -- 1-bit set input
         );      
      end generate;
   end generate;
  

 
   txiq      <= datout(11 downto 0);
   txiqsel   <= datout(12);
   
  
end arch;   





