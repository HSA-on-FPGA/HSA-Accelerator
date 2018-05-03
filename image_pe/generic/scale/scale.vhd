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

entity scale is
    Generic (   DATA_IN_WIDTH : integer := 32
            ;   DATA_OUT_WIDTH : integer := 32
    );
    Port ( clk              :   in  STD_LOGIC
         ; reset            :   in  STD_LOGIC

         ; in_ready         :   out STD_LOGIC
         ; in_data          :   in  STD_LOGIC_VECTOR (DATA_IN_WIDTH-1 downto 0)
         ; in_enable        :   in  STD_LOGIC

         ; out_ready        :   in  STD_LOGIC
         ; out_enable       :   out STD_LOGIC
         ; out_data         :   out STD_LOGIC_VECTOR (DATA_OUT_WIDTH-1 downto 0)
    );
end scale;



architecture Behavioral of scale is

function max(LEFT, RIGHT: INTEGER) return INTEGER is
begin
    if LEFT > RIGHT then
        return LEFT;
    else
        return RIGHT;
    end if;
end;
  
constant FIFO_SIZE : integer := max((DATA_OUT_WIDTH/DATA_IN_WIDTH + 2) * DATA_IN_WIDTH, DATA_IN_WIDTH * 3);

signal write_position : signed(31 downto 0) := (others => '0');
signal read_possible : STD_LOGIC;
signal write_possible : STD_LOGIC;

signal input_fifo : STD_LOGIC_VECTOR(FIFO_SIZE - 1 downto 0);

-- output of input_fifo, input of axi_write_buffer
signal output_write_enable : STD_LOGIC;
signal output_write_data : STD_LOGIC_VECTOR(DATA_OUT_WIDTH - 1 downto 0);

-- whether data will be read from in or not
signal enable : STD_LOGIC;

begin

    -- when enough data is in the fifo, we read
    read_possible <= out_ready when to_integer(write_position) >= DATA_OUT_WIDTH else '0';
    write_possible <= '1' when to_integer(write_position) + DATA_IN_WIDTH <= FIFO_SIZE else '0';

    enable <= write_possible and in_enable;

    -- this process is responsible for the updates of write_position.
    -- whenever new data is written, it increases by DATA_IN_WIDTH,
    -- and whenever data gets pulled from the fifo, it decreases by DATA_OUT_WIDTH.
    data_position_tracker: process(clk, enable, reset)
    begin
        -- reset
        if reset = '0' then
            write_position <= (others => '0');
        -- normal operation        
        elsif rising_edge(clk) then
            -- normal operation, increase position on write enable, decrease if we have enough to read
            if read_possible = '1' then
                if enable = '1' then
                    write_position <= write_position - DATA_OUT_WIDTH + DATA_IN_WIDTH;
                else
                    write_position <= write_position - DATA_OUT_WIDTH;
                end if;
            else
                if enable = '1' then
                    write_position <= write_position + DATA_IN_WIDTH;
                else
                    write_position <= write_position;
                end if;
            end if; 
        end if;
    end process;
    
    -- this process is responsible for the data management in the input_fifo.
    -- appends new data to the end of the fifo, and lshifts the fifo upon data removal.
    input_fifo_process: process(clk, enable, reset)
    begin
        if reset = '0' then
            input_fifo <= (others => '0');
            output_write_enable <= '0';
            output_write_data <= (others => '0');
        elsif rising_edge(clk) then
            -- default values
            input_fifo <= input_fifo;
            output_write_enable <= '0';
            output_write_data <= (others => '0');
            
            -- if read
            if read_possible = '1' then
                
                -- output data
                --output_write_enable <= '1';
                --output_write_data <= input_fifo(DATA_OUT_WIDTH - 1 downto 0);
                -- shift fifo data
                input_fifo(input_fifo'length - 1 - DATA_OUT_WIDTH downto 0) <= input_fifo(input_fifo'length - 1 downto DATA_OUT_WIDTH);
                input_fifo(input_fifo'length - 1 downto input_fifo'length - DATA_OUT_WIDTH) <= (others => '0');
                
                -- write new data to fifo if enable, important: consider the moved position of the fifo
                if enable = '1' then
                    input_fifo(to_integer(write_position) + DATA_IN_WIDTH - 1 - DATA_OUT_WIDTH downto to_integer(write_position) - DATA_OUT_WIDTH) <= in_data;
                end if;
            
            else
                -- write new data to fifo if enable
                if enable = '1' then
                    input_fifo(to_integer(write_position) + DATA_IN_WIDTH - 1 downto to_integer(write_position)) <= in_data;
                end if;
            end if;
        end if;
    end process;

    -- output signals
    out_enable <= read_possible;
    out_data <= input_fifo(DATA_OUT_WIDTH - 1 downto 0);

    in_ready <= write_possible;
    
end Behavioral;


