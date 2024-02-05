-- ----------------------------------------------------------------------------
-- FILE:          rxtx_top.vhd
-- DESCRIPTION:   Top wrapper file for RX and TX components
-- DATE:          9:47 AM Thursday, May 10, 2018
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
use work.fpgacfg_pkg.all;
use work.memcfg_pkg.all;

-- ----------------------------------------------------------------------------
-- Entity declaration
-- ----------------------------------------------------------------------------
entity rxtx_top is
   generic(  
      index                        : integer := 1;             --! Module index, if more than one module exists in design
      DEV_FAMILY                   : string := "Cyclone IV E"; --! Device family
      TX_EN                        : boolean := true;          --! TX path enable
      RX_EN                        : boolean := true;          --! RX path enable
      -- TX parameters
      TX_IQ_WIDTH                  : integer := 12;      --! TX DIQ sample width
      TX_N_BUFF                    : integer := 4;       --! 2,4 valid values
      TX_IN_PCT_SIZE               : integer := 4096;    --! TX packet size in bytes
      TX_IN_PCT_HDR_SIZE           : integer := 16;      --! TX packet header size
      TX_IN_PCT_DATA_W             : integer := 128;     --! TX packet data width
      TX_IN_PCT_RDUSEDW_W          : integer := 11;      --! TX in packet read used word width
      TX_OUT_PCT_DATA_W            : integer := 64;      --! TX out packet data width
      TX_SMPL_FIFO_WRUSEDW_W       : integer := 9;       --! TX sample FIFO write used word size
      TX_HIGHSPEED_BUS             : boolean := false;   --! Double TX sample FIFO size to
      
      -- RX parameters
      RX_DATABUS_WIDTH             : integer := 64;      --! RX data width
      RX_IQ_WIDTH                  : integer := 12;      --! RX IQ sample width
      RX_INVERT_INPUT_CLOCKS       : string := "OFF";    --! RX input clock inversion
      RX_SMPL_BUFF_RDUSEDW_W       : integer := 11;      --! RX sample bus read used words width in bits 
      RX_PCT_BUFF_WRUSEDW_W        : integer := 12;      --! RX packet buffer write used words width in bits 
      RX_DISABLE_14B_SAMPLEPACKING : boolean := false    --! Disable RX sample packing in 14b words
      
   );
   port (
      sys_clk                 : in     std_logic;        --! System clock, freerunning
      -- Configuration memory ports     
      from_fpgacfg            : in     t_FROM_FPGACFG;   --! Signals from FPGACFG registers
      to_fpgacfg              : out    t_TO_FPGACFG;     --! Signals to FPGACFG register
      -- TX path
      tx_clk                  : in     std_logic;        --! TX path clock
      tx_clk_reset_n          : in     std_logic;        --! TX path active low reset
      tx_pct_loss_flg         : out    std_logic;        --! TX packet loss indication flag
         -- Tx interface data
      --! @virtualbus tx_smpl_fifo @dir out
      tx_smpl_fifo_wrreq      : out    std_logic;        --! Write request (data valid)
      tx_smpl_fifo_wrfull     : in     std_logic;        --! Write full
      tx_smpl_fifo_wrusedw    : in     std_logic_vector(TX_SMPL_FIFO_WRUSEDW_W-1 downto 0); --! Write used words
      tx_smpl_fifo_data       : out    std_logic_vector(127 downto 0);   --! Write data @end
         -- TX FIFO read ports
      --! @virtualbus tx_in_pct @dir in 
      tx_in_pct_reset_n_req   : out    std_logic;        --! Reset request
      tx_in_pct_rdreq         : out    std_logic;        --! Read request
      tx_in_pct_data          : in     std_logic_vector(TX_IN_PCT_DATA_W-1 downto 0); --! Packet data
      tx_in_pct_rdempty       : in     std_logic;        --! Read empty
      tx_in_pct_rdusedw       : in     std_logic_vector(TX_IN_PCT_RDUSEDW_W-1 downto 0); --! Read used words @end 
      -- RX path
      rx_clk                  : in     std_logic;        --! RX path clock
      rx_clk_reset_n          : in     std_logic;        --! RX path active low reset
         --RX Sample FIFO ports
      --! @virtualbus rx_smpl_fifo @dir in 
      rx_smpl_fifo_wrreq      : in     std_logic;        --! Write request 
      rx_smpl_fifo_data       : in     std_logic_vector(RX_IQ_WIDTH*4-1 downto 0); --! Data
      rx_smpl_fifo_wrfull     : out    std_logic;        --! Write full @end 
         --RX Packet FIFO ports
      --! @virtualbus rx_pct_fifo @dir out
      rx_pct_fifo_aclrn_req   : out    std_logic;        --! Asynchronous clear request
      rx_pct_fifo_wusedw      : in     std_logic_vector(RX_PCT_BUFF_WRUSEDW_W-1 downto 0);   --! Write used words
      rx_pct_fifo_wrreq       : out    std_logic;        --! Write request (data valid)
      rx_pct_fifo_wdata       : out    std_logic_vector(RX_DATABUS_WIDTH-1 downto 0); --! Data @end 
         -- RX sample nr count enable
      rx_smpl_nr_cnt_en       : in     std_logic;        --! RX path sample number count enable
      to_memcfg               : out    t_TO_MEMCFG;      --! Signals to MEMCFG registers 
      from_memcfg             : in     t_FROM_MEMCFG;    --! Signals from MEMCFG registers

      ext_rx_en               : in     std_logic;        --! External RX path enable
      tx_dma_en               : in     std_logic         --! TX DMA enble flag
      );
end rxtx_top;

-- ----------------------------------------------------------------------------
-- Architecture
-- ----------------------------------------------------------------------------
architecture arch of rxtx_top is
--declare signals,  components here
     
--inst0
signal tx_dma_en_sync            : std_logic;
signal inst0_reset_n_in          : std_logic;
signal inst0_reset_n             : std_logic;
signal inst0_fifo_wrreq          : std_logic;
signal inst0_fifo_data           : std_logic_vector(TX_IN_PCT_DATA_W-1 downto 0);

signal inst0_tx_fifo_wr          : std_logic;
signal inst0_tx_fifo_data        : std_logic_vector(TX_IN_PCT_DATA_W-1 downto 0);
signal inst0_wfm_data            : std_logic_vector(31 downto 0);
signal inst0_wfm_fifo_wr         : std_logic;

--inst1
signal inst1_reset_n             : std_logic;
signal inst1_DIQ_h               : std_logic_vector(TX_IQ_WIDTH downto 0);
signal inst1_DIQ_l               : std_logic_vector(TX_IQ_WIDTH downto 0);
signal inst1_in_pct_full         : std_logic;
signal inst1_pct_loss_flg        : std_logic;
--signal inst1_in_pct_rdy          : std_logic;
signal inst1_in_pct_reset_n_req  : std_logic;

--inst2
signal inst2_dd_iq_h             : std_logic_vector(15 downto 0);
signal inst2_dd_iq_l             : std_logic_vector(15 downto 0);

--inst3
signal inst3_diq_h               : std_logic_vector(TX_IQ_WIDTH downto 0);
signal inst3_diq_l               : std_logic_vector(TX_IQ_WIDTH downto 0);

--inst5
signal inst5_reset_n             : std_logic;
signal inst5_smpl_nr_cnt         : std_logic_vector(63 downto 0);
signal inst5_pct_hdr_cap         : std_logic;

--inst6
signal inst6_reset_n             : std_logic;
signal inst6_pulse               : std_logic;

signal pct_counter               : std_logic_vector(31 downto 0);
signal pct_drop_counter          : std_logic_vector(31 downto 0);

signal pct_counter_sync          : std_logic_vector(31 downto 0);
signal pct_drop_counter_sync     : std_logic_vector(31 downto 0);

signal pct_counter_rst           : std_logic;
signal pct_drop_rst              : std_logic;

signal pct_loss_pulse            : std_logic; 
signal pct_loss_pulse_reg        : std_logic;

signal rx_pct_size               : std_logic_vector(15 downto 0);
signal rx_pct_size_smpls         : std_logic_vector(15 downto 0);

    -- attribute MARK_DEBUG : string;
    -- attribute MARK_DEBUG of pct_counter_sync : signal is "TRUE";
    -- attribute MARK_DEBUG of pct_drop_counter_sync : signal is "TRUE";
--    attribute MARK_DEBUG of pct_counter_rst : signal is "TRUE";
--    attribute MARK_DEBUG of pct_drop_rst : signal is "TRUE";
    -- attribute MARK_DEBUG of pct_loss_pulse : signal is "TRUE";
    -- attribute MARK_DEBUG of pct_loss_pulse_reg : signal is "TRUE";

begin

    rx_pct_size       <= from_fpgacfg.RX_PACKET_SIZE;
    rx_pct_size_smpls <= from_fpgacfg.RX_PACKET_SAMPLES;

    pct_loss_counter_proc : process(all)
    begin
        if rising_edge(tx_clk) then
            pct_loss_pulse_reg <= pct_loss_pulse;
            if (pct_drop_rst = '1' ) then
                pct_drop_counter <= (others => '0');
            elsif (pct_loss_pulse = '1' and pct_loss_pulse_reg = '0') then
                pct_drop_counter <= std_logic_vector(unsigned(pct_drop_counter) +1);
            end if;        
        end if;    
    end process;

    comp_bus_sync_reg0 : entity work.bus_sync_reg
      generic map (
                   bus_width => 32
   )
      port map (
                clk      => sys_clk,
                reset_n  => '1',
                async_in => pct_counter,
                sync_out => pct_counter_sync
   );
   comp_bus_sync_reg1 : entity work.bus_sync_reg
      generic map (
                   bus_width => 32
   )
      port map (
                clk      => sys_clk,
                reset_n  => '1',
                async_in => pct_drop_counter,
                sync_out => pct_drop_counter_sync
   );
   
   g_index1 : if index = 1 generate
    to_memcfg.LMS1_tx_pct_cnt <= pct_counter_sync;
    to_memcfg.LMS1_tx_drp_cnt <= pct_drop_counter_sync;
    pct_counter_rst           <= from_memcfg.LMS1_tx_pct_rst;  
    pct_drop_rst              <= from_memcfg.LMS1_tx_drp_rst;
   end generate;
   g_index2 : if index = 2 generate
    to_memcfg.LMS2_tx_pct_cnt <= pct_counter_sync;
    to_memcfg.LMS2_tx_drp_cnt <= pct_drop_counter_sync;
    pct_counter_rst           <= from_memcfg.LMS2_tx_pct_rst;  
    pct_drop_rst              <= from_memcfg.LMS2_tx_drp_rst;
   end generate;
   g_index3 : if index = 3 generate
    pct_counter_rst <= '1';
    pct_drop_rst    <= '1';
   end generate;

 
        --If ext_rx_en is enabled, use TX when pcie_dma is enabled, otherwise use rx_en
    inst0_reset_n_in <= from_fpgacfg.rx_en when ext_rx_en = '0' else tx_dma_en;  
   -- Reset signal for inst0 with synchronous removal to tx_pct_clk clock domain, 
   sync_reg0_0 : entity work.sync_reg 
   port map(tx_clk, inst0_reset_n_in, '1', inst0_reset_n);  -- B.J.
   
   sync_reg0_1 : entity work.sync_reg 
   port map(tx_clk, tx_dma_en, '1', tx_dma_en_sync);  -- B.J.
   
   -- RX reset
   sync_reg0_2 : entity work.sync_reg 
   port map(tx_clk, from_fpgacfg.rx_en , '1', inst5_reset_n);  -- B.J.
   
   -- TX resets
   tx_in_pct_reset_n_req   <= inst0_reset_n;-- AND inst1_in_pct_reset_n_req;   
   inst1_reset_n           <= inst0_reset_n;--inst0_reset_n and tx_dma_en_sync;
   inst6_reset_n           <= inst0_reset_n;  
   
   -- Reset signal for inst0 with synchronous removal to rx_clk clock domain, 
   sync_reg1 : entity work.sync_reg 
   port map(rx_clk, inst0_reset_n, '1', rx_pct_fifo_aclrn_req);
     
-- ----------------------------------------------------------------------------
-- tx_path_top instance.
-- 
-- ----------------------------------------------------------------------------
--   process(tx_clk, inst1_reset_n)
--      begin
--      if inst1_reset_n = '0' then 
--         inst1_in_pct_rdy <= '0';
--      elsif (tx_clk'event AND tx_clk='1') then 
--         if unsigned(tx_in_pct_rdusedw) < (TX_IN_PCT_SIZE*8)/TX_IN_PCT_DATA_W then 
--            inst1_in_pct_rdy <= '0';
--         else 
--            inst1_in_pct_rdy <= '1';
--         end if;
--      end if;
--   end process;

TX_gen0 : if TX_EN = true generate
   tx_path_top_inst1 : entity work.tx_path_top
   generic map( 
      g_DEV_FAMILY         => DEV_FAMILY,
      g_IQ_WIDTH           => TX_IQ_WIDTH,
      g_PCT_MAX_SIZE       => TX_IN_PCT_SIZE,
      g_PCT_HDR_SIZE       => TX_IN_PCT_HDR_SIZE,
      g_BUFF_COUNT         => TX_N_BUFF,
      g_FIFO_DATA_W        => TX_IN_PCT_DATA_W,
      g_DOUBLE_BUS         => TX_HIGHSPEED_BUS,
      decomp_fifo_size     => 9
      )
   port map(
      sys_clk              => sys_clk,
      pct_wrclk            => tx_clk,
      iq_rdclk             => tx_clk,
      reset_n              => inst1_reset_n,
      en                   => inst1_reset_n,
      
      rx_sample_clk        => rx_clk,
      rx_sample_nr         => inst5_smpl_nr_cnt,
      
      pct_sync_mode        => from_fpgacfg.synch_mode,
      pct_sync_dis         => from_fpgacfg.synch_dis,
      pct_sync_pulse       => inst6_pulse,
      pct_sync_size        => (others => '0'),--from_fpgacfg.sync_size,
            
      pct_loss_flg         => inst1_pct_loss_flg,
      pct_loss_flg_clr     => inst5_pct_hdr_cap, --from_fpgacfg.txpct_loss_clr
      
      --Mode settings
      mode                 => from_fpgacfg.mode,       -- JESD207: 1; TRXIQ: 0
      trxiqpulse           => from_fpgacfg.trxiq_pulse, -- trxiqpulse on: 1; trxiqpulse off: 0
      ddr_en               => from_fpgacfg.ddr_en,     -- DDR: 1; SDR: 0
      mimo_en              => from_fpgacfg.mimo_int_en,    -- SISO: 1; MIMO: 0
      ch_en                => from_fpgacfg.ch_en(1 downto 0),      --"01" - Ch. A, "10" - Ch. B, "11" - Ch. A and Ch. B. 
      fidm                 => '0',       -- Frame start at fsync = 0, when 0. Frame start at fsync = 1, when 1.
      sample_width         => from_fpgacfg.smpl_width, --"10"-12bit, "01"-14bit, "00"-16bit;
      --Tx interface data
      smpl_fifo_wrreq      => tx_smpl_fifo_wrreq,
      smpl_fifo_wrfull     => tx_smpl_fifo_wrfull,
      smpl_fifo_wrusedw    => tx_smpl_fifo_wrusedw,
      smpl_fifo_data       => tx_smpl_fifo_data,
      --fifo ports
      in_pct_rdreq         => tx_in_pct_rdreq,
      in_pct_data          => tx_in_pct_data,
      in_pct_rdempty       => tx_in_pct_rdempty,
      pct_counter          => pct_counter    ,
      pct_counter_rst      => pct_counter_rst,
      pct_loss_pulse       => pct_loss_pulse
      );
      
-- ----------------------------------------------------------------------------
-- pulse_gen instance instance.
-- 
-- ----------------------------------------------------------------------------   
   pulse_gen_inst6 : entity work.pulse_gen
      port map(
      clk         => tx_clk,
      reset_n     => inst6_reset_n,
      wait_cycles => from_fpgacfg.sync_pulse_period,
      pulse       => inst6_pulse
   );
   
end generate;
      
-- ----------------------------------------------------------------------------
-- rx_path_top instance instance.
-- 
-- ----------------------------------------------------------------------------   
RX_gen0 : if RX_EN = true generate
   rx_path_top_inst5 : entity work.rx_path_top
   generic map( 
      dev_family           => DEV_FAMILY,
      iq_width             => RX_IQ_WIDTH,
      invert_input_clocks  => RX_INVERT_INPUT_CLOCKS,
      smpl_buff_rdusedw_w  => 11, 
      pct_buff_wrusedw_w   => RX_PCT_BUFF_WRUSEDW_W,
      outbus_width         => RX_DATABUS_WIDTH,
      G_DISABLE_14BIT      => RX_DISABLE_14B_SAMPLEPACKING -- generic to disable generating 14bit sample packing modules
   )
   port map(
      clk                  => rx_clk,
      reset_n              => inst5_reset_n,
      test_ptrn_en         => from_fpgacfg.rx_ptrn_en,
      --Mode settings
      sample_width         => from_fpgacfg.smpl_width, --"10"-12bit, "01"-14bit, "00"-16bit;
      mode                 => from_fpgacfg.mode,       -- JESD207: 1; TRXIQ: 0
      trxiqpulse           => from_fpgacfg.trxiq_pulse, -- trxiqpulse on: 1; trxiqpulse off: 0
      ddr_en               => from_fpgacfg.ddr_en,     -- DDR: 1; SDR: 0
      mimo_en              => from_fpgacfg.mimo_int_en,    -- SISO: 1; MIMO: 0
      ch_en                => from_fpgacfg.ch_en(1 downto 0),      --"01" - Ch. A, "10" - Ch. B, "11" - Ch. A and Ch. B. 
      fidm                 => '0',       -- Frame start at fsync = 0, when 0. Frame start at fsync = 1, when 1.
      --Rx interface data
      smpl_fifo_wrreq      => rx_smpl_fifo_wrreq,
      smpl_fifo_data       => rx_smpl_fifo_data,
      smpl_fifo_wrfull     => rx_smpl_fifo_wrfull,
      rx_pct_size          => rx_pct_size,
      rx_pct_size_smpls    => rx_pct_size_smpls,
      --Packet fifo ports 
      pct_fifo_wusedw      => rx_pct_fifo_wusedw,
      pct_fifo_wrreq       => rx_pct_fifo_wrreq,
      pct_fifo_wdata       => rx_pct_fifo_wdata,
      pct_hdr_cap          => inst5_pct_hdr_cap,
      --sample nr
      clr_smpl_nr          => from_fpgacfg.smpl_nr_clr,
      ld_smpl_nr           => '0',
      smpl_nr_in           => (others=>'0'),
      smpl_nr_cnt          => inst5_smpl_nr_cnt,
      smpl_nr_cnt_en       => rx_smpl_nr_cnt_en,
      --flag control
      tx_pct_loss          => inst1_pct_loss_flg,
      tx_pct_loss_clr      => from_fpgacfg.txpct_loss_clr
   );
end generate;
     
  
end arch;   


