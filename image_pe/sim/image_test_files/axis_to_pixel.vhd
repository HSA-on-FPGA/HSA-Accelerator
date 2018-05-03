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


entity axis_to_pixel is
generic(
    C_S_AXIS_TDATA_WIDTH : integer := 32 -- must be 32
);
Port ( 

  rout  : out std_logic_vector(7 downto 0);
  gout  : out std_logic_vector(7 downto 0);
  bout  : out std_logic_vector(7 downto 0);
  grayout  : out std_logic_vector(15 downto 0);
	gray : in  std_logic;
  valid : out std_logic;

  S_AXIS_ACLK   : in std_logic;
  S_AXIS_ARESETN  : in std_logic;
  S_AXIS_TVALID : in std_logic;
  S_AXIS_TDATA  : in std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
  S_AXIS_TLAST  : in std_logic;-- TODO work here
  S_AXIS_TREADY : out std_logic

);
end axis_to_pixel;

architecture behavior of axis_to_pixel is


type COLOR_MAPPING_STATE is (r_bgr,gr_bg,bgr_b, write_staged);
type GRAY_MAPPING_STATE is (word_read, write_staged);

signal s_color_st, s_next_color_st : COLOR_MAPPING_STATE;
signal s_gray_st, s_next_gray_st : GRAY_MAPPING_STATE;

signal s_di : std_logic_vector (31 downto 0);
signal s_rgb_staged, s_rgb_shift,s_do_color : std_logic_vector (23 downto 0);
signal s_gray_staged, s_gray_shift,s_do_gray : std_logic_vector (15 downto 0);

signal s_shift_valid,s_color_pixel_valid, s_gray_pixel_valid, s_color_tready,s_gray_tready :std_logic;
signal s_tlast, s_valid : std_logic;
-- signals for debug

alias clk : std_logic is S_AXIS_ACLK;
alias rst_n : std_logic is S_AXIS_ARESETN;

constant c_color_fill : std_logic_vector(7 downto 0):=(others=>'0');

begin


process(clk)
begin
  if clk'event and clk='1' then
    if rst_n = '0' then
      s_tlast <= '0';
    else
      s_tlast <= S_AXIS_TLAST;
    end if;
  end if;
end process;

valid <= s_valid or s_tlast;

rout <= s_do_color(7 downto 0);
gout <= s_do_color(15 downto 8);
bout <= s_do_color(23 downto 16);

grayout <= s_do_gray;


out_mux:process(s_color_pixel_valid,s_gray_pixel_valid,gray,s_gray_tready,s_color_tready)
begin
  if(gray='0') then
    s_valid <= s_color_pixel_valid;
		S_AXIS_TREADY <= s_color_tready; 
	else
    s_valid <= s_gray_pixel_valid;
		S_AXIS_TREADY <= s_gray_tready; 
	end if;
end process; 
s_shift_valid <= S_AXIS_TVALID;
s_di <= S_AXIS_TDATA;

-- State mashine for color conversion

color_sync: process(clk)
begin
  if(clk'event and clk = '1') then
    if(rst_n = '0') then
      s_color_st <= r_bgr;
      s_rgb_staged <= (others=>'0');
    else   
			if(gray='0') then   
        if(s_shift_valid ='1') then
		      s_color_st <= s_next_color_st;
          s_rgb_staged <= s_rgb_shift;
        end if;
      end if;
    end if;
  end if;
end process;

color_state: process(s_color_st, s_shift_valid,s_di,s_rgb_staged)
begin
  s_do_color <= (others=>'0');
  s_color_pixel_valid <= '0';
  s_color_tready <= '1';
  
  case s_color_st is
    when r_bgr =>
      if((s_shift_valid or s_tlast)='1') then
          -- |b|g|r|
        s_do_color <= s_di(23 downto 0);
        s_color_pixel_valid <= '1';
        s_rgb_shift(7 downto 0) <= s_di(31 downto 24); -- save r 
        s_next_color_st <= gr_bg;
      end if;
    when gr_bg =>
      if((s_shift_valid or s_tlast)='1') then
        s_do_color <= s_di(15 downto 0) & s_rgb_staged(7 downto 0);
        s_color_pixel_valid <= '1';
        s_rgb_shift(15 downto 0) <= s_di(31 downto 16); --save gr
        s_next_color_st <= bgr_b;
      end if;
    when bgr_b =>
      if((s_shift_valid or s_tlast)='1') then
        s_do_color <= s_di(7 downto 0) & s_rgb_staged(15 downto 8) & s_rgb_staged(7 downto 0); 
        s_color_pixel_valid <= '1';
        s_rgb_shift<= s_di(31 downto 8); --save bgr
        s_next_color_st <= write_staged;
      end if;
    when write_staged =>
      if((s_shift_valid or s_tlast)='1') then
        s_do_color <= s_rgb_staged; 
        s_color_pixel_valid <= '1';
        s_next_color_st <= r_bgr;
        s_color_tready <= '0';
      end if;
    when others => null;
  end case;
end process;

gray_sync: process(clk)
begin
  if(clk'event and clk = '1') then
    if(rst_n = '0') then
      s_gray_st <= word_read;
      s_gray_staged <= (others=>'0');
    else
			if(gray='1') then   
        if(s_shift_valid ='1') then
		      s_gray_st <= s_next_gray_st;
          s_gray_staged <= s_gray_shift;
        end if;
      end if;
    end if;
  end if;
end process;

gray_state: process(s_gray_st, s_shift_valid, s_di,s_gray_staged)
begin
  s_do_gray <= (others=>'0');
  s_gray_pixel_valid <= '0';
  s_gray_tready <= '1';

  case s_gray_st is
	  when word_read =>
      if(s_shift_valid='1') then
				s_do_gray <= s_di(15 downto 0);
				s_gray_shift <=s_di(31 downto 16);
				s_gray_pixel_valid <= '1';
        s_next_gray_st <= write_staged;
			end if;
	  when write_staged =>
      if(s_shift_valid='1') then
				s_do_gray <= s_gray_staged;
        s_gray_tready <= '0';
				s_gray_pixel_valid <= '1';
        s_next_gray_st <= word_read;
			end if;
    when others => null;
  end case;
end process;


end behavior;
