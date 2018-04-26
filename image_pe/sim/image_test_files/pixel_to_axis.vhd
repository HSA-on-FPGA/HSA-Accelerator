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


entity pixel_to_axis is
generic(
    C_M_AXIS_TDATA_WIDTH : integer := 32 -- must be 32
);
Port ( 
   --  pixel stream side
  rin    : in std_logic_vector (7 downto 0);
  gin    : in std_logic_vector (7 downto 0);
  bin    : in std_logic_vector (7 downto 0);
	grayin : in std_logic_vector (15 downto 0);

  gray   : in std_logic;
	nd     : in std_logic;
  ----- Master AXI Stream Ports----
  M_AXIS_ACLK : in std_logic;
  M_AXIS_ARESETN  : in std_logic;
  M_AXIS_TVALID : out std_logic;
  M_AXIS_TDATA  : out std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
--  M_AXIS_TSTRB  : out std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0);
--  M_AXIS_TLAST  : out std_logic; -- for future use
  M_AXIS_TREADY : in std_logic
);
end pixel_to_axis;

architecture behavior of pixel_to_axis is

type COLOR_MAPPING_STATE is (insert_rgbr,write_rbgr,write_grbg,write_bgrb);
type GRAY_MAPPING_STATE is (word_read,write_staged);

signal s_color_st, s_next_color_st : COLOR_MAPPING_STATE;
signal s_gray_st, s_next_gray_st : GRAY_MAPPING_STATE;

signal s_di_color :std_logic_vector(23 downto 0);
signal s_di_gray  :std_logic_vector(15 downto 0);
signal s_rgb_staged, s_rgb_shift : std_logic_vector(23 downto 0);
signal s_gray_staged, s_gray_shift : std_logic_vector(15 downto 0);
signal s_do_gray :std_logic_vector(31 downto 0);
signal s_do_color :std_logic_vector(31 downto 0);

constant c_color_fill : std_logic_vector(7 downto 0):= (others=>'0');

signal s_shift_valid,s_gray_pixel_valid, s_color_pixel_valid: std_logic ;


alias clk : std_logic is M_AXIS_ACLK;
alias rst_n : std_logic is M_AXIS_ARESETN;

begin


s_di_gray <= grayin;
s_di_color <= bin & gin & rin;
s_shift_valid <= '1' when nd='1' and M_AXIS_TREADY='1' else '0';

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


-- State mashine for color conversion


color_sync: process(clk)
begin
  if(clk'event and clk = '1') then
    if(rst_n = '0') then
      s_color_st <= insert_rgbr;
      s_rgb_staged <= (others=>'0');
    elsif(gray='0') then
      if(s_shift_valid='1') then
				s_color_st <= s_next_color_st;
        s_rgb_staged <= s_rgb_shift;
      end if;
    end if;
  end if;
end process;

color_state: process(s_color_st,s_rgb_staged,s_di_color,s_shift_valid)
begin
--  s_rgb_shift <= (others=>'0');
  s_do_color <= (others=>'0');
  s_color_pixel_valid <= '0';
  
  case s_color_st is
    when insert_rgbr =>
--        s_next_color_st <= insert_rgbr;
--        s_do <= (others=>'0');
--        s_pixel_valid <= '0';
  
      if(s_shift_valid ='1') then
          -- s_di         |b|g|r|
          -------------------------
          -- s_rgb_shift    |b|g|r|
        s_rgb_shift <= s_di_color;
        s_next_color_st <= write_rbgr;
      end if;
    when write_rbgr =>
--        s_next_color_st <= write_rbgr;
--        s_do <= (others=>'0');
--        s_pixel_valid <= '0';
  
      if(s_shift_valid ='1') then
          -- s_di          |b|g|r|
          -- s_rgb_staged  |b|g|r|
          --------------------------
          -- s_do          |r|b|g|r| --> valid
          -- s_rgb_shift   |b|g| |
        s_do_color<= s_di_color(7 downto 0) & s_rgb_staged;
        s_color_pixel_valid <='1';
        s_rgb_shift <= s_di_color(23 downto 8) & c_color_fill;
        s_next_color_st <= write_grbg;
      end if;
    when write_grbg =>
--        s_next_color_st <= write_grbg;
--        s_do <= (others=>'0');
--        s_pixel_valid <= '0';
  
      if(s_shift_valid='1') then
          -- s_di          |b|g|r|
          -- s_rgb_staged  |b|g| |
          --------------------------
          -- s_do          |g|r|b|g| --> valid
          -- s_rgb_shift   |b| | |
        s_do_color<= s_di_color(15 downto 0) & s_rgb_staged(23 downto 8);
				s_color_pixel_valid <='1';
        s_rgb_shift <= s_di_color(23 downto 16) & c_color_fill & c_color_fill;
        s_next_color_st <= write_bgrb; 
      end if;
    when write_bgrb => 
--        s_next_color_st <= write_grbg;
--        s_do <= (others=>'0');
--        s_pixel_valid <= '0';
  
      if(s_shift_valid='1') then
          -- s_di          |b|g|r|
          -- s_rgb_staged  |b| | |
          --------------------------
          -- s_do          |b|g|r|b| --> valid
        s_do_color<= s_di_color & s_rgb_staged(23 downto 16);
				s_color_pixel_valid <='1';
        s_next_color_st <= insert_rgbr; 
      end if;
    when others => null;
  end case;
end process;


-- State mashine for color conversion


gray_sync: process(clk)
begin
  if(clk'event and clk = '1') then
    if(rst_n = '0') then
      s_gray_st <= word_read;
      s_gray_staged <= (others=>'0');
    elsif(gray='1') then
      if(s_shift_valid='1') then
				s_gray_st <= s_next_gray_st;
        s_gray_staged <= s_gray_shift;
      end if;
    end if;
  end if;
end process;

gray_state: process(s_gray_st,s_gray_staged,s_di_gray,s_shift_valid)
begin
  s_do_gray <= (others=>'0');
  s_gray_pixel_valid <= '0';

	  case s_gray_st is
		  when word_read =>
			  if(s_shift_valid='1') then
					s_gray_shift <= s_di_gray;
					s_next_gray_st <= write_staged;
				end if;
		  when write_staged =>
			  if(s_shift_valid='1') then
					s_do_gray <= s_di_gray & s_gray_staged;
          s_gray_pixel_valid <= '1';
					s_next_gray_st <= word_read;
				end if;
    when others => null;
  end case;
end process;


  

end behavior;
