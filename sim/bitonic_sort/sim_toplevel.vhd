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

----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/13/2016 01:11:40 PM
-- Design Name: 
-- Module Name: sim_toplevel - Behavioral
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
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
use ieee.math_real.all;

entity sim_toplevel is
--  Port ( );
end sim_toplevel;

architecture Behavioral of sim_toplevel is

    constant ELEMENT_SIZE : integer := 8; 
    constant ARRAY_SIZE : integer := 81;

    signal clk : std_logic := '0';
    signal rst : std_logic := '0';
    
    
    type internal_data_type is array (natural range <>) of std_logic_vector(ELEMENT_SIZE-1 downto 0);  
    
    signal data_in : internal_data_type(ARRAY_SIZE-1 downto 0);
    signal data_out : internal_data_type(ARRAY_SIZE-1 downto 0);

    
    signal data_in_vec : STD_LOGIC_VECTOR(ELEMENT_SIZE * ARRAY_SIZE - 1 downto 0);
    signal data_out_vec :  STD_LOGIC_VECTOR(ELEMENT_SIZE * ARRAY_SIZE - 1 downto 0);
    
    signal valid : STD_LOGIC;
    signal nd : STD_LOGIC;
    
    --signal median_out : STD_LOGIC_VECTOR(ELEMENT_SIZE - 1 downto 0);

begin

    rst_proc: process
    begin
        nd <= '0';
        rst <= '0';
        wait for 100 ns;
        rst <= '1';
        wait for 40 ns;
        nd <= '1';
        wait for 200 ns;
        nd <= '0';
        wait;
    end process;

    clk_proc: process
    begin
        wait for 10 ns;
        clk <= '1';
        wait for 10 ns;
        clk <= '0';
    end process;
    
    assemble_vectors: for I in 0 to ARRAY_SIZE-1 generate
        data_in_vec((I+1)*ELEMENT_SIZE-1 downto I*ELEMENT_SIZE) <= data_in(I);
        data_out(I) <= data_out_vec((I+1)*ELEMENT_SIZE-1 downto I*ELEMENT_SIZE);
    end generate;

    generate_data: process
    variable seed1,seed2 : positive;
    variable rand : real;
    variable range_of_rand : real := real(2**ELEMENT_SIZE - 1);
    begin
	wait for 20 ns;
        for I in 0 to ARRAY_SIZE-1 loop
            uniform(seed1, seed2, rand);
            data_in(I) <= std_logic_vector(to_unsigned(integer(rand*range_of_rand), data_in(I)'length));
        end loop;
    end process;
    
    sorter: entity work.bitonic_sort
        generic map(
            ELEMENT_SIZE => ELEMENT_SIZE,
            ARRAY_SIZE => ARRAY_SIZE
        )
        port map(
            data_in => data_in_vec,
            data_out => data_out_vec,
            clk => clk,
            en => '1',
            nd => nd,
            valid => valid,
            rst => rst
        );

--    medianer: entity work.bitonic_median
--        generic map(
--            ELEMENT_SIZE => ELEMENT_SIZE,
--            ARRAY_SIZE => ARRAY_SIZE
--        )
--        port map(
--            data_in => data_in_vec,
--            median_out => median_out,
--            clk => clk,
--            en => '1',
--            nd => nd,
--            valid => valid,
--            rst => rst
--        ); 

end Behavioral;
