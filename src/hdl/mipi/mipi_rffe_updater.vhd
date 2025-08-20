----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/19/2025 12:56:14 PM
-- Design Name: 
-- Module Name: mipi_rffe_updater - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity mipi_rffe_updater is
    Generic(
        G_SLAVE_ADDR   : STD_LOGIC_VECTOR(3 downto 0); --! Slave device address
        G_TEST_ADDR    : STD_LOGIC_VECTOR(4 downto 0); --! Address of test register
        G_TEST_VAL     : STD_LOGIC_VECTOR(7 downto 0); --! Expected value of test register
        G_TARGET_ADDR  : STD_LOGIC_VECTOR(4 downto 0)  --! Where to write data_in
    );
    Port ( 
        CLK          : in STD_LOGIC; --! Clock signal, 100MHz expected
        RESET_N      : in STD_LOGIC; --! Active low reset
        INTERFACE_OK : out STD_LOGIC_VECTOR(1 downto 0); --! "11" when interface is ok, "01" - data error, "10" - parity error, "00" - data and parity error
        TEST_DONE    : out STD_LOGIC; --! '1' when test is complete
        DATA_IN      : in STD_LOGIC_VECTOR (7 downto 0); --! Data to write. Written when changes are detected
        -- Interface ports
        SCLK         : out STD_LOGIC; --! Serial clock
        SDATA        : inout STD_LOGIC --! Serial data

           );
end mipi_rffe_updater;

architecture Behavioral of mipi_rffe_updater is

    signal mode, mode_next             : std_logic_vector(1 downto 0);
    signal comm_frame, comm_frame_next : std_logic_vector(11 downto 0);
    signal data_frame, data_frame_next : std_logic_vector(7 downto 0);
    signal status                      : std_logic_vector(1 downto 0);
    signal recv_frame                  : std_logic_vector(7 downto 0);

    signal interface_ok_reg, interface_ok_next : std_logic_vector(1 downto 0);
    signal test_done_reg,    test_done_next    : std_logic;

    type T_STATE is (reset_state, test, fail, wait_for_update, update, waiting_for_clear);
    signal current_state, next_state : T_STATE;

    signal data_in_reg              : std_logic_vector(7 downto 0);
    signal data_in_changed          : std_logic;
    signal data_in_changed_rst      : std_logic;
    signal data_in_changed_rst_next : std_logic;

    constant C_STATUS_DONE  : std_logic_vector(1 downto 0) := "10"; --Done
    constant C_STATUS_FAIL  : std_logic_vector(1 downto 0) := "11"; --Error
    constant C_STATUS_IDLE  : std_logic_vector(1 downto 0) := "00"; --Idle

    constant C_MODE_READ   : std_logic_vector(1 downto 0) := "10"; 
    constant C_MODE_WRITE  : std_logic_vector(1 downto 0) := "01"; 
    constant C_MODE_IDLE   : std_logic_vector(1 downto 0) := "11"; 
    
    attribute MARK_DEBUG : string;
    attribute MARK_DEBUG of current_state: signal is "TRUE";
    attribute MARK_DEBUG of INTERFACE_OK: signal is "TRUE";
    attribute MARK_DEBUG of TEST_DONE: signal is "TRUE";
    attribute MARK_DEBUG of RESET_N: signal is "TRUE";
    
begin

    data_monitor_proc : process(CLK, RESET_N)
    begin
        if RESET_N = '0' then 
            data_in_reg     <= (others => '0');
            data_in_changed <= '0';
        elsif (rising_edge(CLK)) then 
            data_in_reg     <= DATA_IN;
            if data_in_changed_rst = '1' then
                data_in_changed <= '0';
            else
                if data_in_reg /= DATA_IN then
                    data_in_changed <= '1';
                end if;
            end if;
        end if;
    end process;

    mipi_phy_inst: entity work.mipi_rffe_master_phy
      port map (
         CLK_100             => CLK                 ,
         RESET_N             => RESET_N             ,
         MODE                => mode                ,
         COMMAND_FRAME       => comm_frame          ,
         DATA_FRAME          => data_frame          ,
         -- Output signals   
         STATUS              => status              ,  
         RECEIVED_DATA_FRAME => recv_frame          ,
         -- Phy Ports        
         SCLK                => SCLK                 ,
         SDATA               => SDATA                
      );

    reg_proc : process(CLK, RESET_N)
    begin
        if RESET_N = '0' then 
            current_state       <= reset_state;
            data_frame          <= (others => '0');
            comm_frame          <= (others => '0');
            mode                <= C_MODE_IDLE;
            interface_ok_reg    <= (others => '0');
            test_done_reg       <= '0';
            data_in_changed_rst <= '0';
        elsif (rising_edge(CLK)) then 
            current_state       <= next_state;
            data_frame          <= data_frame_next;
            comm_frame          <= comm_frame_next;
            mode                <= mode_next;
            interface_ok_reg    <= interface_ok_next;
            test_done_reg       <= test_done_next;
            data_in_changed_rst <= data_in_changed_rst_next;
        end if;
    end process;

    fsm_proc : process(all)
    begin
        next_state               <= current_state;
        data_frame_next          <= data_frame;
        comm_frame_next          <= comm_frame;
        mode_next                <= mode;
        interface_ok_next        <= interface_ok_reg;
        test_done_next           <= test_done_reg;
        data_in_changed_rst_next <= data_in_changed_rst;

        case current_state is
            when reset_state =>
                comm_frame_next <= (others => '0');
                data_frame_next <= (others => '0');
                mode_next       <= C_MODE_IDLE;
                data_in_changed_rst_next <= '0';
                next_state <= test;
                --
            when test =>
                --Order a register read
                comm_frame_next <= G_SLAVE_ADDR & "011" & G_TEST_ADDR;
                mode_next       <= C_MODE_READ;
                if status = C_STATUS_DONE then
                    test_done_next    <= '1';
                    if (recv_frame = G_TEST_VAL) then
                        interface_ok_next <= "11"; -- parity and data ok
                        next_state        <= wait_for_update;
                        mode_next         <= C_MODE_IDLE; -- set to idle
                    else
                        interface_ok_next <= "01"; -- parity ok, data nok
                        next_state        <= fail;
                        mode_next         <= C_MODE_IDLE; -- set to idle
                    end if;
                elsif status = C_STATUS_FAIL then
                    if (recv_frame = G_TEST_VAL) then
                        interface_ok_next <= "10"; -- parity nok, data ok
                        next_state        <= fail;
                        mode_next         <= C_MODE_IDLE; -- set to idle
                    else
                        interface_ok_next <= "00"; -- parity nok, data nnok
                        next_state        <= fail;
                        mode_next         <= C_MODE_IDLE; -- set to idle
                    end if;
                end if;
                
            when fail =>
                mode_next         <= C_MODE_IDLE; -- set to idle
                -- Interface does not work, sit here, do nothing

            when wait_for_update =>
                if data_in_changed = '1' then
                    next_state <= update;
                end if;

            when update =>
                --Order a register write
                comm_frame_next <= G_SLAVE_ADDR & "010" & G_TARGET_ADDR;
                data_frame_next <= data_in_reg;
                mode_next       <= C_MODE_WRITE;
                --Error state cannot be reached for write operations
                if status = C_STATUS_DONE then
                    data_in_changed_rst_next <= '1';
                    next_state               <= waiting_for_clear;
                    mode_next                <= C_MODE_IDLE; -- set to idle
                end if;

            when waiting_for_clear =>
                if data_in_changed = '0' and status = C_STATUS_IDLE then
                    data_in_changed_rst_next <= '0';
                    next_state               <= wait_for_update;
                    mode_next                <= C_MODE_IDLE; -- set to idle
                end if;
                --
            when others => next_state <= reset_state;
        end case;
    end process;

    INTERFACE_OK <= interface_ok_reg;
    TEST_DONE    <= test_done_reg;


end Behavioral;
