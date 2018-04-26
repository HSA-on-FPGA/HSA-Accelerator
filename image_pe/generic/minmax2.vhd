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

entity minmax2 is
generic(
  g_min          : boolean;  -- true for min detection, false for max detection
  g_valuewidth   : integer;
  g_vectoraddrwidth : integer
);
port(
  di_a : in std_logic_vector(g_valuewidth+g_vectoraddrwidth-1 downto 0);
  di_b : in std_logic_vector(g_valuewidth+g_vectoraddrwidth-1 downto 0);
  do   : out std_logic_vector(g_valuewidth+g_vectoraddrwidth-1 downto 0)
  );
end minmax2;

architecture behavior of minmax2 is

constant c_val_minmax : integer:= g_valuewidth+g_vectoraddrwidth;
signal  s_bcomp,s_acomp : unsigned(g_valuewidth-1 downto 0);
--signal  s_a,s_b : std_logic_vector(c_val_minmax-1 downto 0);
--signal  s_val :std_logic_vector(c_val_minmax-1 downto 0);

begin
  
s_acomp <= unsigned(di_a(c_val_minmax-1 downto g_vectoraddrwidth));  
s_bcomp <= unsigned(di_b(c_val_minmax-1 downto g_vectoraddrwidth));

-- Minimun detection

mingen: if(g_min = true) generate
  mincompare : process(di_a, di_b, s_acomp, s_bcomp)
  begin
    if (s_acomp < s_bcomp) then
      do <= di_a;
    else
      do <= di_b;
    end if;
  end process;
end generate;

-- Maximun detection

maxgen: if(g_min = false) generate
  maxcompare : process(di_a, di_b, s_acomp, s_bcomp)
  begin
    if (s_acomp > s_bcomp) then
      do <= di_a;
    else
      do <= di_b;
    end if;
  end process;
end generate;

end behavior;
