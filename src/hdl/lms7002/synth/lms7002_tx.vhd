-- ----------------------------------------------------------------------------
-- FILE:          lms7002_tx.vhd
-- DESCRIPTION:   Transmit interface for LMS7002 IC
-- DATE:          11:32 AM Friday, August 31, 2018
-- AUTHOR(s):     Lime Microsystems
-- REVISIONS:
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- NOTES:
-- 
-- ----------------------------------------------------------------------------
-- altera vhdl_input_version vhdl_2008
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.FIFO_PACK.all;
use work.fpgacfg_pkg.all;
use work.memcfg_pkg.all;

-- ----------------------------------------------------------------------------
-- Entity declaration
-- ----------------------------------------------------------------------------
entity lms7002_tx is
   generic( 
      g_DEV_FAMILY         : string := "Cyclone IV E";
      g_IQ_WIDTH           : integer := 12;
      g_SMPL_FIFO_0_WRUSEDW: integer := 9;
      g_SMPL_FIFO_0_DATAW  : integer := 128;  -- Must be multiple of four IQ samples, minimum four IQ samples
      g_SMPL_FIFO_1_WRUSEDW: integer := 9;
      g_SMPL_FIFO_1_DATAW  : integer := 128  -- Must be multiple of four IQ samples, minimum four IQ samples
      );
   port (
      clk                  : in  std_logic;
      reset_n              : in  std_logic;
      clk_2x               : in  std_logic;
      clk_2x_reset_n       : in  std_logic;      
      mem_reset_n          : in  std_logic;
      from_memcfg          : in  t_FROM_MEMCFG;
      from_fpgacfg         : in  t_FROM_FPGACFG;
      --Mode settings
      mode                 : in  std_logic; -- JESD207: 1; TRXIQ: 0
      trxiqpulse           : in  std_logic; -- trxiqpulse on: 1; trxiqpulse off: 0
      ddr_en               : in  std_logic; -- DDR: 1; SDR: 0
      mimo_en              : in  std_logic; -- SISO: 1; MIMO: 0
      ch_en                : in  std_logic_vector(1 downto 0); --"01" - Ch. A, "10" - Ch. B, "11" - Ch. A and Ch. B. 
      fidm                 : in  std_logic; -- Frame start at fsync = 0, when 0. Frame start at fsync = 1, when 1.
      --TX testing
      test_ptrn_en         : in  std_logic;
      test_ptrn_I          : in  std_logic_vector(15 downto 0);
      test_ptrn_Q          : in  std_logic_vector(15 downto 0);
      test_cnt_en          : in  std_logic;
      txant_cyc_before_en  : in  std_logic_vector(15 downto 0);
      txant_cyc_after_en   : in  std_logic_vector(15 downto 0);
      txant_en             : out std_logic;                 
      --Tx interface data 
      DIQ                  : out std_logic_vector(g_IQ_WIDTH-1 downto 0);
      fsync                : out std_logic;
      -- Source select
      tx_src_sel           : in std_logic;  -- 0 - FIFO_0 , 1 - FIFO_1
      --TX sample FIFO ports
      fifo_0_wrclk         : in  std_logic;
      fifo_0_reset_n       : in  std_logic;
      fifo_0_wrreq         : in  std_logic;
      fifo_0_data          : in  std_logic_vector(g_SMPL_FIFO_0_DATAW-1 downto 0);
      fifo_0_wrfull        : out std_logic;
      fifo_0_wrusedw       : out std_logic_vector(g_SMPL_FIFO_0_WRUSEDW-1 downto 0);
      fifo_1_wrclk         : in  std_logic;
      fifo_1_reset_n       : in  std_logic;
      fifo_1_wrreq         : in  std_logic;
      fifo_1_data          : in  std_logic_vector(g_SMPL_FIFO_0_DATAW-1 downto 0);
      fifo_1_wrfull        : out std_logic;
      fifo_1_wrusedw       : out std_logic_vector(g_SMPL_FIFO_0_WRUSEDW-1 downto 0);    
      -- SPI for internal modules
      sdin                 : in std_logic;   -- Data in
      sclk                 : in std_logic;   -- Data clock
      sen                  : in std_logic;   -- Enable signal (active low)
      sdout                : out std_logic := '0'  -- Data out
      );
end lms7002_tx;

-- ----------------------------------------------------------------------------
-- Architecture
-- ----------------------------------------------------------------------------
architecture arch of lms7002_tx is
--declare signals,  components here
--inst0
constant c_INST0_RDUSEDW   : integer := FIFORD_SIZE (g_SMPL_FIFO_0_DATAW, 64, g_SMPL_FIFO_0_WRUSEDW); 
signal inst0_q             : std_logic_vector(63 downto 0);
signal inst0_rdreq         : std_logic;
signal inst0_rdempty       : std_logic;
signal inst0_rdusedw       : std_logic_vector(c_INST0_RDUSEDW-1 downto 0);

--inst1
constant c_INST1_RDUSEDW   : integer := FIFORD_SIZE (g_SMPL_FIFO_1_DATAW, 64, g_SMPL_FIFO_1_WRUSEDW); 
signal inst1_q             : std_logic_vector(63 downto 0);
signal inst1_rdreq         : std_logic;
signal inst1_rdempty       : std_logic;
signal inst1_rdusedw       : std_logic_vector(c_INST1_RDUSEDW-1 downto 0);

--FIFO MUX
signal inst0_inst1_q_mux   : std_logic_vector(63 downto 0);

--inst2
signal inst2_diq_in        : std_logic_vector(63 downto 0);
signal inst2_diq_out       : std_logic_vector(63 downto 0);
signal inst2_data_req      : std_logic;
signal inst2_data_valid    : std_logic;

--inst3
signal inst3_wrfull        : std_logic;
signal inst3_q             : std_logic_vector(63 downto 0);
signal inst3_rdempty       : std_logic;
signal inst3_rdusedw       : std_logic_vector(c_INST0_RDUSEDW-1 downto 0);

--inst4
signal inst4_fifo_rdreq    : std_logic;
signal inst4_DIQ_h         : std_logic_vector(g_IQ_WIDTH downto 0);
signal inst4_DIQ_l         : std_logic_vector(g_IQ_WIDTH downto 0);
signal inst4_fifo_q        : std_logic_vector(g_IQ_WIDTH*4-1 downto 0);
signal inst4_rdempty       : std_logic;

--inst5 
signal inst5_diq_h         : std_logic_vector(g_IQ_WIDTH downto 0);
signal inst5_diq_l         : std_logic_vector(g_IQ_WIDTH downto 0);


 
begin

-- ----------------------------------------------------------------------------
-- FIFO for storing TX samples
-- ----------------------------------------------------------------------------
-- FIFO_0
   inst0_fifo_inst : entity work.fifo_inst
   generic map(
      dev_family     => g_DEV_FAMILY,
      wrwidth        => g_SMPL_FIFO_0_DATAW,
      wrusedw_witdth => g_SMPL_FIFO_0_WRUSEDW, 
      rdwidth        => 64,
      rdusedw_width  => c_INST0_RDUSEDW,
      show_ahead     => "OFF"
  ) 
   port map(
      reset_n  => fifo_0_reset_n,
      wrclk    => fifo_0_wrclk,
      wrreq    => fifo_0_wrreq,
      data     => fifo_0_data,
      wrfull   => fifo_0_wrfull,
      wrempty  => open,
      wrusedw  => fifo_0_wrusedw,
      rdclk    => clk,
      rdreq    => inst0_rdreq,
      q        => inst0_q,
      rdempty  => inst0_rdempty,
      rdusedw  => open --inst0_rdusedw  
   );
   
   inst0_rdreq <= inst4_fifo_rdreq AND (NOT tx_src_sel);
   
-- FIFO_1
   inst1_fifo_inst : entity work.fifo_inst
   generic map(
      dev_family     => g_DEV_FAMILY,
      wrwidth        => g_SMPL_FIFO_1_DATAW,
      wrusedw_witdth => g_SMPL_FIFO_1_WRUSEDW, 
      rdwidth        => 64,
      rdusedw_width  => c_INST1_RDUSEDW,
      show_ahead     => "OFF"
  ) 
   port map(
      reset_n  => fifo_1_reset_n,
      wrclk    => fifo_1_wrclk,
      wrreq    => fifo_1_wrreq,
      data     => fifo_1_data,
      wrfull   => fifo_1_wrfull,
      wrempty  => open,
      wrusedw  => fifo_1_wrusedw,
      rdclk    => clk,
      rdreq    => inst1_rdreq,
      q        => inst1_q,
      rdempty  => inst1_rdempty,
      rdusedw  => inst1_rdusedw  
   );   
   
   inst1_rdreq <= inst4_fifo_rdreq AND tx_src_sel;
   
-- ----------------------------------------------------------------------------
-- FIFO MUX
-- ----------------------------------------------------------------------------
   inst0_inst1_q_mux <= inst0_q when tx_src_sel = '0' else inst1_q;
       
-- ----------------------------------------------------------------------------
-- FIFO2DIQ module
-- ----------------------------------------------------------------------------
   inst4_rdempty<=   inst0_rdempty when tx_src_sel = '0' else inst1_rdempty;
   
   inst4_fifo_q <=   inst0_inst1_q_mux(63 downto 64-g_IQ_WIDTH) & 
                     inst0_inst1_q_mux(47 downto 48-g_IQ_WIDTH) &
                     inst0_inst1_q_mux(31 downto 32-g_IQ_WIDTH) & 
                     inst0_inst1_q_mux(15 downto 16-g_IQ_WIDTH);

   inst4_fifo2diq : entity work.fifo2diq
   generic map( 
      dev_family           => g_DEV_FAMILY,
      iq_width             => g_IQ_WIDTH
      )
   port map(
      clk                  => clk,
      reset_n              => reset_n,
      --Mode settings
      mode                 => mode, -- JESD207: 1; TRXIQ: 0
      trxiqpulse           => trxiqpulse, -- trxiqpulse on: 1; trxiqpulse off: 0
      ddr_en               => ddr_en, -- DDR: 1; SDR: 0
      mimo_en              => mimo_en, -- SISO: 1; MIMO: 0
      ch_en                => ch_en, --"01" - Ch. A, "10" - Ch. B, "11" - Ch. A and Ch. B. 
      fidm                 => fidm, -- External Frame ID mode. Frame start at fsync = 0, when 0. Frame start at fsync = 1, when 1.
      pct_sync_mode        => '0', -- 0 - timestamp, 1 - external pulse 
      pct_sync_pulse       => '0', -- external packet synchronisation pulse signal
      pct_sync_size        => (others=>'0'), -- valid in external pulse mode only
      pct_buff_rdy         => '0',
      --txant
      txant_cyc_before_en  => txant_cyc_before_en, -- valid in external pulse sync mode only
      txant_cyc_after_en   => txant_cyc_after_en, -- valid in external pulse sync mode only
      txant_en             => txant_en,                  
      --Tx interface data 
      DIQ                  => open,
      fsync                => open,
      DIQ_h                => inst4_DIQ_h, 
      DIQ_l                => inst4_DIQ_l, 
      --fifo ports 
      fifo_rdempty         => inst4_rdempty, 
      fifo_rdreq           => inst4_fifo_rdreq,
      fifo_q               => inst4_fifo_q
   );
   
-- ----------------------------------------------------------------------------
-- TX MUX
-- ----------------------------------------------------------------------------  
   inst5_txiqmux : entity work.txiqmux
   generic map(
      diq_width   => g_IQ_WIDTH
   )
   port map(
      clk               => clk,
      reset_n           => reset_n,
      test_ptrn_en      => test_ptrn_en,  -- Enables test pattern
      test_ptrn_fidm    => '0',           -- Frame start at fsync = 0, when 0. Frame start at fsync = 1, when 1.
      test_ptrn_I       => test_ptrn_I,
      test_ptrn_Q       => test_ptrn_Q,
      test_data_en      => test_cnt_en,
      test_data_mimo_en => '1',
      mux_sel           => '0',   -- Mux select: 0 - tx, 1 - wfm
      tx_diq_h          => inst4_DIQ_h,
      tx_diq_l          => inst4_DIQ_l,
      wfm_diq_h         => (others=>'0'),
      wfm_diq_l         => (others=>'0'),
      diq_h             => inst5_diq_h,
      diq_l             => inst5_diq_l
   );
   
-- ----------------------------------------------------------------------------
-- lms7002_ddout instance. Double data rate cells
-- ----------------------------------------------------------------------------     
   inst6_lms7002_ddout : entity work.lms7002_ddout
   generic map( 
      dev_family     => g_DEV_FAMILY,
      iq_width       => g_IQ_WIDTH
   )
   port map(
      from_fpgacfg   => from_fpgacfg,
      --input ports 
      clk            => clk,
      reset_n        => reset_n,
      data_in_h      => inst5_diq_h,
      data_in_l      => inst5_diq_l,
      --output ports 
      txiq           => DIQ,
      txiqsel        => fsync
   ); 
   
end arch;   


