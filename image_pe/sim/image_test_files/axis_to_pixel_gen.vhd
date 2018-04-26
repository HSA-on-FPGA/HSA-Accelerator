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


entity axis_to_pixel_gen is
generic(
  DATA_IN_WIDTH: integer range 1 to 512:= 32;
	COLOR_WIDTH: integer range 1 to 512:= 8;
	GRAY_WIDTH: integer range 1 to 512:= 16;
  COL_NUM: integer range 1 to 16:= 3;
  PAR : integer range 1 to 64:= 1
);
Port ( 

  rout  : out std_logic_vector(PAR*COLOR_WIDTH-1 downto 0); -- FIX Later with num_col
  gout  : out std_logic_vector(PAR*COLOR_WIDTH-1 downto 0);
  bout  : out std_logic_vector(PAR*COLOR_WIDTH-1 downto 0);
  grayout  : out std_logic_vector(PAR*GRAY_WIDTH-1 downto 0);
	gray : in  std_logic;
  valid : out std_logic;
  out_ready : in std_logic;

  S_AXIS_ACLK   : in std_logic;
  S_AXIS_ARESETN  : in std_logic;
  S_AXIS_TVALID : in std_logic;
  S_AXIS_TDATA  : in std_logic_vector(DATA_IN_WIDTH-1 downto 0);
  S_AXIS_TLAST  : in std_logic;-- TODO work here
  S_AXIS_TREADY : out std_logic

);
end axis_to_pixel_gen;

architecture behavior of axis_to_pixel_gen is


--type COLOR_MAPPING_STATE is (r_bgr,gr_bg,bgr_b, write_staged);
--type GRAY_MAPPING_STATE is (word_read, write_staged);

--signal s_color_st, s_next_color_st : COLOR_MAPPING_STATE;
--signal s_gray_st, s_next_gray_st : GRAY_MAPPING_STATE;

signal s_di : std_logic_vector (DATA_IN_WIDTH-1 downto 0);
signal s_do_color : std_logic_vector (PAR*COL_NUM*COLOR_WIDTH-1 downto 0);
signal s_do_gray : std_logic_vector (PAR*GRAY_WIDTH-1 downto 0);

signal s_color_pixel_valid, s_gray_pixel_valid, s_color_tready,s_gray_tready :std_logic;
--signal s_tlast, s_valid : std_logic;
-- signals for debug

alias clk : std_logic is S_AXIS_ACLK;
alias rst_n : std_logic is S_AXIS_ARESETN;



--constant c_color_fill : std_logic_vector(7 downto 0):=(others=>'0');
--constant c_gray_fill : std_logic_vector(15 downto 0):=(others=>'0');


begin



rout <= s_do_color(PAR*COLOR_WIDTH-1 downto 0); --FIX later
gout <= s_do_color(2*PAR*COLOR_WIDTH-1 downto PAR*COLOR_WIDTH); -- FIX
bout <= s_do_color(3*PAR*COLOR_WIDTH-1 downto 2*PAR*COLOR_WIDTH); --FIX

grayout <= s_do_gray;


out_mux:process(s_color_pixel_valid,s_gray_pixel_valid,gray,s_gray_tready,s_color_tready)
begin
  if(gray='0') then
    valid <= s_color_pixel_valid;
		S_AXIS_TREADY <= s_color_tready; 
	else
    valid <= s_gray_pixel_valid;
		S_AXIS_TREADY <= s_gray_tready; 
	end if;
end process; 
--valid <= S_AXIS_TVALID;
s_di <= S_AXIS_TDATA;
--S_AXIS_TREADY <= s_tready;


gray_inst: entity work.scale
generic map(
  DATA_IN_WIDTH => DATA_IN_WIDTH, 
  DATA_OUT_WIDTH => PAR*GRAY_WIDTH
)
port map(
  clk => clk,
	reset => rst_n,
	in_enable => S_AXIS_TVALID,
	in_ready => s_gray_tready,
  out_enable => s_gray_pixel_valid,
	out_ready => out_ready,
	in_data => s_di,
	out_data => s_do_gray
);

gen_color_scale: if COL_NUM>1 generate
  gray_inst: entity work.scale
  generic map(
    DATA_IN_WIDTH => DATA_IN_WIDTH, 
    DATA_OUT_WIDTH => PAR*COL_NUM*COLOR_WIDTH
  )
  port map(
    clk => clk,
	  reset => rst_n,
	  in_enable => S_AXIS_TVALID,
	  in_ready => s_color_tready,
    out_enable => s_color_pixel_valid,
	  out_ready => out_ready,
	  in_data => s_di,
	  out_data => s_do_color
  );
end generate;




end behavior;
