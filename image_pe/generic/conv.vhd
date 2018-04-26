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

entity conv is
generic(
	g_valuewidth: natural;
	g_vectorsize: natural
);
port(
	clk		: in  std_logic;
	rst_n	: in  std_logic;
	en		: in  std_logic;
	nd		: in  std_logic;
	valid	: out std_logic;
	di_a	: in  std_logic_vector(g_vectorsize*g_valuewidth-1 downto 0);
	di_b	: in  std_logic_vector(g_vectorsize*g_valuewidth-1 downto 0);
	do		: out std_logic_vector(2*g_valuewidth-1 downto 0)
);
end conv;

architecture behavior of conv is

type VEC_DI is array (0 to g_vectorsize-1) of std_logic_vector(g_valuewidth-1 downto 0);
--type VEC_CONV is array (0 to g_vectorsize-1) of std_logic_vector(2*g_valuewidth-1 downto 0);

signal s_nd_d1, s_nd_d2		: std_logic;
signal s_di_a, s_di_b : VEC_DI;
signal s_mulres : std_logic_vector(2*g_vectorsize*g_valuewidth-1 downto 0);


component acc
generic(
  g_valuewidth: natural;
  g_vectorsize: natural
);
port(
	clk		: in  std_logic;
	rst_n	: in  std_logic;
	en		: in  std_logic;
	nd		: in  std_logic;
	valid	: out std_logic;
	di		: in  std_logic_vector(g_vectorsize*g_valuewidth-1 downto 0);
	do		: out std_logic_vector(g_valuewidth-1 downto 0)
);
end component;


begin

--readin: for i in 0 to g_vectorsize-1 generate
--  s_di_a(i) <= di_a((i+1)*g_valuewidth-1 downto i*g_valuewidth);
--  s_di_b(i) <= di_b((i+1)*g_valuewidth-1 downto i*g_valuewidth);
--end generate;

mulreg: process(clk)
begin
	if(clk'event and clk='1') then
	  if (rst_n = '0') then
--		  s_mulres <= (others=>'0');
			s_nd_d1 <= '0';
			s_nd_d2 <= '0';
--      s_di_a <= (others=>(others=>'0'));
--      s_di_b <= (others=>(others=>'0'));
    else
		  s_nd_d1 <= nd; --  one cycle latency for valid bit
--		  s_nd_d2 <= s_nd_d1; --  second cycle latency for valid bit
--		  if (en = '1') then
			  if(nd='1') then
			    for i in 0 to g_vectorsize-1 loop
            s_di_a(i) <= di_a((i+1)*g_valuewidth-1 downto i*g_valuewidth);
            s_di_b(i) <= di_b((i+1)*g_valuewidth-1 downto i*g_valuewidth);
	--			    s_mulres(2*(i+1)*g_valuewidth-1 downto i*2*g_valuewidth) <= std_logic_vector(signed(s_di_a(i)) * signed(s_di_b(i)));
			    end loop;
        end if;
--			  if(s_nd_d1='1') then
--			    for i in 0 to g_vectorsize-1 loop
--				    s_mulres(2*(i+1)*g_valuewidth-1 downto i*2*g_valuewidth) <= std_logic_vector(signed(s_di_a(i)) * signed(s_di_b(i)));
--			    end loop;
--        end if;
--		  end if;
		end if;
	end if;
end process;

readin: for i in 0 to g_vectorsize-1 generate
	s_mulres(2*(i+1)*g_valuewidth-1 downto i*2*g_valuewidth) <= std_logic_vector(signed(s_di_a(i)) * signed(s_di_b(i)));
end generate;


addall: acc
generic map(
  g_valuewidth => 2*g_valuewidth,
  g_vectorsize => g_vectorsize
)
port map(
	clk		=> clk,
	rst_n	=> rst_n,
	en		=> s_nd_d1,
	nd		=> s_nd_d1,
	valid	=> valid,
	di		=> s_mulres,
	do		=> do
);


end behavior;

