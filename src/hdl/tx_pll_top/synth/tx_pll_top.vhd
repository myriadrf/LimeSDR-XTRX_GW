----------------------------------------------------------------------------
-- FILE: tx_pll_top.vhd
-- DESCRIPTION:top file for tx_pll modules
-- DATE:Jan 27, 2016
-- AUTHOR(s):Lime Microsystems
-- REVISIONS:
-- Apr 17 2019 - Added Xilinx Support
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
entity tx_pll_top is
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
      scan_chain_mif_file     : STRING    := "ip/txpll/pll.mif";
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

   c2                : out std_logic; -- B.J.

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
   dynps_areset_n    : in std_logic;
   dynps_mode        : in std_logic; -- 0 - manual, 1 - auto
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
   busy              : out std_logic;
   from_pllcfg       : in  t_FROM_PLLCFG
   );
end tx_pll_top;

----------------------------------------------------------------------------
-- Architecture
----------------------------------------------------------------------------
architecture arch of tx_pll_top is
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

signal c0_mux, c1_mux            : std_logic;
signal locked_mux                : std_logic;

begin
   
pll_areset_n   <= not pll_areset;
   
----------------------------------------------------------------------------
-- Synchronization registers
----------------------------------------------------------------------------  
 sync_reg0 : entity work.sync_reg 
 port map(rcnfg_clk, pll_logic_reset_n, rcnfig_en, rcnfig_en_sync); 
 
 sync_reg1 : entity work.sync_reg 
 port map(inst1_pll_scanclk, pll_logic_reset_n, dynps_en, dynps_en_sync); 
 
 sync_reg2 : entity work.sync_reg 
 port map(inst1_pll_scanclk, pll_logic_reset_n, dynps_dir, dynps_dir_sync); 
 
 sync_reg3 : entity work.sync_reg 
 port map(inst1_pll_scanclk, pll_logic_reset_n, rcnfig_en, rcnfig_en_sync_scanclk);
 
 sync_reg4 : entity work.sync_reg 
 port map(inst1_pll_scanclk, pll_logic_reset_n, dynps_mode, dynps_mode_sync);
 
 sync_reg5 : entity work.sync_reg 
 port map(inst1_pll_scanclk, pll_logic_reset_n, smpl_cmp_done, smpl_cmp_done_sync);

 sync_reg6 : entity work.sync_reg 
 port map(inst1_pll_scanclk, pll_logic_reset_n, smpl_cmp_error, smpl_cmp_error_sync);
 
 sync_reg7 : entity work.sync_reg 
 port map(inst1_pll_scanclk, pll_logic_reset_n, dynps_areset_n, dynps_areset_n_sync);
 
 sync_reg8 : entity work.sync_reg 
 port map(rcnfg_clk, pll_logic_reset_n, rcnfig_areset, rcnfig_areset_sync);
 
 sync_reg9 : entity work.sync_reg 
 port map(inst1_pll_scanclk, pll_logic_reset_n, dynps_tst, dynps_tst_sync);
 
 sync_reg10 : entity work.sync_reg 
 port map(inst1_pll_scanclk, pll_logic_reset_n, inst3_locked, inst3_locked_scanclk);
 
 bus_sync_reg0 : entity work.bus_sync_reg
 generic map (144) 
 port map(rcnfg_clk, pll_logic_reset_n, rcnfig_data, rcnfig_data_sync);
 
 bus_sync_reg1 : entity work.bus_sync_reg
 generic map (3) 
 port map(inst1_pll_scanclk, pll_logic_reset_n, dynps_cnt_sel, dynps_cnt_sel_sync);
 
 bus_sync_reg2 : entity work.bus_sync_reg
 generic map (10) 
 port map(inst1_pll_scanclk, pll_logic_reset_n, dynps_phase, dynps_phase_sync);
 
bus_sync_reg3 : entity work.bus_sync_reg
 generic map (10) 
 port map(inst1_pll_scanclk, pll_logic_reset_n, dynps_step_size, dynps_step_size_sync);
 
----------------------------------------------------------------------------
-- pll_reconfig_module instance
---------------------------------------------------------------------------- 
inst1_pll_areset_in <= pll_areset OR inst2_pll_reset_req;

XILINX_MMCM : if vendor = "XILINX" generate

inst1_pll_scanclk <= rcnfg_clk;

--MMCM_inst1 : top_mmcme2
--generic map(
--BANDWIDTH => bandwidth_type,
--DIVCLK_DIVIDE => XIL_DIVCLK_DIVIDE,
--CLKFBOUT_MULT_F => XIL_CLK_MULT,
--CLKFBOUT_PHASE  => XIL_MMCM_PHASE,
--CLKFBOUT_USE_FINE_PS => XIL_MMCM_PS_EN,
--
--CLKIN1_PERIOD => real(inclk0_input_frequency)*0.001,
--REF_JITTER1 => 0.01,-- default value
--
--CLKOUT0_DIVIDE_F  => clk0_divide_by,
--CLKOUT0_DUTY_CYCLE => real(clk0_duty_cycle)*0.01,
--CLKOUT0_PHASE      => 0.0,
--CLKOUT0_USE_FINE_PS => "FALSE",
--
--CLKOUT1_DIVIDE => clk1_divide_by,
--CLKOUT1_DUTY_CYCLE => real(clk1_duty_cycle)*0.01,
--CLKOUT1_PHASE => 0.0,
--CLKOUT1_USE_FINE_PS => "TRUE"
--)
--port map(
--      SSTEP     =>rcnfig_en_sync_scanclk,
--      SCLK      =>inst1_pll_scanclk,
----RST will reset the entire reference design including the MMCM_ADV
--      RST       =>inst1_pll_areset_in,
--      -- CLKIN is the input clock that feeds the MMCM_ADV CLKIN as well as the
--      -- clock for the MMCM_DRP module
--      CLKIN     =>pll_inclk,
--
--      -- SRDY pulses for one clock cycle after the MMCM_ADV is locked and the
--      -- MMCM_DRP module is ready to start another re-configuration
--      SRDY      =>inst4_rcfig_complete,
--	   LOCKED    =>inst3_locked,
--      
--      -- clock config inputs
--      c0_cnt    =>from_pllcfg.c0_cnt,
--      c1_cnt    =>from_pllcfg.c1_cnt,
--      c2_cnt    =>from_pllcfg.c2_cnt,
--      c3_cnt    =>from_pllcfg.c3_cnt,
--      c4_cnt    =>from_pllcfg.c4_cnt,
--      c5_cnt    =>(others => '0'),
--      c6_cnt    =>(others => '0'),
--      c0_oddiv  =>from_pllcfg.c0_odddiv,
--      c1_oddiv  =>from_pllcfg.c1_odddiv,
--      c2_oddiv  =>from_pllcfg.c2_odddiv,
--      c3_oddiv  =>from_pllcfg.c3_odddiv,
--      c4_oddiv  =>from_pllcfg.c4_odddiv,
--      c5_oddiv  =>'0',
--      c6_oddiv  =>'0',
--      c0_byp    =>from_pllcfg.c0_byp,
--      c1_byp    =>from_pllcfg.c1_byp,
--      c2_byp    =>from_pllcfg.c2_byp,
--      c3_byp    =>from_pllcfg.c3_byp,
--      c4_byp    =>from_pllcfg.c4_byp,
--      c5_byp    =>'1',
--      c6_byp    =>'1',
--      m_cnt     =>from_pllcfg.m_cnt,
--      m_oddiv   =>from_pllcfg.m_odddiv,
--      m_byp     =>from_pllcfg.m_byp,
--      n_cnt     =>from_pllcfg.n_cnt,
--      n_oddiv   =>from_pllcfg.n_odddiv,
--      n_byp     =>from_pllcfg.n_byp,
--      xil_cm_f  =>from_pllcfg.xil_cm_f,
--      
--      -- These are the clock outputs from the MMCM_ADV.
--      CLK0OUT   =>inst3_clk(0),
--      CLK1OUT   =>inst3_clk(1),
--      CLK2OUT   =>inst3_clk(2),
--      CLK3OUT   =>inst3_clk(3),
--      CLK4OUT   =>inst3_clk(4),
--      CLK5OUT   =>open,
--      CLK6OUT   =>open,
--      
--      -- fine phase shift ports
--      PSDONE    =>inst3_phasedone,    
--      PSCLK     =>inst1_pll_scanclk,
--      PSEN      =>inst2_pll_phasestep,        
--      PSINCDEC  =>inst2_pll_phaseupdown,
--      PS_CNT_SEL=>inst2_pll_phasecounterselect
--);
  MMCM_inst1 : entity work.tx_pll
  port map(
      clk_in1        => pll_inclk,
      --reset          => inst1_pll_areset_in,
      clk_out1       => inst3_clk(0),
      clk_out2       => inst3_clk(1),

      locked         => inst3_locked,
      s_axi_aclk     => rcnfg_axi_clk,           -- in
      s_axi_aresetn  => rcfig_axi_reset_n,        -- in
         
      s_axi_awaddr   => rcnfig_from_axim.awaddr(10 downto 0),         -- in
      s_axi_awvalid  => rcnfig_from_axim.awvalid(0),        -- in
      s_axi_awready  => rcnfig_to_axim.awready(0),        -- out
      s_axi_wdata    => rcnfig_from_axim.wdata,          -- in
      s_axi_wstrb    => rcnfig_from_axim.wstrb,          -- in
      s_axi_wvalid   => rcnfig_from_axim.wvalid(0),         -- in
      s_axi_wready   => rcnfig_to_axim.wready(0),         -- out
      s_axi_bresp    => rcnfig_to_axim.bresp,          -- out
      s_axi_bvalid   => rcnfig_to_axim.bvalid(0),         -- out
      s_axi_bready   => rcnfig_from_axim.bready(0),         -- in
         
      s_axi_araddr   => rcnfig_from_axim.araddr(10 downto 0),         -- in
      s_axi_arvalid  => rcnfig_from_axim.arvalid(0),        -- in
      s_axi_arready  => rcnfig_to_axim.arready(0),        -- out
      s_axi_rdata    => rcnfig_to_axim.rdata,          -- out
      s_axi_rresp    => rcnfig_to_axim.rresp,          -- out
      s_axi_rvalid   => rcnfig_to_axim.rvalid(0),         -- out
      s_axi_rready   => rcnfig_from_axim.rready(0)         -- in
         
      --psclk          => inst1_pll_scanclk,
      --psen           => inst2_pll_phasestep,
      --psincdec       => inst2_pll_phaseupdown,
      --psdone         => inst3_phasedone 
  );


end generate;

    pll_ps_top_inst2 :  pll_ps_top
       port map(
    
          clk                     => inst1_pll_scanclk,
          reset_n                 => dynps_areset_n_sync,
          --module control ports
          ps_en                   => dynps_en_sync,
          ps_mode                 => dynps_mode_sync,
          ps_tst                  => dynps_tst_sync, 
          ps_cnt                  => dynps_cnt_sel_sync,
          ps_updwn                => dynps_dir_sync,
          ps_phase                => dynps_phase_sync,
          ps_step_size            => dynps_step_size_sync,
          ps_busy                 => inst2_ps_busy,
          ps_done                 => inst2_ps_done,
          ps_status               => inst2_ps_status,
          --pll ports
          pll_phasecounterselect  => inst2_pll_phasecounterselect,
          pll_phaseupdown         => inst2_pll_phaseupdown, 
          pll_phasestep           => inst2_pll_phasestep,        
          pll_phasedone           => inst3_phasedone,      
          pll_locked              => inst3_locked_scanclk,
          pll_reconfig            => rcnfig_en_sync_scanclk,
          pll_reset_req           => inst2_pll_reset_req,
          --sample compare module
          smpl_cmp_en             => smpl_cmp_en,
          smpl_cmp_done           => smpl_cmp_done_sync,
          smpl_cmp_error          => smpl_cmp_error_sync
                
          );  
    
           
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
   
   
pll_reconfig_status_inst4 : entity work.pll_reconfig_status
   port map(
      clk               => inst1_pll_scanclk,
      reset_n           => pll_areset_n,
      reconfig_en       => rcnfig_en_sync_scanclk,
      scandone          => inst3_scandone,
      exclude_ps_status => '0',
      ps_en             => dynps_en_sync,
      ps_status         => inst2_ps_status,
      rcfig_complete    => inst4_rcfig_complete
      
      );   

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



   -- ----------------------------------------------------------------------------
   -- c0 clk MUX
   -- ----------------------------------------------------------------------------
   c0_mux <=   inst3_clk(0) when drct_clk_en(0)='0' else 
               drct_c0_dly_chain(drct_c0_ndly-1);

   -- ----------------------------------------------------------------------------
   -- c1 clk MUX
   -- ----------------------------------------------------------------------------
   c1_mux <=   inst3_clk(1) when drct_clk_en(1)='0' else 
               drct_c1_dly_chain(drct_c1_ndly-1);
end generate;

XILINX_PLL_DELAY : if vendor = "XILINX" generate

   -- ----------------------------------------------------------------------------
   -- c0 clk MUX
   -- ----------------------------------------------------------------------------
   --c0_mux <=   inst3_clk(0) when drct_clk_en(0)='0' else 
   --            pll_inclk; -- no delay
               
  --c0_mux <=   inst3_clk(0); -- no delay

   -- ----------------------------------------------------------------------------
   -- c1 clk MUX
   -- ----------------------------------------------------------------------------
   --c1_mux <=   inst3_clk(1) when drct_clk_en(1)='0' else 
   --            pll_inclk; -- no delay
 
   --c1_mux <=   inst3_clk(1);-- no delay        
end generate;

locked_mux <=  pll_areset_n when (drct_clk_en(0)='1' OR drct_clk_en(1)='1') else
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
   XILINX_PLL_DDIO  : ODDR
   generic map(
      DDR_CLK_EDGE => "SAME_EDGE", -- "OPPOSITE_EDGE" or "SAME_EDGE" 
      INIT => '0',   -- Initial value for Q port ('1' or '0')
      SRTYPE => "SYNC") -- Reset Type ("ASYNC" or "SYNC")
   port map (
      Q => inst5_dataout(0),   -- 1-bit DDR output
      C => inst3_clk(0),    -- 1-bit clock input
      CE => '1',  -- 1-bit clock enable input
      D1 => '1',  -- 1-bit data input (positive edge)
      D2 => '0',  -- 1-bit data input (negative edge)
      R => '0',    -- 1-bit reset input
      S => '0'     -- 1-bit set input
   );


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

--c0_global <= c0_mux;


--clkctrl_inst8 : BUFGCE_1 
--port map(
--   I    => c1_mux,
--   CE   => clk_ena(1),
--   O    => c1_global
--);


--c1_global <= c1_mux;
end generate;



-- ----------------------------------------------------------------------------
-- To output ports
-- ----------------------------------------------------------------------------
--c0           <= c0_global;
c0             <= inst5_dataout(0);
--c1           <= c1_global;
c1             <= inst3_clk(1);

pll_locked     <= locked_mux;
rcnfig_status  <= inst4_rcfig_complete;
dynps_done     <= inst2_ps_done;
dynps_status   <= inst2_ps_status;
busy           <= inst1_busy OR inst2_ps_status;
  
end arch;   





