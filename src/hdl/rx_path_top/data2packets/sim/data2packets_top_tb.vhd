-- ----------------------------------------------------------------------------	
-- FILE: 	data2packets_top_tb.vhd
-- DESCRIPTION:	
-- DATE:	Feb 13, 2014
-- AUTHOR(s):	Lime Microsystems
-- REVISIONS:
-- ----------------------------------------------------------------------------	
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- ----------------------------------------------------------------------------
-- Entity declaration
-- ----------------------------------------------------------------------------
entity data2packets_top_tb is
end data2packets_top_tb;

-- ----------------------------------------------------------------------------
-- Architecture
-- ----------------------------------------------------------------------------

architecture tb_behave of data2packets_top_tb is
constant clk0_period          : time := 10 ns;
constant clk1_period          : time := 10 ns; 
constant iq_width             : integer := 12;
constant C_outbus_width       : integer := 128;
   --signals
signal clk0,clk1		         : std_logic;
signal reset_n                : std_logic; 
   
--dut0 signals
signal dut0_sample_width      : std_logic_vector(1 downto 0) := "10"; --"10"-12bit, "01"-14bit, "00"-16bit;
signal dut0_pct_hdr_0         : std_logic_vector(63 downto 0) := (others=>'1');
signal dut0_pct_hdr_1         : std_logic_vector(63 downto 0);         
signal dut0_pct_buff_wrreq    : std_logic;
signal dut0_pct_buff_wrdata   : std_logic_vector(C_outbus_width-1 downto 0);
signal dut0_smpl_buff_rdreq   : std_logic;

signal smpl_fifo_size         : integer := 11;
signal pct_fifo_size          : integer := 12;

--inst1
signal inst1_wrreq            : std_logic;
signal inst1_data             : std_logic_vector(iq_width*4-1 downto 0):= (others => '0');
signal sample_data            : signed(11 downto 0):= (others => '0');
signal inst1_q                : std_logic_vector(iq_width*4-1 downto 0);
signal inst1_rdusedw          : std_logic_vector(10 downto 0);

--inst2 
signal inst2_wrusedw          : std_logic_vector(11 downto 0);
signal inst2_smpl_buff_rddata : std_logic_vector(128-1 downto 0);

signal outfifo_rdempty        : std_logic;
signal outfifo_rddata         : std_logic_vector(63 downto 0);
signal counter_64             : integer;
 

begin 
  
      clock0: process is
	begin
		clk0 <= '0'; wait for clk0_period/2;
		clk0 <= '1'; wait for clk0_period/2;
	end process clock0;

   	clock: process is
	begin
		clk1 <= '0'; wait for clk1_period/2;
		clk1 <= '1'; wait for clk1_period/2;
	end process clock;
	
		res: process is
	begin
		reset_n <= '0'; wait for 20 ns;
		reset_n <= '1'; wait;
	end process res;
	
	
	datagen : process(clk0) is
	begin
	   if rising_edge(clk0) then
	       if inst1_wrreq = '1' then
               if sample_data > 5000 then
                   sample_data <= (others => '0');
               else
                   sample_data <= sample_data + 16;
               end if;
	       end if;
	   end if;
	end process;
	
	sampl16 : if iq_width = 16 generate
	   inst1_data <= std_logic_vector(sample_data) &"0000" & std_logic_vector(sample_data) &"0000" & std_logic_vector(sample_data) &"0000" & std_logic_vector(sample_data) &"0000";
	end generate;
	
	sampl12 : if iq_width = 12 generate
        inst1_data <= std_logic_vector(sample_data) & std_logic_vector(sample_data) & std_logic_vector(sample_data) & std_logic_vector(sample_data);
    end generate;
   
 process(clk0, reset_n)
   begin
      if reset_n = '0' then 
         dut0_pct_hdr_1 <= (others=>'0');
      elsif (clk0'event AND clk0='1') then 
         if dut0_smpl_buff_rdreq = '1' then 
            dut0_pct_hdr_1 <= std_logic_vector(unsigned(dut0_pct_hdr_1)+1);
         else 
            dut0_pct_hdr_1 <= dut0_pct_hdr_1;
         end if;
      end if;
   end process;
   
inst2_smpl_buff_rddata(63 downto 64-iq_width) <= inst1_q(iq_width*4-1 downto iq_width*3);
inst2_smpl_buff_rddata(64-iq_width-1 downto 48) <= (others=>'0');

inst2_smpl_buff_rddata(47 downto 48-iq_width) <= inst1_q(iq_width*3-1 downto iq_width*2);
inst2_smpl_buff_rddata(48-iq_width-1 downto 32) <= (others=>'0');

inst2_smpl_buff_rddata(31 downto 32-iq_width) <= inst1_q(iq_width*2-1 downto iq_width);
inst2_smpl_buff_rddata(32-iq_width-1 downto 16) <= (others=>'0');

inst2_smpl_buff_rddata(15 downto 16-iq_width) <= inst1_q(iq_width-1 downto 0);
inst2_smpl_buff_rddata(16-iq_width-1 downto 0) <= (others=>'0');       

  
  dut0 : entity work.data2packets_top 
   generic map (
      outbus_width        => C_outbus_width,
      smpl_buff_rdusedw_w => 11, --bus width in bits 
      pct_buff_wrusedw_w  => 12 --bus width in bits  
   )
   port map(              
      clk               => clk0,
      reset_n           => reset_n,
      sample_width      => dut0_sample_width,
      pct_hdr_0         => dut0_pct_hdr_0,
      pct_hdr_1         => dut0_pct_hdr_1,
      pct_buff_wrusedw  => inst2_wrusedw,
      pct_buff_wrreq    => dut0_pct_buff_wrreq,
      pct_buff_wrdata   => dut0_pct_buff_wrdata,
      smpl_buff_rdusedw => inst1_rdusedw,
      smpl_buff_rdreq   => dut0_smpl_buff_rdreq,
      smpl_buff_rddata  => inst2_smpl_buff_rddata--(others=>'0')
      );
      
      
 proc_name : process(clk0, reset_n)
 begin
    if reset_n = '0' then 
       inst1_wrreq <= '0';
    elsif (clk0'event AND clk0='1') then 
       inst1_wrreq <= NOT inst1_wrreq;
    end if;
 end process;
      
      
fifo_inst_inst1 : entity work.fifo_inst
  generic map (
      dev_family	    => "Cyclone IV E",
      wrwidth         => iq_width*4,
      wrusedw_witdth  => 11, --12=2048 words 
      rdwidth         => iq_width*4,
      rdusedw_width   => 11,
      show_ahead      => "OFF"
  ) 
  port map(
      --input ports 
      reset_n       => reset_n,
      wrclk         => clk0,
      wrreq         => inst1_wrreq,
      data          => inst1_data,
      wrfull        => open,
		wrempty		  => open,
      wrusedw       => open,
      rdclk 	     => clk0,
      rdreq         => dut0_smpl_buff_rdreq,
      q             => inst1_q,
      rdempty       => open,
      rdusedw       => inst1_rdusedw
        );
        
        
fifo_inst_inst2 : entity work.fifo_inst
  generic map (
      dev_family	    => "Cyclone IV E",
      wrwidth         => C_outbus_width,
      wrusedw_witdth  => 12, --12=2048 words 
      rdwidth         => 64,
      rdusedw_width   => 12,
      show_ahead      => "OFF"
  ) 
  port map(
      --input ports 
      reset_n       => reset_n,
      wrclk         => clk0,
      wrreq         => dut0_pct_buff_wrreq,
      data          => dut0_pct_buff_wrdata,
      wrfull        => open,
		wrempty		  => open,
      wrusedw       => inst2_wrusedw,
      rdclk 	     => clk0,
      rdreq         => not outfifo_rdempty,
      q             => outfifo_rddata,
      rdempty       => outfifo_rdempty,
      rdusedw       => open
        );
	
	  
counting : process(clk0,outfifo_rdempty)
    variable counter : integer := 0;
begin
    if rising_edge(clk0) then
        if (outfifo_rddata = "1111111111111111111111111111111111111111111111111111111111111111") then
            counter := 0;
        elsif (outfifo_rdempty='0') then
            counter := counter + 1;
        end if;
    end if;
    counter_64 <= counter;
end process;
  
	
	
	end tb_behave;



  
