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
use work.pkg_config.all;

entity accel_control is
port(
  clk        : in  std_logic;
  rst_n      : in  std_logic;
  start      : in  std_logic; -- Start Signal
  valid_in   : in  std_logic; -- New Data for valid input pixel
  ready_in   : out  std_logic;
  valid_out  : out std_logic; -- valid output pixel
  ready_out  : in  std_logic;
  pipe_filled: in std_logic; -- bit for enabling streaming
  pipe_we    : out std_logic;
	np         : in std_logic_vector(c_np_addr_0-1 downto 0); -- only for prog. hw
  di         : in VEC_DPEPAR_0;
  do         : out VEC_DPEPAR_0; 
  last       : out std_logic 
);
end accel_control;

architecture behavior of accel_control is

type t_accel_state is (IDLE, FILL,NEW_DATA_READY, EMPTY); 


signal s_read_cnt, s_stream_out_cnt  : unsigned(c_np_addr_0-1 downto 0);
signal s_accel_state: t_accel_state;

signal s_read_enable, s_read_last, s_stream_out_enable, s_write_out_first,s_write_out_stream,s_stream_out_last,
s_pipe_nd, s_pipe_fill, s_pipe_empty,s_pipe_fill_last, s_pipe_empty_last : std_logic;

begin

s_pipe_fill <= '1' when s_accel_state=FILL and valid_in='1' else '0';
s_pipe_nd <= '1' when s_accel_state = NEW_DATA_READY and valid_in ='1' and ready_out='1'else '0';
s_pipe_empty <= '1' when s_accel_state=EMPTY and ready_out='1' else '0';

s_read_last <= '1' when s_read_cnt = unsigned(np) else '0';
s_stream_out_last <= '1' when s_stream_out_cnt = unsigned(np)-1 else '0';
s_read_enable <= s_pipe_fill or s_pipe_nd; 
pipe_we <= s_read_enable or s_pipe_empty;
ready_in <= '1' when s_accel_state=FILL else
             ready_out when s_accel_state= NEW_DATA_READY else '0';


s_write_out_first <= '1' when s_accel_state=FILL and pipe_filled='1' and s_pipe_fill_last='1'  else '0';
s_stream_out_enable <= s_write_out_first or s_write_out_stream;




read_in_counter:process(clk)
begin
  if clk'event and clk='1' then
    if rst_n = '0' then
      s_read_cnt <= (others =>'0');
    elsif s_read_cnt < unsigned(np) then
      if s_read_enable = '1'then
        s_read_cnt <= s_read_cnt+c_par_0;
      end if;
    elsif s_read_cnt >= unsigned(np) then
      s_read_cnt <= (others =>'0');
    end if;
  end if;
end process;

process(clk)
begin
  if clk'event and clk='1' then
    if rst_n = '0' then
      s_pipe_fill_last <= '0';
      s_pipe_empty_last <= '0';
    else
      s_pipe_fill_last <= s_pipe_fill;
      s_pipe_empty_last <= s_pipe_empty;
    end if;
  end if;
end process;


-- Show current Accelerator state

accel_state: process(clk)
begin
  if clk'event and clk='1' then
    if rst_n = '0' then
      s_accel_state <= IDLE;
      s_write_out_stream <= '0';
    else
      case(s_accel_state) is
        when IDLE =>
          s_write_out_stream <= '0';
          if(start = '1') then
            s_accel_state <= FILL;
          end if;
        when FILL =>
          if(pipe_filled ='1') then
              s_accel_state <= NEW_DATA_READY;
            if(valid_in='1' and ready_out='1') then
              s_write_out_stream <= '1';
            end if;
          end if;
        when NEW_DATA_READY =>
          if (valid_in='1' and ready_out='1') then
            s_write_out_stream <= '1';
          else
            s_write_out_stream <= '0';
          end if;
          if s_read_last='1' and ready_out='1' then
            s_accel_state <= EMPTY;
          end if;
        when EMPTY =>
          if (ready_out='1') then
            s_write_out_stream <= '1';
            if s_pipe_empty='1' then
              s_write_out_stream <= '1';
            else
              s_write_out_stream <= '0';
            end if;
          else
            s_write_out_stream <= '0';
          end if;

          if(s_stream_out_last ='1' and s_pipe_empty='1') then
            s_accel_state <= IDLE;
            s_write_out_stream <= '0';
          end if;
        when others =>
          s_accel_state <= IDLE;
        end case;
    end if;
  end if;
end process;


stream_out_counter:process(clk)
begin
  if clk'event and clk='1' then
    if rst_n = '0' then
      s_stream_out_cnt <= (others =>'0');
    elsif s_stream_out_cnt < unsigned(np) then
      if s_stream_out_enable = '1' then
        s_stream_out_cnt <= s_stream_out_cnt+c_par_0;
      end if;
    elsif s_stream_out_cnt >= unsigned(np) then
      s_stream_out_cnt <= (others =>'0');
    end if;
  end if;
end process;

stream_out_reg: process(clk)
begin
  if clk'event and clk='1' then
    if rst_n = '0' then
      do <= (others =>(others=>'0'));
      valid_out <= '0';
      last <= '0';
    else
      last      <= s_stream_out_last;
      valid_out <= s_stream_out_enable;
      if s_stream_out_enable = '1' then
        do <= di;
      end if;
    end if;
  end if;
end process;


end behavior;
