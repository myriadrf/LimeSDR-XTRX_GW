
-- ----------------------------------------------------------------------------	
-- FILE: 	unpack_128_to_48.vhd
-- DESCRIPTION:	unpacks bits from 128b words to 12 bit samples
-- DATE:	August 22, 2022
-- AUTHOR(s):	Lime Microsystems
-- REVISIONS:
-- ----------------------------------------------------------------------------	
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- ----------------------------------------------------------------------------
-- Entity declaration
-- ----------------------------------------------------------------------------
entity unpack_128_to_48 is
  port (
      --input ports 
        clk       		: in std_logic;
        reset_n   		: in std_logic;
		data_available	: in std_logic;
		data128_in   	: in std_logic_vector(127 downto 0);
		data128_out		: out std_logic_vector(127 downto 0);
		data_out_valid	: out std_logic;
		data_rdreq      : out std_logic
       
        );
end unpack_128_to_48;

-- ----------------------------------------------------------------------------
-- Architecture
-- ----------------------------------------------------------------------------
architecture arch of unpack_128_to_48 is

signal data128_in_reg	      : std_logic_vector(127 downto 0);
signal data128_out_int        : std_logic_vector(127 downto 0);
signal data_rdreq_int         : std_logic;
signal data_out_valid_int     : std_logic;

type t_state_type is (state0, state1, state2, state3);
signal current_state, next_state : t_state_type := state0;
				
begin

-- ----------------------------------------------------------------------------
-- State switcher
-- ----------------------------------------------------------------------------
	state_sw : process(all)
		begin
			if reset_n = '0' then
				current_state <= state0;			
			elsif rising_edge(clk) then
				current_state <= next_state;			
			end if;	
	end process;
	
-- ----------------------------------------------------------------------------
-- Input data register
-- ----------------------------------------------------------------------------
  data_reg : process(all)
    begin
      if reset_n='0' then
			data128_in_reg<=(others=>'0');
      elsif rising_edge(clk) then
         if data_available = '1' and data_rdreq_int = '1' then 
			data128_in_reg     <= data128_in;
         else 
            data128_in_reg     <= data128_in_reg;
         end if;
 	    end if;
    end process;
	
-- ----------------------------------------------------------------------------
-- FSM
-- ----------------------------------------------------------------------------

	fsm : process(all)
		begin
			next_state               <= current_state;
			data128_out_int          <= data128_out_int;
			data_out_valid_int       <= '0';
			data_rdreq_int           <= '0';
			
			case current_state is 
					
				when state0 =>
				
					data128_out_int(127 downto 112) <= data128_in(95 downto 84) & "0000";
					data128_out_int(111 downto 96 ) <= data128_in(83 downto 72) & "0000";
					data128_out_int(95  downto 80 ) <= data128_in(71 downto 60) & "0000";
					data128_out_int(79  downto 64 ) <= data128_in(59 downto 48) & "0000";
					data128_out_int(63  downto 48 ) <= data128_in(47 downto 36) & "0000";
					data128_out_int(47  downto 32 ) <= data128_in(35 downto 24) & "0000";
					data128_out_int(31  downto 16 ) <= data128_in(23 downto 12) & "0000";
					data128_out_int(15  downto 0  ) <= data128_in(11 downto 0 ) & "0000";
					
					if data_available = '1' then
					   data_rdreq_int     <= '1';
					   data_out_valid_int <= '1';
					   next_state         <= state1;
					end if;
				
				when state1 =>
				
					data128_out_int(127 downto 112) <= data128_in(63 downto 52) & "0000";
				    data128_out_int(111 downto 96 ) <= data128_in(51 downto 40) & "0000";
				    data128_out_int(95  downto 80 ) <= data128_in(39 downto 28) & "0000";
				    data128_out_int(79  downto 64 ) <= data128_in(27 downto 16) & "0000";
				    data128_out_int(63  downto 48 ) <= data128_in(15 downto 4 ) & "0000";
				    data128_out_int(47  downto 32 ) <= data128_in(3  downto 0 ) & data128_in_reg(127 downto 120) & "0000";
				    data128_out_int(31  downto 16 ) <= data128_in_reg(119 downto 108) & "0000";
				    data128_out_int(15  downto 0  ) <= data128_in_reg(107 downto 96 ) & "0000";
					
					if data_available = '1' then
					   data_rdreq_int     <= '1';
					   data_out_valid_int <= '1';
					   next_state         <= state2;
					end if;
					
				when state2 =>
				
					data128_out_int(127 downto 112) <= data128_in(31 downto 20) & "0000";
					data128_out_int(111 downto 96 ) <= data128_in(19 downto 8 ) & "0000";
					data128_out_int(95  downto 80 ) <= data128_in(7  downto 0 ) & data128_in_reg(127 downto 124) & "0000";
					data128_out_int(79  downto 64 ) <= data128_in_reg(123 downto 112) & "0000";
					data128_out_int(63  downto 48 ) <= data128_in_reg(111 downto 100) & "0000";
					data128_out_int(47  downto 32 ) <= data128_in_reg(99  downto 88 ) & "0000";
					data128_out_int(31  downto 16 ) <= data128_in_reg(87  downto 76 ) & "0000";
					data128_out_int(15  downto 0  ) <= data128_in_reg(75  downto 64 ) & "0000";
					
					if data_available = '1' then
					   data_rdreq_int     <= '1';
					   data_out_valid_int <= '1';
					   next_state         <= state3;
					end if;
					
				when state3 =>
				
					data128_out_int(127 downto 112) <= data128_in_reg(127 downto 116) & "0000";
					data128_out_int(111 downto 96 ) <= data128_in_reg(115 downto 104) & "0000";
					data128_out_int(95  downto 80 ) <= data128_in_reg(103 downto 92 ) & "0000";
					data128_out_int(79  downto 64 ) <= data128_in_reg(91  downto 80 ) & "0000";
					data128_out_int(63  downto 48 ) <= data128_in_reg(79  downto 68 ) & "0000";
					data128_out_int(47  downto 32 ) <= data128_in_reg(67  downto 56 ) & "0000";
					data128_out_int(31  downto 16 ) <= data128_in_reg(55  downto 44 ) & "0000";
					data128_out_int(15  downto 0  ) <= data128_in_reg(43  downto 32 ) & "0000";
					
					next_state            <= state0;
					data_out_valid_int    <= '1';
								
				when others => next_state <= state0;
			end case;
	end process;

    output_register_proc : process(clk)
    begin
        if rising_edge(clk) then
            data128_out    <= data128_out_int;
            data_out_valid <= data_out_valid_int;
        end if;
    end process;
    data_rdreq     <= data_rdreq_int;

end arch;   



