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
 
entity bitonic_sort_impl is
    Generic ( ELEMENT_SIZE : Integer;
              ARRAY_SIZE : Integer );
    Port ( data_in : in std_logic_vector(ARRAY_SIZE*ELEMENT_SIZE-1 downto 0);
           data_out : out std_logic_vector(ARRAY_SIZE*ELEMENT_SIZE-1 downto 0);
           clk : in STD_LOGIC;
           en : in STD_LOGIC;
           di : in STD_LOGIC;
           do : out STD_LOGIC;
           rst : in STD_LOGIC);
end bitonic_sort_impl;

architecture Behavioral of bitonic_sort_impl is

type internal_data_type is array (natural range <>) of std_logic_vector(ELEMENT_SIZE*ARRAY_SIZE-1 downto 0);  
type internal_do_type is array (natural range <>) of std_logic;  

constant log_array_size : integer := integer(ceil(log2(real(ARRAY_SIZE))));

signal data_connections : internal_data_type(0 to log_array_size - 1);
signal do_connections : internal_do_type(0 to log_array_size - 1);

begin

    simple_case: if ARRAY_SIZE = 2 generate
        merger: entity work.bitonic_merge_1
                    generic map(
                            ELEMENT_SIZE => ELEMENT_SIZE,
                            ARRAY_SIZE => ARRAY_SIZE
                        )
                    port map(
                        clk => clk,
                        en => en,
                        di => di,
                        do => do,
                        data_in => data_in,
                        data_out => data_out,
                        rst => rst
                    );
    end generate simple_case;

    larger_case: if ARRAY_SIZE > 2 generate
        merge1: entity work.bitonic_merge_1
             generic map(
                 ELEMENT_SIZE => ELEMENT_SIZE,
                 ARRAY_SIZE => ARRAY_SIZE
             )
             port map(
                 clk => clk,
                 en => en,
                 di => di,
                 do => do_connections(0),
                 data_in => data_in,
                 data_out => data_connections(0),
                 rst => rst
             );
        merges2: for I in 0 to log_array_size - 2 generate
            inst: for I2 in 0 to 2**(I+1)-1 generate
                u0: if I2 = 0 generate
                    m: entity work.bitonic_merge_2
                        generic map(
                            ELEMENT_SIZE => ELEMENT_SIZE,
                            ARRAY_SIZE => ARRAY_SIZE/(2**(I+1))
                        )
                        port map(
                            clk => clk,
                            en => en,
                            do => do_connections(I+1),
                            di => do_connections(I),
                            data_in => data_connections(I)((I2+1) * ELEMENT_SIZE * ARRAY_SIZE/(2**(I+1)) - 1 downto I2 * ELEMENT_SIZE * ARRAY_SIZE/(2**(I+1))),
                            data_out => data_connections(I+1)((I2+1) * ELEMENT_SIZE * ARRAY_SIZE/(2**(I+1)) - 1 downto I2 * ELEMENT_SIZE * ARRAY_SIZE/(2**(I+1))),
                            rst => rst
                        );
                end generate u0;
                ux: if I2 > 0 generate
                    m: entity work.bitonic_merge_2
                    generic map(
                        ELEMENT_SIZE => ELEMENT_SIZE,
                        ARRAY_SIZE => ARRAY_SIZE/(2**(I+1))
                    )
                    port map(
                        clk => clk,
                        en => en,
                        di => do_connections(I),
                        data_in => data_connections(I)((I2+1) * ELEMENT_SIZE * ARRAY_SIZE/(2**(I+1)) - 1 downto I2 * ELEMENT_SIZE * ARRAY_SIZE/(2**(I+1))),
                        data_out => data_connections(I+1)((I2+1) * ELEMENT_SIZE * ARRAY_SIZE/(2**(I+1)) - 1 downto I2 * ELEMENT_SIZE * ARRAY_SIZE/(2**(I+1))),
                        rst => rst
                    );           
                end generate ux;
            end generate inst;
        end generate merges2;
        data_out <= data_connections(log_array_size - 1);
        do <= do_connections(log_array_size - 1);
        
    end generate larger_case;
  
end Behavioral;
