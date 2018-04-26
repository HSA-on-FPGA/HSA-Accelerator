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

entity tb_image_test is
end tb_image_test;

architecture behavior of tb_image_test is

constant c_vecsize : integer:= c_ww_max_0 * c_wh_max_0;

constant c_dw : integer:= c_dw_pe_0;
constant c_pixw: integer:= c_dw_pix_max_0;
constant c_pixw_gray: integer:= c_dw_pix_max_gray_0;
constant c_col: integer:= c_num_col_max_0;
constant c_cw : integer:= c_coeffw_0;
constant c_par: integer:= c_par_0;
constant c_regw_0 : integer:= 32;

constant c_base_coeff_one : integer:=c_num_im_para_0;
constant c_base_coeff_two : integer:=c_num_im_para_0+c_vecsize;


type VEC_KERINT is array(0 to c_vecsize-1) of integer;
type VEC_COEFF is array(0 to c_vecsize-1) of std_logic_vector(c_regw_0-1 downto 0);
type VEC_COLOR is array(0 to c_num_col_max_0-1) of std_logic_vector(c_par*c_pixw-1 downto 0);

constant clk_period : time := 10 ns;
constant c_nd_tresh : integer:= 0;
constant c_iw : integer:= 128;
constant c_ih : integer:= 128;
constant c_np       : integer:= c_iw*c_ih;

signal clk,cclk, en,nd,en_nd, rst_n, valid,ready,start,pixel_valid, init, ready_out : std_logic;
signal s_di : VEC_DPEPAR_0 :=(others=>(others=>'0'));
signal s_do : VEC_DPEPAR_0;
signal s_dreg : std_logic_vector(c_regw_0-1 downto 0);
signal s_operation : std_logic_vector(c_regw_0-1 downto 0);
signal s_reg_addr: std_logic_vector(c_reg_addr_0-1 downto 0);
signal s_nd_cnt : unsigned(7 downto 0) :=(others=>'0');
signal s_coeff_one: VEC_COEFF;
signal s_coeff_two: VEC_COEFF;
signal s_color_in, s_color_out: VEC_COLOR;
--signal s_coeffint_one: VEC_KERINT:=(0,0,0,0,0,
--                                    0,1,2,1,0, -- uncomment for gauss
--                                    0,2,4,2,0,
--                                    0,1,2,1,0,
--                                    0,0,0,0,0);
signal s_coeffint_one: VEC_KERINT:=(0,0,0,0,0,
                                    0,0,0,0,0, -- uncomment for gauss
                                    0,0,1,0,0,
                                    0,0,0,0,0,
                                    0,0,0,0,0);
--signal s_coeffint_one: VEC_KERINT:=(0, 1,0,0,0, -- uncomment for laplace
--                                    1,-4,1,0,0,
--                                    0, 1,0,0,0,
--                                    0, 0,0,0,0,
--                                    0, 0,0,0,0);
--signal s_coeffint_one: VEC_KERINT:=(1, 0,-1,0,0, -- uncomment for sobel in x direction
--                                    2, 0,-2,0,0,
--                                    1, 0,-1,0,0,
--                                    0, 0,0,0,0,
--                                    0, 0,0,0,0);

signal s_coeffint_two: VEC_KERINT:=(0,0,0,0,0,
                                    0,1,2,1,0, -- uncomment for sobel in y direction
                                    0,0,0,0,0,
                                    0,-1,-2,-1,0,
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


coeff_con:for i in 0 to c_vecsize-1 generate
  s_coeff_one(i) <= std_logic_vector(to_signed(s_coeffint_one(i),c_regw_0));
  s_coeff_two(i) <= std_logic_vector(to_signed(s_coeffint_two(i),c_regw_0));
end generate;



uut: entity work.accelerator_pe_0
port map (
  clk => clk,
  rst_n => rst_n,
  en  => en,
  valid_in  => pixel_valid,
	ready_in => open, 
  valid_out => valid,
  ready_out => ready_out,
  start => start,
  init => init,
  dreg => s_dreg,
  reg_addr => s_reg_addr, 
  di => s_di,
  do => s_do
);

pix_gen: entity work.pixel_gen
generic map(
  g_par => c_par,
  g_imagesize => c_np
)
port map (
  rclk => clk,
  wclk => clk,
  rst_n => rst_n,
  nd  => nd,
  valid => valid,
  read_valid => pixel_valid,
  rin=> s_color_in(0),
  gin=> s_color_in(1),
  bin=> s_color_in(2),
  rout=> s_color_out(0),
  gout=> s_color_out(1),
  bout=> s_color_out(2)
 -- gout=> s_color_out(0),
--  bout=> s_color_out(0)
);


time_proc: process
begin
  clk <= '1';
  cclk <= '0';
  wait for clk_period/2;
  clk <= '0';
  cclk <= '1';
  wait for clk_period/2;
end process;

-- TODO set correct coeffs

en_proc: process
begin
start <='0';
init <='0';
en <= '1';
en_nd <= '0';
nd <= '0';
rst_n <= '0';
wait for clk_period;
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
s_dreg <= std_logic_vector(to_unsigned(c_np,s_dreg'length)); -- set number of pixel
s_reg_addr <= std_logic_vector(to_unsigned(2,s_reg_addr'length)); -- set address
wait for clk_period;
s_dreg <= std_logic_vector(to_unsigned(3,s_dreg'length)); -- set window width
s_reg_addr <= std_logic_vector(to_unsigned(3,s_reg_addr'length)); -- set address
wait for clk_period;
s_dreg <= std_logic_vector(to_unsigned(3,s_dreg'length)); -- set window hight
s_reg_addr <= std_logic_vector(to_unsigned(4,s_reg_addr'length)); -- set address
wait for clk_period;
-- set single convolution with norm on (GAUSS, laplace)
--s_dreg <= std_logic_vector(to_unsigned(1,s_dreg'length)); -- set operation
s_dreg <= s_operation;
s_reg_addr <= std_logic_vector(to_unsigned(5,s_reg_addr'length)); -- set address
wait for clk_period;
s_dreg <= std_logic_vector(to_unsigned(4,s_dreg'length)); -- set norm for gauss
--s_dreg <= std_logic_vector(to_unsigned(0,s_dreg'length)); -- set norm for laplace
s_reg_addr <= std_logic_vector(to_unsigned(6,s_reg_addr'length)); -- set address
wait for clk_period;
s_dreg <= std_logic_vector(to_unsigned(350,s_dreg'length)); -- set tresh
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

start <='0';
wait for 100*clk_period;
ready_out <='1';
--nd <='1';
--wait for 100*clk_period;
--nd <='0';
--wait for clk_period;
--nd <='1';

--wait for 1*clk_period;
for i in 0 to 20 loop
  if (i mod 2 = 0) then
    nd <= '0';
     else
    nd <='1';
  end if;
  wait for 1*clk_period;
end loop;
    nd <='1';

wait for 100*clk_period;

for i in 0 to 40 loop
  if (i mod 2 = 0) then
    ready_out <= '0';
     else
    ready_out <='1';
  end if;
  wait for 1*clk_period;
end loop;
    ready_out <='1';
--nd <='1';



wait;
end process;
--- End of data init and Processing

--new_data_sig_gen:process
--begin
--  wait until clk'event and clk='1' and en_nd='1';
--    nd
--	  if(s_nd_cnt > to_unsigned(c_nd_tresh,8)) then
--			nd <= '1';
--			s_nd_cnt <= (others=>'0');
--		else
--	    s_nd_cnt <= s_nd_cnt+1;
--			nd <= '0';
--		end if;
--end process;

-- Mapping color signals to input
par_gen: for i in 0 to c_par-1 generate
  s_di(i)(c_pixw_gray-1 downto 0) <= std_logic_vector(resize(unsigned(s_color_in(0)((i+1)*c_pixw-1 downto i*c_pixw)),c_pixw_gray));
  s_color_out(0)((i+1)*c_pixw-1 downto i*c_pixw) <= std_logic_vector(resize(unsigned(s_do(i)(c_pixw_gray-1 downto 0)),c_pixw));
  multicol_gen: if c_col>1 generate
    col_gen:for j in 0 to c_col-2 generate
		s_di(i)(c_pixw_gray+((j+1)*c_pixw)-1 downto c_pixw_gray+j*c_pixw) <= s_color_in(j+1)((i+1)*c_pixw-1 downto i*c_pixw);
		s_color_out(j+1)((i+1)*c_pixw-1 downto i*c_pixw) <= s_do(i)(c_pixw_gray+((j+1)*c_pixw)-1 downto c_pixw_gray+((j)*c_pixw));
    end generate;
  end generate;
end generate;

end behavior;
