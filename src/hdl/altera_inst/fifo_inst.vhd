-- ----------------------------------------------------------------------------	
-- FILE: 	fifo_inst.vhd
-- DESCRIPTION:	describe
-- DATE:	Feb 13, 2014
-- AUTHOR(s):	Lime Microsystems
-- REVISIONS:
-- April 17, 2019 - added Xilinx support
-- ----------------------------------------------------------------------------	
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
LIBRARY altera_mf;
USE altera_mf.all;
Library xpm;
use xpm.all;


-- ----------------------------------------------------------------------------
-- Entity declaration
-- ----------------------------------------------------------------------------
entity fifo_inst is
  generic(vendor          : string  := "XILINX"; -- valid vals = "XILINX" or "ALTERA"
          dev_family	  : string  := "Cyclone IV E";
          wrwidth         : integer := 24;
          wrusedw_witdth  : integer := 12; --12=2048 words 
          rdwidth         : integer := 48;
          rdusedw_width   : integer := 11;
          show_ahead      : string  := "ON"
  );  

  port (
      --input ports 
      reset_n       : in std_logic;
      wr_rst_busy   : out std_logic;
      rd_rst_busy   : out std_logic;
      wrclk         : in std_logic;
      wrreq         : in std_logic;
      data          : in std_logic_vector(wrwidth-1 downto 0);
      wrfull        : out std_logic;
		wrempty		  : out std_logic;
      wrusedw       : out std_logic_vector(wrusedw_witdth-1 downto 0);
      rdclk 	     : in std_logic;
      rdreq         : in std_logic;
      q             : out std_logic_vector(rdwidth-1 downto 0);
      rdempty       : out std_logic;
      rdusedw       : out std_logic_vector(rdusedw_width-1 downto 0)     

        );
end fifo_inst;

-- ----------------------------------------------------------------------------
-- Architecture
-- ----------------------------------------------------------------------------
architecture arch of fifo_inst is
--declare signals,  components here
   --altera
   signal aclr : std_logic;
   --xilinx
   function show_ahead_to_read_mode(show_ahead : string) return string is
   begin
        if show_ahead = "ON" then return "fwft";
        else return "std";
        end if;
   end show_ahead_to_read_mode;
      
   function fifo_latency(show_ahead : string) return natural is 
   begin 
        if show_ahead = "ON" then return 0;
        else return 1;
        end if;
   end fifo_latency;
        
   constant fifo_read_mode : string := show_ahead_to_read_mode(show_ahead); 
   constant fifo_read_latency : natural := fifo_latency(show_ahead);
   signal rst : std_logic;
   signal xilinx_wrusedw      : std_logic_vector(wrusedw_witdth-1 downto 0);
   signal xilinx_rdusedw      : std_logic_vector(rdusedw_width-1 downto 0);
   signal xilinx_wrfull       : std_logic;
   signal xilinx_empty        : std_logic;
   signal xilinx_rd_rst_busy  : std_logic;


      COMPONENT dcfifo_mixed_widths
      GENERIC (
         add_usedw_msb_bit				: STRING;
         intended_device_family		: STRING;
         lpm_numwords					: NATURAL;
         lpm_showahead					: STRING;
         lpm_type							: STRING;
         lpm_width						: NATURAL;
         lpm_widthu						: NATURAL;
         lpm_widthu_r					: NATURAL;
         lpm_width_r						: NATURAL;
         overflow_checking				: STRING;
         rdsync_delaypipe				: NATURAL;
         read_aclr_synch				: STRING;
         underflow_checking			: STRING;
         use_eab							: STRING;
         write_aclr_synch				: STRING;
         wrsync_delaypipe				: NATURAL
      );
      PORT (
            aclr		: IN STD_LOGIC ;
            data		: IN STD_LOGIC_VECTOR (wrwidth-1 downto 0);
            rdclk	    : IN STD_LOGIC ;
            rdreq	    : IN STD_LOGIC ;
            wrclk	    : IN STD_LOGIC ;
            wrreq	    : IN STD_LOGIC ;
            q			: OUT STD_LOGIC_VECTOR(rdwidth-1 downto 0);
            rdempty	    : OUT STD_LOGIC ;
            rdusedw	    : OUT STD_LOGIC_VECTOR (rdusedw_width-1 downto 0); 
            wrempty	    : out std_logic;
            wrfull	    : OUT STD_LOGIC;
            wrusedw	    : OUT STD_LOGIC_VECTOR (wrusedw_witdth-1 downto 0)
      );
      END COMPONENT;
      
      
      COMPONENT xpm_fifo_async
      GENERIC(
        CDC_SYNC_STAGES      :natural;    -- DECIMAL  
        DOUT_RESET_VALUE     :string ;    -- String   
        ECC_MODE             :string ;    -- String   
        FIFO_MEMORY_TYPE     :string ;    -- String   
        FIFO_READ_LATENCY    :natural;    -- DECIMAL  
        FIFO_WRITE_DEPTH     :natural;    -- DECIMAL  
        FULL_RESET_VALUE     :natural;    -- DECIMAL  
        PROG_EMPTY_THRESH    :natural;    -- DECIMAL  
        PROG_FULL_THRESH     :natural;    -- DECIMAL  
        RD_DATA_COUNT_WIDTH  :natural;    -- DECIMAL  
        READ_DATA_WIDTH      :natural;    -- DECIMAL  
        READ_MODE            :string ;    -- String   
        RELATED_CLOCKS       :natural;    -- DECIMAL  
        USE_ADV_FEATURES     :string ;    -- String   
        WAKEUP_TIME          :natural;    -- DECIMAL  
        WRITE_DATA_WIDTH     :natural;    -- DECIMAL  
        WR_DATA_COUNT_WIDTH  :natural    -- DECIMAL  
      
      );
      PORT(
        almost_empty        :out std_logic;
        almost_full         :out std_logic;
        data_valid          :out std_logic;
        dbiterr             :out std_logic;
        dout                :out std_logic_vector(READ_DATA_WIDTH-1 downto 0);        
        empty               :out std_logic;
        full                :out std_logic;
        overflow            :out std_logic;
        prog_empty          :out std_logic;   
        prog_full           :out std_logic;
        rd_data_count       :out std_logic_vector(RD_DATA_COUNT_WIDTH-1 downto 0);
        rd_rst_busy         :out std_logic;    
        sbiterr             :out std_logic;
        underflow           :out std_logic;       
        wr_ack              :out std_logic;           
        wr_data_count       :out std_logic_vector(WR_DATA_COUNT_WIDTH-1 downto 0);
        wr_rst_busy         :out std_logic;     
        din                 :in  std_logic_vector(WRITE_DATA_WIDTH-1 downto 0);              
        injectdbiterr       :in  std_logic; 
        injectsbiterr       :in  std_logic; 
        rd_clk              :in  std_logic;      
        rd_en               :in  std_logic;      
        rst                 :in  std_logic;       
        sleep               :in  std_logic;     
        wr_clk              :in  std_logic;    
        wr_en               :in  std_logic
      );
      END COMPONENT;
      
      
   

begin


    FIFO_ALT : if vendor = "ALTERA" generate
         
         aclr<= not reset_n;
         
         
          dcfifo_mixed_widths_component : dcfifo_mixed_widths
          GENERIC MAP (
             add_usedw_msb_bit       => "ON",
             intended_device_family  => dev_family,
             lpm_numwords            => 2**(wrusedw_witdth-1),
             lpm_showahead           => show_ahead,
             lpm_type                => "dcfifo_mixed_widths",
             lpm_width               => wrwidth,
             lpm_widthu              => wrusedw_witdth,
             lpm_widthu_r            => rdusedw_width,
             lpm_width_r             => rdwidth,
             overflow_checking       => "ON",
             rdsync_delaypipe        => 4,
             read_aclr_synch         => "OFF",
             underflow_checking      => "ON",
             use_eab                 => "ON",
             write_aclr_synch        => "OFF",
             wrsync_delaypipe        => 4
          )
          PORT MAP (
             aclr    	=> aclr,
             data    	=> data,
             rdclk   	=> rdclk,
             rdreq   	=> rdreq,
             wrclk   	=> wrclk,
             wrreq   	=> wrreq,
             q       	=> q,
             rdempty 	=> rdempty,
             rdusedw 	=> rdusedw,
             wrempty	=> wrempty,
             wrfull  	=> wrfull,
             wrusedw	=> wrusedw
          );
    end generate;

    FIFO_XIL : if vendor = "XILINX" generate
    
    rst_sync : process(wrclk)
    begin
      if rising_edge(wrclk) then
         rst <= not reset_n;
      end if;
   end process;
    --    Library     : In addition to adding the instance declaration, a use
    --  declaration   : statement for the UNISIM.vcomponents library needs to be
    --      for       : added before the entity declaration.  This library
    --     Xilinx     : contains the component declarations for all Xilinx
    --   primitives   : primitives and points to the models that will be used
    --                : for simulation.
    
    --  Please reference the appropriate libraries guide for additional information on the XPM modules.
    
    --  Copy the following two statements and paste them before the
    --  Entity declaration, unless they already exist.
    
    
    -- <-----Cut code below this line and paste into the architecture body---->
    
       -- xpm_fifo_async: Asynchronous FIFO
       -- Xilinx Parameterized Macro, version 2018.3
       --fifo_read_mode <= "std" when show_ahead = "OFF" else "fwft";
    
       xpm_fifo_async_inst : xpm_fifo_async
       generic map (
          CDC_SYNC_STAGES => 2,       -- DECIMAL
          DOUT_RESET_VALUE => "0",    -- String
          ECC_MODE => "no_ecc",       -- String
          FIFO_MEMORY_TYPE => "block", -- String
          FIFO_READ_LATENCY => fifo_read_latency,     -- DECIMAL
          FIFO_WRITE_DEPTH => 2**(wrusedw_witdth-1),   -- DECIMAL
          FULL_RESET_VALUE => 0,      -- DECIMAL
          PROG_EMPTY_THRESH => 10,    -- DECIMAL
          PROG_FULL_THRESH => 10,     -- DECIMAL
          RD_DATA_COUNT_WIDTH => rdusedw_width,   -- DECIMAL
          READ_DATA_WIDTH => rdwidth,      -- DECIMAL
          READ_MODE => fifo_read_mode,         -- String
          RELATED_CLOCKS => 0,        -- DECIMAL
          USE_ADV_FEATURES => "404", -- String
          WAKEUP_TIME => 0,           -- DECIMAL
          WRITE_DATA_WIDTH => wrwidth,     -- DECIMAL
          WR_DATA_COUNT_WIDTH => wrusedw_witdth    -- DECIMAL
       )
       port map (
          almost_empty => open,   -- 1-bit output: Almost Empty : When asserted, this signal indicates that
                                          -- only one more read can be performed before the FIFO goes to empty.
    
          almost_full => open,     -- 1-bit output: Almost Full: When asserted, this signal indicates that
                                          -- only one more write can be performed before the FIFO is full.
    
          data_valid => open,       -- 1-bit output: Read Data Valid: When asserted, this signal indicates
                                          -- that valid data is available on the output bus (dout).
    
          dbiterr => open,             -- 1-bit output: Double Bit Error: Indicates that the ECC decoder
                                          -- detected a double-bit error and data in the FIFO core is corrupted.
    
          dout => q,                   -- READ_DATA_WIDTH-bit output: Read Data: The output data bus is driven
                                          -- when reading the FIFO.
    
          empty => xilinx_empty,       -- 1-bit output: Empty Flag: When asserted, this signal indicates that
                                          -- the FIFO is empty. Read requests are ignored when the FIFO is empty,
                                          -- initiating a read while empty is not destructive to the FIFO.
    
          full => xilinx_wrfull,          -- 1-bit output: Full Flag: When asserted, this signal indicates that the
                                          -- FIFO is full. Write requests are ignored when the FIFO is full,
                                          -- initiating a write when the FIFO is full is not destructive to the
                                          -- contents of the FIFO.
    
          overflow => open,           -- 1-bit output: Overflow: This signal indicates that a write request
                                          -- (wren) during the prior clock cycle was rejected, because the FIFO is
                                          -- full. Overflowing the FIFO is not destructive to the contents of the
                                          -- FIFO.
    
          prog_empty => open,       -- 1-bit output: Programmable Empty: This signal is asserted when the
                                          -- number of words in the FIFO is less than or equal to the programmable
                                          -- empty threshold value. It is de-asserted when the number of words in
                                          -- the FIFO exceeds the programmable empty threshold value.
    
          prog_full => open,         -- 1-bit output: Programmable Full: This signal is asserted when the
                                          -- number of words in the FIFO is greater than or equal to the
                                          -- programmable full threshold value. It is de-asserted when the number
                                          -- of words in the FIFO is less than the programmable full threshold
                                          -- value.
    
          rd_data_count => xilinx_rdusedw, -- RD_DATA_COUNT_WIDTH-bit output: Read Data Count: This bus indicates
                                          -- the number of words read from the FIFO.
    
          rd_rst_busy => xilinx_rd_rst_busy,     -- 1-bit output: Read Reset Busy: Active-High indicator that the FIFO
                                          -- read domain is currently in a reset state.
    
          sbiterr => open,             -- 1-bit output: Single Bit Error: Indicates that the ECC decoder
                                          -- detected and fixed a single-bit error.
    
          underflow => open,         -- 1-bit output: Underflow: Indicates that the read request (rd_en)
                                          -- during the previous clock cycle was rejected because the FIFO is
                                          -- empty. Under flowing the FIFO is not destructive to the FIFO.
    
          wr_ack => open,               -- 1-bit output: Write Acknowledge: This signal indicates that a write
                                          -- request (wr_en) during the prior clock cycle is succeeded.
    
          wr_data_count => xilinx_wrusedw, -- WR_DATA_COUNT_WIDTH-bit output: Write Data Count: This bus indicates
                                          -- the number of words written into the FIFO.
    
          wr_rst_busy => wr_rst_busy,     -- 1-bit output: Write Reset Busy: Active-High indicator that the FIFO
                                          -- write domain is currently in a reset state.
    
          din => data,                     -- WRITE_DATA_WIDTH-bit input: Write Data: The input data bus used when
                                          -- writing the FIFO.
    
          injectdbiterr => '0', -- 1-bit input: Double Bit Error Injection: Injects a double bit error if
                                          -- the ECC feature is used on block RAMs or UltraRAM macros.
    
          injectsbiterr => '0', -- 1-bit input: Single Bit Error Injection: Injects a single bit error if
                                          -- the ECC feature is used on block RAMs or UltraRAM macros.
    
          rd_clk => rdclk,               -- 1-bit input: Read clock: Used for read operation. rd_clk must be a
                                          -- free running clock.
    
          rd_en => rdreq,                 -- 1-bit input: Read Enable: If the FIFO is not empty, asserting this
                                          -- signal causes data (on dout) to be read from the FIFO. Must be held
                                          -- active-low when rd_rst_busy is active high.
    
          rst => rst,                     -- 1-bit input: Reset: Must be synchronous to wr_clk. The clock(s) can be
                                          -- unstable at the time of applying reset, but reset must be released
                                          -- only after the clock(s) is/are stable.
    
          sleep => '0',                 -- 1-bit input: Dynamic power saving: If sleep is High, the memory/fifo
                                          -- block is in power saving mode.
    
          wr_clk => wrclk,               -- 1-bit input: Write clock: Used for write operation. wr_clk must be a
                                          -- free running clock.
    
          wr_en => wrreq                  -- 1-bit input: Write Enable: If the FIFO is not full, asserting this
                                          -- signal causes data (on din) to be written to the FIFO. Must be held
                                          -- active-low when rst or wr_rst_busy is active high.
    
       );
       
      wrempty <= '1' when unsigned(xilinx_wrusedw)=0 else '0';
      wrfull  <= xilinx_wrfull;
      wrusedw <= xilinx_wrusedw;
      
      
      
      rdusedw <= xilinx_rdusedw;
      rdempty <= '1' when xilinx_rd_rst_busy = '1' else xilinx_empty;
      rd_rst_busy <= xilinx_rd_rst_busy;
       
            
    end generate;
  
end arch;   





