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


entity fifo_to_pixel_gen is

generic(
  DATA_IN_WIDTH: integer range 1 to 512:= 32;
	COLOR_WIDTH: integer range 1 to 512:= 8;
	GRAY_WIDTH: integer range 1 to 512:= 16;
  COL_NUM: integer range 1 to 16:= 3;
  PAR : integer range 1 to 64:= 1
);
Port ( 
  clk : in std_logic;
  rst_n : in std_logic;
  en : in std_logic;
  gray: in std_logic;
--    fifo control read side;
  control_data_out : in std_logic_vector (DATA_IN_WIDTH-1 downto 0); -- fixme change to genvall
  control_data_valid : in std_logic;
	control_data_req : out std_logic;
--  accelerator side
  do_gray : out std_logic_vector (PAR*GRAY_WIDTH-1 downto 0); --fixme change to gen val
  do_color : out std_logic_vector (PAR*COL_NUM*COLOR_WIDTH-1 downto 0); --fixme change to gen val
  valid : out std_logic;
  ready : in std_logic
);
end fifo_to_pixel_gen;

architecture behavior of fifo_to_pixel_gen is

--constant c_pew : integer:= (COL_NUM-1)*COLOR_WIDTH+GRAY_WIDTH; 
--constant c_colvecw : integer:= COL_NUM*COLOR_WIDTH; 

--constant c_color_fill : std_logic_vector(GRAY_WIDTH-COLOR_WIDTH-1 downto 0):=(others=>'0');--TODO must be fixed
--constant c_gray_fill : std_logic_vector(c_pew-GRAY_WIDTH-1 downto 0):=(others=>'0'); -- TODO must be fixed

signal s_dfifo : std_logic_vector (DATA_IN_WIDTH-1 downto 0);
signal s_color : std_logic_vector (PAR*COL_NUM*COLOR_WIDTH-1 downto 0);
signal s_gray : std_logic_vector (PAR*GRAY_WIDTH-1 downto 0);

-- signals for debug

--signal s_fifo_one, s_fifo_two,s_fifo_three, s_fifo_four  : std_logic_vector (COLOR_WIDTH-1 downto 0);
--signal s_color_one, s_color_two,s_color_three, s_color_four  : std_logic_vector (COLOR_WIDTH-1 downto 0);

--signal s_color_out , s_gray_out: std_logic_vector(PAR*((COL_NUM-1)*COLOR_WIDTH+GRAY_WIDTH)-1 downto 0);
signal s_shift_valid,s_color_valid,s_gray_valid,s_gray_data_req,s_color_data_req,s_gray_en,s_color_en : std_logic ;

begin


-- Debugging Signals--

-- must be removed for generic usage!!

--s_fifo_one <= s_dfifo(7 downto 0);
--s_fifo_two <= s_dfifo(15 downto 8);
--s_fifo_three <= s_dfifo(23 downto 16);
--s_fifo_four <= s_dfifo(31 downto 24);

--s_color_one <= s_color(7 downto 0);
--s_color_two <= s_color(15 downto 8);
--s_color_three <= s_color(23 downto 16);
--s_color_four <= s_color(31 downto 24);

-- END Debugging Signals---

s_shift_valid <= control_data_valid;
s_dfifo <= control_data_out;

gray_inst: entity work.scale
generic map(
  DATA_IN_WIDTH => DATA_IN_WIDTH, 
  DATA_OUT_WIDTH => PAR*GRAY_WIDTH
)
port map(
  clk => clk,
	reset => rst_n,
	in_enable => s_shift_valid,
	in_ready => s_gray_data_req,
  out_enable => s_gray_valid,
	out_ready => ready, 
	in_data => s_dfifo,
	out_data => s_gray
);

-- SIG Gen should be changed later

--sig_gen : for i in 0 to PAR-1 generate
--  s_color_out((i+1)*c_pew-1 downto i*c_pew) <= s_color((i+1)*c_colvecw-1 downto c_colvecw*i+COLOR_WIDTH) &
--  c_color_fill & s_color(i*c_colvecw+COLOR_WIDTH-1 downto i*c_colvecw);
--  s_gray_out((i+1)*c_pew-1 downto i*c_pew) <= c_gray_fill & s_gray((i+1)*GRAY_WIDTH-1 downto i*GRAY_WIDTH);
--end generate;

do_gray <= s_gray;
do_color <= s_color;


gen_color_scale: if COL_NUM>1 generate
  color_inst: entity work.scale
  generic map(
    DATA_IN_WIDTH => DATA_IN_WIDTH, 
    DATA_OUT_WIDTH => PAR*COL_NUM*COLOR_WIDTH
  )
  port map(
    clk => clk,
	  reset => rst_n,
	  in_enable => s_shift_valid,
	  in_ready => s_color_data_req,
    out_enable => s_color_valid,
	  out_ready => ready, -- fixme
	  in_data => s_dfifo,
	  out_data => s_color
  );

  col_mux: process(s_gray_valid,s_color_valid,s_gray_data_req,s_color_data_req,gray)
  begin
    if(gray='0') then
      valid <= s_color_valid;
		  control_data_req <= s_color_data_req;
	  else
      valid <= s_gray_valid;
		  control_data_req <= s_gray_data_req;
	  end if;
  end process;
end generate;

gen_gray: if COL_NUM=1 generate
  valid <= s_gray_valid;
  control_data_req <= s_gray_data_req;
  do_color <= (others=>'0');
end generate;

-- Write out process


end behavior;
