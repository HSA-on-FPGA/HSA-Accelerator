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

entity border_control is
generic(
  WW : integer range 2 to 160:= 5; -- window width
  WH: integer range 2 to 160:= 5; -- window height
  IW_MAX: integer range 16 to 8192:= 4096; --Image width
  IH_MAX: integer range 16 to 8192:= 4096; -- Image height  
  PAR: integer range 1 to 32 := 1 -- parallel degree
);
port(
  clk        : in  std_logic;
  rst_n      : in  std_logic;
  nd         : in  std_logic; -- New Data for valid input pixel
	iw         : in std_logic_vector(integer(ceil(log2(real(IW_MAX))))-1 downto 0); -- only for prog. hw
	ih         : in std_logic_vector(integer(ceil(log2(real(IH_MAX))))-1 downto 0); -- only for prog. hw
  border_en  : in  std_logic; -- enable signal
  border_vec : out std_logic_vector((WW+PAR-1)*WH-1 downto 0)
);
end border_control;

architecture behavior of border_control is

type t_border_vec is array (WW+PAR-2 downto 0) of std_logic;
type t_border_array is array (WH-1 downto 0) of t_border_vec;


signal s_x_cnt, s_x_cnt_nxt  : unsigned(integer(ceil(log2(real(IW_MAX))))-1 downto 0);
signal s_y_cnt, s_y_cnt_nxt  : unsigned(integer(ceil(log2(real(IH_MAX))))-1 downto 0);
signal s_border_array: t_border_array;

begin

-- counter for calulate two-dimensional pixel position in image

pixel_counter:process(clk)
begin
  if clk'event and clk='1' then
    if rst_n='0' then
      s_x_cnt <= (others =>'0');
      s_y_cnt <= (others =>'0');
    elsif border_en='1' and nd='1'then

    s_x_cnt <= s_x_cnt_nxt;
    s_y_cnt <= s_y_cnt_nxt;
--      if s_x_cnt = unsigned(iw)-1 then -- check if correct
--        s_x_cnt <= (others=>'0');
--        s_y_cnt <= s_y_cnt+1;
--      else
--        s_x_cnt <= s_x_cnt+PAR; -- shift pixel depends on PAR
--      end if;
--      if s_y_cnt = unsigned(ih)-1 and s_x_cnt = unsigned(iw)-1 then
--        s_y_cnt <= (others =>'0');
--      end if;
    end if;
  end if;
end process;

-- process for calculating border vector

border_vec_proc:process(s_x_cnt, s_y_cnt, iw, ih, border_en)
variable v_x, v_y, v_i, v_iw, v_ih: integer;
variable v_x_rel, v_y_rel: integer;
variable v_x_cnt, v_y_cnt: unsigned(integer(ceil(log2(real(IH_MAX))))-1 downto 0);
begin
  v_x_cnt := s_x_cnt;
  v_y_cnt := s_y_cnt;

  for y in WH-1 downto 0 loop
    for x in WW+PAR-2 downto 0 loop
      v_i:= y*(WW+PAR-1)+x; -- get linear index in mask
      v_x_rel:=-(x-WW/2); -- calculate index value relative to middle pixel of mask
      v_y_rel:=-(y-WH/2); -- calculate index value relative to middle pixel of mask
      if border_en /= '1' then
        border_vec <= (others=>'0');
      else
        if v_i >= WH*WW/2 and v_i < WH*WW/2+PAR then 
          border_vec(v_i)<='0'; -- all middle pixels do not react on border
          s_border_array(y)(x) <= '0'; -- only for debug
        else
          v_x:= v_x_rel + to_integer(unsigned(v_x_cnt)); 
          v_y:= v_y_rel + to_integer(unsigned(v_y_cnt));
          v_iw:= to_integer(unsigned(iw));
          v_ih:= to_integer(unsigned(ih));
          if v_x < 0 or v_x >= v_iw or v_y < 0 or v_y >= v_ih then
            border_vec(v_i) <='1'; -- enable border mux if index out of region;
            s_border_array(y)(x) <= '1'; -- only for debug
          else
            border_vec(v_i) <= '0';
            s_border_array(y)(x) <= '0'; -- only for debug
          end if;
        end if;
      end if;
    end loop;
  end loop;
 
-- Counter now directly in process

  v_x_cnt := v_x_cnt+PAR; -- shift pixel depends on PAR
  if v_x_cnt > unsigned(iw)-1 then -- check if correct
      v_x_cnt := (others=>'0');
      v_y_cnt := v_y_cnt+1;
--  else
--      v_x_cnt := v_x_cnt+PAR; -- shift pixel depends on PAR
  end if;
  if v_y_cnt >= unsigned(ih) and v_x_cnt >= unsigned(iw) then
     v_y_cnt := (others =>'0');
  end if;

  s_x_cnt_nxt <= v_x_cnt;
  s_y_cnt_nxt <= v_y_cnt;


end process;


end behavior;
