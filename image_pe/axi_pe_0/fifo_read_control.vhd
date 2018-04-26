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
-- Create Date: 05/11/2016 07:14:07 PM
-- Design Name: 
-- Module Name: fifo_to_axi_stream - Behavioral
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

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
library ieee;
use ieee.math_real.all;

entity fifo_read_control is
    Generic (   
               DATA_WIDTH : integer:=32
    );
    Port ( fifo_empty : in STD_LOGIC;
           fifo_data_out : in STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
           fifo_read_enable : out STD_LOGIC;
           control_data_out : out STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
           control_data_valid : out STD_LOGIC;
           control_data_req : in STD_LOGIC;
           clk : in STD_LOGIC;
           rst_n : in STD_LOGIC);
end fifo_read_control;

architecture Behavioral of fifo_read_control is


signal data_word : STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0) := (others => '0');
signal data_word_ready,data_req : STD_LOGIC := '0'; -- TODO try if works without init!!
signal data_word_will_be_read : STD_LOGIC := '0';
signal data_word_needs_new_data : STD_LOGIC := '1';


begin

    control_data_valid <= data_word_ready;
    control_data_out <= data_word;
		data_req <= control_data_req;

    -- data word is the output of the fifo, as the fifo buffers one word anyway
    data_word <= fifo_data_out;

    -- signals wether the data word will get invalidated during next clk
    data_word_will_be_read <= '1' when data_req = '1' and data_word_ready = '1' else '0'; 
    data_word_needs_new_data <= '1' when data_word_will_be_read = '1' or data_word_ready = '0' else '0';

    -- process is responsible for pulling data out of the fifo into data_word
    fifo_read_enable <= '1' when data_word_needs_new_data = '1' and fifo_empty = '0' else '0';
    read_from_fifo: process(clk)
    begin
      if rising_edge(clk) then
        if rst_n='0' then
            data_word_ready <= '0';
        else
        --    data_word_ready <= data_word_ready; -- required?
        
            if data_word_needs_new_data = '1' then
                if fifo_empty = '0' then
                    data_word_ready <= '1';
                else
                    data_word_ready <= '0';
                end if;
            end if;
        end if;    
      end if;    
    end process;

end Behavioral;
