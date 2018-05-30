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

entity fifo_to_axi_stream is
    Generic (   AXI_PACKAGE_SIZE : integer
            ;   AXIS_DATA_WIDTH : integer
    );
    Port ( fifo_empty : in STD_LOGIC;
           fifo_is_last : in STD_LOGIC;
           fifo_data_out : in STD_LOGIC_VECTOR (AXIS_DATA_WIDTH - 1 downto 0);
           fifo_read_enable : out STD_LOGIC;
           axi_tdata : out STD_LOGIC_VECTOR (AXIS_DATA_WIDTH - 1 downto 0);
           axi_tvalid : out STD_LOGIC;
           axi_tlast : out STD_LOGIC;
           axi_tready : in STD_LOGIC;
           clk : in STD_LOGIC;
           reset : in STD_LOGIC);
end fifo_to_axi_stream;

architecture Behavioral of fifo_to_axi_stream is

constant COUNTER_SIZE : integer := integer(ceil(log2(real(AXI_PACKAGE_SIZE))));

signal data_word, data_buffer : STD_LOGIC_VECTOR (AXIS_DATA_WIDTH - 1 downto 0) := (others => '0');
signal data_word_ready : STD_LOGIC := '0';
signal data_word_will_be_read : STD_LOGIC := '0';
signal data_word_needs_new_data : STD_LOGIC := '1';

signal tlast_counter : unsigned (COUNTER_SIZE downto 0) := (others => '0');
signal tlast_sig : STD_LOGIC := '0';
signal use_buffer : std_logic;

begin

    axi_tvalid <= data_word_ready;
    --axi_tvalid <= not fifo_empty;
    axi_tdata <= data_word;
    axi_tlast <= tlast_sig;

    -- data word is the output of the fifo, as the fifo buffers one word anyway
    data_word <= fifo_data_out;

    -- signals wether the data word will get invalidated during next clk
    data_word_will_be_read <= '1' when axi_tready = '1' and data_word_ready = '1' else '0'; 
    --data_word_will_be_read <= '1' when data_word_ready = '1' else '0'; 
    data_word_needs_new_data <= '1' when data_word_will_be_read = '1' or data_word_ready = '0' else '0';

    -- process is responsible for pulling data out of the fifo into data_word
    fifo_read_enable <= '1' when data_word_needs_new_data = '1' and fifo_empty = '0' else '0';
    read_from_fifo: process(clk)
    begin
      if rising_edge(clk) then
        if reset='0' then
            data_word_ready <= '0';
        else
            data_word_ready <= data_word_ready; 
        
            if data_word_needs_new_data = '1' then
                if fifo_empty = '0' then
                    data_word_ready <= '1';
                else
                    data_word_ready <= '0';
                end if;
            end if;
        end if;    
      end if;    
    end process;

    tlast_sig <= fifo_is_last;
    
    compute_tlast : process(clk)
    begin
        if rising_edge(clk) then
          if reset='0' then
            tlast_counter <= (others => '0');
          elsif data_word_will_be_read = '1' then
                if tlast_sig = '0' then
                    tlast_counter <= tlast_counter + 1;
                else
                    tlast_counter <= (others => '0');
                end if;
          else
              tlast_counter <= tlast_counter; 
          end if;
        end if;
    end process;
    

end Behavioral;
