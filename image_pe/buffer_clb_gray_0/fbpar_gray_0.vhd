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
use work.pkg_config.all;
use work.pkg_buffer_gray_0.all;

entity fbpar_gray_0 is
port(
  clk   : in std_logic;
  rst_n : in std_logic;
  en    : in std_logic;
  nd    : in std_logic;
--  valid : out std_logic;
  iw    : in std_logic_vector(c_iw_addr_0-1 downto 0);
  di    : in std_logic_vector(d*par-1 downto 0);
  mask  : out MASKPQ);
end fbpar_gray_0;

architecture behavior of fbpar_gray_0 is

-- generisches BRAM-Modul
--component raminfr is
--generic(
--  x : integer;
--  y : integer;
--  z : integer);
--port ( 
--  clka  : in  std_logic;
--  clkb  : in  std_logic;
--  ena   : in  std_logic;
--  enb   : in  std_logic;
--  wea   : in  std_logic;
--  web   : in  std_logic;
--  addra : in  std_logic_vector(f_ramlog2(x*y) downto 0);
--  addrb : in  std_logic_vector(f_ramlog2(x*y) downto 0);
--  dia   : in  std_logic_vector(z-1 downto 0); 
--  dib   : in  std_logic_vector(z-1 downto 0);
--  doa   : out std_logic_vector(z-1 downto 0);
--  dob   : out std_logic_vector(z-1 downto 0));
--end component;

-- komplette Register-Maske
signal env: ENVPQ;

-- Register-Maske als Zeilenvektoren
signal envzw: ENVVECQ;

-- Adresszähler für BRAM-Schieberegister
signal addra, addrb: std_logic_vector(f_ramlog2(mp) downto 0); 

-- Dummy-Signal für nicht genutzten Port
signal dibzw: std_logic_vector(d*par-1 downto 0);

-- BRAM-Ports als Spaltenvektoren
signal diavec, dobvec:  COLQ; 

signal s_cnt_tresh : unsigned(c_iw_addr_0-1 downto 0);

begin

-- tresh = iw/par- ww
s_cnt_tresh <= unsigned(iw)/to_unsigned(c_par_0,c_iw_addr_0) - to_unsigned(c_ww_max_0, c_iw_addr_0); -- FIXME must be resized?

dibzw <= (others => '1');

-- (q-1) BRAM-Blöcke für Zeilen-Pufferung
BRAMARRAY: for i in q-1 downto 1 generate
  UBRAM: entity work.raminfr --FIXME see if this works
  generic map(
    x => mp,
    y => 1,
    z => d*par)
  port map( 
    clka  => clk,
    clkb  => clk,
    ena   => nd,
    enb   => nd,
    wea   => nd,
    web   => '0',
    addra => addra,
    addrb => addrb,
    dia   => diavec(i),
    dib   => dibzw,
    doa   => open,
    dob   => dobvec(i)
  );
end generate;

-- Counter für das Speichern von Daten im BRAM-FIFO
process(clk)
begin
  if clk'event and clk = '1' then
    if rst_n = '0' then  -- FIXME changed to '0'
      addra <= (others => '0'); 
    elsif en = '1' and nd ='1' then
      if unsigned(addra) < s_cnt_tresh-2 then 
        addra  <= std_logic_vector(unsigned(addra) + 1);
      else 
        addra <= (others => '0');
      end if;
    end if;
  end if;
end process;

-- Auslesen des BRAM-FIFO
process(addra,s_cnt_tresh)
begin
--  if unsigned(addra) = mp-p-2 then
  if unsigned(addra) = s_cnt_tresh-2 then 
    addrb <= (others  => '0');
  else 
    addrb <= std_logic_vector(unsigned(addra)+1);
  end if;
end process;

-- Schiebeoperation für Maskenregister
process(clk)
begin
  if clk'event and clk = '1' then
    if rst_n = '0' then  -- FIXME changed from template
--      env <= (others => (others => (others => '0')));
--      diavec <= (others => (others => '0'));  
    elsif (en='1' and nd='1') then
    for i in q-1 downto 0 loop
      for j in p-1 downto 0 loop
        if j > 0 then
          env(i)(j) <= env(i)(j-1);
        elsif j = 0 then
          if i > 0 then
            diavec(i) <= env(i-1)(p-1);
            env(i)(0) <= dobvec(i);
          else
            env(0)(0) <= di;
          end if;
        end if;
      end loop;
    end loop;
		end if;
  end if;
end process;


-- relevanten Maskenausschnitt fuer Berechnung aus env ausschneiden und mask zuweisen
process(env, envzw)
begin
  for i in q-1 downto 0 loop
    for j in p-1 downto 0 loop
      envzw(i)((j+1)*d*par-1 downto j*d*par) <= env(i)(j);
    end loop;
    mask(i) <= envzw(i)((par+p+((par*p-par-p+1)/2)-1)*d-1 downto ((par*p-par-p+1)/2)*d);
  end loop;
end process;

end behavior;
