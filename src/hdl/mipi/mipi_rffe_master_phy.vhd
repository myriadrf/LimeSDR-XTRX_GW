----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/18/2025 04:12:54 PM
-- Design Name: 
-- Module Name: mipi_rffe_master_phy - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: Implements a basic mipi rffe master, supporting reg0_write, reg_write, reg_read
--              commands only.
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity mipi_rffe_master_phy is
    Generic(
        G_MAX_NUM_DFRAMES : integer := 4 --! 4 is max value
    );
    Port ( 
        -- Clock, Reset and Control signals
        CLK_100             : in STD_LOGIC; --! 100MHz input clock
        RESET_N             : in STD_LOGIC; --! Active low reset
        MODE                : in STD_LOGIC_VECTOR  (2  downto 0); --! 000 - reg0_write, 001 - reg_write, 010 - reg_read, 011 - idle, 100 - extended reg write, 101 - extended reg read
        COMMAND_FRAME       : in STD_LOGIC_VECTOR  (11 downto 0); --! 12 bit command frame
        DATA_FRAME          : in STD_LOGIC_VECTOR  (31  downto 0); --! 8 bit data frame
        NUM_FRAMES          : in STD_LOGIC_VECTOR  (3 downto 0);
        -- Output signals
        STATUS              : out STD_LOGIC_VECTOR (1  downto 0); --! 00 - Idle, 01 - Busy, 10 - Done, 11 - Error
        RECEIVED_DATA_FRAME : out STD_LOGIC_VECTOR (31  downto 0); --! 8 bit data frame
        -- Phy Ports
        SCLK                : out STD_LOGIC; --! Serial clock
        SDATA               : inout STD_LOGIC; --! Serial data
        DEBUG_SDATA         : out STD_LOGIC
           );
end mipi_rffe_master_phy;

architecture Behavioral of mipi_rffe_master_phy is

type T_STATE is (idle, ssc, bpc, slave_bpc, c_frame, d_frame, recv_d_frame, done);
signal current_state, next_state : T_STATE;

signal command_frame_reg                   : STD_LOGIC_VECTOR  (11 downto 0);
signal command_frame_reg_next              : STD_LOGIC_VECTOR  (11 downto 0);
signal data_frame_reg, data_frame_reg_next : STD_LOGIC_VECTOR  (31  downto 0);
signal mode_reg, mode_reg_next             : STD_LOGIC_VECTOR  (MODE'LEFT  downto 0);
signal received_data_frame_reg             : STD_LOGIC_VECTOR  (31  downto 0);
signal received_data_frame_reg_next        : STD_LOGIC_VECTOR  (31  downto 0);
signal status_reg, status_reg_next         : STD_LOGIC_VECTOR  (1  downto 0);
signal finished, finished_next             : STD_LOGIC;
signal frame_cnt, frame_cnt_next           : UNSIGNED(3 downto 0);
signal frame_num, frame_num_next           : UNSIGNED(3 downto 0);

signal counter       : UNSIGNED(3 downto 0);
signal counter_next  : UNSIGNED(3 downto 0);

signal parity_bit, parity_bit_next : STD_LOGIC;

signal comm_clk                               : STD_LOGIC;
signal comm_clk_reg                           : STD_LOGIC;
signal comm_clk_gen_en, comm_clk_gen_en_next  : STD_LOGIC;
signal comm_clk_gen_cnt                       : UNSIGNED (7 downto 0);
signal sclk_out_en, sclk_out_en_next          : STD_LOGIC;
signal error_flag, error_flag_next            : STD_LOGIC;

signal sdata_oe , sdata_oe_next  : STD_LOGIC;
signal sdata_out, sdata_out_next : STD_LOGIC;


attribute MARK_DEBUG : string;
attribute MARK_DEBUG of sdata_oe: signal is "TRUE";
attribute MARK_DEBUG of sdata_out: signal is "TRUE";
attribute MARK_DEBUG of SDATA: signal is "TRUE";
attribute MARK_DEBUG of SCLK: signal is "TRUE";
attribute MARK_DEBUG of comm_clk: signal is "TRUE";
attribute MARK_DEBUG of counter: signal is "TRUE";
attribute MARK_DEBUG of current_state: signal is "TRUE";
attribute MARK_DEBUG of parity_bit: signal is "TRUE";
attribute MARK_DEBUG of mode_reg: signal is "TRUE";
attribute MARK_DEBUG of command_frame_reg: signal is "TRUE";
attribute MARK_DEBUG of data_frame_reg: signal is "TRUE";
				
				
begin

    state_reg_proc : process(CLK_100,RESET_N)
    begin
        if RESET_N = '0' then
            current_state <= idle;
        elsif rising_edge(CLK_100) then
            current_state <= next_state;
        end if;
    end process state_reg_proc;

    fsm_proc : process(all)
    begin
        --Keep values
        next_state                   <= current_state  ;
        parity_bit_next              <= parity_bit     ;
        sclk_out_en_next             <= sclk_out_en    ;
        counter_next                 <= counter        ;
        comm_clk_gen_en_next         <= comm_clk_gen_en;
        received_data_frame_reg_next <= received_data_frame_reg;
        data_frame_reg_next          <= data_frame_reg;
        status_reg_next              <= status_reg     ;
        mode_reg_next                <= mode_reg       ;
        error_flag_next              <= error_flag     ;
        finished_next                <= finished       ;
        frame_cnt_next               <= frame_cnt      ;
        frame_num_next               <= frame_num      ;
        command_frame_reg_next       <= command_frame_reg;

        sdata_oe_next  <= sdata_oe;
        sdata_out_next <= sdata_out;

        case current_state is
            when idle =>
            
                --Reset values
                status_reg_next        <= "00";
                sclk_out_en_next       <= '0';
                parity_bit_next        <= '1';
--                parity_bit_next        <= '0';
                counter_next           <= (others => '0');
                comm_clk_gen_en_next   <= '0';
                mode_reg_next          <= (others => '0');
                sdata_oe_next          <= '0';
                sdata_out_next         <= '0';
                error_flag_next        <= '0';
                finished_next          <= '0';
                frame_cnt_next         <= (others => '0');
                frame_num_next         <= (others => '0');
                data_frame_reg_next    <= (others => '0');
                command_frame_reg_next <= (others => '0');
                --Set next state
                if mode /= "011" then
                    next_state             <= ssc;
                    mode_reg_next          <= mode;
                    command_frame_reg_next <= COMMAND_FRAME;
                    data_frame_reg_next    <= DATA_FRAME;
                    comm_clk_gen_en_next   <= '1';
                    status_reg_next        <= "01";
                    if mode = "101" or mode = "100" then
                        frame_cnt_next <= UNSIGNED(NUM_FRAMES); 
                    elsif mode = "000" then
                        frame_cnt_next <= "0000"; -- zero dframes for reg0write
                    elsif mode = "001" or mode = "010" then
                        frame_cnt_next <= "0001"; -- one dframe for regwrite/regread
                    end if;
                    
                end if;
                
            when ssc =>
                sdata_oe_next        <= '1';
                case to_integer(counter) is 
                    when 0 =>
                        -- Rising edge
                        if comm_clk = '1' and comm_clk_reg = '0' then
                            sdata_out_next       <= '1';    
                        -- Falling edge
                        elsif comm_clk = '0' and comm_clk_reg = '1' then
                            counter_next <= counter + 1;
                        end if;

                    when 1 =>
                        if comm_clk = '1' and comm_clk_reg = '0' then
                            sdata_out_next       <= '0';
                        elsif comm_clk = '0' and comm_clk_reg = '1' then
                            next_state   <= c_frame;
                            counter_next <= (others => '0');
                            sclk_out_en_next  <= '1';
                        end if;
                        
                    when others =>
                        --Should never happen, go to reset
                        next_state <= idle;
                end case;
                --
            when c_frame =>
                sdata_oe_next        <= '1';
                case to_integer(counter) is
                    when 0 to 11 =>
                        if comm_clk = '1' and comm_clk_reg = '0' then
                            -- sdata_out_next         <= command_frame_reg(command_frame_reg'LEFT);
                            -- parity_bit_next        <= parity_bit xor command_frame_reg(command_frame_reg'LEFT);
                            -- command_frame_reg_next <= command_frame_reg(command_frame_reg'LEFT - 1 downto 0) & '0';
                            sdata_out_next       <= command_frame_reg(to_integer(11-counter));
                            parity_bit_next <= parity_bit xor command_frame_reg(to_integer(11-counter));
                        elsif comm_clk = '0' and comm_clk_reg = '1' then
                            counter_next    <= counter + 1;
                        end if;

                    when 12 => 
                        if comm_clk = '1' and comm_clk_reg = '0' then
                            sdata_out_next       <= parity_bit;
                        elsif comm_clk = '0' and comm_clk_reg = '1' then
                            -- reset parity bit
                            parity_bit_next <= '1';
                            counter_next    <= (others => '0');
                            if mode_reg = "000" or mode_reg = "010" then 
                                next_state <= bpc;
                            else
                                next_state <= d_frame;
                            end if;
                        end if;

                    when others =>
                        --Should never happen, go to reset
                        next_state <= idle;

                end case;

                --
            when bpc =>
                if comm_clk = '1' and comm_clk_reg = '0' then
                    sdata_oe_next        <= '1';
                    sdata_out_next       <= '0';                    
                elsif comm_clk = '0' and comm_clk_reg = '1' then
                    sdata_oe_next        <= '0';
                    sdata_out_next       <= '0';         
                    -- BPC is used only either before handing over the bus to slave or after finishing a write
                    if finished = '1' then 
                        next_state <= done;
                    else
                        next_state <= recv_d_frame;
                    end if;           
                end if;
                
            --Handle BPC generated by slave
            when slave_bpc =>
                --do nothing, just generate clock
                if comm_clk = '1' and comm_clk_reg = '0' then
                    sdata_oe_next        <= '0';
                    sdata_out_next       <= '0';                    
                elsif comm_clk = '0' and comm_clk_reg = '1' then
                    sdata_oe_next        <= '0';
                    sdata_out_next       <= '0';         
                    next_state <= done;          
                end if;

            when d_frame =>
                sdata_oe_next        <= '1';
                case to_integer(counter) is
                    when 0 to 7 =>
                        if comm_clk = '1' and comm_clk_reg = '0' then
                            -- sdata_out_next       <= data_frame_reg(data_frame_reg'LEFT);
                            -- parity_bit_next      <= parity_bit xor data_frame_reg(data_frame_reg'LEFT);
                            -- data_frame_reg_next  <= data_frame_reg(data_frame_reg'LEFT - 1 downto 0) & '0';
                            sdata_out_next       <= data_frame_reg(to_integer(7-counter + (frame_num * 8))); 
                            parity_bit_next      <= parity_bit xor data_frame_reg(to_integer(7-counter + (frame_num * 8)));
                        elsif comm_clk = '0' and comm_clk_reg = '1' then
                            counter_next    <= counter + 1;
                        end if;

                    when 8 => 
                        if comm_clk = '1' and comm_clk_reg = '0' then
                            sdata_out_next       <= parity_bit;
                        elsif comm_clk = '0' and comm_clk_reg = '1' then
                            parity_bit_next <= '1';
                            counter_next    <= (others => '0');
                            if mode_reg = "101" then
                                -- go to bpc if extended read, do not finish transaction yet
                                finished_next   <= '0';
                                next_state      <= bpc;
                            elsif frame_num + 1 >= frame_cnt then
                                finished_next   <= '1';
                                next_state      <= bpc;--done;
                            else--counter already reset, increment frame_num and go again if there are frames remaining
                                frame_num_next  <= frame_num + 1;
                            end if;
                        end if;

                    when others =>
                        --Should never happen, go to reset
                        next_state <= idle;

                end case;            
                
            when recv_d_frame =>
                sdata_oe_next        <= '0';
                sdata_out_next       <= '0';
                case to_integer(counter) is
                    when 0 to 7 =>
                        if comm_clk = '1' and comm_clk_reg = '0' then
                            --master does nothing here
                        elsif comm_clk = '0' and comm_clk_reg = '1' then
                            received_data_frame_reg_next(to_integer(7-counter + (frame_num * 8))) <= SDATA;
                            parity_bit_next                                                       <= parity_bit xor SDATA;
                            counter_next                                                          <= counter + 1;
                        end if;

                    when 8 => 
                        if comm_clk = '1' and comm_clk_reg = '0' then
                            --master does nothing here
                        elsif comm_clk = '0' and comm_clk_reg = '1' then
                            if parity_bit /= SDATA then
                                error_flag_next <= '1';
                            end if;
                            parity_bit_next <= '1';
                            counter_next    <= (others => '0');
--                            if frame_num >= frame_cnt then
                            if frame_num + 1 >= frame_cnt then -- ORIGINAL
                                next_state      <= slave_bpc;
                                finished_next   <= '1';
                            else--counter already reset, increment frame_num and go again if there are frames remaining
                                frame_num_next  <= frame_num + 1;
                            end if;
                        end if;

                    when others =>
                        --Should never happen, go to reset
                        next_state <= idle;
                end case;


            when done =>
                sdata_oe_next        <= '0';
                sdata_out_next       <= '0';
                sclk_out_en_next     <= '0';
                comm_clk_gen_en_next <= '0';
                if error_flag = '1' then
                    status_reg_next <= "11"; --error
                else
                    status_reg_next <= "10"; --done
                end if;
                if MODE = "011" then
                    next_state <= idle;
                end if;
            when others =>
                next_state <= idle;
        end case;
    end process fsm_proc;

    comm_clk_gen_proc : process(CLK_100, RESET_N)
    begin
        if RESET_N = '0' then
            comm_clk         <= '0';
            comm_clk_reg     <= '0';
            comm_clk_gen_cnt <= (others => '0');
        elsif rising_edge(CLK_100) then
            if(comm_clk_gen_en = '1') then
                comm_clk_reg <= comm_clk;
                --5 cycles of up, 5 cycles of down generates a 10MHz clock from 100MHz
                if(comm_clk_gen_cnt >=4) then
                    comm_clk <= not comm_clk;
                    comm_clk_gen_cnt <= (others => '0');
                else
                    comm_clk_gen_cnt <= comm_clk_gen_cnt + 1;
                end if; 
            else
                comm_clk         <= '0';
                comm_clk_reg     <= '0';
                comm_clk_gen_cnt <= (others => '0');
            end if;
        end if;
    end process comm_clk_gen_proc;

    reg_proc : process(CLK_100, RESET_N)
    begin
        if RESET_N = '0' then
            counter                 <= (others => '0');
            parity_bit              <= '1';
            RECEIVED_DATA_FRAME     <= (others => '0');
            error_flag              <= '0';
            sclk_out_en             <= '0';
            comm_clk_gen_en         <= '0';
            mode_reg                <= "011";
            status_reg              <= (others => '0');
            received_data_frame_reg <= (others => '0');
            sdata_oe                <= '0';
            sdata_out               <= '0';
            finished                <= '0';
            frame_cnt               <= (others => '0');
            frame_num               <= (others => '0');
            data_frame_reg          <= (others => '0');
            command_frame_reg       <= (others => '0');
        elsif rising_edge(CLK_100) then
            counter                 <= counter_next;
            parity_bit              <= parity_bit_next;
            RECEIVED_DATA_FRAME     <= received_data_frame_reg;
            error_flag              <= error_flag_next;
            sclk_out_en             <= sclk_out_en_next;
            comm_clk_gen_en         <= comm_clk_gen_en_next;
            mode_reg                <= mode_reg_next;
            status_reg              <= status_reg_next;
            received_data_frame_reg <= received_data_frame_reg_next;
            sdata_oe                <= sdata_oe_next;
            sdata_out               <= sdata_out_next;
            finished                <= finished_next;
            frame_cnt               <= frame_cnt_next;
            frame_num               <= frame_num_next;
            data_frame_reg          <= data_frame_reg_next;
            command_frame_reg       <= command_frame_reg_next;
        end if;
    end process reg_proc;


    SCLK   <= '0' when sclk_out_en = '0' else comm_clk;
--    SDATA  <= 'Z' when sdata_oe = '0' else sdata_out;
    SDATA  <= 'Z' when sdata_oe_next = '0' else sdata_out_next;
    DEBUG_SDATA <= SDATA when sdata_oe_next = '0' else sdata_out_next;
    STATUS <= status_reg;


end Behavioral;
