-- ----------------------------------------------------------------------------	
-- FILE:	spitx.vhd
-- DESCRIPTION:	Serial configuration interface to control TX modules
-- DATE:	2007.06.07
-- AUTHOR(s):	
-- REVISIONS:	
-- ----------------------------------------------------------------------------	

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.txtspcfg_pkg.ALL;
USE work.nr_mem_package.ALL;

-- ----------------------------------------------------------------------------
-- Entity declaration
-- ----------------------------------------------------------------------------
ENTITY txtspcfg IS
   PORT (
      -- Address and location of this module
      -- Will be hard wired at the top level
      maddress : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
      mimo_en : IN STD_LOGIC; -- MIMO enable, from TOP SPI

      -- Serial port IOs
      sdin : IN STD_LOGIC; -- Data in
      sclk : IN STD_LOGIC; -- Data clock
      sen : IN STD_LOGIC; -- Enable signal (active low)
      sdout : OUT STD_LOGIC; -- Data out

      -- Signals coming from the pins or top level serial interface
      lreset : IN STD_LOGIC; -- Logic reset signal, resets logic cells only
      mreset : IN STD_LOGIC; -- Memory reset signal, resets configuration memory only

      oen : OUT STD_LOGIC;
      stateo : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);

      to_txtspcfg : IN t_TO_TXTSPCFG;
      from_txtspcfg : OUT t_FROM_TXTSPCFG

   );
END txtspcfg;

-- ----------------------------------------------------------------------------
-- Architecture
-- ----------------------------------------------------------------------------
ARCHITECTURE txtspcfg_arch OF txtspcfg IS
   SIGNAL inst_reg : STD_LOGIC_VECTOR(15 DOWNTO 0); -- Instruction register
   SIGNAL inst_reg_en : STD_LOGIC;

   SIGNAL din_reg : STD_LOGIC_VECTOR(15 DOWNTO 0); -- Data in register
   SIGNAL din_reg_en : STD_LOGIC;

   SIGNAL dout_reg : STD_LOGIC_VECTOR(15 DOWNTO 0); -- Data out register
   SIGNAL dout_reg_sen, dout_reg_len : STD_LOGIC;

   SIGNAL mem : marray16x16; -- Config memory
   SIGNAL mem_we : STD_LOGIC;

   SIGNAL oe : STD_LOGIC; -- Tri state buffers control 

   -- Components
   USE work.mcfg_components.mcfg32wm_fsm;
   FOR ALL : mcfg32wm_fsm USE ENTITY work.mcfg32wm_fsm(mcfg32wm_fsm_arch);

BEGIN
   -- ---------------------------------------------------------------------------------------------
   -- Finite state machines
   -- ---------------------------------------------------------------------------------------------
   fsm : mcfg32wm_fsm PORT MAP(
      address => maddress, mimo_en => mimo_en, inst_reg => inst_reg, sclk => sclk, sen => sen, reset => lreset,
      inst_reg_en => inst_reg_en, din_reg_en => din_reg_en, dout_reg_sen => dout_reg_sen,
      dout_reg_len => dout_reg_len, mem_we => mem_we, oe => oe, stateo => stateo);

   -- ---------------------------------------------------------------------------------------------
   -- Instruction register
   -- ---------------------------------------------------------------------------------------------
   inst_reg_proc : PROCESS (sclk, lreset)
      VARIABLE i : INTEGER;
   BEGIN
      IF lreset = '0' THEN
         inst_reg <= (OTHERS => '0');
      ELSIF sclk'event AND sclk = '1' THEN
         IF inst_reg_en = '1' THEN
            FOR i IN 15 DOWNTO 1 LOOP
               inst_reg(i) <= inst_reg(i - 1);
            END LOOP;
            inst_reg(0) <= sdin;
         END IF;
      END IF;
   END PROCESS inst_reg_proc;

   -- ---------------------------------------------------------------------------------------------
   -- Data input register
   -- ---------------------------------------------------------------------------------------------
   din_reg_proc : PROCESS (sclk, lreset)
      VARIABLE i : INTEGER;
   BEGIN
      IF lreset = '0' THEN
         din_reg <= (OTHERS => '0');
      ELSIF sclk'event AND sclk = '1' THEN
         IF din_reg_en = '1' THEN
            FOR i IN 15 DOWNTO 1 LOOP
               din_reg(i) <= din_reg(i - 1);
            END LOOP;
            din_reg(0) <= sdin;
         END IF;
      END IF;
   END PROCESS din_reg_proc;

   -- ---------------------------------------------------------------------------------------------
   -- Data output register
   -- ---------------------------------------------------------------------------------------------
   dout_reg_proc : PROCESS (sclk, lreset)
      VARIABLE i : INTEGER;
   BEGIN
      IF lreset = '0' THEN
         dout_reg <= (OTHERS => '0');
      ELSIF sclk'event AND sclk = '0' THEN
         -- Shift operation
         IF dout_reg_sen = '1' THEN
            FOR i IN 15 DOWNTO 1 LOOP
               dout_reg(i) <= dout_reg(i - 1);
            END LOOP;
            dout_reg(0) <= dout_reg(15);
            -- Load operation
         ELSIF dout_reg_len = '1' THEN
            dout_reg <= mem(to_integer(unsigned(inst_reg(4 DOWNTO 0))));
         END IF;
      END IF;
   END PROCESS dout_reg_proc;

   -- Tri state buffer to connect multiple serial interfaces in parallel
   --sdout <= dout_reg(7) when oe = '1' else 'Z';

   -- sdout <= dout_reg(7);
   -- oen <= oe;

   sdout <= dout_reg(15) AND oe;
   oen <= oe;

   -- ---------------------------------------------------------------------------------------------
   -- Configuration memory
   -- --------------------------------------------------------------------------------------------- 
   ram : PROCESS (sclk, mreset)
   BEGIN
      -- Defaults
      IF mreset = '0' THEN
         mem(0) <= "0000000010000001"; --  6 free, UNUSED[5:0], TSGFC, TSGFCW[1:0], TSGDCLDQ, TSGDCLDI, TSGSWAPIQ, TSGMODE, INSEL, BSTART, EN
         mem(1) <= "0000011111111111"; --  5 free, UNUSED[4:0], gcorrQ[10:0]
         mem(2) <= "0000011111111111"; --  5 free, UNUSED[4:0], gcorrI[10:0]
         mem(3) <= "0000000000000000"; --  0 free, INSEL, HBI_OVR[2:0], IQcorr[11:0]
         mem(4) <= "0000000000000000"; --  dccorri
         mem(5) <= "0000000000000000"; --  dccorrq
         mem(6) <= "1111111111111111"; --  cfr_threshold
         mem(7) <= "0010000000000000"; --  cfr_gain
         mem(8) <= x"30FF"; --  various settings
         mem(9) <= "0000000000000000"; -- 16 free, UNUSED[15:0]
         mem(10) <= "0000000000000000"; -- 16 free, UNUSED[15:0]
         mem(11) <= "0000000000000000"; -- 16 free, UNUSED[15:0]
         mem(12) <= "0000000000000000"; -- 16 free, UNUSED[15:0]
         mem(13) <= "0000000000000000"; -- 16 free, UNUSED[15:0]
         --       mem(14)  <= "0000000000000000"; -- 16 free, UNUSED[15:0]
         --       mem(15)	<= "0000000000000000"; -- 16 free, UNUSED[15:0] 
         mem(14) <= x"0855"; --  0 free, TNCOF MSB --1MHz, When Fclk = 30.72MHz
         mem(15) <= x"5555"; --  0 free, TNCOF LSB
         --       mem(14)  <= x"042A"; --  0 free, TNCOF MSB --0.25MHz, When Fclk = 30.72MHz
         --       mem(15)  <= x"AAAB"; --  0 free, TNCOF LSB
      ELSIF sclk'event AND sclk = '1' THEN
         IF mem_we = '1' THEN
            mem(to_integer(unsigned(inst_reg(4 DOWNTO 0)))) <= din_reg(14 DOWNTO 0) & sdin;
         END IF;

         IF dout_reg_len = '0' THEN
            mem(9) <= to_txtspcfg.bsigi(14 DOWNTO 0) & to_txtspcfg.bstate;
            mem(10) <= to_txtspcfg.bsigq(7 DOWNTO 0) & to_txtspcfg.bsigi(22 DOWNTO 15);
            mem(11)(14 DOWNTO 0) <= to_txtspcfg.bsigq(22 DOWNTO 8);
         END IF;

      END IF;
   END PROCESS ram;

   -- ---------------------------------------------------------------------------------------------
   -- Decoding logic
   -- ---------------------------------------------------------------------------------------------
   --0x0
   from_txtspcfg.tsgfc <= mem(0)(9);
   from_txtspcfg.tsgfcw <= mem(0)(8 DOWNTO 7);
   from_txtspcfg.tsgdcldq <= mem(0)(6);
   from_txtspcfg.tsgdcldi <= mem(0)(5);
   from_txtspcfg.tsgswapiq <= mem(0)(4);
   from_txtspcfg.tsgmode <= mem(0)(3);
   from_txtspcfg.insel <= mem(0)(2);
   from_txtspcfg.bstart <= mem(0)(1);
   from_txtspcfg.en <= mem(0)(0) AND to_txtspcfg.txen;

   --0x1, 0x2
   from_txtspcfg.gcorrq <= mem(1)(10 DOWNTO 0);
   from_txtspcfg.gcorri <= mem(2)(10 DOWNTO 0);

   --0x3
   from_txtspcfg.iqcorr <= mem(3)(11 DOWNTO 0);

   --0x4, 0x5, B.J.
   from_txtspcfg.dccorri <= mem(4)(15 DOWNTO 0);
   from_txtspcfg.dccorrq <= mem(5)(15 DOWNTO 0);

   --0x6
   from_txtspcfg.cfr_threshold <= mem(6)(15 DOWNTO 0);

   --0x7
   from_txtspcfg.cfr_gain <= mem(7)(15 DOWNTO 0);

   --0x8
   from_txtspcfg.hbi_byp <= mem(8)(0); -- default 1
   from_txtspcfg.hbi_del <= mem(8)(1); -- default 1
   from_txtspcfg.cfr_sleep <= mem(8)(2); -- default 1
   from_txtspcfg.cfr_byp <= mem(8)(3); -- default 1
   from_txtspcfg.cfr_odd <= mem(8)(4); -- default 1
   from_txtspcfg.cfr_gain_byp <= mem(8)(5); -- default 1
   from_txtspcfg.fir_sleep <= mem(8)(6); -- default 1
   from_txtspcfg.fir_byp <= mem(8)(7); -- default 1

   from_txtspcfg.fir_odd <= mem(8)(8); -- default 0
   from_txtspcfg.ph_byp <= mem(8)(9); -- default 0
   from_txtspcfg.gc_byp <= mem(8)(10); -- default 0
   from_txtspcfg.dc_byp <= mem(8)(11); -- default 0
   from_txtspcfg.isinc_byp <= mem(8)(12); -- default 1
   from_txtspcfg.equaliser_byp <= mem(8)(13); -- default 1
   -- mem(8)(14); default 0
   from_txtspcfg.invertq <= mem(8)(15); -- default 0
   
   -- 0x9, 0xA, 0xB, 0xC
   -- Read only signatures
   from_txtspcfg.nco_fcv <= mem(14) & mem(15);

END txtspcfg_arch;
