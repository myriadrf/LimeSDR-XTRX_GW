-- ----------------------------------------------------------------------------
-- FILE:          usb_serial_top.vhd
-- DESCRIPTION:   describe file
-- DATE:          Jan 27, 2016
-- AUTHOR(s):     Lime Microsystems
-- REVISIONS:
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- NOTES:
-- ----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.axis_pkg.all;

-- ----------------------------------------------------------------------------
-- Entity declaration
-- ----------------------------------------------------------------------------
entity usb_serial_top is
   generic (
      G_UART_BAUDRATE   : integer := 9600
  );
   port (
      CLK100         : in     std_logic;
      RESET_N        : in     std_logic;
      --USB to serial ULPI interface
      USB_NRST       : out    std_logic;
      USB_D          : inout  std_logic_vector(7 downto 0);
      USB_STP        : out    std_logic;
      USB_NXT        : in     std_logic;
      USB_DIR        : in     std_logic;
      USB_CLK        : in     std_logic;
      -- UART0 serial    
      UART0_RX             : in     std_logic;
      UART0_TX             : out    std_logic;
      -- UART1 serial with internal data interface 
      UART1_DATA_STREAM_IN       : in  std_logic_vector(7 downto 0);
      UART1_DATA_STREAM_IN_STB   : in  std_logic;
      UART1_DATA_STREAM_IN_ACK   : out std_logic;
      -- UART1 serial with internal data interface 
      UART1_DATA_STREAM_OUT      : out std_logic_vector(7 downto 0);
      UART1_DATA_STREAM_OUT_STB  : out std_logic;
      UART1_DATA_STREAM_OUT_ACK  : in  std_logic
   );
end usb_serial_top;

-- ----------------------------------------------------------------------------
-- Architecture
-- ----------------------------------------------------------------------------
architecture arch of usb_serial_top is
--declare signals,  components here

   signal usb_serial_rx_o       : std_logic;
   signal usb_serial_tx_i       : std_logic;
   signal usb_serial_reset_out: std_logic;

   signal uart_usb_tx           : std_logic;
   signal uart_usb_rx           : std_logic;

   signal uart0_data_stream_out : std_logic_vector(7 downto 0);
   signal uart0_data_stream_out_stb : std_logic;
   signal uart0_data_stream_out_ack : std_logic;

   signal uart_mux_data_stream_out     : std_logic_vector(7 downto 0);
   signal uart_mux_data_stream_out_stb : std_logic;
   signal uart_mux_data_stream_out_ack : std_logic;

   component usb_serial is 
   generic (
       BAUDRATE         : integer := 9600
   );
   port(
       -- Serial
       uart_rx_o     : out    std_logic;
       uart_tx_i     : in     std_logic;
   
       --ULPI Interface
       ulpi_reset_o  : out    std_logic;
       ulpi_data_io  : inout  std_logic_vector(7 downto 0);
       ulpi_stp_o    : out    std_logic;
       ulpi_nxt_i    : in     std_logic;
       ulpi_dir_i    : in     std_logic;
       ulpi_clk60_i  : in     std_logic;
       reset_in      : in     std_logic;
       reset_out     : out    std_logic
   );
   end component;

begin


-- ----------------------------------------------------------------------------
-- USB Serial instance
-- ----------------------------------------------------------------------------   
   usb_serial_inst : usb_serial 
   generic map(
       BAUDRATE => G_UART_BAUDRATE
   )
   port map(
       -- Serial
       uart_rx_o     => usb_serial_rx_o,
       uart_tx_i     => usb_serial_tx_i,
       --ULPI Interface
       ulpi_reset_o  => USB_NRST,
       ulpi_data_io  => USB_D,
       ulpi_stp_o    => USB_STP,
       ulpi_nxt_i    => USB_NXT,
       ulpi_dir_i    => USB_DIR,
       ulpi_clk60_i  => USB_CLK,
       reset_in      => NOT RESET_N,
       reset_out     => usb_serial_reset_out
   );

   usb_serial_tx_i <= uart_usb_tx;
   uart_usb_rx     <= usb_serial_rx_o;

-- ----------------------------------------------------------------------------
-- UART for USB serial module
-- ----------------------------------------------------------------------------
   UART_USB_inst : entity work.UART
      generic map(
         BAUD_RATE            => G_UART_BAUDRATE,
         CLOCK_FREQUENCY      => 100000000
      )
       port map(     
         CLOCK                => CLK100,   
         RESET                => usb_serial_reset_out,
         DATA_STREAM_IN       => uart_mux_data_stream_out    ,    
         DATA_STREAM_IN_STB   => uart_mux_data_stream_out_stb,
         DATA_STREAM_IN_ACK   => uart_mux_data_stream_out_ack,
         DATA_STREAM_OUT      => UART1_DATA_STREAM_OUT,
         DATA_STREAM_OUT_STB  => UART1_DATA_STREAM_OUT_STB,
         DATA_STREAM_OUT_ACK  => UART1_DATA_STREAM_OUT_ACK,
         TX                   => uart_usb_tx,                 
         RX                   => uart_usb_rx 
      );

-- ----------------------------------------------------------------------------
-- UART0 module
-- ----------------------------------------------------------------------------
   UART0_inst : entity work.UART
      generic map(
         BAUD_RATE            => G_UART_BAUDRATE,
         CLOCK_FREQUENCY      => 100000000
      )
       port map(     
         CLOCK                => CLK100,   
         RESET                => usb_serial_reset_out,
         DATA_STREAM_IN       => (others=>'0'),    
         DATA_STREAM_IN_STB   => '0',
         DATA_STREAM_IN_ACK   => open,
         DATA_STREAM_OUT      => uart0_data_stream_out,
         DATA_STREAM_OUT_STB  => uart0_data_stream_out_stb,
         DATA_STREAM_OUT_ACK  => uart0_data_stream_out_ack,
         TX                   => open,                 
         RX                   => UART0_RX  
      );

-- ----------------------------------------------------------------------------
-- UART0 UART1 mux module
-- ----------------------------------------------------------------------------
   uart_mux_inst : entity work.uart_mux
      port map(
         CLK                  => CLK100,
         RESET_N              => NOT usb_serial_reset_out,
         -- Data 0
         DATA0_STREAM_IN      => uart0_data_stream_out,
         DATA0_STREAM_IN_STB  => uart0_data_stream_out_stb,
         DATA0_STREAM_IN_ACK  => uart0_data_stream_out_ack,
         -- Data 1
         DATA1_STREAM_IN      => UART1_DATA_STREAM_IN    ,
         DATA1_STREAM_IN_STB  => UART1_DATA_STREAM_IN_STB,
         DATA1_STREAM_IN_ACK  => UART1_DATA_STREAM_IN_ACK,
         -- MUXED Data
         DATA_STREAM_OUT      => uart_mux_data_stream_out    ,
         DATA_STREAM_OUT_STB  => uart_mux_data_stream_out_stb,
         DATA_STREAM_OUT_ACK  => uart_mux_data_stream_out_ack
   );


-- ----------------------------------------------------------------------------
-- Output ports
-- ----------------------------------------------------------------------------
   UART0_TX <= usb_serial_rx_o;









  
end arch;   

