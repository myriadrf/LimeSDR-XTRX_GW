-- ----------------------------------------------------------------------------	
-- FILE:	fircfg.vhd
-- DESCRIPTION:	Serial configuration interface to control FIR filter
-- DATE:	Dec 31 2013
-- AUTHOR(s):	Lime Microsystems
-- REVISIONS:	
-- ----------------------------------------------------------------------------	

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.mem_package.ALL;
USE work.fircfg_pkg.ALL;
-- ----------------------------------------------------------------------------
-- Entity declaration
-- ----------------------------------------------------------------------------
ENTITY fircfg IS
   PORT (
      -- Address and location of this module
      -- These signals will be hard wired at the top level
      maddress : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
      mimo_en : IN STD_LOGIC; --

      -- Serial port A IOs
      sdin : IN STD_LOGIC; -- Data in
      sclk : IN STD_LOGIC; -- Data clock
      sen : IN STD_LOGIC; -- Enable signal (active low)
      sdout : OUT STD_LOGIC; -- Data out

      -- Signals coming from the pins or top level serial interface
      lreset : IN STD_LOGIC; -- Logic reset signal, resets logic cells only  (use only one reset)
      mreset : IN STD_LOGIC; -- Memory reset signal, resets configuration memory only (use only one reset)

      oen : OUT STD_LOGIC; --nc
      stateo : OUT STD_LOGIC_VECTOR(5 DOWNTO 0); -- MIMO/SISO identification. From PAD.

      from_fircfg : OUT t_FROM_FIRCFG
   );
END fircfg;

-- ----------------------------------------------------------------------------
-- Architecture
-- ----------------------------------------------------------------------------
ARCHITECTURE fircfg_arch OF fircfg IS
   SIGNAL inst_reg : STD_LOGIC_VECTOR(15 DOWNTO 0); -- Instruction register
   SIGNAL inst_reg_en : STD_LOGIC;

   SIGNAL din_reg : STD_LOGIC_VECTOR(15 DOWNTO 0); -- Data in register
   SIGNAL din_reg_en : STD_LOGIC;

   SIGNAL dout_reg : STD_LOGIC_VECTOR(15 DOWNTO 0); -- Data out register
   SIGNAL dout_reg_sen, dout_reg_len : STD_LOGIC;

   SIGNAL mem : marray32x16; -- Config memory
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
            CASE inst_reg(4 DOWNTO 0) IS -- mux read-only output
               WHEN OTHERS => dout_reg <= mem(to_integer(unsigned(inst_reg(4 DOWNTO 0))));
            END CASE;
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

         -- I coeffs
         mem(16#000#) <= "0111111111111111"; -- H0			
         mem(16#001#) <= "0000000000000000"; -- H1
         mem(16#002#) <= "0000000000000000"; -- H2
         mem(16#003#) <= "0000000000000000"; -- H3
         mem(16#004#) <= "0000000000000000"; -- H4
         mem(16#005#) <= "0000000000000000"; -- H5
         mem(16#006#) <= "0000000000000000"; -- H6
         mem(16#007#) <= "0000000000000000"; -- H7
         mem(16#008#) <= "0000000000000000"; -- H8
         mem(16#009#) <= "0000000000000000"; -- H9
         mem(16#00A#) <= "0000000000000000"; -- HA
         mem(16#00B#) <= "0000000000000000"; -- HB  
         mem(16#00C#) <= "0000000000000000"; -- HC
         mem(16#00D#) <= "0000000000000000"; -- HD
         mem(16#00E#) <= "0000000000000000"; -- HE
         mem(16#00F#) <= "0000000000000000"; -- HF

         -- Q coeffs
         mem(16#010#) <= "0111111111111111"; -- H10			
         mem(16#011#) <= "0000000000000000"; -- H11
         mem(16#012#) <= "0000000000000000"; -- H12
         mem(16#013#) <= "0000000000000000"; -- H13
         mem(16#014#) <= "0000000000000000"; -- H14
         mem(16#015#) <= "0000000000000000"; -- H15
         mem(16#016#) <= "0000000000000000"; -- H16
         mem(16#017#) <= "0000000000000000"; -- H17
         mem(16#018#) <= "0000000000000000"; -- H18
         mem(16#019#) <= "0000000000000000"; -- H19
         mem(16#01A#) <= "0000000000000000"; -- H1A
         mem(16#01B#) <= "0000000000000000"; -- H1B
         mem(16#01C#) <= "0000000000000000"; -- H1C
         mem(16#01D#) <= "0000000000000000"; -- H1D 
         mem(16#01E#) <= "0000000000000000"; -- H1E
         mem(16#01F#) <= "0000000000000000"; -- H1F 

         -- I coeffs
      ELSIF sclk'event AND sclk = '1' THEN
         IF mem_we = '1' THEN
            mem(to_integer(unsigned(inst_reg(4 DOWNTO 0)))) <= din_reg(14 DOWNTO 0) & sdin;
         END IF;
      END IF;
   END PROCESS ram;
   -- ---------------------------------------------------------------------------------------------
   -- Decoding logic
   -- ---------------------------------------------------------------------------------------------
   -- I coeffs
   from_fircfg.H0 <= mem(16#000#) & "00";
   from_fircfg.H1 <= mem(16#001#) & "00";
   from_fircfg.H2 <= mem(16#002#) & "00";
   from_fircfg.H3 <= mem(16#003#) & "00";
   from_fircfg.H4 <= mem(16#004#) & "00";
   from_fircfg.H5 <= mem(16#005#) & "00";
   from_fircfg.H6 <= mem(16#006#) & "00";
   from_fircfg.H7 <= mem(16#007#) & "00";
   from_fircfg.H8 <= mem(16#008#) & "00";
   from_fircfg.H9 <= mem(16#009#) & "00";
   from_fircfg.HA <= mem(16#00A#) & "00";
   from_fircfg.HB <= mem(16#00B#) & "00";
   from_fircfg.HC <= mem(16#00C#) & "00";
   from_fircfg.HD <= mem(16#00D#) & "00";
   from_fircfg.HE <= mem(16#00E#) & "00";
   from_fircfg.HF <= mem(16#00F#) & "00";

   -- Q coeffs
   from_fircfg.H10 <= mem(16#010#) & "00";
   from_fircfg.H11 <= mem(16#011#) & "00";
   from_fircfg.H12 <= mem(16#012#) & "00";
   from_fircfg.H13 <= mem(16#013#) & "00";
   from_fircfg.H14 <= mem(16#014#) & "00";
   from_fircfg.H15 <= mem(16#015#) & "00";
   from_fircfg.H16 <= mem(16#016#) & "00";
   from_fircfg.H17 <= mem(16#017#) & "00";
   from_fircfg.H18 <= mem(16#018#) & "00";
   from_fircfg.H19 <= mem(16#019#) & "00";
   from_fircfg.H1A <= mem(16#01A#) & "00";
   from_fircfg.H1B <= mem(16#01B#) & "00";
   from_fircfg.H1C <= mem(16#01C#) & "00";
   from_fircfg.H1D <= mem(16#01D#) & "00";
   from_fircfg.H1E <= mem(16#01E#) & "00";
   from_fircfg.H1F <= mem(16#01F#) & "00";

END fircfg_arch;