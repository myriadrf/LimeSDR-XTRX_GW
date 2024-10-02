-- ----------------------------------------------------------------------------
-- FILE:          vctcxo_tamer_top.vhd
-- DESCRIPTION:   describe file
-- DATE:          Jan 27, 2016
-- AUTHOR(s):     Lime Microsystems
-- REVISIONS:
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
--NOTES:
-- ----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- ----------------------------------------------------------------------------
-- Entity declaration
-- ----------------------------------------------------------------------------
entity vctcxo_tamer_top is
   generic ( 
      G_UART_BAUD_RATE        : positive := 9600;
      G_USB_CLK_FREQUENCY     : positive := 60000000;
      MM_CLOCK_FREQUENCY      : positive := 100000000
   );
   port (
      --USB to serial ULPI interface
      USB_NRST : out    std_logic;
      USB_D    : inout  std_logic_vector(7 downto 0);
      USB_STP  : out    std_logic;
      USB_NXT  : in     std_logic;
      USB_DIR  : in     std_logic;
      USB_CLK  : in     std_logic;

      -- Physical VCXO tamer Interface
      tune_ref             : in  std_logic;
      vctcxo_clock         : in  std_logic
      );
end vctcxo_tamer_top;

-- ----------------------------------------------------------------------------
-- Architecture
-- ----------------------------------------------------------------------------
architecture arch of vctcxo_tamer_top is
--declare signals,  components here

-- USB serial
signal usb_serial_reset_out   : std_logic;
signal usb_serial_rx          : std_logic;
signal usb_serial_tx          : std_logic;

-- UART
signal uart_data_stream_in       : std_logic_vector(7 downto 0);
signal uart_data_stream_in_stb   : std_logic;
signal uart_data_stream_in_ack   : std_logic;
signal uart_data_stream_out      : std_logic_vector(7 downto 0);
signal uart_data_stream_out_stb  : std_logic;
signal uart_data_stream_out_ack  : std_logic;

--NMEA parser
signal iiena_valid         : std_logic;         
signal iiena_en            : std_logic;
signal iirst_valid         : std_logic;
signal iirst_cnt           : std_logic;
signal iiirq_valid         : std_logic;
signal iiirq_en            : std_logic;
signal iiirq_rst           : std_logic;
signal iicfg_valid         : std_logic;
signal iicfg_1s_target     : std_logic_vector(31 downto 0);   
signal iicfg_1s_tol        : std_logic_vector(31 downto 0);
signal iicfg_10s_target    : std_logic_vector(31 downto 0);   
signal iicfg_10s_tol       : std_logic_vector(31 downto 0);
signal iicfg_100s_target   : std_logic_vector(31 downto 0);      
signal iicfg_100s_tol      : std_logic_vector(31 downto 0);   



-- MM bus
signal mm_rd_req   : std_logic;
signal mm_wr_req   : std_logic;
signal mm_addr     : std_logic_vector(7 downto 0);
signal mm_wr_data  : std_logic_vector(7 downto 0);
signal mm_rd_data  : std_logic_vector(7 downto 0);
signal mm_rd_datav : std_logic;
signal mm_wait_req : std_logic;
signal mm_irq      : std_logic;

signal pps_1s_error_v   : std_logic;
signal pps_1s_error     : std_logic_vector(31 downto 0);  
signal pps_10s_error_v  : std_logic;  
signal pps_10s_error    : std_logic_vector(31 downto 0); 
signal pps_100s_error_v : std_logic;
signal pps_100s_error   : std_logic_vector(31 downto 0); 

signal pps_1s_count_v    : std_logic;
signal pps_10s_count_v   : std_logic;  
signal pps_100s_count_v  : std_logic;





attribute MARK_DEBUG : string;
attribute MARK_DEBUG of uart_data_stream_out: signal is "TRUE";
attribute MARK_DEBUG of uart_data_stream_out_stb: signal is "TRUE";
attribute MARK_DEBUG of uart_data_stream_out_ack: signal is "TRUE";

attribute MARK_DEBUG of uart_data_stream_in: signal is "TRUE";
attribute MARK_DEBUG of uart_data_stream_in_stb: signal is "TRUE";
attribute MARK_DEBUG of uart_data_stream_in_ack: signal is "TRUE";

attribute MARK_DEBUG of mm_rd_req  : signal is "TRUE";
attribute MARK_DEBUG of mm_wr_req  : signal is "TRUE";
attribute MARK_DEBUG of mm_addr    : signal is "TRUE";
attribute MARK_DEBUG of mm_wr_data : signal is "TRUE";
attribute MARK_DEBUG of mm_rd_data : signal is "TRUE";
attribute MARK_DEBUG of mm_rd_datav: signal is "TRUE";
attribute MARK_DEBUG of mm_wait_req: signal is "TRUE";
attribute MARK_DEBUG of mm_irq     : signal is "TRUE";

attribute MARK_DEBUG of tune_ref     : signal is "TRUE";

attribute MARK_DEBUG of pps_1s_error       : signal is "TRUE";
attribute MARK_DEBUG of pps_10s_error      : signal is "TRUE";
attribute MARK_DEBUG of pps_100s_error     : signal is "TRUE";
attribute MARK_DEBUG of pps_1s_count_v     : signal is "TRUE";
attribute MARK_DEBUG of pps_10s_count_v    : signal is "TRUE";
attribute MARK_DEBUG of pps_100s_count_v   : signal is "TRUE";

attribute MARK_DEBUG of iiena_valid         : signal is "TRUE";
attribute MARK_DEBUG of iiena_en            : signal is "TRUE";
attribute MARK_DEBUG of iicfg_valid         : signal is "TRUE";
attribute MARK_DEBUG of iicfg_1s_target     : signal is "TRUE";
attribute MARK_DEBUG of iicfg_1s_tol        : signal is "TRUE";
attribute MARK_DEBUG of iicfg_10s_target    : signal is "TRUE";
attribute MARK_DEBUG of iicfg_10s_tol       : signal is "TRUE";
attribute MARK_DEBUG of iicfg_100s_target   : signal is "TRUE";
attribute MARK_DEBUG of iicfg_100s_tol      : signal is "TRUE";

attribute MARK_DEBUG of iirst_valid       : signal is "TRUE";
attribute MARK_DEBUG of iirst_cnt         : signal is "TRUE";
attribute MARK_DEBUG of iiirq_valid       : signal is "TRUE";
attribute MARK_DEBUG of iiirq_en          : signal is "TRUE";
attribute MARK_DEBUG of iiirq_rst         : signal is "TRUE";




  

  



component usb_serial is 
   generic (
       BAUDRATE         : integer := 9600
   );
   port(
       -- Serial
       uart_rx_o : out std_logic;
       uart_tx_i : in  std_logic;
   
       --ULPI Interface
       ulpi_reset_o        : out std_logic;
       ulpi_data_io        : inout std_logic_vector(7 downto 0);
       ulpi_stp_o          : out std_logic;
       ulpi_nxt_i          : in std_logic;
       ulpi_dir_i          : in std_logic;
       ulpi_clk60_i        : in std_logic;
       reset_out           : out std_logic
   );
   end component;



  
begin

-- ----------------------------------------------------------------------------
-- USB Serial instance
-- ----------------------------------------------------------------------------   
usb_serial_inst : usb_serial 
generic map(
    BAUDRATE => G_UART_BAUD_RATE
)
port map(
    -- Serial
    uart_rx_o => usb_serial_rx,
    uart_tx_i => usb_serial_tx,

    --ULPI Interface
    ulpi_reset_o        => USB_NRST,
    ulpi_data_io        => USB_D,
    ulpi_stp_o          => USB_STP,
    ulpi_nxt_i          => USB_NXT,
    ulpi_dir_i          => USB_DIR,
    ulpi_clk60_i        => USB_CLK,
    reset_out           => usb_serial_reset_out
);


-- ----------------------------------------------------------------------------
-- UART module
-- ----------------------------------------------------------------------------
UART_inst3 : entity work.UART
   generic map(
      BAUD_RATE            => G_UART_BAUD_RATE,
      CLOCK_FREQUENCY      => G_USB_CLK_FREQUENCY
   )
    port map(     
      CLOCK                => USB_CLK,   
      RESET                => usb_serial_reset_out,
      DATA_STREAM_IN       => uart_data_stream_in,
      DATA_STREAM_IN_STB   => uart_data_stream_in_stb,
      DATA_STREAM_IN_ACK   => uart_data_stream_in_ack,
      DATA_STREAM_OUT      => uart_data_stream_out    ,
      DATA_STREAM_OUT_STB  => uart_data_stream_out_stb,
      DATA_STREAM_OUT_ACK  => uart_data_stream_out_ack,
      TX                   => usb_serial_tx,                 
      RX                   => usb_serial_rx  
   );

   -- Process to acknowledge incoming serial DATA
   process(USB_CLK)
   begin
      if (USB_CLK'event and USB_CLK = '1') then
         if uart_data_stream_out_stb = '1' AND uart_data_stream_out_ack = '0' then 
            uart_data_stream_out_ack <= '1';
         else 
            uart_data_stream_out_ack <= '0';
         end if;
      end if;
   end process;

   nmea_parser_inst : entity work.nmea_parser
   port map (
      clk         => USB_CLK,
      reset_n     => NOT usb_serial_reset_out,
      data        => uart_data_stream_out,  --NMEA data character
      data_v      => uart_data_stream_out_stb AND uart_data_stream_out_ack,  --NMEA data valid
      
      --Parsed NMEA sentences (ASCII format)

      IIENA_valid       => iiena_valid,
      IIENA_EN          => iiena_en,

      IIRST_valid       => iirst_valid, 
      IIRST_CNT         => iirst_cnt, 
      IIIRQ_valid       => iiirq_valid, 
      IIIRQ_EN          => iiirq_en, 
      IIIRQ_RST         => iiirq_rst,

      IICFG_valid       => iicfg_valid,
      IICFG_1S_TARGET   => iicfg_1s_target,
      IICFG_1S_TOL      => iicfg_1s_tol,
      IICFG_10S_TARGET  => iicfg_10s_target,
      IICFG_10S_TOL     => iicfg_10s_tol,
      IICFG_100S_TARGET => iicfg_100s_target,
      IICFG_100S_TOL    => iicfg_100s_tol
   );

   nmea_mm_driver_inst : entity work.nmea_mm_driver
      port map(
         clk             => USB_CLK,
         reset_n         => NOT usb_serial_reset_out,
  
         mm_rd_req       => mm_rd_req  ,
         mm_wr_req       => mm_wr_req  ,
         mm_addr         => mm_addr    ,
         mm_wr_data      => mm_wr_data ,
         mm_rd_data      => mm_rd_data ,
         mm_rd_datav     => mm_rd_datav,
         mm_wait_req     => mm_wait_req,
  
         mm_irq          => mm_irq,
  
         IIENA_valid     => iiena_valid,
         IIENA_EN        => iiena_en,

         IIRST_valid     => iirst_valid,
         IIRST_CNT       => iirst_cnt, 
         IIIRQ_valid     => iiirq_valid,
         IIIRQ_EN        => iiirq_en, 
         IIIRQ_RST       => iiirq_rst
  
      );
   
-- ----------------------------------------------------------------------------
-- vctcxo_tamer instance
-- ----------------------------------------------------------------------------   
   vctcxo_tamer_inst0 : entity work.vctcxo_tamer
    port map(
      -- Physical Interface
      tune_ref           => tune_ref,
      vctcxo_clock       => vctcxo_clock,
      -- Avalon-MM Interface
      mm_clock           => USB_CLK,
      mm_reset           => usb_serial_reset_out,
      mm_rd_req          => mm_rd_req  ,
      mm_wr_req          => mm_wr_req  ,
      mm_addr            => mm_addr    ,
      mm_wr_data         => mm_wr_data ,
      mm_rd_data         => mm_rd_data ,
      mm_rd_datav        => mm_rd_datav,
      mm_wait_req        => mm_wait_req,
      -- Avalon Interrupts
      mm_irq             => mm_irq,
    
      PPS_1S_TARGET      => iicfg_1s_target,
      PPS_1S_ERROR_TOL   => iicfg_1s_tol,
      PPS_10S_TARGET     => iicfg_10s_target,
      PPS_10S_ERROR_TOL  => iicfg_10s_tol,
      PPS_100S_TARGET    => iicfg_100s_target,
      PPS_100S_ERROR_TOL => iicfg_100s_tol,
    
      -- Status registers
      pps_1s_error_v     => pps_1s_error_v,
      pps_1s_error       => pps_1s_error  ,
      pps_10s_error_v    => pps_10s_error_v,
      pps_10s_error      => pps_10s_error ,
      pps_100s_error_v   => pps_100s_error_v,
      pps_100s_error     => pps_100s_error,
      accuracy           => open,
      state              => open,
      dac_tuned_val      => open,
      pps_1s_count_v     => pps_1s_count_v,
      pps_10s_count_v    => pps_10s_count_v,
      pps_100s_count_v   => pps_100s_count_v
    );


    vctcxo_tamer_log_inst : entity work.vctcxo_tamer_log
      port map(
         clk                  => USB_CLK,
         reset_n              => NOT usb_serial_reset_out,
            
         irq                  => mm_irq,
         --Data to log 
         pps_1s_error_v       => pps_1s_error_v,
         pps_1s_error         => pps_1s_error,
         pps_10s_error_v      => pps_10s_error_v,
         pps_10s_error        => pps_10s_error,
         pps_100s_error_v     => pps_100s_error_v,
         pps_100s_error       => pps_100s_error,
         
         --To uart module
         uart_data_in         => uart_data_stream_in,
         uart_data_in_stb     => uart_data_stream_in_stb,
         uart_data_in_ack     => uart_data_stream_in_ack
         
         );
  
-- ----------------------------------------------------------------------------
-- output ports
-- ---------------------------------------------------------------------------- 
  
end arch;   


