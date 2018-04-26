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
use ieee.numeric_std.all;

entity mux2 is
generic(
  g_valuewidth : natural
);
port(
  di_a : in  std_logic_vector(g_valuewidth-1 downto 0);
  di_b : in  std_logic_vector(g_valuewidth-1 downto 0);
  sel  : in  std_logic;
  do   : out std_logic_vector(g_valuewidth-1 downto 0)
);
end mux2;

architecture behavior of mux2 is
begin

process(sel,di_a,di_b)
begin
  if(sel='0') then
    do <= di_a;
  else
    do <= di_b;
  end if;
end process;

end behavior;
