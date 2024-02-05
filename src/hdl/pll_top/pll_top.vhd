-- ----------------------------------------------------------------------------
-- FILE:          pll_top.vhd
-- DESCRIPTION:   Top wrapper file for PLLs
-- DATE:          10:50 AM Wednesday, May 9, 2018
-- AUTHOR(s):     Lime Microsystems
-- REVISIONS:
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
--NOTES:
-- ----------------------------------------------------------------------------
-- altera vhdl_input_version vhdl_2008
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.pllcfg_pkg.all;
use work.axi_pkg.all;

-- ----------------------------------------------------------------------------
-- Entity declaration
-- ----------------------------------------------------------------------------
entity pll_top is
   generic(
      INTENDED_DEVICE_FAMILY     : STRING    := "Cyclone V GX";   --! Device family
      N_PLL                      : integer   := 2;                --! Number of PLLs
      -- TX pll parameters
      LMS1_TXPLL_DRCT_C0_NDLY    : integer   := 1; --! Direct TX clock delay (Obsolete)
      LMS1_TXPLL_DRCT_C1_NDLY    : integer   := 2; --! Direct TX clock delay (Obsolete)
      -- RX pll parameters
      LMS1_RXPLL_DRCT_C0_NDLY    : integer   := 1; --! Direct RX clock delay (Obsolete)
      LMS1_RXPLL_DRCT_C1_NDLY    : integer   := 2  --! Direct RX clock delay (Obsolete)

   );
   port (
      --! @virtualbus lms1_txpll LMS#1 TX PLL ports
      lms1_txpll_inclk              : in  std_logic;  --! TXPLL input clock
      lms1_txpll_reconfig_clk       : in  std_logic;  --! TXPLL reconfiguration clock
      lms1_txpll_logic_reset_n      : in  std_logic;  --! TXPLL logic active low reset
      lms1_txpll_clk_ena            : in  std_logic_vector(1 downto 0); --! TXPLL clock enable 
      lms1_txpll_drct_clk_en        : in  std_logic_vector(1 downto 0); --! TXPLL direct clock enable (Obsolete)
      lms1_txpll_c0                 : out std_logic;  --! TXPLL clock output c0
      lms1_txpll_c1                 : out std_logic;  --! TXPLL clock output c1
      lms1_txpll_locked             : out std_logic;  --! TXPLL locked output @end
      --! @virtualbus lms1_rxpll LMS#1 RX PLL ports
      lms1_rxpll_inclk              : in  std_logic;  --! RXPLL input clock
      lms1_rxpll_reconfig_clk       : in  std_logic;  --! RXPLL reconfiguration clock
      lms1_rxpll_logic_reset_n      : in  std_logic;  --! RXPLL logic active low reset
      lms1_rxpll_clk_ena            : in  std_logic_vector(1 downto 0); --! RXPLL clock enable 
      lms1_rxpll_drct_clk_en        : in  std_logic_vector(1 downto 0); --! RXPLL direct clock enable (Obsolete)
      lms1_rxpll_c0                 : out std_logic;  --! RXPLL clock output c0
      lms1_rxpll_c1                 : out std_logic;  --! RXPLL clock output c1
      lms1_rxpll_locked             : out std_logic;  --! RXPLL locked output @end
      -- Sample comparing ports from LMS#1 RX interface
      lms1_smpl_cmp_en              : out std_logic;  --! Sample compare enable
      lms1_smpl_cmp_done            : in  std_logic;  --! Sample compare done
      lms1_smpl_cmp_error           : in  std_logic;  --! Sample compare error
      lms1_smpl_cmp_cnt             : out std_logic_vector(15 downto 0); --! Number of samples to compare
      -- Reconfiguration AXI ports 
      rcnfg_axi_clk                 : in  std_logic;  --! AXI bus reconfiguration clock
      rcnfg_axi_reset_n             : in  std_logic;  --! AXI bus active low reset 
      rcnfg_from_axim               : in  t_FROM_AXIM_32x32; --! AXI bus inputs
      rcnfg_to_axim                 : out t_TO_AXIM_32x32;   --! AXI bus outputs
      rcnfg_sel                     : in  std_logic_vector(3 downto 0); --! Reconfiguration select
      -- pllcfg ports
      to_pllcfg                     : out t_TO_PLLCFG;   --! Output signals PLLCFG registers
      from_pllcfg                   : in  t_FROM_PLLCFG  --! Input signals from PLLCFG registers
      );
end pll_top;

-- ----------------------------------------------------------------------------
-- Architecture
-- ----------------------------------------------------------------------------
architecture arch of pll_top is
--declare signals,  components here
   signal lms1_txpll_inclk_g           : std_logic;
   signal lms1_rxpll_inclk_g           : std_logic;
   signal lms2_txpll_inclk_g           : std_logic;
   signal lms2_rxpll_inclk_g           : std_logic;

   --inst0
   signal inst0_pll_locked             : std_logic;
   signal inst0_smpl_cmp_en            : std_logic;
   signal inst0_busy                   : std_logic;
   signal inst0_dynps_done             : std_logic;
   signal inst0_dynps_status           : std_logic;
   signal inst0_rcnfig_status          : std_logic;
   signal inst0_rcnfg_mgmt_read        : std_logic;
   signal inst0_rcnfg_mgmt_write       : std_logic;
   signal inst0_rcnfg_mgmt_address     : std_logic_vector(5 downto 0);
   signal inst0_rcnfg_mgmt_writedata   : std_logic_vector(31 downto 0);
   signal inst0_rcnfig_from_axim       : t_FROM_AXIM_32x32;
   signal inst0_rcnfig_to_axim         : t_TO_AXIM_32x32;

   --inst1
   signal inst1_pll_locked             : std_logic;
   signal inst1_smpl_cmp_en            : std_logic;
   signal inst1_busy                   : std_logic;
   signal inst1_dynps_done             : std_logic;
   signal inst1_dynps_status           : std_logic;
   signal inst1_rcnfig_status          : std_logic;
   signal inst1_rcnfg_mgmt_read        : std_logic;
   signal inst1_rcnfg_mgmt_write       : std_logic;
   signal inst1_rcnfg_mgmt_address     : std_logic_vector(5 downto 0);
   signal inst1_rcnfg_mgmt_writedata   : std_logic_vector(31 downto 0);
   signal inst1_rcnfig_from_axim       : t_FROM_AXIM_32x32;
   signal inst1_rcnfig_to_axim         : t_TO_AXIM_32x32;
   
   --inst2
   signal inst4_pllcfg_busy            : std_logic_vector(N_PLL-1 downto 0);
   signal inst4_pllcfg_done            : std_logic_vector(N_PLL-1 downto 0);
   signal inst4_pll_lock               : std_logic_vector(N_PLL-1 downto 0);
   signal inst4_phcfg_start            : std_logic_vector(N_PLL-1 downto 0);
   signal inst4_pllcfg_start           : std_logic_vector(N_PLL-1 downto 0);
   signal inst4_pllrst_start           : std_logic_vector(N_PLL-1 downto 0);
   signal inst4_auto_phcfg_done        : std_logic_vector(N_PLL-1 downto 0);
   signal inst4_auto_phcfg_err         : std_logic_vector(N_PLL-1 downto 0);
   signal inst4_phcfg_mode             : std_logic;
   signal inst4_phcfg_tst              : std_logic;
   signal inst4_phcfg_updn             : std_logic;
   signal inst4_cnt_ind                : std_logic_vector(4 downto 0);
   signal inst4_cnt_phase              : std_logic_vector(15 downto 0);
   signal inst4_pllcfg_data            : std_logic_vector(143 downto 0);
   signal inst4_auto_phcfg_smpls       : std_logic_vector(15 downto 0);
   signal inst4_auto_phcfg_step        : std_logic_vector(15 downto 0);
   
   signal pllcfg_busy                  : std_logic;
   signal pllcfg_done                  : std_logic;
 
begin

----------------------------------------------------------------------------
-- Global clock control blocks
----------------------------------------------------------------------------   
   lms1_txpll_inclk_g <= lms1_txpll_inclk;
   lms1_rxpll_inclk_g <= lms1_rxpll_inclk;
-- ----------------------------------------------------------------------------
-- TX PLL instance for LMS#1
-- ----------------------------------------------------------------------------
   -- MUX for AXI bus 
   inst0_rcnfig_from_axim <= rcnfg_from_axim when rcnfg_sel = "0000" else c_FROM_AXIM_32x32_ZERO;
   


   inst0_tx_pll_top_cyc5 : entity work.tx_pll_top
   generic map(
      vendor                  => "XILINX", -- ALTERA or XILINX
      intended_device_family  => INTENDED_DEVICE_FAMILY,
      drct_c0_ndly            => LMS1_TXPLL_DRCT_C0_NDLY,
      drct_c1_ndly            => LMS1_TXPLL_DRCT_C1_NDLY,
      XIL_DIVCLK_DIVIDE      => 2,
      XIL_CLK_MULT           => 2,
      XIL_MMCM_PHASE         => 0.0,
      XIL_MMCM_PS_EN         => "FALSE"
   )
   port map(
   --PLL input    
   pll_inclk                  => lms1_txpll_inclk_g,
   pll_areset                 => inst4_pllrst_start(0),
   pll_logic_reset_n          => lms1_txpll_logic_reset_n,
   inv_c0                     => '0',
   c0                         => lms1_txpll_c0, --muxed clock output
   c1                         => lms1_txpll_c1, --muxed clock output
   
   pll_locked                 => inst0_pll_locked,
   --Bypass control
   clk_ena                    => lms1_txpll_clk_ena,       --clock output enable
   drct_clk_en                => lms1_txpll_drct_clk_en,   --1 - Direct clk, 0 - PLL clocks  
   --Reconfiguration ports
   rcnfg_clk                  => lms1_txpll_reconfig_clk,
   rcnfig_areset              => inst4_pllrst_start(0),
   rcnfg_axi_clk              => rcnfg_axi_clk,
   rcfig_axi_reset_n          => rcnfg_axi_reset_n,
   rcnfig_from_axim           => inst0_rcnfig_from_axim,
   rcnfig_to_axim             => inst0_rcnfig_to_axim,
   rcnfig_en                  => inst4_pllcfg_start(0),
   rcnfig_data                => inst4_pllcfg_data,
   rcnfig_status              => inst0_rcnfig_status,
   --Dynamic phase shift ports
   dynps_areset_n             => not inst4_pllrst_start(0),
   dynps_mode                 => inst4_phcfg_mode, -- 0 - manual, 1 - auto
   dynps_en                   => inst4_phcfg_start(0),
   dynps_tst                  => inst4_phcfg_tst,
   dynps_dir                  => inst4_phcfg_updn,
   dynps_cnt_sel              => inst4_cnt_ind(2 downto 0),
   -- max phase steps in auto mode, phase steps to shift in manual mode 
   dynps_phase                => inst4_cnt_phase(9 downto 0),
   dynps_step_size            => inst4_auto_phcfg_step(9 downto 0),
   dynps_busy                 => open,
   dynps_done                 => inst0_dynps_done,
   dynps_status               => inst0_dynps_status,
   --signals from sample compare module (required for automatic phase searching)
   smpl_cmp_en                => inst0_smpl_cmp_en,
   smpl_cmp_done              => lms1_smpl_cmp_done,
   smpl_cmp_error             => lms1_smpl_cmp_error,
   --Overall configuration PLL status
   busy                       => inst0_busy
--   from_pllcfg                => from_pllcfg
   );
   
-- ----------------------------------------------------------------------------
-- RX PLL instance for LMS#1
-- ----------------------------------------------------------------------------

-- MUX for AXI bus 
   inst1_rcnfig_from_axim <= rcnfg_from_axim when rcnfg_sel = "0001" else c_FROM_AXIM_32x32_ZERO;
   
   
   inst1_rx_pll_top_cyc5 : entity work.rx_pll_top
   generic map(
      vendor                  => "XILINX", -- ALTERA or XILINX
      intended_device_family  => INTENDED_DEVICE_FAMILY,
      drct_c0_ndly            => LMS1_RXPLL_DRCT_C0_NDLY,
      drct_c1_ndly            => LMS1_RXPLL_DRCT_C1_NDLY
   )
   port map(
   --PLL input
   pll_inclk                  => lms1_rxpll_inclk_g,
   pll_areset                 => inst4_pllrst_start(1),
   pll_logic_reset_n          => lms1_rxpll_logic_reset_n,
   inv_c0                     => '0',
   c0                         => lms1_rxpll_c0, --muxed clock output
   c1                         => lms1_rxpll_c1, --muxed clock output
   pll_locked                 => inst1_pll_locked,
   --Bypass control
   clk_ena                    => lms1_rxpll_clk_ena,       --clock output enable
   drct_clk_en                => lms1_rxpll_drct_clk_en,   --1 - Direct clk, 0 - PLL clocks 
   --Reconfiguration ports
   rcnfg_clk                  => lms1_rxpll_reconfig_clk,
   rcnfig_areset              => inst4_pllrst_start(1),
   rcnfg_axi_clk              => rcnfg_axi_clk,
   rcfig_axi_reset_n          => rcnfg_axi_reset_n,
   rcnfig_from_axim           => inst1_rcnfig_from_axim,
   rcnfig_to_axim             => inst1_rcnfig_to_axim,
   rcnfig_en                  => inst4_pllcfg_start(1),
   rcnfig_data                => inst4_pllcfg_data,
   rcnfig_status              => inst1_rcnfig_status,
   --Dynamic phase shift ports
   dynps_areset_n             => not inst4_pllrst_start(1),
   dynps_mode                 => inst4_phcfg_mode, -- 0 - manual, 1 - auto
   dynps_en                   => inst4_phcfg_start(1),
   dynps_tst                  => inst4_phcfg_tst,
   dynps_dir                  => inst4_phcfg_updn,
   dynps_cnt_sel              => inst4_cnt_ind(2 downto 0),
   -- max phase steps in auto mode, phase steps to shift in manual mode 
   dynps_phase                => inst4_cnt_phase(9 downto 0),
   dynps_step_size            => inst4_auto_phcfg_step(9 downto 0),
   dynps_busy                 => open,
   dynps_done                 => inst1_dynps_done,
   dynps_status               => inst1_dynps_status,
   --signals from sample compare module (required for automatic phase searching)
   smpl_cmp_en                => inst1_smpl_cmp_en,
   smpl_cmp_done              => lms1_smpl_cmp_done,
   smpl_cmp_error             => lms1_smpl_cmp_error,
   busy                       => inst1_busy
--   from_pllcfg                => from_pllcfg
   
   );
   
  
  rcnfg_to_axim <=   inst0_rcnfig_to_axim when rcnfg_sel = "0000" else 
                     inst1_rcnfig_to_axim when rcnfg_sel = "0001" else
                     c_TO_AXIM_32x32_ZERO;

                     
   pllcfg_busy <= inst1_busy OR inst0_busy;
   pllcfg_done <= not pllcfg_busy;
-- ----------------------------------------------------------------------------
-- pllcfg_top instance
-- ----------------------------------------------------------------------------
   inst4_pllcfg_busy     <= (0=>pllcfg_busy, others=>'0'); 
   inst4_pllcfg_done     <= (0=>pllcfg_done, others=>'1');
   inst4_pll_lock        <= (0=>inst0_pll_locked, 1=>inst1_pll_locked, others=>'0');
   inst4_auto_phcfg_done <= (0=>inst0_dynps_done, 1=>inst1_dynps_done, others=>'0');
   inst4_auto_phcfg_err  <= (0=>inst0_dynps_status, 1=>inst1_dynps_status, others=>'1');
     

--   inst4_pll_ctrl : entity work.pll_ctrl 
--   generic map(
--      n_pll	=> N_PLL
--   )
--   port map(
--      to_pllcfg         => to_pllcfg,
--      from_pllcfg       => from_pllcfg,
--         -- Status Inputs
--      pllcfg_busy       => inst4_pllcfg_busy,
--      pllcfg_done       => inst4_pllcfg_done,
--         -- PLL Lock flags
--      pll_lock          => inst4_pll_lock,
--         -- PLL Configuration Related
--      phcfg_mode        => inst4_phcfg_mode,
--      phcfg_tst         => inst4_phcfg_tst,
--      phcfg_start       => inst4_phcfg_start,   --
--      pllcfg_start      => inst4_pllcfg_start,  --
--      pllrst_start      => inst4_pllrst_start,  --
--      phcfg_updn        => inst4_phcfg_updn,
--      cnt_ind           => inst4_cnt_ind,       --
--      cnt_phase         => inst4_cnt_phase,     --
--      pllcfg_data       => inst4_pllcfg_data,
--      auto_phcfg_done   => inst4_auto_phcfg_done,
--      auto_phcfg_err    => inst4_auto_phcfg_err,
--      auto_phcfg_smpls  => inst4_auto_phcfg_smpls,
--      auto_phcfg_step   => inst4_auto_phcfg_step
        
--      );
-- ----------------------------------------------------------------------------
-- Output ports
-- ----------------------------------------------------------------------------  
lms1_txpll_locked    <= inst0_pll_locked;
lms1_rxpll_locked    <= inst1_pll_locked;
lms1_smpl_cmp_en     <= inst0_smpl_cmp_en OR inst1_smpl_cmp_en;
lms1_smpl_cmp_cnt    <= inst4_auto_phcfg_smpls;

end arch;   


