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

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity pixel_to_axis_gen is
Generic(
  DATA_OUT_WIDTH: integer range 1 to 512:= 32;
  COLOR_WIDTH: integer range 1 to 512:= 8;
  GRAY_WIDTH: integer range 1 to 512:= 16;
  COL_NUM: integer range 1 to 16:= 3;
  PAR: integer range 1 to 64:= 1
);
Port ( 
   --  pixel stream side
  rin    : in std_logic_vector (PAR*COLOR_WIDTH-1 downto 0); -- fix later with COL_NUM
  gin    : in std_logic_vector (PAR*COLOR_WIDTH-1 downto 0);
  bin    : in std_logic_vector (PAR*COLOR_WIDTH-1 downto 0);
	grayin : in std_logic_vector (PAR*GRAY_WIDTH-1 downto 0);

  gray   : in std_logic;
	nd     : in std_logic;
  ----- Master AXI Stream Ports----
  M_AXIS_ACLK : in std_logic;
  M_AXIS_ARESETN  : in std_logic;
  M_AXIS_TVALID : out std_logic;
  M_AXIS_TDATA  : out std_logic_vector(DATA_OUT_WIDTH-1 downto 0);
--  M_AXIS_TSTRB  : out std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0);
--  M_AXIS_TLAST  : out std_logic; -- for future use
  M_AXIS_TREADY : in std_logic
);
end pixel_to_axis_gen;

architecture behavior of pixel_to_axis_gen is

--type COLOR_MAPPING_STATE is (insert_rgbr,write_rbgr,write_grbg,write_bgrb);
--type GRAY_MAPPING_STATE is (word_read,write_staged);

--signal s_color_st, s_next_color_st : COLOR_MAPPING_STATE;
--signal s_gray_st, s_next_gray_st : GRAY_MAPPING_STATE;

signal s_di_color :std_logic_vector(PAR*COL_NUM*COLOR_WIDTH-1 downto 0);
signal s_di_gray  :std_logic_vector(PAR*GRAY_WIDTH-1 downto 0);
--signal s_rgb_staged, s_rgb_shift : std_logic_vector(23 downto 0);
--signal s_gray_staged, s_gray_shift : std_logic_vector(15 downto 0);
signal s_do_gray, s_do_color : std_logic_vector(DATA_OUT_WIDTH-1 downto 0);
--signal s_do_color :std_logic_vector(31 downto 0);

--constant c_color_fill : std_logic_vector(7 downto 0):= (others=>'0');

signal s_gray_pixel_valid, s_color_pixel_valid: std_logic ;


alias clk : std_logic is M_AXIS_ACLK;
alias rst_n : std_logic is M_AXIS_ARESETN;

begin


s_di_gray <= grayin;
s_di_color <= bin & gin & rin; -- TODO FIX later



gray_inst: entity work.scale
generic map(
  DATA_IN_WIDTH => PAR*GRAY_WIDTH, -- change later
  DATA_OUT_WIDTH => DATA_OUT_WIDTH -- change later
)
port map(
  clk => clk,
	reset => rst_n,
	in_enable => nd,
	in_ready=> open,
	in_data => s_di_gray,
	out_enable => s_gray_pixel_valid,
	out_ready => M_AXIS_TREADY,
	out_data => s_do_gray
);

gen_color_scale: if COL_NUM>1 generate
  color_inst: entity work.scale
  generic map(
    DATA_IN_WIDTH => PAR*COL_NUM*COLOR_WIDTH, -- change later
    DATA_OUT_WIDTH => DATA_OUT_WIDTH -- change later
  )
  port map(
    clk => clk,
	  reset => rst_n,
	  in_enable => nd,
	  in_ready=> open,
	  in_data => s_di_color,
	  out_enable => s_color_pixel_valid,
	  out_ready => M_AXIS_TREADY,
	  out_data => s_do_color
  );
end generate;




out_mux:process(s_gray_pixel_valid,s_color_pixel_valid,s_do_color,s_do_gray, gray)
begin
  if(gray='0') then 
    M_AXIS_TVALID <= s_color_pixel_valid;
    M_AXIS_TDATA <= s_do_color;
  else
    M_AXIS_TVALID <= s_gray_pixel_valid;
    M_AXIS_TDATA <= s_do_gray;
  end if;
end process;


end behavior;
