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
--use IEEE.NUMERIC_STD.ALL;
-- must be changed for altera or other then 7 series
Library UNISIM;
use UNISIM.vcomponents.all;
Library UNIMACRO;
use UNIMACRO.vcomponents.all;
Library xpm;
use xpm.vcomponents.all;

entity fifo_wrapper is
generic(
  g_datawidth : integer;
  g_device_ultra: boolean:= true
);
Port ( 
  rst_n : in std_logic;
   --  fifo write side
       wclk:  in std_logic;
       we : in std_logic;
       di : in std_logic_vector (g_datawidth-1 downto 0);
       full: out std_logic;
			 almostfull: out std_logic;
   --    fifo read side;
       rclk:  in std_logic;
       re : in std_logic;
       do : out std_logic_vector (g_datawidth-1 downto 0);
       empty: out std_logic;
			 almostempty: out std_logic
);
end fifo_wrapper;

architecture behavior of fifo_wrapper is


signal s_rst, overflow,underflow, rd_rst_busy, wr_rst_busy : std_logic;
signal s_wrcount,s_rdcount : std_logic_vector(9 downto 0); -- must be changed for other depth
signal wr_data_count,rd_data_count : std_logic_vector(10 downto 0); -- must be changed for other depth


begin

s_rst <= not rst_n; -- see if correct

seven_ser_gen:if g_device_ultra=false generate

  fifo_inst : FIFO_DUALCLOCK_MACRO
  generic map(
    DEVICE => "7SERIES", -- Target: "VIRTEX5", "VIRTEX6", "7SERIES"
    ALMOST_FULL_OFFSET => X"0080", -- default for set almost full treshold
    ALMOST_EMPTY_OFFSET => X"0010", -- default for set almost empty treshold
    DATA_WIDTH => g_datawidth, -- 1-72 for higher than 36 bit only 36-kb fifo is used
    FIFO_SIZE => "36Kb", -- target Bram, "18Kb" or "36Kb"
    FIRST_WORD_FALL_THROUGH => FALSE)  --Sets the FIFO FWFT to TRUE or FALSE
  port map(
    ALMOSTEMPTY => almostempty,
    ALMOSTFULL => almostfull,
    DO => do,
    EMPTY => empty,
    FULL => full,
    RDCOUNT => s_rdcount,
    RDERR => open,
    WRCOUNT => s_wrcount,
    WRERR => open,
    DI => di,
    RDCLK => rclk,
    RDEN => re,
    RST => s_rst,
    WRCLK => wclk,
    WREN => we
 );
  
end generate; 


-- Following device should be used for all Ultrascale and Ultrascale+ platforms

ultra_gen:if g_device_ultra=true generate

  xpm_fifo_async_inst:xpm_fifo_async
  generic map(
    FIFO_MEMORY_TYPE =>"block", --string;"auto","block","distributed",or"ultra";
    ECC_MODE =>"no_ecc", --string;"no_ecc"or"en_ecc";
    RELATED_CLOCKS => 1, -- positiv integer; 0 or 1
    FIFO_WRITE_DEPTH =>1024, --positiveinteger
    WRITE_DATA_WIDTH =>g_datawidth, --positiveinteger
    WR_DATA_COUNT_WIDTH=>11, --positiveinteger --FIXME change to gen
    PROG_FULL_THRESH =>1000, --positiveinteger
    FULL_RESET_VALUE =>0, --positiveinteger;0or1;
    READ_MODE =>"std", --string;"std"or"fwft";
    FIFO_READ_LATENCY =>1, --positiveinteger;
    READ_DATA_WIDTH  =>g_datawidth, --positiveinteger
    RD_DATA_COUNT_WIDTH =>11, --positiveinteger
    PROG_EMPTY_THRESH =>5, --positiveinteger
    DOUT_RESET_VALUE =>"0", --string
    CDC_SYNC_STAGES => 2, -- positiv integer
    WAKEUP_TIME =>0 --positiveinteger;0or2;
  )
  port map(
    rst =>s_rst,
    wr_clk=>wclk,
    wr_en=>we,
    din=>di,
    full=> full,
    overflow=>overflow,
    wr_rst_busy=>wr_rst_busy,
    rd_clk=>rclk,
    rd_en=>re,
    dout=>do,
    empty=> empty,
    underflow=>underflow,
    rd_rst_busy=>rd_rst_busy,
    prog_full=>almostfull,
    wr_data_count=>wr_data_count,
    prog_empty=>almostempty,
    rd_data_count=>rd_data_count,
    sleep=>'0',
    injectsbiterr=>'0',
    injectdbiterr=>'0',
    sbiterr=>open,
    dbiterr=>open
  );
end generate;










-- End dual Macro instantiation

end behavior;
