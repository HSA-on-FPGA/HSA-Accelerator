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
use work.pkg_functions.all;

entity raminfr is
generic(
  x: integer;
  y: integer;
  z: integer
  );
port(
  clka  : in  std_logic;
  clkb  : in  std_logic;
  ena   : in  std_logic;
  enb   : in  std_logic;
  wea   : in  std_logic;
  web   : in  std_logic;
  addra : in  std_logic_vector(f_ramlog2(x*y) downto 0); 
  addrb : in  std_logic_vector(f_ramlog2(x*y) downto 0);
  dia   : in  std_logic_vector(z-1 downto 0); 
  dib   : in  std_logic_vector(z-1 downto 0);
  doa   : out std_logic_vector(z-1 downto 0);
  dob   : out std_logic_vector(z-1 downto 0));
end raminfr;

architecture syn of raminfr is

type ram_type is array (x*y-1 downto 0) of std_logic_vector (z-1 downto 0);

shared variable RAM : ram_type;

begin

process(clka)
begin
  if(clka'event and clka = '1') then
    if (ena = '1') then
      if (wea = '1') then
        RAM(to_integer(unsigned(addra))) := dia;
      end if;
      doa <= RAM(to_integer(unsigned(addra)));
    end if;
  end if;
end process;

process (clkb)
begin
  if (clkb'event and clkb = '1') then
    if (enb = '1') then
      if (web = '1') then
        RAM(to_integer(unsigned(addrb))) := dib;
      end if;
      dob <= RAM(to_integer(unsigned(addrb)));
    end if;
  end if;
end process;

end syn;
