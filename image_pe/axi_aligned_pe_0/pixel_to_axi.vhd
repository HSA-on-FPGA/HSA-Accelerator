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


entity pixel_to_axi is
Generic(
  DATA_WIDTH: integer range 1 to 512:= 32;
  GRAY_WIDTH: integer range 1 to 512:= 16;
  COLOR_WIDTH: integer range 1 to 512:= 8;
  NUM_COL: integer range 1 to 512:= 3;
  PAR: integer range 1 to 64:= 1
);
Port ( 
  clk : in std_logic;
  rst_n : in std_logic;
  gray: in std_logic;
   --  accelerator side
  in_gray : in std_logic_vector (PAR*GRAY_WIDTH-1 downto 0);
  in_color : in std_logic_vector (PAR*NUM_COL*COLOR_WIDTH-1 downto 0);

	in_valid : in std_logic;
  in_ready : out std_logic;
   --    AXI Master side;
  out_data : out std_logic_vector (PAR*DATA_WIDTH-1 downto 0);
  out_valid : out std_logic;
  out_ready : in std_logic
);
end pixel_to_axi;

architecture behavior of pixel_to_axi is


signal s_gray, s_color : std_logic_vector(PAR*DATA_WIDTH-1 downto 0);
signal s_gray_in_ready,s_gray_out_valid, s_color_in_ready, s_color_out_valid: std_logic;

begin


gray_inst: entity work.scale
generic map(
  DATA_IN_WIDTH =>PAR*GRAY_WIDTH, 
  DATA_OUT_WIDTH =>PAR*DATA_WIDTH 
)
port map(
  clk => clk,
	reset => rst_n,
	in_enable => in_valid,
	in_ready=> s_gray_in_ready,
	in_data => in_gray,
	out_enable => s_gray_out_valid,
	out_ready => out_ready,
	out_data => s_gray
);

gen_color_scale: if NUM_COL > 1 generate

color_inst: entity work.scale
generic map(
  DATA_IN_WIDTH =>PAR*NUM_COL*COLOR_WIDTH, 
  DATA_OUT_WIDTH =>PAR*DATA_WIDTH 
)
port map(
  clk => clk,
	reset => rst_n,
	in_enable => in_valid,
	in_ready=> s_color_in_ready,
	in_data => in_color,
	out_enable => s_color_out_valid,
	out_ready => out_ready,
	out_data => s_color
);

  process(gray,s_color,s_color_out_valid,s_color_in_ready,s_gray,s_gray_out_valid,s_gray_in_ready)
  begin     
    if(gray='0') then
      out_data <= s_color;
      out_valid <= s_color_out_valid;
      in_ready <= s_color_in_ready;
    else
      out_data <= s_gray;
      out_valid <= s_gray_out_valid;
      in_ready <= s_gray_in_ready;
    end if;
  end process;

end generate;

gen_gray: if NUM_COL=1 generate
  out_data <= s_gray;
  out_valid <= s_gray_out_valid;
  in_ready <= s_gray_in_ready;
end generate;


end behavior;
