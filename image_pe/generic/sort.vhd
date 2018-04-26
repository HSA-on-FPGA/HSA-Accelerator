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

entity sort is
generic(
  g_valuewidth : natural;
  g_vectorsize : natural
);
port(
  clk   : in  std_logic;
  rst_n : in  std_logic;
  en    : in  std_logic;
  nd    : in  std_logic;
  valid : out std_logic;
  di    : in std_logic_vector(g_vectorsize*g_valuewidth-1 downto 0);
  do    : out std_logic_vector(g_vectorsize*g_valuewidth-1 downto 0)
);
end entity;

architecture behavior of sort is


type VEC_SORT is array(0 to g_vectorsize-1) of std_logic_vector(g_valuewidth-1 downto 0);
type ARRAY_SORT is array(0 to g_vectorsize) of VEC_SORT;

signal s_swapin, s_swapout : ARRAY_SORT;


component swap
generic(
  g_valuewidth: natural
);
port(
  di_a  : in  std_logic_vector(g_valuewidth-1 downto 0);
  di_b  : in  std_logic_vector(g_valuewidth-1 downto 0);
  do_a  : out std_logic_vector(g_valuewidth-1 downto 0);
  do_b  : out std_logic_vector(g_valuewidth-1 downto 0)
);
end component;

component reg
generic(
  g_valuewidth: natural
);
port(
  clk   : in  std_logic;
  rst_n : in  std_logic;
  en    : in  std_logic;
  di    : in  std_logic_vector(g_valuewidth-1 downto 0);
  do    : out std_logic_vector(g_valuewidth-1 downto 0)
);
end component;

component valshiftreg
generic(
  g_length: natural
);
port(
  clk   : in  std_logic;
  rst_n : in  std_logic;
  en    : in  std_logic;
  di    : in  std_logic;
  do    : out std_logic
);
end component;

begin


read_in_out: for i in 0 to g_vectorsize-1 generate
begin
  s_swapin(0)(i) <= di((i+1)*g_valuewidth-1 downto i*g_valuewidth); --connect all value inputs to first line of sig array
  do((i+1)*g_valuewidth-1 downto i*g_valuewidth) <= s_swapout(g_vectorsize-1)(i); -- connect to output
end generate;


stagegen: for i in 0 to g_vectorsize-1 generate
begin

  ev_stagegen : if (even(i)= true) generate -- for even stages 
    ev_swapin : for j in 0 to g_vectorsize/2-1 generate -- vecsize/2 swap
    begin

      ev_swapgen : swap
      generic map(
        g_valuewidth => g_valuewidth
      )
      port map(
        di_a  => s_swapin(i)(2*j),
        di_b  => s_swapin(i)(2*j+1),  -- every second input to sort input
        do_a  => s_swapout(i)(2*j),
        do_b  => s_swapout(i)(2*j+1)  -- every second input to sort output
      );
    end generate;

    ev_unvenvec : if(even(g_vectorsize) = false) generate
      s_swapout(i)(g_vectorsize-1) <= s_swapin(i)(g_vectorsize-1); -- if uneven vec size pass last signal!!
    end generate;

  end generate;
  

  un_stagegen : if (even(i) = false) generate -- TODO and now for uneven stages ....

    s_swapout(i)(0) <= s_swapin(i)(0); -- pass first signal

    un_swapin : for j in 0 to (g_vectorsize-1)/2-1 generate
    begin
       
      un_swapgen : swap
      generic map(
        g_valuewidth => g_valuewidth
      )
      port map(
        di_a  => s_swapin(i)(2*j+1),
        di_b  => s_swapin(i)(2*j+2),  -- every second input to sort input
        do_a  => s_swapout(i)(2*j+1),
        do_b  => s_swapout(i)(2*j+2)  -- every second input to sort output
      );
    end generate;
    
    un_unevenvec: if (even(g_vectorsize)= true) generate 
      s_swapout(i)(g_vectorsize-1) <= s_swapin(i)(g_vectorsize-1); -- if uneven vec size pass last signal!!
    end generate;
		
	end generate;
 
-- Generate Registers
 
  reg_gen: for j in 0 to g_vectorsize-1 generate
  begin
    regi : reg
      generic map(
        g_valuewidth => g_valuewidth
      )
    port map(
      clk => clk,
      rst_n => rst_n,
      en => en,
      di => s_swapout(i)(j), -- save swapout out in register
      do => s_swapin(i+1)(j) -- pass register value to next stage
    );
  end generate;

end generate; -- end generate of stage gen


-- for valid delay
valshiftgen : valshiftreg
generic map(
  g_length => g_vectorsize  
)
port map(
  clk   => clk,
  rst_n => rst_n,
  en    => en,
  di    => nd,
  do    => valid
);

end behavior;


