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


entity pixel_to_fifo_gen is
Generic(
  DATA_OUT_WIDTH: integer range 1 to 512:= 32;
  COLOR_WIDTH: integer range 1 to 512:= 8;
  GRAY_WIDTH: integer range 1 to 512:= 16;
  COL_NUM: integer range 1 to 16:= 3;
  PAR: integer range 1 to 64:= 1
);
Port ( 
  clk : in std_logic;
  rst_n : in std_logic;
  en : in std_logic;
  gray: in std_logic;
   --  accelerator side
  accel_do_gray : in std_logic_vector (PAR*GRAY_WIDTH-1 downto 0);
  accel_do_color : in std_logic_vector (PAR*COL_NUM*COLOR_WIDTH-1 downto 0);

	accel_valid : in std_logic;
  accel_ready : out std_logic;
   --    fifo read side;
  fifo_full : in std_logic;
  fifo_data_in : out std_logic_vector (DATA_OUT_WIDTH-1 downto 0);
  fifo_write_enable : out std_logic
);
end pixel_to_fifo_gen;

architecture behavior of pixel_to_fifo_gen is


signal  s_fifo_gray,s_fifo_color : std_logic_vector(DATA_OUT_WIDTH-1 downto 0);
--signal  s_di_gray : std_logic_vector(15 downto 0);
--signal  s_di_color : std_logic_vector(23 downto 0);

signal s_fifo_ready,s_fifo_write_color,s_fifo_write_gray,s_data_ready_gray, s_data_ready_color : std_logic;

--signal s_fifo_one, s_fifo_two,s_fifo_three, s_fifo_four  : std_logic_vector (7 downto 0); 
--signal s_color_one, s_color_two,s_color_three, s_color_four  : std_logic_vector (7 downto 0); 

begin


s_fifo_ready <= not fifo_full;



-- Signal for debug, should be removed later

--s_fifo_one <= s_fifo_color(7 downto 0); 
--s_fifo_two <= s_fifo_color(15 downto 8); 
--s_fifo_three <= s_fifo_color(23 downto 16);
--s_fifo_four <= s_fifo_color(31 downto 24);

--s_color_one <= accel_di(7 downto 0);
--s_color_two <= accel_di(15 downto 8);
--s_color_three <= accel_di(23 downto 16);
--s_color_four <= accel_di(31 downto 24);

gray_inst: entity work.scale
generic map(
  DATA_IN_WIDTH =>PAR*GRAY_WIDTH, -- change later
  DATA_OUT_WIDTH =>DATA_OUT_WIDTH -- change later
)
port map(
  clk => clk,
	reset => rst_n,
	in_enable => accel_valid,
	in_ready=> s_data_ready_gray,
	in_data => accel_do_gray,
	out_enable => s_fifo_write_gray,
	out_ready => s_fifo_ready,
	out_data => s_fifo_gray
);

gen_color_scale: if COL_NUM>1 generate
  color_inst: entity work.scale
  generic map(
    DATA_IN_WIDTH =>PAR*COL_NUM*COLOR_WIDTH, 
    DATA_OUT_WIDTH =>DATA_OUT_WIDTH 
  )
  port map(
    clk => clk,
	  reset => rst_n,
	  in_enable => accel_valid,
	  in_ready=> s_data_ready_color,
	  in_data => accel_do_color,
	  out_enable => s_fifo_write_color,
	  out_ready => s_fifo_ready,
	  out_data => s_fifo_color
  );

  process(s_fifo_color,s_fifo_write_color,s_fifo_gray,s_fifo_write_gray,gray, s_data_ready_gray,
  s_data_ready_color)
  begin     
    if(gray='0') then
      fifo_data_in <= s_fifo_color;
      fifo_write_enable <= s_fifo_write_color;
      accel_ready <= s_data_ready_color;
    else
      fifo_data_in <= s_fifo_gray;
      fifo_write_enable <= s_fifo_write_gray;
      accel_ready <= s_data_ready_gray;
    end if;
  end process;
end generate;

gen_gray_lut: if COL_NUM=1 generate
  fifo_data_in <= s_fifo_gray;
  fifo_write_enable <= s_fifo_write_gray;
  accel_ready <= s_data_ready_gray;
end generate;

end behavior;
