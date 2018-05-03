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
use work.pkg_buffer_0.all;

entity buffer_clb_0 is
port(
  clk   : in  std_logic;
  rst_n : in  std_logic;
  en    : in  std_logic; -- Global enable signal
  -- Control line infertace
  nd    : in  std_logic; -- New Data for valid input pixel
  -- ports for controlling border handling
  border_vec  : in std_logic_vector(((c_ww_max_0+c_par_0-1)*c_wh_max_0)-1 downto 0); -- vector for boarder handling
  border_st   : in BORDER_STATE_0;
  border_op   : in std_logic_vector(1 downto 0); -- 0 off, 1 zero pad, 2 clamp
  -- Config interface, must be constant, should only be changed, if not in processing mode  
  iw    : in std_logic_vector(c_iw_addr_0-1 downto 0); -- sets image width from config reg
  ww    : in std_logic_vector(c_ww_addr_0-1 downto 0); -- sets window width from config reg
  wh    : in std_logic_vector(c_wh_addr_0-1 downto 0); -- sets window height from config reg
  -- Data interace
  di    : in  std_logic_vector(c_dw_pix_max_0 * c_par_0-1 downto 0);  
  mo    : out  ARRAY_MASKPAR_0 -- Mask in one dimension multiplied with c_par_0
);
end buffer_clb_0;

architecture behavior of buffer_clb_0 is

constant c_en_border: boolean:= c_en_border_handling_0;
constant c_dw: integer:= c_dw_pix_max_0; 
constant c_int_length : integer:= 32;
constant c_ww: integer:= c_ww_max_0;
constant c_wh: integer:= c_wh_max_0;
constant c_ww_half: integer:= (c_ww+par-1)/2;
constant c_wh_half: integer:= c_wh/2;

type VEC_SECMUX is array (c_ww-1 downto 0) of std_logic;
type ARRAY_SECMUX is array (c_wh-1 downto 0) of VEC_SECMUX;

type VEC_BORDERMUX is array (c_ww+par-2 downto 0) of std_logic;
type ARRAY_BORDERMUX is array (c_wh-1 downto 0) of VEC_BORDERMUX;

signal s_clamp, s_border_en, s_zero_pad : std_logic;
signal s_mask : MASKPQ; -- Mask format from fbpar
signal s_maskpar,s_borderres, s_border : MASKPARQ; -- Mask format for border handling
signal s_swopar, s_secswopar : SWOPQPAR;
signal s_arraysecmux: ARRAY_SECMUX;
signal s_arraybordermux: ARRAY_BORDERMUX;
signal s_maskreg : ARRAY_MASKPAR_0;
signal s_zero: std_logic_vector(c_dw-1 downto 0);
signal s_border_vec:std_logic_vector(((c_ww+c_par_0-1)*c_wh)-1 downto 0);
signal s_border_st: BORDER_STATE_0;

begin

s_zero <= (others=>'0');


ufbpar0: entity work.fbpar_0
port map(
  clk   => clk,
  rst_n => rst_n,
  en    => en,
  nd    => nd,
  iw    => iw,
  di    => di, 
  mask  => s_mask
);


------------------------------
-- Border handling begins here
------------------------------

gen_border: if c_en_border = true generate

-- Mapping from MASKPQ to MASKPARQ
process(s_mask)
begin
  for x in q-1 downto 0 loop
    for y in p+par-2 downto 0 loop
      s_maskpar(x)(y) <= s_mask(x)(d*(y+1)-1 downto d*y);
    end loop;    
  end loop;
end process;

-- sets bits for border handling option
process(border_op)
begin
  s_border_en<='0';
  s_zero_pad <='0';
  s_clamp <='0';
  if border_op="01" then
    s_border_en<='1';
    s_zero_pad<='1'; -- coding for zero pad
  elsif border_op="10" then
    s_border_en<='1';
    s_clamp <='1'; -- coding for clamping
  end if;
end process;

-- Reading in border vector

process(border_vec,s_border_en,border_st)
begin
  if s_border_en ='1' then
    s_border_vec <= border_vec;
    s_border_st <= border_st;
  else
    s_border_vec <= (others=>'0');
    s_border_st <= no_border;
  end if;
end process;

-- Instantiantating mux for border handling

mux_border_x: for x in q-1 downto 0 generate
  mux_border_y: for y in p+par-2 downto 0 generate
    mux_border_gen: if x*(p+par-1)+y < q*p/2 or x*(p+par-1)+y >= q*p/2+par generate
      umuxborder: entity work.mux2 -- mux are not generated for middle pixel
      generic map(
        g_valuewidth => c_dw
      )
      port map(
        di_a => s_maskpar(x)(y),
        di_b => s_border(x)(y), -- FIXME
        sel  => s_arraybordermux(x)(y),
        do   => s_borderres(x)(y)
      );
      end generate;

      no_mux_gen: if x*(p+par-1)+y >= q*p/2 and x*(p+par-1)+y < q*p/2+par generate
        process(s_border_vec,s_zero_pad, s_maskpar)
        begin
          if(s_zero_pad='1'and unsigned(s_border_vec) /= 0) then
            s_borderres(x)(y) <= (others=>'0'); -- add border and zero pad middle pix must be zero
          else
            s_borderres(x)(y) <= s_maskpar(x)(y); -- pass middle pixel directly
          end if;
        end process;

      end generate;

  end generate;
end generate;

-- Connect mux for border handling
process(s_borderres,s_border_vec,s_clamp,s_zero_pad,s_border_en,s_border_st)
variable v_i: integer;
variable v_x_norm: integer;
variable v_y_norm: integer;
variable v_x_norm_abs: integer;
variable v_y_norm_abs: integer;
variable v_border_vec_int: integer;
begin
v_border_vec_int := to_integer(unsigned(s_border_vec));


  for x in q-1 downto 0 loop
    for y in p+par-2 downto 0 loop

--     (y)(x)  |  (-y)(x)
--             |
--     Quadr.1 | Quadr.2 
--    ---------+----------
--     Quadr.3 | Quadr.4
--             |
--     (y)(-x) | (-y)(-x)

      v_i := x*(p+par-1)+y; -- calculate linear index
      v_x_norm := x-q/2;
      v_y_norm := y-p/2;
      v_x_norm_abs:= to_integer(abs(to_signed(v_x_norm,c_int_length)));
      v_y_norm_abs:= to_integer(abs(to_signed(v_y_norm,c_int_length)));

      s_border(x)(y) <= (others=>'0');
      s_arraybordermux(x)(y) <='0';

        if(s_border_en='1') then
          if v_i >= q*p/2 and v_i < q*p/2+par then
            s_border(x)(y) <= (others=>'0');
            s_arraybordermux(x)(y) <= '0'; 
          elsif(s_zero_pad='1') then
            s_border(x)(y) <= (others=>'0');
            if v_border_vec_int /= 0 then
              s_arraybordermux(x)(y) <= '1'; -- during border, make all pixel black
            else
              s_arraybordermux(x)(y) <= '0'; -- else pass regular pixel
            end if;
          end if;
      else -- pass regular pixel if border handling off
        s_border(x)(y) <= (others=>'0');
        s_arraybordermux(x)(y) <='0';
      end if;
    end loop;    
  end loop;
end process;


-- PE mask mapping to swo 
process(s_borderres)
begin
  for j in par-1 downto 0 loop
    for x in q-1 downto 0 loop
      for y in p-1 downto 0 loop
        s_swopar(j)(x)(y) <= s_borderres(x)(y+j);
      end loop;
    end loop;
  end loop;
end process;

end generate;

------------------------------
-- Border handling ends here
------------------------------

-- correct signal mapping in case border hanling is turned off

gen_no_border: if c_en_border = false generate

process(s_mask)
begin
  for j in par-1 downto 0 loop
    for x in q-1 downto 0 loop
      for y in p-1 downto 0 loop
        s_swopar(j)(x)(y) <= s_mask(x)(d*(j+y+1)-1 downto d*(j+y));
      end loop;
    end loop;
  end loop;
end process;

end generate;

-- Set select for muxes depending on configured array section

process(ww,wh)
variable v_ww,v_wh : integer; 
variable v_x_norm: integer;
variable v_y_norm: integer;
variable v_x_norm_abs: integer;
variable v_y_norm_abs: integer;
begin

  v_ww := to_integer(unsigned(ww)) ;
  v_wh := to_integer(unsigned(wh)) ;
  for x in c_wh-1 downto 0 loop
    for y in c_ww-1 downto 0 loop
      v_x_norm := x-c_wh/2;
      v_y_norm := y-c_ww/2;
      v_x_norm_abs:= to_integer(abs(to_signed(v_x_norm,c_int_length)));
      v_y_norm_abs:= to_integer(abs(to_signed(v_y_norm,c_int_length)));
       if ( v_x_norm_abs >=(v_wh-1)) or ( v_y_norm_abs>=(v_ww-1)) then
          s_arraysecmux(x)(y) <= '1'; -- zero will be passed
        else 
          s_arraysecmux(x)(y) <= '0'; -- normal value will be passed
        end if;
    end loop;
  end loop;
end process;

-- Generating mux2 for handling smaller masks than maximum mask size
mux_par: for j in c_par_0-1 downto 0 generate
  mux_x: for x in c_wh/2 downto -(c_wh-1)/2 generate
    mux_y: for y in c_ww/2 downto -(c_ww-1)/2 generate
      mux_gen: if (x < 0 or y < 0) or ((x >= 0 and y >= 0) and 
               ((x > c_wh_min_0-1) or y> c_ww_min_0-1)) generate
        umux2: entity work.mux2
        generic map(
          g_valuewidth => c_dw
        )
        port map(
          di_a => s_swopar(j)(x+c_wh/2)(y+c_ww/2),
          di_b => s_zero,
          sel  => s_arraysecmux(x+c_wh/2)(y+c_ww/2),
          do   => s_secswopar(j)(x+c_wh/2)(y+c_ww/2)
        );
      end generate;
    end generate;
  end generate;
end generate;

-- smallest possible mask can be connected directly
con_par: for j in c_par_0-1 downto 0 generate
  con_x: for x in c_wh-1 downto 0 generate
    con_y: for y in c_ww-1 downto 0 generate
      con: if (x >= c_wh/2 and x < c_wh/2+c_wh_min_0) and
              (y >= c_ww/2 and y < c_ww/2+c_ww_min_0) generate
        s_secswopar(j)(x)(y) <= s_swopar(j)(x)(y);
      end generate;
    end generate;
  end generate;
end generate;

process(s_secswopar)
begin
  for j in 0 to c_par_0-1 loop
    for x in 0 to c_wh_max_0-1 loop
      for y in 0 to c_ww_max_0-1  loop
        s_maskreg(j)(x)(y) <= s_secswopar(j)(x)(y);
      end loop;
    end loop;
  end loop;
end process;

mo <= s_maskreg;

end behavior;
