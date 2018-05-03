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

entity reg is
generic(
  g_valuewidth: natural
);
port(
  clk   : in  std_logic;
  en    : in  std_logic;
  di    : in  std_logic_vector(g_valuewidth-1 downto 0);
  do    : out std_logic_vector(g_valuewidth-1 downto 0)
);
end entity;

architecture behavior of reg is

begin

regproc: process(clk) 
begin
  if(clk'event and clk ='1') then
    if(en='1') then
      do <= di;
    end if;
  end if;
end process;

end behavior;

