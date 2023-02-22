-- ----------------------------------------------------------------------------	
-- FILE: tstcfg.vhd
-- DESCRIPTION: Serial interface with FPGA and testing info
-- DATE: Aug 22, 2016
-- AUTHOR(s): Lime Microsystems
-- REVISIONS: 
-- ----------------------------------------------------------------------------	

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.mem_package.all;
use work.tstcfg_pkg.all;


-- ----------------------------------------------------------------------------
-- Entity declaration
-- ----------------------------------------------------------------------------
entity tstcfg is
   port (
      -- Address and location of this module
      -- Will be hard wired at the top level
      maddress             : in std_logic_vector(9 downto 0);
      mimo_en              : in std_logic;   -- MIMO enable, from TOP SPI (always 1)
   
      -- Serial port IOs
      sdin                 : in std_logic;   -- Data in
      sclk                 : in std_logic;   -- Data clock
      sen                  : in std_logic;   -- Enable signal (active low)
      sdout                : out std_logic;  -- Data out
   
      -- Signals coming from the pins or top level serial interface
      lreset               : in std_logic;   -- Logic reset signal, resets logic cells only  (use only one reset)
      mreset               : in std_logic;   -- Memory reset signal, resets configuration memory only (use only one reset)
      
      oen                  : out std_logic;  --nc
      stateo               : out std_logic_vector(5 downto 0);
      
      to_tstcfg            : in t_TO_TSTCFG;
      from_tstcfg          : out t_FROM_TSTCFG

   );
end tstcfg;

-- ----------------------------------------------------------------------------
-- Architecture
-- ----------------------------------------------------------------------------
architecture arch of tstcfg is

   signal inst_reg: std_logic_vector(15 downto 0);    -- Instruction register
   signal inst_reg_en: std_logic;
   
   signal din_reg: std_logic_vector(15 downto 0);     -- Data in register
   signal din_reg_en: std_logic;
   
   signal dout_reg: std_logic_vector(15 downto 0);    -- Data out register
   signal dout_reg_sen, dout_reg_len: std_logic;
   
   signal mem: marray32x16;                           -- Config memory
   signal mem_we: std_logic;
   
   signal oe: std_logic;                              -- Tri state buffers control
   signal spi_config_data_rev	: std_logic_vector(143 downto 0);
   
   -- Components
   use work.mcfg_components.mcfg32wm_fsm;
   for all: mcfg32wm_fsm use entity work.mcfg32wm_fsm(mcfg32wm_fsm_arch);
   
   signal GW_TEST_RES : std_logic_vector(3 downto 0);

begin


   -- ---------------------------------------------------------------------------------------------
   -- Finite state machines
   -- ---------------------------------------------------------------------------------------------
   fsm: mcfg32wm_fsm port map( 
      address => maddress, mimo_en => mimo_en, inst_reg => inst_reg, sclk => sclk, sen => sen, reset => lreset,
      inst_reg_en => inst_reg_en, din_reg_en => din_reg_en, dout_reg_sen => dout_reg_sen,
      dout_reg_len => dout_reg_len, mem_we => mem_we, oe => oe, stateo => stateo);
      
   -- ---------------------------------------------------------------------------------------------
   -- Instruction register
   -- ---------------------------------------------------------------------------------------------
   inst_reg_proc: process(sclk, lreset)
      variable i: integer;
   begin
      if lreset = '0' then
         inst_reg <= (others => '0');
      elsif sclk'event and sclk = '1' then
         if inst_reg_en = '1' then
            for i in 15 downto 1 loop
               inst_reg(i) <= inst_reg(i-1);
            end loop;
            inst_reg(0) <= sdin;
         end if;
      end if;
   end process inst_reg_proc;

   -- ---------------------------------------------------------------------------------------------
   -- Data input register
   -- ---------------------------------------------------------------------------------------------
   din_reg_proc: process(sclk, lreset)
      variable i: integer;
   begin
      if lreset = '0' then
         din_reg <= (others => '0');
      elsif sclk'event and sclk = '1' then
         if din_reg_en = '1' then
            for i in 15 downto 1 loop
               din_reg(i) <= din_reg(i-1);
            end loop;
            din_reg(0) <= sdin;
         end if;
      end if;
   end process din_reg_proc;

   -- ---------------------------------------------------------------------------------------------
   -- Data output register
   -- ---------------------------------------------------------------------------------------------
   dout_reg_proc: process(sclk, lreset)
      variable i: integer;
   begin
      if lreset = '0' then
         dout_reg <= (others => '0');
      elsif sclk'event and sclk = '0' then
         -- Shift operation
         if dout_reg_sen = '1' then
            for i in 15 downto 1 loop
               dout_reg(i) <= dout_reg(i-1);
            end loop;
            dout_reg(0) <= dout_reg(15);
         -- Load operation
         elsif dout_reg_len = '1' then
            case inst_reg(4 downto 0) is	-- mux read-only outputs
               when "00000"  => dout_reg <= (15 downto 8 => '0') & GW_TEST_RES & mem(0)(3 downto 0);
               --
               when 5d"1"    => dout_reg <= to_tstcfg.TX_TS_BUF(0)(15 downto  0);
               when 5d"2"    => dout_reg <= to_tstcfg.TX_TS_BUF(0)(31 downto 16);
               when 5d"3"    => dout_reg <= to_tstcfg.TX_TS_BUF(0)(47 downto 32);
               when 5d"4"    => dout_reg <= to_tstcfg.TX_TS_BUF(0)(63 downto 48);
               --
               when 5d"5"    => dout_reg <= to_tstcfg.TX_TS_BUF(1)(15 downto  0);
               when 5d"6"    => dout_reg <= to_tstcfg.TX_TS_BUF(1)(31 downto 16);
               when 5d"7"    => dout_reg <= to_tstcfg.TX_TS_BUF(1)(47 downto 32);
               when 5d"8"    => dout_reg <= to_tstcfg.TX_TS_BUF(1)(63 downto 48);
               --
               when 5d"9"    => dout_reg <= to_tstcfg.TX_TS_BUF(2)(15 downto  0);
               when 5d"10"   => dout_reg <= to_tstcfg.TX_TS_BUF(2)(31 downto 16);
               when 5d"11"   => dout_reg <= to_tstcfg.TX_TS_BUF(2)(47 downto 32);
               when 5d"12"   => dout_reg <= to_tstcfg.TX_TS_BUF(2)(63 downto 48);
               --
               when 5d"13"   => dout_reg <= to_tstcfg.TX_TS_BUF(3)(15 downto  0);
               when 5d"14"   => dout_reg <= to_tstcfg.TX_TS_BUF(3)(31 downto 16);
               when 5d"15"   => dout_reg <= to_tstcfg.TX_TS_BUF(3)(47 downto 32);
               when 5d"16"   => dout_reg <= to_tstcfg.TX_TS_BUF(3)(63 downto 48);
               --
               when 5d"17"   => dout_reg <= to_tstcfg.TX_RX_TS(15 downto  0);
               when 5d"18"   => dout_reg <= to_tstcfg.TX_RX_TS(31 downto 16);
               when 5d"19"   => dout_reg <= to_tstcfg.TX_RX_TS(47 downto 32);
               when 5d"20"   => dout_reg <= to_tstcfg.TX_RX_TS(63 downto 48);
               --
               when 5d"21"   => dout_reg <= 8d"0" & to_tstcfg.TX_AVAIL_BUFS & to_tstcfg.crnt_buff_cnt;
               when others => dout_reg <= mem(to_integer(unsigned(inst_reg(4 downto 0))));
            end case;
         end if;  
      end if;
   end process dout_reg_proc;

   sdout <= dout_reg(15) and oe;
   oen <= oe;
   -- ---------------------------------------------------------------------------------------------
   -- Configuration memory
   -- --------------------------------------------------------------------------------------------- 
   ram: process(sclk, mreset) --(remap)
   begin
      -- Defaults
      if mreset = '0' then	 
         mem(0)   <= "0000000000000000"; --R/W  0 free, reserved[15:8],SPI_SIGN_REZ[7:4],SPI_SIGN[3:0]
         mem(1)   <= "0000000000000000"; --RD/W 0 free, reserved
         mem(2)   <= "0000000000000000"; --RD/W 0 free, reserved
         mem(3)   <= "0000000000000000"; --RD/W 0 free, reserved
         mem(4)   <= "0000000000000000"; --RD/W 0 free, reserved
         mem(5)   <= "0000000000000000"; --RD/W 0 free, reserved
         mem(6)   <= "0000000000000000"; --RD/W 0 free, reserved
         mem(7)   <= "0000000000000000"; --RD/W 0 free, reserved
         mem(8)   <= "0000000000000000"; --RD/W 0 free, reserved
         mem(9)   <= "0000000000000000"; --RD/W 0 free, reserved
         mem(10)  <= "0000000000000000"; --RD/W 0 free, reserved
         mem(11)  <= "0000000000000000"; --RD/W 0 free, reserved
         mem(12)  <= "0000000000000000"; --RD/W 0 free, reserved
         mem(13)  <= "0000000000000000"; --RD/W 0 free, reserved
         mem(14)  <= "0000000000000000"; --RD/W 0 free, reserved
         mem(15)  <= "0000000000000000"; --RD/W 0 free, reserved
         mem(16)  <= "0000000000000000"; --RD/W 0 free, reserved
         mem(17)  <= "0000000000000000"; --RD/W 0 free, reserved
         mem(18)  <= "0000000000000000"; --RD/W 0 free, reserved
         mem(19)  <= "0000000000000000"; --RD/W 0 free, reserved
         mem(20)  <= "0000000000000000"; --RD/W 0 free, reserved
         mem(21)  <= "0000000000000000"; --RD/W 0 free, reserved
         mem(22)  <= "0000000000000000"; --RD/W 0 free, reserved
         mem(23)  <= "0000000000000000"; --RD/W 0 free, reserved
         mem(24)  <= "0000000000000000"; --RD/W 0 free, reserved
         mem(25)  <= "0000000000000000"; --RD/W 0 free, reserved
         mem(26)  <= "0000000000000000"; --RD/W 0 free, reserved
         mem(27)  <= "0000000000000000"; --RD/W 0 free, reserved
         mem(28)  <= "0000000000000000"; --RD/W 0 free, reserved
         mem(29)  <= "1010101010101010"; --RD/W 0 free, TX_TST_I
         mem(30)  <= "0101010101010101"; --RD/W 0 free, TX_TST_Q
         mem(31)  <= "0000000000000000"; --RD/W 0 free, reserved
   
      elsif sclk'event and sclk = '1' then
         if mem_we = '1' then
            mem(to_integer(unsigned(inst_reg(4 downto 0)))) <= din_reg(14 downto 0) & sdin;
         end if;
         
         if dout_reg_len = '0' then
         
         end if;
            
      end if;
   end process ram;
   
   process(mem(0)(3 downto 0))
   begin 
      for_loop : for i in 0 to 3 loop  
         GW_TEST_RES(i) <= not mem(0)(i);
      end loop;
   end process;
   
   -- ---------------------------------------------------------------------------------------------
   -- Decoding logic
   -- ---------------------------------------------------------------------------------------------
   
   from_tstcfg.TX_TST_I      <= mem(29)(15 downto 0);
   from_tstcfg.TX_TST_Q      <= mem(30)(15 downto 0);



end arch;
