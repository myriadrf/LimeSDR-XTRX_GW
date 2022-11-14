-- ----------------------------------------------------------------------------	
-- FILE:	fpgacfg.vhd
-- DESCRIPTION:	Serial configuration interface to control TX modules
-- DATE:	June 07, 2007
-- AUTHOR(s):	Lime Microsystems
-- REVISIONS:
-- ----------------------------------------------------------------------------	

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.mem_package.all;


-- ----------------------------------------------------------------------------
-- Entity declaration
-- ----------------------------------------------------------------------------
entity adpdcfg is
	port (
		maddress	: in std_logic_vector(9 downto 0);
		mimo_en	: in std_logic;	
		sdin	: in std_logic; 
		sclk	: in std_logic; 
		sen	: in std_logic;	
		sdout	: out std_logic; 
		lreset	: in std_logic; 	
		mreset	: in std_logic; 		
		oen: out std_logic; 
		stateo: out std_logic_vector(5 downto 0);		
		ADPD_BUFF_SIZE 	: out std_logic_vector(15 downto 0);
		ADPD_CONT_CAP_EN	: out std_logic;
		ADPD_CAP_EN, ADPD_CAP_RESETN: out std_logic;		
		adpd_config0, adpd_config1, adpd_data: out std_logic_vector(15 downto 0);
		-- CFR
		cfr0_bypass, cfr0_sleep, cfr1_bypass, cfr1_sleep, cfr0_odd, cfr1_odd : OUT STD_LOGIC;
		cfr0_interpolation, cfr1_interpolation : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
		cfr0_threshold, cfr1_threshold: out std_logic_vector(15 downto 0);
		cfr0_order, cfr1_order : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		-- CFR GAIN
		gain_cfr0, gain_cfr1 : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		gain_cfr0_bypass, gain_cfr1_bypass : OUT STD_LOGIC;		
	    -- HB
	    hb0_delay, hb1_delay : OUT STD_LOGIC;
	    -- FIR
	    gfir0_byp, gfir0_sleep, gfir0_odd, gfir1_byp, gfir1_sleep, gfir1_odd : OUT STD_LOGIC;
		
		PAEN0, PAEN1, DCEN0, DCEN1, reset_n_soft : OUT STD_LOGIC;
		rf_sw : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
		
		tx_en, capture_en, lms3_monitoring, fix_mimo, dpdtop_en: out std_logic
	);
end adpdcfg;

-- ----------------------------------------------------------------------------
-- Architecture
-- ----------------------------------------------------------------------------
architecture adpdcfg_arch of adpdcfg is

	signal inst_reg: std_logic_vector(15 downto 0);		-- Instruction register
	signal inst_reg_en: std_logic;

	signal din_reg: std_logic_vector(15 downto 0);		-- Data in register
	signal din_reg_en: std_logic;
	
	signal dout_reg: std_logic_vector(15 downto 0);		-- Data out register
	signal dout_reg_sen, dout_reg_len: std_logic;
	
	signal mem: marray32x16;									-- Config memory
	signal mem_we: std_logic;
	
	signal oe: std_logic;										-- Tri state buffers control
	signal spi_config_data_rev	: std_logic_vector(143 downto 0);
	
	-- Components
	use work.mcfg_components.mcfg32wm_fsm;
	for all: mcfg32wm_fsm use entity work.mcfg32wm_fsm(mcfg32wm_fsm_arch);

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
					when others  => dout_reg <= mem(to_integer(unsigned(inst_reg(4 downto 0))));
				end case;
			end if;			      
		end if;
	end process dout_reg_proc;
	
	-- Tri state buffer to connect multiple serial interfaces in parallel
	--sdout <= dout_reg(7) when oe = '1' else 'Z';

--	sdout <= dout_reg(7);
--	oen <= oe;

	sdout <= dout_reg(15) and oe;
	oen <= oe;
	-- ---------------------------------------------------------------------------------------------
	-- Configuration memory
	-- --------------------------------------------------------------------------------------------- 
	ram: process(sclk, mreset) --(remap)
	begin
		-- Defaults
		if mreset = '0' then	
			--Read only registers
			mem(0)	<= "0100000000000000"; -- ADPD_BUFF_SIZE
			mem(1)  <= "0000100000100000"; -- 9 free, rf_sw(2:0),PAEN1,PAEN0,ADPD_CONT_CAP_EN,ADPD_CAP_EN
			mem(2)	<= "0000000000000000"; -- adpd_config0(15:0) 
			mem(3)	<= "0000000000000000"; -- adpd_config1(15:0)
			mem(4)	<= "0000000000000000"; -- adpd_data(15:0)
			mem(5)  <= "1110111011101110"; -- various CHB, CHA settings
			mem(6)  <= "1111111111111111"; -- cfr0_threshold
			mem(7)  <= "1111111111111111"; -- cfr1_threshold
			mem(8)  <= "0010000000000000"; -- gain_cfr0 [-4..4]
			mem(9)  <= "0010000000000000"; -- gain_cfr1	[-4..4]			
			
			mem(10)	<= "0000000000000000"; -- 16 free, 
			mem(11)	<= "0000000000000000"; -- 16 free, 
			mem(12)	<= "0000000000000000"; -- 16 free, 
			mem(13)	<= "0000000000000000"; -- 16 free, 
			mem(14)	<= "0000000000000000"; -- 16 free, 
			mem(15)	<= "0000000000000000"; -- 16 free, 
			mem(16)	<= "0000000000000000"; -- 16 free, 
			mem(17)	<= "0000000000000000"; -- 16 free,
			mem(18) <= "0000000000000000"; -- 16 free, 
			mem(19)	<= "0000000000000000"; -- 16 free, 
			mem(20)	<= "0000000000000000"; -- 16 free, 
			mem(21)	<= "0000000000000000"; -- 16 free, 
			mem(22)	<= "0000000000000000"; -- 16 free, 
			mem(23)	<= "0000000000000000"; -- 16 free, 		

		elsif sclk'event and sclk = '1' then
				if mem_we = '1' then
					mem(to_integer(unsigned(inst_reg(4 downto 0)))) <= din_reg(14 downto 0) & sdin;
				end if;
				
				if dout_reg_len = '0' then
				end if;
				
		end if;
	end process ram;
	
	-- ---------------------------------------------------------------------------------------------
	-- Decoding logic
	-- ---------------------------------------------------------------------------------------------
		ADPD_BUFF_SIZE 	<= mem(0); 		
		ADPD_CAP_EN			<= mem(1)(0);
		ADPD_CONT_CAP_EN	<= mem(1)(1);

		PAEN0 <= mem(1)(2); -- PA amplifier enable  channel A
	    PAEN1 <= mem(1)(3); -- PA amplifier enable  channel B

	    --rf_sw <= mem(1)(6 DOWNTO 4); -- RF_SW control
	    -- not used on this board
	    rf_sw <= (others=>'0');
	    
	    ADPD_CAP_RESETN	<= mem(1)(4);
		lms3_monitoring <= mem(1)(5); -- default 1  (LMS#3 is used for montoring path)		
		dpdtop_en <= mem(1)(6); -- DEFAULT = 0
			
		fix_mimo <= '0';

	    DCEN0 <= mem(1)(7); -- DC-DC enable  channel A
	    DCEN1 <= mem(1)(8); -- DC-DC enable  channel B
	
	    tx_en <= mem(1)(9);  -- default 1
	    capture_en <= mem(1)(10); -- default 0 (signals transferred to FFTViewer, not to DPDViewer)
	    reset_n_soft <= mem(1)(11); -- default 1

	    cfr0_interpolation <= mem(1)(13 DOWNTO 12);  -- default "00"
	    cfr1_interpolation <= mem(1)(15 DOWNTO 14);  -- default "00"
		
		adpd_config0 <= mem(2)(15 DOWNTO 0);
		adpd_config1 <= mem(3)(15 DOWNTO 0);
		adpd_data <= mem(4)(15 DOWNTO 0);
	
		-- mem(5) default:0xEEEE
		-- CH A		
		cfr0_sleep <= mem(5)(0); -- default 0
		cfr0_bypass <= mem(5)(1); -- default 1	
		cfr0_odd <= mem(5)(2); -- default1 		
		gain_cfr0_bypass <= mem(5)(3); -- default 1		
	
		gfir0_sleep <= mem(5)(4); -- default 0	
		gfir0_byp <= mem(5)(5); -- default 1
		gfir0_odd <= mem(5)(6); -- default 1	
		hb0_delay <= mem(5)(7); -- default 1	
		-- CH B			
		cfr1_sleep <= mem(5)(8); -- default 0
		cfr1_bypass <= mem(5)(9); -- default 1
		cfr1_odd <= mem(5)(10); -- default 1	
		gain_cfr1_bypass <= mem(5)(11); -- default 1
	
		gfir1_sleep <= mem(5)(12); -- default 0	
		gfir1_byp <= mem(5)(13); -- default 1
		gfir1_odd <= mem(5)(14); -- default 1	
		hb1_delay <= mem(5)(15); -- default 1
		----------------		
		cfr0_threshold <= mem(6)(15 DOWNTO 0); --"1111111111111111"	
		cfr1_threshold <= mem(7)(15 DOWNTO 0); --"1111111111111111"	
		gain_cfr0 <= mem(8) (15 DOWNTO 0); --"0010000000000000"		
		gain_cfr1 <= mem(9) (15 DOWNTO 0); --"0010000000000000"
	
		cfr0_order <= mem(10) (7 DOWNTO 0); 
		cfr1_order <= mem(10) (15 DOWNTO 8);
		

end adpdcfg_arch;
