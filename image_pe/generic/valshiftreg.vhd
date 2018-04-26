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

entity valshiftreg is
generic(
  g_length : natural
);
port(
  clk   : in  std_logic;
  rst_n : in  std_logic;
  en    : in  std_logic;
  di    : in  std_logic;
  do    : out std_logic
);
end valshiftreg;

architecture behavior of valshiftreg is

type SHIFTREG is array (0 to g_length-1) of std_logic;
signal shift : SHIFTREG;

begin

shiftproc : process(clk)
begin
  if(clk 'event and clk = '1') then
    if (rst_n ='0') then
      shift <= (others=>'0');
    elsif(en = '1') then
      shift(0) <= di;
      for i in 1 to g_length-1 loop
        shift(i) <= shift(i-1);
      end loop;
    end if;
  end if;
end process;

do <= shift(g_length-1);


end behavior;
