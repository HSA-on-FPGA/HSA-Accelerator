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
use ieee.math_real.all;


entity axi_master is
Generic(
  DATA_WIDTH: integer range 1 to 512:= 32;
  NUM_PIX_MAX: integer:= 4096*4096;
  PAR: integer range 1 to 64:= 1
);
Port ( 
  clk : in std_logic;
  rst_n : in std_logic;
  gray : in std_logic;
  num_pix : in std_logic_vector(integer(ceil(log2(real(NUM_PIX_MAX))))-1 downto 0);

   --  Input side
  in_data : in std_logic_vector (PAR*DATA_WIDTH-1 downto 0);
	in_valid : in std_logic;
  in_ready : out std_logic;
   --    AXI Master side;
  axi_tdata : out std_logic_vector (PAR*DATA_WIDTH-1 downto 0);
  axi_tvalid : out std_logic;
  axi_tlast : out std_logic;
  axi_tready : in std_logic
);
end axi_master;

architecture behavior of axi_master is

-- Counts in Byte !!!

signal s_bytes_cnt, s_num_bytes : integer range 0 to NUM_PIX_MAX*4-1;
signal s_read_en, s_axi_last : std_logic;

begin

s_axi_last <= '1' when (s_bytes_cnt = s_num_bytes-(4*PAR)) and (s_num_bytes > 0) else '0';

s_read_en <= in_valid and axi_tready;
in_ready <= axi_tready;

process(gray,num_pix)
begin
--TODO must be corrected for other widths
  if gray='1' then
    s_num_bytes <= to_integer(resize(unsigned(num_pix),num_pix'length+2))*2;
  else
    s_num_bytes <= to_integer(resize(unsigned(num_pix),num_pix'length+2))*3;
  end if;
end process;


-- Read Counter

process(clk)
begin
  if(clk'event and clk='1') then
    if(rst_n = '0') then
      s_bytes_cnt <= 0;
    else
      if(s_bytes_cnt <= s_num_bytes-4) then
        if( s_read_en ='1') then
          s_bytes_cnt <= s_bytes_cnt + 4*PAR;
        end if;
      elsif(s_bytes_cnt = s_num_bytes) then
        s_bytes_cnt <= 0; 
      end if;
    end if;
  end if;
end process;

process(clk)
begin
  if(clk'event and clk='1') then
    if(rst_n = '0') then
      axi_tvalid <= '0';
      axi_tlast <= '0';
      axi_tdata <= (others =>'0');
    else
      axi_tvalid <= in_valid;
      axi_tlast <= s_axi_last;
      if(s_read_en='1') then
        axi_tdata <= in_data;
      end if;
    end if;
  end if;
end process;


end behavior;
