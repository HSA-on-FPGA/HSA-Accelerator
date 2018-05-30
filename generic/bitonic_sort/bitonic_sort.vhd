--
-- Copyright 2017 Konrad Haeublein
--
-- konrad.haeublein@fau.de
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.all;
 
entity bitonic_sort is
    Generic ( ELEMENT_SIZE : Integer := 8;
              ARRAY_SIZE : Integer := 25 );
    Port ( data_in : in std_logic_vector(ARRAY_SIZE*ELEMENT_SIZE-1 downto 0);
           data_out : out std_logic_vector(ARRAY_SIZE*ELEMENT_SIZE-1 downto 0);
           clk : in STD_LOGIC;
           en : in STD_LOGIC;
           nd : in STD_LOGIC;
           valid : out STD_LOGIC;
           rst : in STD_LOGIC);
end bitonic_sort;

architecture Behavioral of bitonic_sort is

constant INTERNAL_ARRAY_SIZE : integer := integer(2**ceil(log2(real(ARRAY_SIZE))));

signal internal_data_in : std_logic_vector(INTERNAL_ARRAY_SIZE * ELEMENT_SIZE - 1 downto 0);
signal internal_data_out : std_logic_vector(INTERNAL_ARRAY_SIZE * ELEMENT_SIZE - 1 downto 0);

type internal_data_type is array (natural range <>) of std_logic_vector(ELEMENT_SIZE*INTERNAL_ARRAY_SIZE-1 downto 0);  
type internal_do_type is array (natural range <>) of std_logic;  


constant log_array_size : integer := integer(ceil(log2(real(INTERNAL_ARRAY_SIZE))));

signal data_connections : internal_data_type(0 to log_array_size);
signal do_connections : internal_do_type(0 to log_array_size);

begin

    data_in_proc: process(data_in)
    begin
        internal_data_in <= (others => '1');
        internal_data_in(ARRAY_SIZE*ELEMENT_SIZE-1 downto 0) <= data_in;
    end process;

    data_out <= internal_data_out(ARRAY_SIZE*ELEMENT_SIZE - 1 downto 0);

    data_connections(0) <= internal_data_in;
    internal_data_out <= data_connections(log_array_size);
    do_connections(0) <= nd;
    valid <= do_connections(log_array_size);


--    m: entity work.bitonic_sort_impl
--        generic map(
--            ELEMENT_SIZE => ELEMENT_SIZE,
--            ARRAY_SIZE => INTERNAL_ARRAY_SIZE
--        )
--        port map(
--            data_in => internal_data_in,
--            data_out => internal_data_out,
--            clk => clk,
--            en => en,
--            di => nd,
--            do => valid,
--            rst => rst
--        );

    stages: for I in 1 to log_array_size generate
        mergers: for K in 1 to 2**(log_array_size-I) generate
            u0: if K = 1 generate
                m: entity work.bitonic_sort_impl
                    generic map(
                        ELEMENT_SIZE => ELEMENT_SIZE,
                        ARRAY_SIZE => INTERNAL_ARRAY_SIZE/(2**(log_array_size - I))
                    )
                    port map(
                        data_in => data_connections(I - 1)(INTERNAL_ARRAY_SIZE*ELEMENT_SIZE/(2**(log_array_size - I)) - 1 + (K-1) * ELEMENT_SIZE*INTERNAL_ARRAY_SIZE/(2**(log_array_size - I)) downto (K-1) * ELEMENT_SIZE*INTERNAL_ARRAY_SIZE/(2**(log_array_size - I))),
                        data_out => data_connections(I)(INTERNAL_ARRAY_SIZE*ELEMENT_SIZE/(2**(log_array_size - I)) - 1 + (K-1) * ELEMENT_SIZE*INTERNAL_ARRAY_SIZE/(2**(log_array_size - I)) downto (K-1) * ELEMENT_SIZE*INTERNAL_ARRAY_SIZE/(2**(log_array_size - I))),
                        clk => clk,
                        en => en,
                        di => do_connections(I-1),
                        do => do_connections(I),
                        rst => rst
                    );
            end generate u0;
            ux: if K > 1 generate
                m: entity work.bitonic_sort_impl
                    generic map(
                        ELEMENT_SIZE => ELEMENT_SIZE,
                        ARRAY_SIZE => INTERNAL_ARRAY_SIZE/(2**(log_array_size - I))
                    )
                    port map(
                        data_in => data_connections(I - 1)(INTERNAL_ARRAY_SIZE*ELEMENT_SIZE/(2**(log_array_size - I)) - 1 + (K-1) * ELEMENT_SIZE*INTERNAL_ARRAY_SIZE/(2**(log_array_size - I)) downto (K-1) * ELEMENT_SIZE*INTERNAL_ARRAY_SIZE/(2**(log_array_size - I))),
                        data_out => data_connections(I)(INTERNAL_ARRAY_SIZE*ELEMENT_SIZE/(2**(log_array_size - I)) - 1 + (K-1) * ELEMENT_SIZE*INTERNAL_ARRAY_SIZE/(2**(log_array_size - I)) downto (K-1) * ELEMENT_SIZE*INTERNAL_ARRAY_SIZE/(2**(log_array_size - I))),
                        clk => clk,
                        en => en,
                        di => do_connections(I-1),
                        rst => rst
                    );
            end generate ux;
                
        end generate mergers;
    end generate stages;

end Behavioral;
