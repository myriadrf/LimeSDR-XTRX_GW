-- ----------------------------------------------------------------------------	
-- FILE: 	pll_top_blackbox_pkg.vhd
-- DESCRIPTION:	Contains component black box declarations used in PLL modules
-- DATE:	April 17, 2019
-- AUTHOR(s):	Lime Microsystems
-- REVISIONS:
-- ----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
package pll_top_blackbox_pkg is
component pll_reconfig_module is
    port (
        busy	             :	OUT  STD_LOGIC;
        clock	             :	IN   STD_LOGIC;
        counter_param	    :	IN   STD_LOGIC_VECTOR (2 DOWNTO 0);
        counter_type	       :	IN   STD_LOGIC_VECTOR (3 DOWNTO 0);
        data_in     	       :	IN   STD_LOGIC_VECTOR (8 DOWNTO 0);
        data_out	          :	OUT  STD_LOGIC_VECTOR (8 DOWNTO 0);
        pll_areset	       :	OUT  STD_LOGIC;
        pll_areset_in	    :	IN   STD_LOGIC ;
        pll_configupdate	 :	OUT  STD_LOGIC;
        pll_scanclk	       :	OUT  STD_LOGIC;
        pll_scanclkena	    :	OUT  STD_LOGIC;
        pll_scandata	       :	OUT  STD_LOGIC;
        pll_scandataout	    :	IN   STD_LOGIC ;
        pll_scandone	       :	IN   STD_LOGIC ;
        read_param	       :	IN   STD_LOGIC ;
        reconfig	          :	IN   STD_LOGIC ;
        reset	             :	IN   STD_LOGIC;
        reset_rom_address	 :	IN   STD_LOGIC ;
        rom_address_out 	 :	OUT  STD_LOGIC_VECTOR (7 DOWNTO 0);
        rom_data_in	       :	IN   STD_LOGIC ;
        write_from_rom	    :	IN   STD_LOGIC ;
        write_param     	 :	IN   STD_LOGIC ;
        write_rom_ena	    :	OUT  STD_LOGIC
);
end component;

component clkctrl is
   port (
      inclk  : in  std_logic := '0'; --  altclkctrl_input.inclk
      ena    : in  std_logic := '0'; --                  .ena
      outclk : out std_logic         -- altclkctrl_output.outclk
);
end component;

component lcell
port(
    a_in : in  std_logic;
    a_out: out std_logic
);
end component;

component ALTDDIO_OUT
generic(
    extend_oe_disable      : string;
    intended_device_family : string;
    invert_output          : string;
    lpm_hint               : string;
    lpm_type               : string;
    oe_reg                 : string;
    power_up_high          : string;
    width                  : integer
    );
port(
    datain_h : in std_logic_vector(width-1 downto 0);
    datain_l : in std_logic_vector(width-1 downto 0);
    outclock : in std_logic;
    aclr     : in std_logic;
    dataout  : out std_logic_vector(width-1 downto 0)
);
end component;

component top_mmcme2
   generic(
    BANDWIDTH            : STRING;
    
    DIVCLK_DIVIDE        : INTEGER;
    
    CLKFBOUT_MULT_F      : INTEGER;
    CLKFBOUT_PHASE       : REAL;
    CLKFBOUT_USE_FINE_PS : STRING;
    
    CLKIN1_PERIOD        : REAL;
    REF_JITTER1          : REAL;
    
    CLKOUT0_DIVIDE_F     : INTEGER;
    CLKOUT0_DUTY_CYCLE   : REAL;
    CLKOUT0_PHASE        : REAL;
    CLKOUT0_USE_FINE_PS  : STRING;
    
    CLKOUT1_DIVIDE       : INTEGER;
    CLKOUT1_DUTY_CYCLE   : REAL;
    CLKOUT1_PHASE        : REAL;
    CLKOUT1_USE_FINE_PS  : STRING
    );
   port
   (
      -- SSTEP is the input to start a reconfiguration.  It should only be
      -- pulsed for one clock cycle.
      SSTEP          : in std_logic;
      SCLK           : in std_logic;
      -- RST will reset the entire reference design including the MMCM_ADV
      RST            : in std_logic;
      -- CLKIN is the input clock that feeds the MMCM_ADV CLKIN as well as the
      -- clock for the MMCM_DRP module
      CLKIN          : in std_logic;

      -- SRDY pulses for one clock cycle after the MMCM_ADV is locked and the
      -- MMCM_DRP module is ready to start another re-configuration
     SRDY            : out std_logic;
	  LOCKED         : out std_logic;
      
      -- clock config inputs
      c0_cnt         : in std_logic_vector(15 downto 0);
      c1_cnt         : in std_logic_vector(15 downto 0);
      c2_cnt         : in std_logic_vector(15 downto 0);
      c3_cnt         : in std_logic_vector(15 downto 0);
      c4_cnt         : in std_logic_vector(15 downto 0);
      c5_cnt         : in std_logic_vector(15 downto 0);
      c6_cnt         : in std_logic_vector(15 downto 0);
      c0_oddiv       : in std_logic;
      c1_oddiv       : in std_logic;
      c2_oddiv       : in std_logic;
      c3_oddiv       : in std_logic;
      c4_oddiv       : in std_logic;
      c5_oddiv       : in std_logic;
      c6_oddiv       : in std_logic;
      c0_byp         : in std_logic;
      c1_byp         : in std_logic;
      c2_byp         : in std_logic;
      c3_byp         : in std_logic;
      c4_byp         : in std_logic;
      c5_byp         : in std_logic;
      c6_byp         : in std_logic;
      m_cnt          : in std_logic_vector(15 downto 0);
      m_oddiv        : in std_logic;
      m_byp          : in std_logic;
      n_cnt          : in std_logic_vector(15 downto 0);
      n_oddiv        : in std_logic;
      n_byp          : in std_logic;
      xil_cm_f       : in std_logic_vector(9 downto 0);
      
      -- These are the clock outputs from the MMCM_ADV.
      CLK0OUT        : out std_logic;
      CLK1OUT        : out std_logic;
      CLK2OUT        : out std_logic;
      CLK3OUT        : out std_logic;
      CLK4OUT        : out std_logic;
      CLK5OUT        : out std_logic;
      CLK6OUT        : out std_logic;
      
      -- fine phase shift ports
      PSDONE         : out std_logic;    
      PSCLK          : in std_logic;
      PSEN           : in std_logic;        
      PSINCDEC       : in std_logic;
      PS_CNT_SEL     : in std_logic_vector(2 downto 0)  
   );
end component;

COMPONENT pll_ps_top
   port(
    clk                           : in std_logic;
    reset_n                       : in std_logic;
    --module control ports
    ps_en                         : in std_logic; -- rising edge triggers dynamic phase shift
    ps_mode                       : in std_logic; -- 0 - manual, 1 - auto
    ps_tst                        : in std_logic;
    ps_cnt                        : in std_logic_vector(2 downto 0); 
                                                 -- 000 - ALL, 001 -   M, 010 - C0,
                                                 -- 011 -  C1, 100 -  C2, 101 - C3,
                                                 -- 110 -  C4
    ps_updwn                      : in std_logic; -- 1- UP, 0 - DOWN 
    ps_phase                      : in std_logic_vector(9 downto 0); -- phase value in steps
    ps_step_size                  : in std_logic_vector(9 downto 0);
    ps_busy                       : out std_logic;
    ps_done                       : out std_logic;
    ps_status                     : out std_logic;     
    --pll ports
    pll_phasecounterselect        : out std_logic_vector(2 downto 0);
    pll_phaseupdown               : out std_logic;
    pll_phasestep                 : out std_logic;
    pll_phasedone                 : in std_logic;
    pll_locked                    : in std_logic;
    pll_reconfig                  : in std_logic;
    pll_reset_req                 : out std_logic;
    --sample compare module
    smpl_cmp_en                   : out std_logic;
    smpl_cmp_done                 : in std_logic;
    smpl_cmp_error                : in std_logic
   );
end component;

COMPONENT BUFGCE_1
port (
  O  : out std_logic;   -- 1-bit output: Clock output
  CE : in std_logic; -- 1-bit input: Clock enable input for I0
  I  : in std_logic    -- 1-bit input: Primary clock
);
end COMPONENT;

COMPONENT altpll
   GENERIC (
      bandwidth_type          : STRING;
      clk0_divide_by          : NATURAL;
      clk0_duty_cycle         : NATURAL;
      clk0_multiply_by        : NATURAL;
      clk0_phase_shift        : STRING;
      clk1_divide_by          : NATURAL;
      clk1_duty_cycle         : NATURAL;
      clk1_multiply_by        : NATURAL;
      clk1_phase_shift        : STRING;
      compensate_clock        : STRING;
      inclk0_input_frequency  : NATURAL;
      intended_device_family  : STRING;
      lpm_hint                : STRING;
      lpm_type                : STRING;
      operation_mode          : STRING;
      pll_type                : STRING;
      port_activeclock        : STRING;
      port_areset             : STRING;
      port_clkbad0            : STRING;
      port_clkbad1            : STRING;
      port_clkloss            : STRING;
      port_clkswitch          : STRING;
      port_configupdate       : STRING;
      port_fbin               : STRING;
      port_inclk0             : STRING;
      port_inclk1             : STRING;
      port_locked             : STRING;
      port_pfdena             : STRING;
      port_phasecounterselect : STRING;
      port_phasedone          : STRING;
      port_phasestep          : STRING;
      port_phaseupdown        : STRING;
      port_pllena             : STRING;
      port_scanaclr           : STRING;
      port_scanclk            : STRING;
      port_scanclkena         : STRING;
      port_scandata           : STRING;
      port_scandataout        : STRING;
      port_scandone           : STRING;
      port_scanread           : STRING;
      port_scanwrite          : STRING;
      port_clk0               : STRING;
      port_clk1               : STRING;
      port_clk2               : STRING;
      port_clk3               : STRING;
      port_clk4               : STRING;
      port_clk5               : STRING;
      port_clkena0            : STRING;
      port_clkena1            : STRING;
      port_clkena2            : STRING;
      port_clkena3            : STRING;
      port_clkena4            : STRING;
      port_clkena5            : STRING;
      port_extclk0            : STRING;
      port_extclk1            : STRING;
      port_extclk2            : STRING;
      port_extclk3            : STRING;
      self_reset_on_loss_lock : STRING;
      width_clock             : NATURAL;
      width_phasecounterselect: NATURAL;
      scan_chain_mif_file     : STRING
   );
PORT (
      areset               : IN STD_LOGIC ;
      configupdate         : IN STD_LOGIC ;
      inclk                : IN STD_LOGIC_VECTOR (1 DOWNTO 0);
      pfdena               : IN STD_LOGIC ;
      phasecounterselect   : IN STD_LOGIC_VECTOR (2 DOWNTO 0);
      phasestep            : IN STD_LOGIC ;
      phaseupdown          : IN STD_LOGIC ;
      scanclk              : IN STD_LOGIC ;
      scanclkena           : IN STD_LOGIC ;
      scandata             : IN STD_LOGIC ;
      clk                  : OUT STD_LOGIC_VECTOR (4 DOWNTO 0);
      locked               : OUT STD_LOGIC ;
      phasedone            : OUT STD_LOGIC ;
      scandataout          : OUT STD_LOGIC ;
      scandone             : OUT STD_LOGIC 
);
END COMPONENT;


end pll_top_blackbox_pkg;