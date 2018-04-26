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
use ieee.math_real.all;
--use work.pkg_functions.all;
--use work.pkg_config.all;

entity pixel_gen is
generic(
  g_pixwidth: integer := 8; -- usually 8 for current design
	g_imagesize: integer;
	g_par: integer:=1 -- should be power of 2
  );
port(
	rclk: in std_logic;
	wclk: in std_logic;
	rst_n: in std_logic;
	nd : in std_logic;
	valid: in std_logic;
	rin : out std_logic_vector(g_par*g_pixwidth-1 downto 0);
	gin : out std_logic_vector(g_par*g_pixwidth-1 downto 0);
	bin : out std_logic_vector(g_par*g_pixwidth-1 downto 0);
  read_valid: out std_logic;
	rout : in std_logic_vector(g_par*g_pixwidth-1 downto 0);
	gout : in std_logic_vector(g_par*g_pixwidth-1 downto 0);
	bout : in std_logic_vector(g_par*g_pixwidth-1 downto 0)
	);
end entity;

architecture behavior of pixel_gen is

constant c_par: integer:= g_par;
constant c_pixwidth: integer:= g_pixwidth;
constant c_memsize : integer := g_imagesize;
constant c_memwidth: integer:= integer(ceil(log2(real(c_memsize))))+1; --must be fixed


signal mem_re,mem_we : std_logic:='0';
type mem_type is array (0 to c_memsize-1) of std_logic_vector(3*c_pixwidth-1 downto 0);
signal mem_r,mem_w: mem_type;
signal mem_addr_r,mem_addr_w : std_logic_vector(c_memwidth-1 downto 0) := (others => '0');

begin


--read_valid_proc: process(rclk)
--begin
--  if (rclk 'event and rclk = '1') then
--    read_valid <= nd;
--  end if;
--end process;



read_mem_proc: process(rclk)
begin
	if (rclk 'event and rclk = '1') then
    read_valid <= '0';
		if(mem_re = '1') then
      read_valid <= '1';
			for i in 0 to c_par-1 loop
			  rin(((i+1)*c_pixwidth)-1 downto i*c_pixwidth) <= mem_r(to_integer(unsigned(mem_addr_r)+c_par-1-i))(3*c_pixwidth-1 downto 2*c_pixwidth);
			  gin(((i+1)*c_pixwidth)-1 downto i*c_pixwidth) <= mem_r(to_integer(unsigned(mem_addr_r)+c_par-1-i))(2*c_pixwidth-1 downto 1*c_pixwidth);
			  bin(((i+1)*c_pixwidth)-1 downto i*c_pixwidth) <= mem_r(to_integer(unsigned(mem_addr_r)+c_par-1-i))(1*c_pixwidth-1 downto 0);
			end loop;
		end if;
	end if;
end process;

write_mem_proc: process(wclk)
begin
	if (wclk 'event and wclk = '1') then
		if (mem_we = '1') then
			for i in 0 to c_par-1 loop 
			  mem_w(to_integer(unsigned(mem_addr_w)+c_par-1-i))(3*c_pixwidth-1 downto 2*c_pixwidth)	<= rout(((i+1)*c_pixwidth)-1 downto (i)*c_pixwidth);
			  mem_w(to_integer(unsigned(mem_addr_w)+c_par-1-i))(2*c_pixwidth-1 downto 1*c_pixwidth)	<= gout(((i+1)*c_pixwidth)-1 downto (i)*c_pixwidth);
			  mem_w(to_integer(unsigned(mem_addr_w)+c_par-1-i))(1*c_pixwidth-1 downto 0) <= bout(((i+1)*c_pixwidth)-1 downto (i)*c_pixwidth);
			end loop;
		end if;
	end if;
end process;



we_proc: process(valid,mem_addr_w)
begin
  if (valid = '1') and (to_integer(unsigned(mem_addr_w)) < c_memsize) then 
		mem_we <= '1';			
	else
		mem_we <= '0';
	end if;
end process;

re_proc: process(mem_addr_r,nd)
begin
	if (nd='1') and (to_integer(unsigned(mem_addr_r)) < c_memsize) then
		mem_re <= '1';
	else
		mem_re <= '0';
	end if;
end process;

addr_r: process(rclk)
begin
  if(rst_n='0') then
    mem_addr_r <= (others=>'0');
	elsif rclk 'event and rclk='1' and mem_re='1' then
	  mem_addr_r <= std_logic_vector(unsigned(mem_addr_r)+c_par);
  end if;
end process;

addr_w: process(wclk)
begin
  if(rst_n='0') then
    mem_addr_w <= (others=>'0');
	elsif wclk 'event and wclk='1' and mem_we ='1' then
	  mem_addr_w <= std_logic_vector(unsigned(mem_addr_w)+c_par);
  end if;
end process;

end behavior;
