----------------------------------------------------------------------------
-- FILE: rx_pll_top.vhd
-- DESCRIPTION:top file for rx_pll modules
-- DATE:Jan 27, 2016
-- AUTHOR(s):Lime Microsystems
-- REVISIONS:
-- Apr 17, 2019 - Added Xilinx Support
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

LIBRARY altera_mf;

USE altera_mf.all;

use work.pllcfg_pkg.all;
use work.pll_top_blackbox_pkg.all;
use work.axi_pkg.all;


Library UNISIM;
use UNISIM.vcomponents.all;
----------------------------------------------------------------------------
-- Entity declaration
----------------------------------------------------------------------------
entity rx_pll_top is
   generic(
      vendor                  : STRING    := "ALTERA"; -- ALTERA or XILINX
      bandwidth_type          : STRING    := "AUTO";
      clk0_divide_by          : NATURAL   := 1;
      clk0_duty_cycle         : NATURAL   := 50;
      clk0_multiply_by        : NATURAL   := 1;
      clk0_phase_shift        : STRING    := "0";
      clk1_divide_by          : NATURAL   := 1;
      clk1_duty_cycle         : NATURAL   := 50;
      clk1_multiply_by        : NATURAL   := 1;
      clk1_phase_shift        : STRING    := "0";
      compensate_clock        : STRING    := "CLK1";
      inclk0_input_frequency  : NATURAL   := 6250;
      intended_device_family  : STRING    := "Cyclone IV E";
      operation_mode          : STRING    := "SOURCE_SYNCHRONOUS";
      scan_chain_mif_file     : STRING    := "ip/pll/pll.mif";
      drct_c0_ndly            : integer   := 1;
      drct_c1_ndly            : integer   := 2;
      XIL_DIVCLK_DIVIDE       : integer   := 2;
      XIL_CLK_MULT            : integer   := 2;
      XIL_MMCM_PHASE          : real      := 0.0;
      XIL_MMCM_PS_EN          : string    := "FALSE"
   );
   port (
   --PLL input 
   pll_inclk         : in std_logic;
   pll_areset        : in std_logic;
   pll_logic_reset_n : in std_logic;
   inv_c0            : in std_logic;
   c0                : out std_logic; --muxed clock output
   c1                : out std_logic; --muxed clock output
   pll_locked        : out std_logic;
   --Bypass control
   clk_ena           : in std_logic_vector(1 downto 0); --clock output enable
   drct_clk_en       : in std_logic_vector(1 downto 0); --1- Direct clk, 0 - PLL clocks 
   --Reconfiguration ports
   rcnfg_clk         : in std_logic;
   rcnfig_areset     : in std_logic;
   rcnfg_axi_clk     : in std_logic;
   rcfig_axi_reset_n : in std_logic;
   rcnfig_from_axim  : in  t_FROM_AXIM_32x32;
   rcnfig_to_axim    : out t_TO_AXIM_32x32;
   rcnfig_en         : in std_logic;
   rcnfig_data       : in std_logic_vector(143 downto 0);
   rcnfig_status     : out std_logic;
   --Dynamic phase shift ports
   dynps_mode        : in std_logic; -- 0 - manual, 1 - auto
   dynps_areset_n    : in std_logic;
   dynps_en          : in std_logic;
   dynps_tst         : in std_logic;
   dynps_dir         : in std_logic;
   dynps_cnt_sel     : in std_logic_vector(2 downto 0);
   -- max phase steps in auto mode, phase steps to shift in manual mode 
   dynps_phase       : in std_logic_vector(9 downto 0);
   dynps_step_size   : in std_logic_vector(9 downto 0);
   dynps_busy        : out std_logic;
   dynps_done        : out std_logic;
   dynps_status      : out std_logic;
   --signals from sample compare module (required for automatic phase searching)
   smpl_cmp_en       : out std_logic;
   smpl_cmp_done     : in std_logic;
   smpl_cmp_error    : in std_logic;
   --Overall configuration PLL status
   busy              : out std_logic
--   from_pllcfg       : in  t_FROM_PLLCFG
   );
end rx_pll_top;

----------------------------------------------------------------------------
-- Architecture
----------------------------------------------------------------------------
architecture arch of rx_pll_top is
--declare signals,  components here
signal pll_areset_n              : std_logic;
signal pll_inclk_global          : std_logic;

signal c0_global                 : std_logic;
signal c1_global                 : std_logic;
      
signal rcnfig_en_sync            : std_logic;
signal rcnfig_data_sync          : std_logic_vector(143 downto 0);
signal rcnfig_areset_sync        : std_logic;

signal dynps_areset_n_sync       : std_logic;
signal dynps_en_sync             : std_logic;
signal dynps_dir_sync            : std_logic;
signal dynps_cnt_sel_sync        : std_logic_vector(2 downto 0);
signal dynps_phase_sync          : std_logic_vector(9 downto 0);
signal dynps_step_size_sync      : std_logic_vector(9 downto 0);
signal rcnfig_en_sync_scanclk    : std_logic;
signal dynps_mode_sync           : std_logic;
signal dynps_tst_sync            : std_logic;

signal smpl_cmp_done_sync        : std_logic; 
signal smpl_cmp_error_sync       : std_logic;

      
--inst0     
signal inst0_wr_rom              : std_logic;
signal inst0_reconfig            : std_logic;
signal inst0_config_data         : std_logic;
--inst1
signal inst1_busy                : std_logic;
signal inst1_pll_areset          : std_logic;
signal inst1_pll_configupdate    : std_logic;
signal inst1_pll_scanclk         : std_logic;
signal inst1_pll_scanclkena      : std_logic;
signal inst1_pll_scandata        : std_logic;
signal inst1_rom_address_out     : std_logic_vector(7 downto 0);
signal inst1_write_rom_ena       : std_logic;
signal inst1_pll_areset_in       : std_logic;
-- inst2
signal inst2_pll_phasestep       : std_logic;
signal inst2_ps_status           : std_logic;
signal inst2_ps_busy             : std_logic;
signal inst2_ps_done             : std_logic;
signal inst2_pll_reset_req       : std_logic;
signal inst2_pll_phasecounterselect : std_logic_vector(2 downto 0);
signal inst2_pll_phaseupdown        : std_logic; 

--inst3
signal inst3_inclk               : std_logic_vector(1 downto 0);
signal inst3_clk                 : std_logic_vector(4 downto 0);
signal inst3_locked              : std_logic;
signal inst3_locked_scanclk      : std_logic;
signal inst3_phasedone           : std_logic;
signal inst3_scandataout         : std_logic;
signal inst3_scandone            : std_logic;

--isnt4
signal inst4_rcfig_complete      : std_logic;

--inst5
signal inst5_c0_pol_h            : std_logic_vector(0 downto 0);
signal inst5_c0_pol_l            : std_logic_vector(0 downto 0);
signal inst5_dataout             : std_logic_vector(0 downto 0);

signal drct_c0_dly_chain         : std_logic_vector(drct_c0_ndly-1 downto 0);
signal drct_c1_dly_chain         : std_logic_vector(drct_c1_ndly-1 downto 0);

signal c0_mux, c1_mux, c1_mux_bufg  : std_logic;
signal c0_dly, c1_dly               : std_logic;
signal c0_oddr                      : std_logic;
signal locked_mux                   : std_logic;	

begin
   
pll_areset_n   <= not pll_areset;
   
 
----------------------------------------------------------------------------
-- pll_reconfig_module instance
---------------------------------------------------------------------------- 
inst1_pll_areset_in <= pll_areset OR inst2_pll_reset_req;

XILINX_MMCM : if vendor = "XILINX" generate
   
   -- Global buffer for PLL input clock
   BUFG_inst : BUFG
   port map (
      O => pll_inclk_global,  -- 1-bit output: Clock output
      I => pll_inclk          -- 1-bit input: Clock input
   );
   

   -- MMCM instance when frequency is >5MHz
   MMCM_inst1 : entity work.rx_pll
   port map(
      clk_in1        => pll_inclk_global,
      --reset          => inst1_pll_areset_in,
      clk_out1       => inst3_clk(0),
      clk_out2       => inst3_clk(1),
      locked         => inst3_locked,
      
      s_axi_aclk     => rcnfg_axi_clk,       
      s_axi_aresetn  => rcfig_axi_reset_n,      
         
      s_axi_awaddr   => rcnfig_from_axim.awaddr(10 downto 0),         
      s_axi_awvalid  => rcnfig_from_axim.awvalid(0),       
      s_axi_awready  => rcnfig_to_axim.awready(0),       
      s_axi_wdata    => rcnfig_from_axim.wdata,          
      s_axi_wstrb    => rcnfig_from_axim.wstrb,          
      s_axi_wvalid   => rcnfig_from_axim.wvalid(0),        
      s_axi_wready   => rcnfig_to_axim.wready(0),         
      s_axi_bresp    => rcnfig_to_axim.bresp,          
      s_axi_bvalid   => rcnfig_to_axim.bvalid(0),         
      s_axi_bready   => rcnfig_from_axim.bready(0),         
         
      s_axi_araddr   => rcnfig_from_axim.araddr(10 downto 0),        
      s_axi_arvalid  => rcnfig_from_axim.arvalid(0),        
      s_axi_arready  => rcnfig_to_axim.arready(0),        
      s_axi_rdata    => rcnfig_to_axim.rdata,          
      s_axi_rresp    => rcnfig_to_axim.rresp,          
      s_axi_rvalid   => rcnfig_to_axim.rvalid(0),         
      s_axi_rready   => rcnfig_from_axim.rready(0)         
  );
  

   -- C1 clock delay when frequency is <5MHz
   IDELAYE2_c1 : IDELAYE2
   generic map (
      CINVCTRL_SEL            => "TRUE",     -- Enable dynamic clock inversion (FALSE, TRUE)
      DELAY_SRC               => "DATAIN",   -- Delay input (IDATAIN, DATAIN)
      HIGH_PERFORMANCE_MODE   => "TRUE",     -- Reduced jitter ("TRUE"), Reduced power ("FALSE")
      IDELAY_TYPE             => "FIXED",    -- FIXED, VARIABLE, VAR_LOAD, VAR_LOAD_PIPE
      IDELAY_VALUE            => 31,         -- Input delay tap setting (0-31)
      PIPE_SEL                => "FALSE",    -- Select pipelined mode, FALSE, TRUE
      REFCLK_FREQUENCY        => 200.0,      -- IDELAYCTRL clock input frequency in MHz (190.0-210.0, 290.0-310.0).
      SIGNAL_PATTERN          => "CLOCK"     -- DATA, CLOCK input signal
   )
   port map (
      CNTVALUEOUT => open,             -- 5-bit output: Counter value output
      DATAOUT     => c1_dly,           -- 1-bit output: Delayed data output
      C           => '0',              -- 1-bit input: Clock input
      CE          => '0',              -- 1-bit input: Active high enable increment/decrement input
      CINVCTRL    => '0',              -- 1-bit input: Dynamic clock inversion input
      CNTVALUEIN  => (others=>'0'),    -- 5-bit input: Counter value input
      DATAIN      => pll_inclk_global, -- 1-bit input: Internal delay data input
      IDATAIN     => '0',              -- 1-bit input: Data input from the I/O
      INC         => '0',              -- 1-bit input: Increment / Decrement tap delay input
      LD          => '0',              -- 1-bit input: Load IDELAY_VALUE input
      LDPIPEEN    => '0',              -- 1-bit input: Enable PIPELINE register to load data input
      REGRST      => '0'               -- 1-bit input: Active-high reset tap-delay input
   );
   
   
   -- Asynchronous Mux for C0 output clock (MMCM output or delayed clock from global buffer)
   BUFGCTRL_c0_mux : BUFGCTRL
   generic map (
      INIT_OUT => 0,         -- Initial value of BUFGCTRL output ($VALUES;)
      PRESELECT_I0 => FALSE, -- BUFGCTRL output uses I0 input ($VALUES;)
      PRESELECT_I1 => FALSE  -- BUFGCTRL output uses I1 input ($VALUES;)
   )
   port map (
      O        => c0_mux,              -- 1-bit output: Clock output
      CE0      => '1',                 -- 1-bit input: Clock enable input for I0
      CE1      => '1',                 -- 1-bit input: Clock enable input for I1
      I0       => inst3_clk(0),        -- 1-bit input: Primary clock
      I1       => pll_inclk_global,    -- 1-bit input: Secondary clock
      IGNORE0  => '1',                 -- 1-bit input: Clock ignore input for I0
      IGNORE1  => '1',                 -- 1-bit input: Clock ignore input for I1
      S0       => NOT drct_clk_en(0),  -- 1-bit input: Clock select for I0
      S1       => drct_clk_en(0)       -- 1-bit input: Clock select for I1
   );
   
   
   -- Asynchronous Mux for C1 output clock (MMCM output or delayed clock from global buffer)
   BUFGCTRL_c1_mux : BUFGCTRL
   generic map (
      INIT_OUT => 0,         -- Initial value of BUFGCTRL output ($VALUES;)
      PRESELECT_I0 => FALSE, -- BUFGCTRL output uses I0 input ($VALUES;)
      PRESELECT_I1 => FALSE  -- BUFGCTRL output uses I1 input ($VALUES;)
   )
   port map (
      O        => c1_mux,              -- 1-bit output: Clock output
      CE0      => '1',                 -- 1-bit input: Clock enable input for I0
      CE1      => '1',                 -- 1-bit input: Clock enable input for I1
      I0       => inst3_clk(1),        -- 1-bit input: Primary clock
      I1       => c1_dly,              -- 1-bit input: Secondary clock
      IGNORE0  => '1',                 -- 1-bit input: Clock ignore input for I0
      IGNORE1  => '1',                 -- 1-bit input: Clock ignore input for I1
      S0       => NOT drct_clk_en(1),  -- 1-bit input: Clock select for I0
      S1       => drct_clk_en(1)       -- 1-bit input: Clock select for I1
   );
   
   
   -- Global buffer for PLL input clock
   BUFG_c1_mux : BUFG
   port map (
      O => c1_mux_bufg, -- 1-bit output: Clock output
      I => c1_mux       -- 1-bit input: Clock input
   );
   
   
   -- Final stage for C0. ODDR instance to have option to invert clock on c0
   ODDR_inst : ODDR
   generic map(
      DDR_CLK_EDGE   => "OPPOSITE_EDGE",  -- "OPPOSITE_EDGE" or "SAME_EDGE" 
      INIT           => '0',              -- Initial value for Q port ('1' or '0')
      SRTYPE         => "ASYNC")           -- Reset Type ("ASYNC" or "SYNC")
   port map (
      Q  => c0_oddr,       -- 1-bit DDR output
      C  => c0_mux,        -- 1-bit clock input
      CE => '1',           -- 1-bit clock enable input
      D1 => NOT inv_c0,    -- 1-bit data input (positive edge)
      D2 => inv_c0,        -- 1-bit data input (negative edge)
      R  => '0',           -- 1-bit reset input
      S  => '0'            -- 1-bit set input
   );
   
  
end generate;
       
   inst3_inclk <= '0' & pll_inclk;



ALTERA_PLL : if vendor = "ALTERA" generate

   ----------------------------------------------------------------------------
-- pll_reconfig_module controller instance
----------------------------------------------------------------------------
config_ctrl_inst0 : entity work.config_ctrl
port map(
      clk         => rcnfg_clk,
      rst         => rcnfig_areset_sync,
      busy        => inst1_busy,
      addr        => inst1_rom_address_out,
      rd_data     => inst1_write_rom_ena,
      spi_data    => rcnfig_data_sync,
      en_config   => rcnfig_en_sync,
      en_clk      => open,
      wr_rom      => inst0_wr_rom,
      reconfig    => inst0_reconfig,
      config_data => inst0_config_data
);
 

    pll_reconfig_module_inst1 : pll_reconfig_module
       PORT MAP
    (
          clock                => rcnfg_clk,
          counter_param        => (others=>'0'),
          counter_type         => (others=>'0'),
          data_in              => (others=>'0'),
          pll_areset_in        => inst1_pll_areset_in,
          pll_scandataout      => inst3_scandataout,
          pll_scandone         => inst3_scandone,
          read_param           => '0',
          reconfig             => inst0_reconfig,
          reset                => rcnfig_areset_sync,
          reset_rom_address    => '0',
          rom_data_in          => inst0_config_data,
          write_from_rom       => inst0_wr_rom,
          write_param          => '0',
          busy                 => inst1_busy,
          data_out             => open,
          pll_areset           => inst1_pll_areset,
          pll_configupdate     => inst1_pll_configupdate,
          pll_scanclk          => inst1_pll_scanclk,
          pll_scanclkena       => inst1_pll_scanclkena,
          pll_scandata         => inst1_pll_scandata,
          rom_address_out      => inst1_rom_address_out,
          write_rom_ena        => inst1_write_rom_ena
    );

   ----------------------------------------------------------------------------
   -- PLL instance
   ----------------------------------------------------------------------------      
   altpll_inst3 : altpll
   GENERIC MAP (
         bandwidth_type             => bandwidth_type,
         clk0_divide_by             => clk0_divide_by,
         clk0_duty_cycle            => clk0_duty_cycle,
         clk0_multiply_by           => clk0_multiply_by,
         clk0_phase_shift           => clk0_phase_shift,   
         clk1_divide_by             => clk1_divide_by,
         clk1_duty_cycle            => clk1_duty_cycle,
         clk1_multiply_by           => clk1_multiply_by,
         clk1_phase_shift           => clk1_phase_shift,
         compensate_clock           => compensate_clock,
         inclk0_input_frequency     => inclk0_input_frequency,
         intended_device_family     => intended_device_family,
         lpm_hint                   => "CBX_MODULE_PREFIX=pll",
         lpm_type                   => "altpll",
         operation_mode             => operation_mode,
         pll_type                   => "AUTO",
         port_activeclock           => "PORT_UNUSED",
         port_areset                => "PORT_USED",
         port_clkbad0               => "PORT_UNUSED",
         port_clkbad1               => "PORT_UNUSED",
         port_clkloss               => "PORT_UNUSED",
         port_clkswitch             => "PORT_UNUSED",
         port_configupdate          => "PORT_USED",
         port_fbin                  => "PORT_UNUSED",
         port_inclk0                => "PORT_USED",
         port_inclk1                => "PORT_UNUSED",
         port_locked                => "PORT_USED",
         port_pfdena                => "PORT_USED",
         port_phasecounterselect    => "PORT_USED",
         port_phasedone             => "PORT_USED",
         port_phasestep             => "PORT_USED",
         port_phaseupdown           => "PORT_USED",
         port_pllena                => "PORT_UNUSED",
         port_scanaclr              => "PORT_UNUSED",
         port_scanclk               => "PORT_USED",
         port_scanclkena            => "PORT_USED",
         port_scandata              => "PORT_USED",
         port_scandataout           => "PORT_USED",
         port_scandone              => "PORT_USED",
         port_scanread              => "PORT_UNUSED",
         port_scanwrite             => "PORT_UNUSED",
         port_clk0                  => "PORT_USED",
         port_clk1                  => "PORT_USED",
         port_clk2                  => "PORT_UNUSED",
         port_clk3                  => "PORT_UNUSED",
         port_clk4                  => "PORT_UNUSED",
         port_clk5                  => "PORT_UNUSED",
         port_clkena0               => "PORT_UNUSED",
         port_clkena1               => "PORT_UNUSED",
         port_clkena2               => "PORT_UNUSED",
         port_clkena3               => "PORT_UNUSED",
         port_clkena4               => "PORT_UNUSED",
         port_clkena5               => "PORT_UNUSED",
         port_extclk0               => "PORT_UNUSED",
         port_extclk1               => "PORT_UNUSED",
         port_extclk2               => "PORT_UNUSED",
         port_extclk3               => "PORT_UNUSED",
         self_reset_on_loss_lock    => "OFF",
         width_clock                => 5,
         width_phasecounterselect   => 3,
         scan_chain_mif_file        => scan_chain_mif_file
   )
   PORT MAP (
         areset               => inst1_pll_areset,
         configupdate         => inst1_pll_configupdate,
         inclk                => inst3_inclk,
         pfdena               => '1',
         phasecounterselect   => inst2_pll_phasecounterselect,
         phasestep            => inst2_pll_phasestep,
         phaseupdown          => inst2_pll_phaseupdown,
         scanclk              => inst1_pll_scanclk,
         scanclkena           => inst1_pll_scanclkena,
         scandata             => inst1_pll_scandata,
         clk                  => inst3_clk,
         locked               => inst3_locked,
         phasedone            => inst3_phasedone,
         scandataout          => inst3_scandataout,
         scandone             => inst3_scandone
   );
end generate;
   
   
--pll_reconfig_status_inst4 : entity work.pll_reconfig_status
--   port map(
--      clk               => inst1_pll_scanclk,
--      reset_n           => pll_areset_n,
--      reconfig_en       => rcnfig_en_sync_scanclk,
--      scandone          => inst3_scandone,
--      exclude_ps_status => '0',
--      ps_en             => dynps_en_sync,
--      ps_status         => inst2_ps_status,
--      rcfig_complete    => inst4_rcfig_complete
      
--      );   

-- ----------------------------------------------------------------------------
-- c0 direct output lcell delay chain 
-- ----------------------------------------------------------------------------   
ALTERA_PLL_delay : if vendor = "ALTERA" generate                                                
c0_dly_instx_gen : 
for i in 0 to drct_c0_ndly-1 generate
   --first lcell instance
   first : if i = 0 generate 
   lcell0 : lcell 
      port map (
         a_in  => pll_inclk_global,
         a_out => drct_c0_dly_chain(i)
         );
   end generate first;
   --rest of the lcell instance
   rest : if i > 0 generate
   lcellx : lcell 
      port map (
         a_in  => drct_c0_dly_chain(i-1),
         a_out => drct_c0_dly_chain(i)
         );
   end generate rest;
end generate c0_dly_instx_gen;


-- ----------------------------------------------------------------------------
-- c1 direct output lcell delay chain 
-- ----------------------------------------------------------------------------   
c1_dly_instx_gen : 
for i in 0 to drct_c1_ndly-1 generate
   --first lcell instance
   first : if i = 0 generate 
   lcell0 : lcell 
      port map (
         a_in  => pll_inclk_global,
         a_out => drct_c1_dly_chain(i)
         );
   end generate first;
   --rest of the lcell instance
   rest : if i > 0 generate
   lcellx : lcell 
      port map (
         a_in  => drct_c1_dly_chain(i-1),
         a_out => drct_c1_dly_chain(i)
         );
   end generate rest;
end generate c1_dly_instx_gen;
end generate;             

-- ----------------------------------------------------------------------------
-- c0 clk MUX
-- ----------------------------------------------------------------------------
   --c0_mux <=   inst3_clk(0) when drct_clk_en(0)='0' else 
   --         drct_c0_dly_chain(drct_c0_ndly-1);

-- ----------------------------------------------------------------------------
-- c1 clk MUX
-- ----------------------------------------------------------------------------



   --c1_mux <=   inst3_clk(1) when drct_clk_en(1)='0' else 
   --         drct_c1_dly_chain(drct_c1_ndly-1);


locked_mux <=  '1' when (drct_clk_en(0)='1' OR drct_clk_en(1)='1') else
               inst3_locked;




inst5_c0_pol_h(0) <= not inv_c0;
inst5_c0_pol_l(0) <= inv_c0;

-- ----------------------------------------------------------------------------
-- DDR output buffer 
-- ----------------------------------------------------------------------------
ALTERA_PLL_DDIO : if vendor = "ALTERA" generate                                               
ALTDDIO_OUT_component_int5 : ALTDDIO_OUT
GENERIC MAP (
   extend_oe_disable       => "OFF",
   intended_device_family  => intended_device_family,
   invert_output           => "OFF",
   lpm_hint                => "UNUSED",
   lpm_type                => "altddio_out",
   oe_reg                  => "UNREGISTERED",
   power_up_high           => "OFF",
   width                   => 1
)
PORT MAP (
   aclr           => '0',
   datain_h       => inst5_c0_pol_h,
   datain_l       => inst5_c0_pol_l,
   outclock       => c0_global,
   dataout        => inst5_dataout
);
end generate;
XILINX_PLL_DDIO : if vendor = "XILINX" generate
    --c0 <= c0_global;
end generate;             

-- ----------------------------------------------------------------------------
-- Clock control buffers 
-- ----------------------------------------------------------------------------
ALTERA_PLL_CLKCTRL : if vendor = "ALTERA" generate                                                   
clkctrl_inst6 : clkctrl 
port map(
   inclk    => pll_inclk,
   ena      => '1',
   outclk   => pll_inclk_global
);

clkctrl_inst7 : clkctrl 
port map(
   inclk    => c0_mux,
   ena      => clk_ena(0),
   outclk   => c0_global
);

clkctrl_inst8 : clkctrl 
port map(
   inclk    => c1_mux,
   ena      => clk_ena(1),
   outclk   => c1_global
);
end generate;

XILINX_PLL_CLKCTRL : if vendor = "XILINX" generate
--clkctrl_inst6 : BUFGCE_1
--port map(
--    I => pll_inclk,
--    CE=> '1',
--    O => pll_inclk_global
--    );

--clkctrl_inst7 : BUFGCE_1 
--port map(
--   I    => c0_mux,
--   CE   => clk_ena(0),
--   O    => c0_global
--);

--clkctrl_inst8 : BUFGCE_1 
--port map(
--   I    => c1_mux,
--   CE   => clk_ena(1),
--   O    => c1_global
--);
end generate;

-- ----------------------------------------------------------------------------
-- To output ports
-- ----------------------------------------------------------------------------
c0             <= c0_oddr;
c1             <= c1_mux_bufg;
pll_locked     <= locked_mux;
rcnfig_status  <= inst4_rcfig_complete;
dynps_done     <= inst2_ps_done;
dynps_status   <= inst2_ps_status;
busy           <= inst1_busy OR inst2_ps_status;
  
end arch;   





