-- ----------------------------------------------------------------------------
-- FILE:          nmea_mm_driver.vhd
-- DESCRIPTION:   NMEA Avalon MM driver for VCTCXO tamer
-- DATE:          11:07 AM Tuesday, February 27, 2018
-- AUTHOR(s):     Lime Microsystems
-- REVISIONS:
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- NOTES:
-- ----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- ----------------------------------------------------------------------------
-- Entity declaration
-- ----------------------------------------------------------------------------
entity nmea_mm_driver is
    port (
        clk             : in std_logic;
        reset_n         : in std_logic;

        mm_rd_req       :   out std_logic;
        mm_wr_req       :   out std_logic;
        mm_addr         :   out std_logic_vector(7 downto 0);
        mm_wr_data      :   out std_logic_vector(7 downto 0);
        mm_rd_data      :   in  std_logic_vector(7 downto 0);
        mm_rd_datav     :   in  std_logic;
        mm_wait_req     :   in  std_logic;

        mm_irq          :   in  std_logic;

        IIENA_valid     : in  std_logic;
        IIENA_EN        : in  std_logic;

        IIRST_valid     : in  std_logic;
        IIRST_CNT       : in  std_logic;
  
        IIIRQ_valid     : in  std_logic;
        IIIRQ_EN        : in  std_logic;
        IIIRQ_RST       : in  std_logic

    );
end nmea_mm_driver;
-- ----------------------------------------------------------------------------
-- Architecture
-- ----------------------------------------------------------------------------
architecture arch of nmea_mm_driver is
    --declare signals,  components here

    constant C_VT_CTRL_ADDR : std_logic_vector(mm_addr'high downto 0) := x"00";

    constant C_VT_CTRL_VCTCXO_RESET_BIT  : integer :=0;
    constant C_VT_CTRL_IRQ_EN_BIT  : integer :=4;
    constant C_VT_CTRL_IRQ_CLR_BIT : integer :=5;

    type t_FSM_STATES is (
        IDLE,
        INIT_SET_TUNE_MODE,   
        INIT_RESET_COUNTERS,
        INIT_ENABLE_COUNTERS,
        INIT_DISABLE_ISR,
        DISABLE,
        RST_COUNTERS,
        ENABLE_COUNTERS,
        ISRCTRL_0,
        ISRCTRL_1,
        ISRCTRL_2
    );

    signal current_state, next_state : t_FSM_STATES;

    signal mm_wr_data_int : std_logic_vector(7 downto 0);
    signal mm_wr_data_reg : std_logic_vector(7 downto 0);

begin 

    process (clk, reset_n)
    begin
        if reset_n = '0' then 
            current_state <= IDLE;
            mm_wr_data_reg <= (others => '0');
        elsif rising_edge(clk) then
            current_state   <= next_state;
            mm_wr_data_reg  <= mm_wr_data_int;
        end if;
    end process;

    process (all)
    begin
        mm_rd_req   <= '0';
        mm_wr_req   <= '0';
        mm_addr     <= (others => '0');
        mm_wr_data_int  <= mm_wr_data_reg;

        case current_state is

            when IDLE => 
                if IIENA_valid ='1' AND IIENA_EN = '1' then 
                    next_state <= INIT_SET_TUNE_MODE;
                elsif IIENA_valid ='1' AND IIENA_EN = '0' then 
                    next_state <= DISABLE;
                elsif IIRST_valid = '1' then 
                    if IIRST_CNT = '1' then 
                        next_state <= RST_COUNTERS;
                    else 
                        next_state <= ENABLE_COUNTERS;
                    end if;
                elsif IIIRQ_valid = '1' then 
                    next_state <= ISRCTRL_0;
                else 
                    next_state <= idle;
                end if;

            when INIT_SET_TUNE_MODE => 
                mm_wr_req   <= '1';
                mm_wr_data_int  <= x"40";
                mm_addr     <= C_VT_CTRL_ADDR;
                next_state  <= INIT_RESET_COUNTERS;

            when INIT_RESET_COUNTERS => 
                mm_wr_req   <= '1';
                mm_wr_data_int(C_VT_CTRL_VCTCXO_RESET_BIT)  <= '1';
                mm_addr     <= C_VT_CTRL_ADDR;
                next_state  <= INIT_ENABLE_COUNTERS;

            when INIT_ENABLE_COUNTERS => 
                mm_wr_req   <= '1';
                mm_wr_data_int(C_VT_CTRL_VCTCXO_RESET_BIT)  <= '0';
                mm_addr     <= C_VT_CTRL_ADDR;
                next_state  <= INIT_DISABLE_ISR;

            when INIT_DISABLE_ISR => 
                mm_wr_req   <= '1';
                mm_wr_data_int(C_VT_CTRL_IRQ_EN_BIT)  <= '0';
                mm_addr     <= C_VT_CTRL_ADDR;
                next_state  <= IDLE;

            when RST_COUNTERS => 
                mm_wr_req   <= '1';
                mm_wr_data_int(C_VT_CTRL_VCTCXO_RESET_BIT)  <= '1';
                mm_addr     <= C_VT_CTRL_ADDR;
                next_state  <= IDLE;

            when ENABLE_COUNTERS => 
                mm_wr_req   <= '1';
                mm_wr_data_int(C_VT_CTRL_VCTCXO_RESET_BIT)  <= '0';
                mm_addr     <= C_VT_CTRL_ADDR;
                next_state  <= IDLE;

            when ISRCTRL_0 => 
                mm_wr_req   <= '1';
                mm_addr     <= C_VT_CTRL_ADDR;
                if IIIRQ_EN = '1' then 
                    mm_wr_data_int(C_VT_CTRL_IRQ_EN_BIT)  <= '1';
                else 
                    mm_wr_data_int(C_VT_CTRL_IRQ_EN_BIT)  <= '0';
                end if;
                next_state <= ISRCTRL_1;

            when ISRCTRL_1 => 
                mm_wr_req   <= '1';
                mm_addr     <= C_VT_CTRL_ADDR;
                if IIIRQ_RST = '1' then 
                    mm_wr_data_int(C_VT_CTRL_IRQ_CLR_BIT)  <= '1';
                    next_state <= ISRCTRL_2;
                else 
                    mm_wr_data_int(C_VT_CTRL_IRQ_CLR_BIT)  <= '0';
                    next_state <= IDLE;
                end if;

            when ISRCTRL_2 => 
                mm_wr_req   <= '1';
                mm_addr     <= C_VT_CTRL_ADDR;
                mm_wr_data_int(C_VT_CTRL_IRQ_CLR_BIT)  <= '0';
                next_state <= IDLE;
                
            when DISABLE => 
                mm_wr_req   <= '1';
                mm_wr_data_int  <= x"21";
                mm_addr     <= C_VT_CTRL_ADDR;
                next_state  <= IDLE;
            
            when others=>
                mm_rd_req   <= '0';
                mm_wr_req   <= '0';
                mm_addr     <= (others => '0');
                mm_wr_data_int  <= (others => '0');
        end case;
        
    end process;

    mm_wr_data <= mm_wr_data_int;


end arch; 