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

entity swap is
generic(
  g_valuewidth : natural
);
port(
  di_a : in  std_logic_vector(g_valuewidth-1 downto 0);
  di_b : in  std_logic_vector(g_valuewidth-1 downto 0);
  do_a : out std_logic_vector(g_valuewidth-1 downto 0);
  do_b : out std_logic_vector(g_valuewidth-1 downto 0)
);
end swap;

architecture behavior of swap is
begin

process(di_a,di_b)
begin
  if(unsigned(di_a) < unsigned(di_b)) then
    do_a <= di_a; 
    do_b <= di_b;
  else
    do_a <= di_b; 
    do_b <= di_a;
  end if;
end process;

end behavior;
