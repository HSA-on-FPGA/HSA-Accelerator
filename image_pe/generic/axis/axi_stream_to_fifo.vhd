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

entity axi_stream_to_fifo is
generic(
  AXIS_DATA_WIDTH : integer
);
port( 
  clk : in std_logic;
  en : in std_logic;
  rst_n : in std_logic;
  fifo_data_in : out std_logic_vector(AXIS_DATA_WIDTH - 1 downto 0);
  fifo_write_enable : out std_logic;
  fifo_full : in std_logic;
  axi_tdata : in std_logic_vector(AXIS_DATA_WIDTH - 1 downto 0);
  axi_tvalid : in std_logic;
  axi_tready : out std_logic
);
end axi_stream_to_fifo;

architecture Behavioral of axi_stream_to_fifo is

signal s_fifo_valid,s_axi_tready,s_fifo_write_enable: std_logic;

begin

process(fifo_full)
begin
  if fifo_full='1' then
		s_fifo_valid <='0';
	else
		s_fifo_valid <='1';
  end if;
end process;

s_axi_tready <= '1' when s_fifo_valid='1' else '0';
s_fifo_write_enable <= '1' when s_fifo_valid='1' and axi_tvalid = '1' else '0';


write_fifo: process(clk)
begin  
  if(clk'event and clk='1') then
    if(rst_n='0') then
      fifo_data_in <= (others=>'1');
			fifo_write_enable <= '0';
    elsif(en='1') then
      fifo_data_in <= axi_tdata;
      fifo_write_enable <= s_fifo_write_enable;
    end if;
  end if;
end process;

axi_tready <= s_axi_tready;


end Behavioral;
