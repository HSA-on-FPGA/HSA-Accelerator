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
--use work.pkg_config.all;  -- missing values for config!!!

entity acc is
generic(
	g_valuewidth		: natural;
	g_vectorsize		: natural
--	g_vectoraddrwidth	: natural:= c_addr_acc_0
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
end entity;

architecture behavior of acc is

constant c_vectoraddrwidth	: integer := f_log2(g_vectorsize);

constant c_uneven		: integer:= unevensearch(g_vectorsize,c_vectoraddrwidth);
constant c_vecwidthtemp	: integer:= c_vectoraddrwidth; -- for debug

type VEC_ACC is array(0 to g_vectorsize-1) of std_logic_vector(g_valuewidth-1 downto 0);
type ADD_ARRAY is array(0 to c_vectoraddrwidth) of VEC_ACC;
type ADD_ADDUNEVENLINE is array(0 to c_vectoraddrwidth-1) of std_logic_vector(g_valuewidth-1 downto 0);

signal s_addin		: ADD_ARRAY;
signal s_regin		: ADD_ARRAY;
signal s_unevenval	: ADD_ADDUNEVENLINE; -- like DP_ADDUNEVENWIDTH
signal s_acc_valid: std_logic;

-- check wether disparity is 2pot value or not

component add2
generic(
	g_valuewidth: natural
);
port(
	di_a	: in  std_logic_vector(g_valuewidth-1 downto 0);
	di_b	: in  std_logic_vector(g_valuewidth-1 downto 0);
	do		: out std_logic_vector(g_valuewidth-1 downto 0)
);
end component;

component add3
generic(
	g_valuewidth: natural
);
port(
	di_a	: in  std_logic_vector(g_valuewidth-1 downto 0);
	di_b	: in  std_logic_vector(g_valuewidth-1 downto 0);
	di_c	: in  std_logic_vector(g_valuewidth-1 downto 0);
	do		: out std_logic_vector(g_valuewidth-1 downto 0)
);
end component;


component reg
generic(
	g_valuewidth: natural
);
port(
	clk		: in  std_logic;
--	rst_n	: in  std_logic;
	en		: in  std_logic;
	di		: in  std_logic_vector(g_valuewidth-1 downto 0);
	do		: out std_logic_vector(g_valuewidth-1 downto 0)
);
end component;

component valshiftreg
generic(
	g_length: natural
);
port(
	clk		: in  std_logic;
	rst_n	: in  std_logic;
	en		: in  std_logic;
	di		: in  std_logic;
	do		: out std_logic
);
end component;

begin

-- s_nd <= nd; -- help signal for mapping std_logic to std_logic_vector

readin: for i in 0 to g_vectorsize-1 generate
begin
	s_addin(0)(i) <= di((i+1)*g_valuewidth-1 downto i*g_valuewidth); --connect all value inputs to first line of sig array
end generate;

addgenout: for i in 0 to c_vectoraddrwidth-1 generate
	begin
	evengen		: if (even(div(g_vectorsize,i-1))= true) generate
		addgen2ev	: for j in 0 to div(g_vectorsize,i)-1 generate
		begin

		a2en : add2
		generic map(
			g_valuewidth => g_valuewidth
		)
		port map(
			di_a	=> s_addin(i)(2*j),
			di_b	=> s_addin(i)(2*j+1),  -- every second input to min input
			do		=> s_regin(i)(j)
		);
		r : reg
		generic map(
			g_valuewidth => g_valuewidth
		)
		port map(
			clk		=> clk,
--			rst_n	=> rst_n,
			en		=> en,
			di		=> s_regin(i)(j),
			do		=> s_addin(i+1)(j)   --output to next stage
		);
		end generate;
	end generate;

	unevengen: if(even(udiv(g_vectorsize,i)) = false and i < c_vectoraddrwidth-1) generate
		addgen2un : for j in 0 to ((udiv(g_vectorsize,i)-3)/2)-1 generate
		begin

		aun2 : add2
		generic map(
			g_valuewidth => g_valuewidth
		)
		port map(
			di_a	=> s_addin(i)(2*j),
			di_b	=> s_addin(i)(2*j+1),  -- every second input to min input
			do		=> s_regin(i)(j)
		);

		run : reg
		generic map(
			g_valuewidth => g_valuewidth
		)
		port map(
			clk		=> clk,
--			rst_n	=> rst_n,
			en		=> en,
			di		=> s_regin(i)(j),
			do		=> s_addin(i+1)(j)  --output to next stage
		);
		end generate;

	a3un : add3
	generic map(
		g_valuewidth => g_valuewidth
	)
	port map(
		di_a	=> s_addin(i)(udiv(g_vectorsize,i)-3),	-- third last input gets in
		di_b	=> s_addin(i)(udiv(g_vectorsize,i)-2),	-- second last input gets in
		di_c	=> s_addin(i)(udiv(g_vectorsize,i)-1),	-- last input gets in
		do		=> s_unevenval(i)
	);
	
	r3 : reg
	generic map(
		g_valuewidth => g_valuewidth
	)
	port map(
		clk		=> clk,
--		rst_n	=> rst_n,
		en		=> en,
		di		=> s_unevenval(i),
		do		=> s_addin(i+1)(udiv(g_vectorsize,i+1)-1)	  --output to next stage
	);
	end generate;
end generate;

unoutputgen: if(c_uneven /= c_vectoraddrwidth) generate -- if first uneven value is 1

	do <= s_addin(c_vectoraddrwidth-1)(0)(g_valuewidth-1 downto 0);
	envalgen: valshiftreg  -- shift reg which for correct valid output
	generic map(
		g_length => c_vectoraddrwidth-1
	)
	port map(
		clk		=> clk,
		rst_n	=> rst_n,
		en		=> en,
		di		=> nd,
		do		=> valid
	);

end generate;

enoutputgen: if(c_uneven = c_vectoraddrwidth) generate -- if first uneven value higher than 1

	do <= s_addin(c_vectoraddrwidth)(0)(g_valuewidth-1 downto 0);

	unvalgen: valshiftreg  -- shift reg  for correct valid output
	generic map(
		g_length => c_vectoraddrwidth -- must be +1 if length ist not power of 2
	)
	port map(
		clk		=> clk,
		rst_n	=> rst_n,
		en		=> en,
		di		=> nd,
		do		=> valid
	);
end generate;

--valid <= s_acc_valid and nd;

end behavior;
