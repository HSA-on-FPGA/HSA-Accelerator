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

--  Package File Template
--
--  Purpose: This package defines supplemental types, subtypes, 
--     constants, and functions 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;
use work.pkg_config.all;


package pkg_buffer_0 is


-- Declare constants take from config.vhd
constant m: integer := c_iw_max_0;    -- Breite Bild
constant n: integer := c_ih_max_0;    -- Hoehe Bild
constant p: integer := c_ww_max_0;    -- Breite Sliding Window
constant q: integer := c_wh_max_0;  -- Hoehe Sliding Window
constant d: integer := c_dw_pix_max_0;    -- notwendige Datenbits pro Bildpunkt

constant par: integer := c_par_0;   -- Parallelisierungsgrad
constant mp: integer := m/par;    -- Pixelbloecke pro Zeile
constant it: integer := c_it_0; -- Iterationstiefe 

constant c_bufdelay: integer:= ((m*(q-1)+p)-1)/par;


type DPAR is array (it-1 downto 0) of std_logic_vector(d*par-1 downto 0);

-- komplette Registermaske
type COLQ  is array(q-1 downto 0) of std_logic_vector(d*par-1 downto 0);
type ROWP  is array(p-1 downto 0) of std_logic_vector(d*par-1 downto 0);
type ENVPQ is array(q-1 downto 0) of ROWP;

-- komplette Registermaske als Array von Zeilenvektoren
type ENVVECQ is array(q-1 downto 0) of std_logic_vector(p*d*par-1 downto 0);

-- gesamte Berechnungsmaske fuer alle PEs
type MASKPQ   is array(q-1 downto 0) of std_logic_vector(d*(par+p-1)-1 downto 0);
--type MASKPQIT is array(it-1 downto 0) of MASKPQ;

-- fuer Mapping zu einzelnen SWOs in fbpipe
type MASKPAR  is array((par+p-2) downto 0) of std_logic_vector(d-1 downto 0);
type MASKPARQ is array(q-1 downto 0) of MASKPAR;
--type MASKPARQIT is array(it-1 downto 0) of MASKPQ;

-- Sliding Window Masken und Arrays fuer die PEs
type SWOP   is array(p-1 downto 0) of std_logic_vector(d-1 downto 0);
type SWOPQ    is array(q-1 downto 0) of SWOP;
type SWOPQPAR is array(par-1 downto 0) of SWOPQ;
--type SWOPQPARIT is array(it-1 downto 0) of SWOPQPAR; -- shouldn't be needed in this template

--type STEUERARRAY is array (it-1 downto 0) of integer; -- FIXME see if necessary


end pkg_buffer_0;
