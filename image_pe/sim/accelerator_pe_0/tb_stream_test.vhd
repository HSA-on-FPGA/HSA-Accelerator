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

entity tb_stream_test is
end tb_stream_test;

architecture behavior of tb_stream_test is

constant c_vecsize : integer:= c_ww_max_0 * c_wh_max_0;

constant c_dw : integer:= c_dw_pe_0;
constant c_pixw: integer:= c_dw_pix_max_0;
constant c_pixw_gray: integer:= c_dw_pix_max_gray_0;
constant c_col: integer:= c_num_col_max_0;
constant c_cw : integer:= c_coeffw_0;
constant c_par: integer:= c_par_0;
constant c_regw_0: integer:= 32;

constant c_base_coeff_one : integer:=c_num_im_para_0;
constant c_base_coeff_two : integer:=c_num_im_para_0+c_vecsize;


type VEC_KERINT is array(0 to c_vecsize-1) of integer;
type VEC_COEFF is array(0 to c_vecsize-1) of std_logic_vector(c_regw_0-1 downto 0);
type VEC_COLOR is array(0 to c_num_col_max_0-1) of std_logic_vector(c_par*c_pixw-1 downto 0);
--type ARRAY_COLOR is array(0 to c_par-1) of VEC_COLOR

constant clk_period : time := 10 ns;
constant c_iw : integer:= 20;
constant c_ih : integer:= 20;
constant c_np : integer:= c_iw*c_ih;


signal clk,cclk, en,nd, rst_n, valid,ready,start, init : std_logic;
--signal s_di,s_do : std_logic_vector(c_dw*c_par_0-1 downto 0):=(others=>'0');
signal s_di : VEC_DPEPAR_0:=(others=>(others=>'0'));
signal s_do : VEC_DPEPAR_0;
signal s_dreg : std_logic_vector(c_regw_0-1 downto 0);
signal s_operation : std_logic_vector(c_regw_0-1 downto 0);
signal s_reg_addr: std_logic_vector(c_reg_addr_0-1 downto 0);
signal s_coeff_one: VEC_COEFF;
signal s_coeff_two: VEC_COEFF;
signal s_color: VEC_COLOR;
signal s_red,s_green,s_blue : std_logic_vector(c_pixw-1 downto 0);
--signal s_di_gray: std_logic_vector(c_pixw_gray-1 downto 0);
signal s_coeffint_one: VEC_KERINT:=(0,0,0,0,0,
                                    0,0,0,0,0,
                                    0,0,1,0,0,
                                    0,0,0,0,0,
                                    0,0,0,0,0);

signal s_coeffint_two: VEC_KERINT:=(0,0,0,0,0,
                                    0,1,0,-1,0,
                                    0,2,0,-2,0,
                                    0,1,0,-1,0,
                                    0,0,0,0,0);

alias a_reserved : std_logic_vector(24 downto 0) is s_operation(31 downto 7); 
alias a_color : std_logic is s_operation(6); -- for color mode
alias a_boarder : std_logic_vector(1 downto 0) is s_operation(5 downto 4); 
alias a_kernelop : std_logic_vector(2 downto 0) is s_operation(3 downto 1); -- set to single conv for testing
alias a_norm_tresh : std_logic is s_operation(0); -- treshold off
                                    

begin
a_reserved <=(others=>'0');
a_color <= '0';
a_boarder <= "01";
a_kernelop <= "000";
a_norm_tresh <= '0';




-- correct coeeff mapping

coeff_con:for i in 0 to c_vecsize-1 generate
  s_coeff_one(i) <= std_logic_vector(to_signed(s_coeffint_one(i),c_regw_0));
  s_coeff_two(i) <= std_logic_vector(to_signed(s_coeffint_two(i),c_regw_0));
end generate;



uut: entity work.accelerator_pe_0
port map (
  clk => clk,
  rst_n => rst_n,
  en  => en,
  valid_in  => nd,
  ready_in => open,
  start => start,
  valid_out => valid,
	ready_out => '1',
--  req => '1', -- FIXME see if loop works
  init => init,
  dreg => s_dreg,
  reg_addr => s_reg_addr, 
  di => s_di,
  do => s_do
);


s_red<=s_do(0)(7 downto 0);
s_green<=s_do(0)(15 downto 8);
s_blue<=s_do(0)(23 downto 16);

time_proc: process
begin
  clk <= '0';
  cclk <= '0';
  wait for clk_period/2;
  clk <= '1';
  cclk <= '1';
  wait for clk_period/2;
end process;

-- TODO set correct coeffs

en_proc: process
begin
start <='0';
init <='0';
en <= '1';
nd <= '0';
rst_n <= '0';
wait for 2*clk_period;
rst_n <= '1';
wait for clk_period;

-- Init phase

init <='1';
s_dreg <= std_logic_vector(to_unsigned(c_iw,s_dreg'length)); -- set image width
s_reg_addr <= std_logic_vector(to_unsigned(0,s_reg_addr'length)); -- set address
wait for clk_period;
s_dreg <= std_logic_vector(to_unsigned(c_ih,s_dreg'length)); -- set image height
s_reg_addr <= std_logic_vector(to_unsigned(1,s_reg_addr'length)); -- set address
wait for clk_period;
s_dreg <= std_logic_vector(to_unsigned(c_np,s_dreg'length)); -- set image hight
s_reg_addr <= std_logic_vector(to_unsigned(2,s_reg_addr'length)); -- set address
wait for clk_period;
s_dreg <= std_logic_vector(to_unsigned(3,s_dreg'length)); -- set window width
s_reg_addr <= std_logic_vector(to_unsigned(3,s_reg_addr'length)); -- set address
wait for clk_period;
s_dreg <= std_logic_vector(to_unsigned(3,s_dreg'length)); -- set window height
s_reg_addr <= std_logic_vector(to_unsigned(4,s_reg_addr'length)); -- set address
wait for clk_period;
s_dreg <= s_operation; 
s_reg_addr <= std_logic_vector(to_unsigned(5,s_reg_addr'length)); -- set address
wait for clk_period;
s_dreg <= std_logic_vector(to_unsigned(4,s_dreg'length)); -- set norm for gauss
s_reg_addr <= std_logic_vector(to_unsigned(6,s_reg_addr'length)); -- set address
wait for clk_period;
s_dreg <= std_logic_vector(to_unsigned(128,s_dreg'length)); -- set tresh
s_reg_addr <= std_logic_vector(to_unsigned(7,s_reg_addr'length)); -- set address
wait for clk_period;

-- set coeffs one
for i in 0 to c_vecsize-1 loop
  s_dreg <= s_coeff_one(i);
  s_reg_addr <= std_logic_vector(to_unsigned(c_base_coeff_one+i,s_reg_addr'length)); -- set address
  wait for clk_period;
end loop;

-- set coeffs two
for i in 0 to c_vecsize-1 loop
  s_dreg <= s_coeff_two(i);
  s_reg_addr <= std_logic_vector(to_unsigned(c_base_coeff_two+i,s_reg_addr'length)); -- set address
  wait for clk_period;
end loop;

init <='0';
wait for clk_period;

---- End of Init Phase -----------

-- Start processing
start <='1';
wait for clk_period;

nd <='1';
start <='0';

wait;
end process;

-- Setting counter values

stim_proc: process(clk)
  begin
  if (clk'event and clk ='1') then
		if (rst_n='0') then
			s_color <= (others=>(others=>'0'));
    elsif (nd='1') then
      for i in 0 to c_par-1 loop
          s_color(0)<=std_logic_vector(unsigned(s_color(0))+1);
        for j in 1 to c_col-1 loop
          s_color(j)((i+1)*c_pixw-1 downto i*c_pixw)<=std_logic_vector(to_unsigned(i+j,c_pixw));
        end loop;
      end loop;
    end if;
  end if;
end process;

-- Mapping color signals to input
par_gen: for i in 0 to c_par-1 generate
  --s_di((i+1)*c_dw-((c_col-1)*c_pixw)-1 downto i*c_dw) <= std_logic_vector(resize(unsigned(s_color(0)((i+1)*c_pixw-1 downto i*c_pixw)),c_pixw_gray));
  s_di(i)(c_pixw_gray-1 downto 0) <= std_logic_vector(resize(unsigned(s_color(0)((i+1)*c_pixw-1 downto i*c_pixw)),c_pixw_gray));
  multicol_gen: if c_col>1 generate
    col_gen:for j in 0 to c_col-2 generate
      s_di(i)(c_pixw_gray+((j+1)*c_pixw)-1 downto c_pixw_gray+((j)*c_pixw)) <=	std_logic_vector(resize(unsigned(s_color(j+1)((i+1)*c_pixw-1 downto i*c_pixw)),c_pixw));
    end generate;
  end generate;
end generate;

end behavior;
