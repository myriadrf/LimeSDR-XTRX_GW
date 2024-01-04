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

entity TSTCFG is
   port (
      -- Address and location of this module
      -- Will be hard wired at the top level
      MADDRESS             : in    std_logic_vector(9 downto 0);
      MIMO_EN              : in    std_logic;   -- MIMO enable, from TOP SPI (always 1)

      -- Serial port IOs
      SDIN                 : in    std_logic;   -- Data in
      SCLK                 : in    std_logic;   -- Data clock
      SEN                  : in    std_logic;   -- Enable signal (active low)
      SDOUT                : out   std_logic;   -- Data out

      -- Signals coming from the pins or top level serial interface
      LRESET               : in    std_logic;   -- Logic reset signal, resets logic cells only  (use only one reset)
      MRESET               : in    std_logic;   -- Memory reset signal, resets configuration memory only (use only one reset)

      OEN                  : out   std_logic;   -- nc
      STATEO               : out   std_logic_vector(5 downto 0);

      TO_TSTCFG            : in    t_TO_TSTCFG;
      FROM_TSTCFG          : out   t_FROM_TSTCFG
   );
end entity TSTCFG;

-- ----------------------------------------------------------------------------
-- Architecture
-- ----------------------------------------------------------------------------

architecture ARCH of TSTCFG is

   signal inst_reg                   : std_logic_vector(15 downto 0);          -- Instruction register
   signal inst_reg_en                : std_logic;

   signal din_reg                    : std_logic_vector(15 downto 0);          -- Data in register
   signal din_reg_en                 : std_logic;

   signal dout_reg                   : std_logic_vector(15 downto 0);          -- Data out register
   signal dout_reg_sen, dout_reg_len : std_logic;

   signal mem                        : marray32x16;                            -- Config memory
   signal mem_we                     : std_logic;

   signal oe                         : std_logic;                              -- Tri state buffers control
   signal spi_config_data_rev        : std_logic_vector(143 downto 0);

   -- Components
   use work.mcfg_components.mcfg32wm_fsm;
   for all: mcfg32wm_fsm use entity work.mcfg32wm_fsm(mcfg32wm_fsm_arch);

   signal gw_test_res                : std_logic_vector(3 downto 0);

begin

   -- ---------------------------------------------------------------------------------------------
   -- Finite state machines
   -- ---------------------------------------------------------------------------------------------
   FSM : MCFG32WM_FSM
      port map (
         ADDRESS      => MADDRESS,
         MIMO_EN      => MIMO_EN,
         INST_REG     => inst_reg,
         SCLK         => SCLK,
         SEN          => SEN,
         RESET        => LRESET,
         INST_REG_EN  => inst_reg_en,
         DIN_REG_EN   => din_reg_en,
         DOUT_REG_SEN => dout_reg_sen,
         DOUT_REG_LEN => dout_reg_len,
         MEM_WE       => mem_we,
         OE           => oe,
         STATEO       => STATEO
      );

   -- ---------------------------------------------------------------------------------------------
   -- Instruction register
   -- ---------------------------------------------------------------------------------------------
   INST_REG_PROC : process (SCLK, LRESET) is

      variable i : integer;

   begin

      if (LRESET = '0') then
         inst_reg <= (others => '0');
      elsif (SCLK'event and SCLK = '1') then
         if (inst_reg_en = '1') then

            for i in 15 downto 1 loop

               inst_reg(i) <= inst_reg(i - 1);

            end loop;

            inst_reg(0) <= SDIN;
         end if;
      end if;

   end process INST_REG_PROC;

   -- ---------------------------------------------------------------------------------------------
   -- Data input register
   -- ---------------------------------------------------------------------------------------------
   DIN_REG_PROC : process (SCLK, LRESET) is

      variable i : integer;

   begin

      if (LRESET = '0') then
         din_reg <= (others => '0');
      elsif (SCLK'event and SCLK = '1') then
         if (din_reg_en = '1') then

            for i in 15 downto 1 loop

               din_reg(i) <= din_reg(i - 1);

            end loop;

            din_reg(0) <= SDIN;
         end if;
      end if;

   end process DIN_REG_PROC;

   -- ---------------------------------------------------------------------------------------------
   -- Data output register
   -- ---------------------------------------------------------------------------------------------
   DOUT_REG_PROC : process (SCLK, LRESET) is

      variable i : integer;

   begin

      if (LRESET = '0') then
         dout_reg <= (others => '0');
      elsif (SCLK'event and SCLK = '0') then
         -- Shift operation
         if (dout_reg_sen = '1') then

            for i in 15 downto 1 loop

               dout_reg(i) <= dout_reg(i - 1);

            end loop;

            dout_reg(0) <= dout_reg(15);
         -- Load operation
         elsif (dout_reg_len = '1') then

            case inst_reg(4 downto 0) is  -- mux read-only outputs

               when "00000" =>
                  dout_reg <= (15 downto 8 => '0') & gw_test_res & mem(0)(3 downto 0);

               when "00101" =>
                  dout_reg <= (15 downto 6 => '0') & to_tstcfg.TEST_CMPLT(5 downto 0);

               when "00111" =>
                  dout_reg <= (15 downto 6 => '0') & to_tstcfg.TEST_REZ(5 downto 0);

               when "01001" =>
                  dout_reg <= to_tstcfg.SYS_CLK_CNT;

               when "10010" =>
                  dout_reg <= to_tstcfg.LMS_TX_CLK_cnt(15 downto 0);

               when "10011" =>
                  dout_reg <= (15 downto 8 => '0') & to_tstcfg.LMS_TX_CLK_cnt(23 downto 16);

               when others =>
                  dout_reg <= mem(to_integer(unsigned(inst_reg(4 downto 0))));

            end case;

         end if;
      end if;

   end process DOUT_REG_PROC;

   -- Tri state buffer to connect multiple serial interfaces in parallel
   -- sdout <= dout_reg(7) when oe = '1' else 'Z';

   -- sdout <= dout_reg(7);
   -- oen <= oe;

   SDOUT <= dout_reg(15) and oe;
   OEN   <= oe;
   -- ---------------------------------------------------------------------------------------------
   -- Configuration memory
   -- ---------------------------------------------------------------------------------------------
   RAM : process (SCLK, MRESET) is -- (remap)
   begin

      -- Defaults
      if (MRESET = '0') then
         mem(0)  <= "0000000000000000"; -- R/W  0 free, reserved[15:8],SPI_SIGN_REZ[7:4],SPI_SIGN[3:0]
         mem(1)  <= "0000000000000000"; -- R/W  0 free, reserved[15:6],DDR2_2_TST_EN,DDR2_1_TST_EN,ADF_TST_EN,VCTCXO_TST_EN,Si5351C_TST_EN,FX3_PCLK_TST_EN
         mem(2)  <= "0000000000000000"; -- RD   0 free, reserved
         mem(3)  <= "0000000000000000"; -- RD   0 free, reserved[15:6],DDR2_2_TST_FRC_ERR,DDR2_1_TST_FRC_ERR,ADF_TST_FRC_ERR,VCTCXO_TST_FRC_ERR,Si5351C_TST_FRC_ERR,FX3_PCLK_TST_FRC_ERR
         mem(4)  <= "0000000000000000"; -- RD   0 free, reserved
         mem(5)  <= "0000000000000000"; -- RD   0 free, reserved[15:6],DDR2_2_TST_CMPLT,DDR2_1_TST_CMPLT,ADF_TST_CMPLT,VCTCXO_TST_CMPLT,Si5351C_TST_CMPLT,FX3_PCLK_TST_CMPLT
         mem(6)  <= "0000000000000000"; -- RD   0 free, reserved
         mem(7)  <= "0000000000000000"; -- RD   0 free, reserved[15:6],DDR2_2_TST_REZ,DDR2_1_TST_REZ,ADF_TST_REZ,VCTCXO_TST_REZ,Si5351C_TST_REZ,FX3_PCLK_TST_REZ
         mem(8)  <= "0000000000000000"; -- RD   0 free, reserved
         mem(9)  <= "0000000000000000"; -- RD   0 free, SYS_CLK_CNT
         mem(10) <= "0000000000000000"; -- RD   0 free, reserved
         mem(11) <= "0000000000000000"; -- RD   0 free, reserved
         mem(12) <= "0000000000000000"; -- RD   0 free, reserved
         mem(13) <= "0000000000000000"; -- RD   0 free, reserved
         mem(14) <= "0000000000000000"; -- RD   0 free, reserved
         mem(15) <= "0000000000000000"; -- RD   0 free, reserved
         mem(16) <= "0000000000000000"; -- RD   0 free, reserved
         mem(17) <= "0000000000000000"; -- RD   0 free, reserved
         mem(18) <= "0000000000000000"; -- RD   0 free, ! LMS_TX_CLK_CNT[15:0]
         mem(19) <= "0000000000000000"; -- RD   0 free, LMS_TX_CLK_CNT[23:16]
         mem(20) <= "0000000000000000"; -- RD   0 free, reserved
         mem(21) <= "0000000000000000"; -- RD   0 free, reserved
         mem(22) <= "0000000000000000"; -- RD   0 free, Reserved
         mem(23) <= "0000000000000000"; -- RD   0 free, Reserved
         mem(24) <= "0000000000000000"; -- RD   0 free, Reserved
         mem(25) <= "0000000000000000"; -- RD/W 0 free, Reserved
         mem(26) <= "0000000000000000"; -- RD   0 free, Reserved
         mem(27) <= "0000000000000000"; -- RD   0 free, Reserved
         mem(28) <= "0000000000000000"; -- RD   0 free, Reserved
         mem(29) <= "1010101010101010"; -- RD/W 0 free, TX_TST_I
         mem(30) <= "0101010101010101"; -- RD/W 0 free, TX_TST_Q
         mem(31) <= "0000000000000000"; -- RD/W 0 free, Reserved
      elsif (SCLK'event and SCLK = '1') then
         if (mem_we = '1') then
            mem(to_integer(unsigned(inst_reg(4 downto 0)))) <= din_reg(14 downto 0) & SDIN;
         end if;

         if (dout_reg_len = '0') then
         end if;
      end if;

   end process RAM;

   process (mem(0)(3 downto 0)) is
   begin

      for_loop : for i in 0 to 3 loop

         gw_test_res(i) <= not mem(0)(i);

      end loop;

   end process;

   -- ---------------------------------------------------------------------------------------------
   -- Decoding logic
   -- ---------------------------------------------------------------------------------------------

   from_tstcfg.TEST_EN  <= mem(1)(5 downto 0);
   from_tstcfg.TX_TST_I <= mem(29)(15 downto 0);
   from_tstcfg.TX_TST_Q <= mem(30)(15 downto 0);

end architecture ARCH;
