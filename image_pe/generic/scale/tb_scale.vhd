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


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use IEEE.math_real.all;



entity tb_scale_top is
end tb_scale_top;
 

  
architecture rtl of tb_scale_top is

constant DATA_IN_SIZE : integer := 32;
constant DATA_OUT_SIZE : integer := 24;

signal clk : std_logic := '0';
signal rst : std_logic := '0';

signal in_ready     : std_logic;
signal in_data      : std_logic_vector(DATA_IN_SIZE - 1 downto 0);
signal in_enable    : std_logic;
signal out_ready    : std_logic;
signal out_data     : std_logic_vector(DATA_OUT_SIZE - 1 downto 0);
signal out_enable   : std_logic;

signal data_read : std_logic_vector(DATA_OUT_SIZE - 1 downto 0);

begin

    process begin
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        wait for 5 ns;
    end process;

    process (clk) begin
        if rising_edge(clk) then
            if(out_enable = '1') then
                data_read <= out_data;
            end if;
        end if;
    end process;

    main: process
    variable next_data : unsigned(DATA_IN_SIZE - 1 downto 0) := x"aabbccdd";
    begin
        in_enable <= '0';
        in_data <= (others => '0');

        rst <= '0';
        wait for 41 ns;
        rst <= '1';
        wait until clk = '0';
        wait until clk = '1';

        in_enable <= '1';
        while(true) loop
            in_data <= std_logic_vector(next_data);
            wait until clk = '0';
            wait until clk = '1';
            --if(in_ready = '1') then
            --    next_data := next_data + 1;
            --end if;
        end loop;

    end process;

    process
    begin
        out_ready <= '1';
        wait for 300 ns;
        wait until clk = '0';
        wait until clk = '1';

        out_ready <= '0';

        wait for 300 ns;
        wait until clk = '0';
        wait until clk = '1';
    end process;

    scale_inst : entity work.scale
    generic map (
        DATA_IN_WIDTH    => DATA_IN_SIZE,
        DATA_OUT_WIDTH   => DATA_OUT_SIZE
    )
    port map (
        clk => clk,
        reset => rst,
        in_ready => in_ready,
        in_data => in_data,
        in_enable => in_enable,
        out_ready => out_ready,
        out_enable => out_enable,
        out_data => out_data
    );


end rtl;
