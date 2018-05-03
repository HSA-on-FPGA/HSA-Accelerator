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

entity kernel_clb_0 is
port(
  clk   : in  std_logic;
  rst_n : in  std_logic;
  en    : in  std_logic; -- Global enable signal
  -- Control line infertace
  nd    : in  std_logic; -- New data for valid input pixel
  valid : out std_logic;  -- Output has valid information
  -- Config interface, must be constant, should only be changed, if not in processing mode 
  ww      : in std_logic_vector(c_ww_addr_0-1 downto 0);
  wh      : in std_logic_vector(c_wh_addr_0-1 downto 0);
  kinstr  : in  std_logic_vector(c_kinstrw_0-1 downto 0); -- instruction for kernel operation
  norm    : in std_logic_vector(c_normw_0-1 downto 0); -- shift value for normalization 
  tresh   : in std_logic_vector(c_treshw_0-1 downto 0); -- value for treshold
  coeff_one : in VEC_COEFF_0; -- Coefficient array for first conv stage
  coeff_two : in VEC_COEFF_0; -- Coefficient array for second conv stage
  -- Data Interace
  di    : in ARRAY_MASKPAR_0; -- Data from mask bus
  do    : out  std_logic_vector(c_par_0*c_dw_pix_max_0-1 downto 0) -- vectorized data output
);
end kernel_clb_0;

architecture behavior of kernel_clb_0 is

constant c_dw: integer:= c_dw_pix_max_0; -- must be changed for gray scale
constant c_convw: integer:= c_dw+1; --

constant c_dw_addr: integer:= c_dw_addr_0;
constant c_cw: integer:= c_coeffw_0;
constant c_par: integer:= c_par_0;
constant c_ww: integer:= c_ww_max_0;
constant c_wh: integer:= c_wh_max_0;
constant c_kinstrw: integer:= c_kinstrw_0;
constant c_num_kernel: integer:= c_num_kernel_0;

constant c_vecsize: integer:= c_ww*c_wh;

type VEC_SORTLIN is array (0 to c_par-1) of std_logic_vector(c_vecsize*c_dw-1 downto 0);
type VEC_CONVLIN is array (0 to c_par-1) of std_logic_vector(c_vecsize*c_convw-1 downto 0);
--type ARRAY_SECMUX is array (c_wh_max_0-1 downto 0) of VEC_SECMUX;

type VEC_KEROUT is array (0 to c_par-1) of std_logic_vector(c_dw-1 downto 0);
type VEC_CONVOUT is array (0 to c_par-1) of std_logic_vector(2*c_convw-1 downto 0);

type VEC_SORTOUT is array(0 to c_vecsize-1) of std_logic_vector(c_dw-1 downto 0);
type ARRAY_SORTOUT is array(0 to c_par-1) of VEC_SORTOUT;

type VEC_VALID is array(0 to c_par-1) of std_logic_vector(c_num_kernel-1 downto 0);

signal s_valid, s_valid_comp: std_logic_vector(c_par-1 downto 0); -- help signal

signal s_envec: std_logic_vector(c_num_kernel-1 downto 0);
signal s_validvec: VEC_VALID;
signal s_kmode : std_logic_vector(c_kinstrw-2 downto 0);
signal s_coeff_one, s_coeff_two : std_logic_vector(c_vecsize*c_convw-1 downto 0);


signal s_sortlin   : VEC_SORTLIN;
signal s_convlin   : VEC_CONVLIN;
signal s_sortlin_out : VEC_SORTLIN;
signal s_sort_out : ARRAY_SORTOUT;

signal s_conv_one_out : VEC_CONVOUT;
signal s_conv_two_out : VEC_CONVOUT;
signal s_conv_absadd : VEC_CONVOUT;
signal s_norm_ext_out : VEC_CONVOUT;

signal s_conv_addcut : VEC_KEROUT;

signal s_rank_out  : VEC_KEROUT;
signal s_tresh_out : VEC_KEROUT;
signal s_norm_out : VEC_KEROUT;


begin


s_valid_comp <=(others=>'1');

s_kmode <= kinstr(c_kinstrw-1 downto 1); -- map only mode without bit for tresh or norm

con_coeff: for i in  0 to c_vecsize-1  generate
  s_coeff_one((i+1)*c_convw-1 downto i*c_convw) <= std_logic_vector(resize(signed(coeff_one(i)),c_convw));
  s_coeff_two((i+1)*c_convw-1 downto i*c_convw) <= std_logic_vector(resize(signed(coeff_two(i)),c_convw));
end generate;

-- enables correct kernel

en_kernel: process(s_kmode)
  variable v_kmode: integer;
begin
  v_kmode:= to_integer(unsigned(s_kmode));
  s_envec <= (others=>'0');
  if(v_kmode = 0) then
    s_envec(0) <= '1';
  elsif(v_kmode =1) then
    s_envec(0) <= '1';
    s_envec(1) <= '1'; -- set both conv cores for dual mode
  elsif(v_kmode >= 2) then
    s_envec(2) <= '1'; -- set sort modul for med, ero, dil instruction
  end if;
end process;



-- main for generate loop for vectorization

par_gen: for i in c_par-1 downto 0 generate

cony: for y in  0 to c_wh-1  generate
  conx: for x in 0 to c_ww-1  generate
    s_convlin(i)(((y*c_ww+x)+1)*c_convw-1 downto (y*c_ww+x)*c_convw) <= '0' & di(i)(y)(x);
    s_sortlin(i)(((y*c_ww+x)+1)*c_dw-1 downto (y*c_ww+x)*c_dw) <= di(i)(y)(x);
  end generate;
end generate;

conv_one: entity work.conv
generic map(
  g_valuewidth => c_convw,
  g_vectorsize => c_vecsize
)
port map(
  clk   => clk,
  rst_n => rst_n,
  en    => nd,
  nd    => nd,
  valid => s_validvec(i)(0),
  di_a    => s_convlin(i),
  di_b    => s_coeff_one,
  do    => s_conv_one_out(i)
);

conv_two: entity work.conv
generic map(
  g_valuewidth => c_convw,
  g_vectorsize => c_vecsize
)
port map(
  clk   => clk,
  rst_n => rst_n,
  en    => nd,
  nd    => nd,
  valid => s_validvec(i)(1),
  di_a    => s_convlin(i), 
  di_b    => s_coeff_two, 
  do    => s_conv_two_out(i)
);

sort: entity work.bitonic_sort
generic map(
  ELEMENT_SIZE => c_dw,
  ARRAY_SIZE => c_vecsize
)
port map(
  clk   => clk,
  rst   => rst_n, -- change name to rst_n
  en    => nd,
  nd    => nd,
  valid => s_validvec(i)(2),
  data_in => s_sortlin(i),
  data_out=> s_sortlin_out(i)
);



-- shifting value for 
norm_proc: process(s_conv_one_out, norm,kinstr)
  variable v_normflag: std_logic; 
  variable v_norm : unsigned(c_dw-1 downto 0);
  variable v_conv_one : unsigned(c_dw-1 downto 0);
begin --TODO value to small for shifting 
  v_normflag:= kinstr(0);
  v_norm:= unsigned(norm);
if(v_normflag ='1') then
  s_norm_ext_out(i) <= std_logic_vector(shift_right(unsigned(s_conv_one_out(i)),to_integer(v_norm)));
else
  s_norm_ext_out(i) <= std_logic_vector(abs(signed(s_conv_one_out(i))));
end if;    
end process;

s_norm_out(i) <= s_norm_ext_out(i)(c_dw-1 downto 0);

-- calculation for gradient e.g sobel value
s_conv_absadd(i) <= std_logic_vector(abs(signed(s_conv_one_out(i))) + abs(signed(s_conv_two_out(i))));
s_conv_addcut(i) <= s_conv_absadd(i)(c_dw-1 downto 0);

-- setting treshold, when flag is set

tresh_proc: process(s_conv_addcut, tresh, kinstr,s_conv_absadd)
  variable v_tresh : integer;
  variable v_conv : integer;
  variable v_treshflag: std_logic; 
begin
  v_treshflag:= kinstr(0);
  v_tresh := to_integer(unsigned(tresh));
  v_conv := to_integer(unsigned(s_conv_absadd(i)));
if(v_treshflag='1') then
  if(v_conv > v_tresh) then
    s_tresh_out(i) <= (others=>'1');
  else
    s_tresh_out(i) <= (others=>'0');
  end if;
else
  s_tresh_out(i) <= s_conv_addcut(i);
end if;


end process; 

-- bring sort back to vectorized representation
con_sort: for j in 0 to c_vecsize-1 generate
  s_sort_out(i)(j) <= s_sortlin_out(i)((j+1)*c_dw-1 downto j*c_dw);
end generate;

-- select correct value from sort operation

sort_mode:process(s_sort_out,s_kmode, ww,wh)
  variable v_kmode: integer;
  variable v_offset: integer;
	variable v_secmaskvec: integer;
begin
  v_kmode := to_integer(unsigned(s_kmode));
  -- offset for ingnoring generated zeros in mask for smaller vector
  v_secmaskvec:= to_integer(unsigned(ww)) * to_integer(unsigned(wh)); -- FIXME see if works correctly!!
	v_offset:= c_vecsize-v_secmaskvec;
if(v_kmode = 2) then
  s_rank_out(i) <= s_sort_out(i)(v_offset+v_secmaskvec/2); -- median value
elsif(v_kmode = 3) then
  s_rank_out(i) <= s_sort_out(i)(v_offset); -- erosion value
elsif(v_kmode = 4) then
  s_rank_out(i) <= s_sort_out(i)(c_vecsize-1); -- delation value
else
  s_rank_out(i) <= (others=>'0');
end if;
end process;

wb_proc: process(s_kmode,s_tresh_out,s_rank_out, s_norm_out)
  variable v_kmode: integer;
begin

    v_kmode := to_integer(unsigned(s_kmode));
    if(v_kmode = 0) then
      do((i+1)*c_dw-1 downto i*c_dw) <= s_norm_out(i);
      s_valid(i) <= s_validvec(i)(0);
    elsif(v_kmode = 1) then
      do((i+1)*c_dw-1 downto i*c_dw) <= s_tresh_out(i);
      s_valid(i) <= s_validvec(i)(1);
    elsif(v_kmode >= 2) then
      do((i+1)*c_dw-1 downto i*c_dw) <= s_rank_out(i);
      s_valid(i) <= s_validvec(i)(2);
    else
      do((i+1)*c_dw-1 downto i*c_dw) <= (others=>'0');
      s_valid(i) <= '0';
    end if;
end process;



end generate;

valid <=s_valid(0);

end behavior;
