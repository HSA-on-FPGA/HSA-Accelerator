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

entity bitonic_merge_1 is
    Generic ( ELEMENT_SIZE : Integer := 8;
              ARRAY_SIZE : Integer := 16 );
    Port ( data_in : in std_logic_vector(ARRAY_SIZE*ELEMENT_SIZE-1 downto 0);
           data_out : out std_logic_vector(ARRAY_SIZE*ELEMENT_SIZE-1 downto 0);
           clk : in STD_LOGIC;
           en : in STD_LOGIC;
           di : in STD_LOGIC;
           do : out STD_LOGIC;
           rst : in STD_LOGIC);
end bitonic_merge_1;

architecture Behavioral of bitonic_merge_1 is

type internal_data_type is array (natural range <>) of std_logic_vector(ELEMENT_SIZE-1 downto 0);  

signal data_sig_in : internal_data_type(ARRAY_SIZE-1 downto 0);
signal data_sig_out : internal_data_type(ARRAY_SIZE-1 downto 0);

begin

    data_input: process(clk)
    begin
        if rising_edge(clk) then
            if rst = '0' then
--                data_sig_in <= (others => (others => '0'));
                do <= '0';
            elsif en = '1' then
                do <= di;
                if di = '1' then
                    for I in 0 to (ARRAY_SIZE-1) loop
                        data_sig_in(I) <= data_in((I+1)*ELEMENT_SIZE-1 downto I*ELEMENT_SIZE);
                    end loop;
                end if;
            end if;
        end if;
    end process;

    data_output: process(data_sig_out)
    begin
        for I in 0 to ARRAY_SIZE-1 loop
            data_out((I+1)*ELEMENT_SIZE-1 downto I*ELEMENT_SIZE) <= data_sig_out(I);
        end loop;
    end process;

    mergers: for I in 0 to ARRAY_SIZE/2 - 1 generate begin
        m: entity work.swap
                generic map(
                        g_valuewidth => ELEMENT_SIZE
                    )
                port map(
                    di_a => data_sig_in(I),
                    di_b => data_sig_in(ARRAY_SIZE-1-I),
                    do_a => data_sig_out(I),
                    do_b => data_sig_out(ARRAY_SIZE-1-I)
                );
    end generate mergers;


end Behavioral;
