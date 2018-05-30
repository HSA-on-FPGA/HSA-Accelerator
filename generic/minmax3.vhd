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


entity minmax3 is
generic(
  g_min : boolean;  -- true for min detection, false for max detection
  g_valuewidth : integer;
  g_vectoraddrwidth: integer
);
port(
  di_a : in std_logic_vector(g_valuewidth+g_vectoraddrwidth-1 downto 0);
  di_b : in std_logic_vector(g_valuewidth+g_vectoraddrwidth-1 downto 0);
  di_c : in std_logic_vector(g_valuewidth+g_vectoraddrwidth-1 downto 0);
  do   : out std_logic_vector(g_valuewidth+g_vectoraddrwidth-1 downto 0)
);
end entity;

architecture behavior of minmax3 is

signal s_dint: std_logic_vector(g_valuewidth+g_vectoraddrwidth-1 downto 0);

component minmax2 is
generic(
  g_valuewidth : integer;
  g_vectoraddrwidth: integer;
  g_min : boolean  -- true for min detection, false for max detection
);
port(
  di_a : in std_logic_vector(g_valuewidth+g_vectoraddrwidth-1 downto 0);
  di_b : in std_logic_vector(g_valuewidth+g_vectoraddrwidth-1 downto 0);
  do   : out std_logic_vector(g_valuewidth+g_vectoraddrwidth-1 downto 0)
);
end component;

begin

m1 : minmax2
generic map(
  g_min        => g_min,
  g_valuewidth => g_valuewidth,
  g_vectoraddrwidth => g_vectoraddrwidth
)
port map(
  di_a => di_a,
  di_b => di_b,
  do   => s_dint
);

m2 : minmax2
generic map(
  g_min        => g_min,
  g_valuewidth => g_valuewidth,
  g_vectoraddrwidth => g_vectoraddrwidth
)
port map(
  di_a => s_dint,
  di_b => di_c,
  do   => do
);

end behavior;
