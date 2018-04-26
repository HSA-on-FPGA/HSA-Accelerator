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

use work.pkg_functions.all;
use work.pkg_config.all;

entity tb_axi_pe_test is
end tb_axi_pe_test;

architecture behavior of tb_axi_pe_test is

constant c_vecsize : integer:= c_ww_max_0 * c_wh_max_0;

constant c_dw : integer:= c_dw_pe_0;
constant c_pixw: integer:= c_dw_pix_max_0;
constant c_regw : integer:= 32;

constant c_base_coeff_one : integer:=c_num_im_para_0;
constant c_base_coeff_two : integer:=c_num_im_para_0+c_vecsize;
constant c_color_fill : std_logic_vector(c_pixw-1 downto 0):= (others=>'0');


type VEC_KERINT is array(0 to c_vecsize-1) of integer;
type VEC_COEFF is array(0 to c_vecsize-1) of std_logic_vector(c_regw-1 downto 0);

constant cclk_period : time:= 10 ns;
constant iclk_period : time:= 10 ns;
constant oclk_period : time:= 10 ns;
--constant pe_clk_period : time:= 10 ns;

signal en,nd, rst_n,start_read, valid_out : std_logic;
-- signal for input
signal s_color: std_logic_vector(c_dw-1 downto 0);
signal s_color_cnt: unsigned(1 downto 0);
signal s_byte_four,s_byte_three,s_byte_two, s_byte_one : std_logic_vector(c_pixw-1 downto 0);

------ axi lite signals -------

signal s_axi_aclk, s_axi_aresetn : std_logic;
-- adress write
signal s_axi_awaddr : std_logic_vector(c_regw-1 downto 0);
signal s_axi_awvalid, s_axi_awready : std_logic;
-- data write
signal s_axi_wvalid, s_axi_wready : std_logic;
signal s_axi_wdata : std_logic_vector(c_dw-1 downto 0);
signal s_axi_wstrb : std_logic_vector(c_dw/8-1 downto 0);
-- response write
signal s_axi_bvalid, s_axi_bready : std_logic;
signal s_axi_bresp : std_logic_vector(1 downto 0);
-- adress read
signal s_axi_araddr : std_logic_vector(c_regw-1 downto 0);
signal s_axi_arvalid, s_axi_arready : std_logic;
-- data read
signal s_axi_rvalid, s_axi_rready : std_logic;
signal s_axi_rdata : std_logic_vector(c_dw-1 downto 0);
signal s_axi_rresp : std_logic_vector(1 downto 0);

------ axis slave  -------
signal s_axis_aclk, s_axis_aresetn : std_logic;
signal s_axis_tvalid, s_axis_tready, s_axis_tlast : std_logic;
signal s_axis_tdata : std_logic_vector(c_dw-1 downto 0);
signal s_axis_tkeep : std_logic_vector(c_dw/8-1 downto 0);

------ axis master  -------
signal m_axis_aclk, m_axis_aresetn : std_logic;
signal m_axis_tvalid, m_axis_tready, m_axis_tlast : std_logic;
signal m_axis_tdata : std_logic_vector(c_dw-1 downto 0);
signal m_axis_tkeep : std_logic_vector(c_dw/8-1 downto 0);


-- Alias for different clk --

alias iclk : std_logic is s_axis_aclk;
alias oclk : std_logic is m_axis_aclk;
alias cclk : std_logic is s_axi_aclk;


----- Signals for Operation

signal s_operation: std_logic_vector(c_regw-1 downto 0);

alias a_reserved : std_logic_vector(24 downto 0) is s_operation(31 downto 7);
alias a_color : std_logic is s_operation(6); -- for color mode
alias a_border : std_logic_vector(1 downto 0) is s_operation(5 downto 4); -- off for now, for future use
alias a_kernelop : std_logic_vector(2 downto 0) is s_operation(3 downto 1); -- set to single conv for testing
alias a_norm_tresh : std_logic is s_operation(0); -- treshold off



--- Setting Configurations for Image

signal s_imagewidth: integer:= 20;
signal s_imageheight: integer:= 20;
signal s_numpix: integer:= s_imagewidth*s_imageheight; 
signal s_windowwidth: integer:= 3;
signal s_windowheight: integer:= 3;
signal s_treshold: integer:= 300;
signal s_normval: integer:= 4;


--- Setting Configurations for Kernel Operation, see package file


signal s_coeff_one: VEC_COEFF;
signal s_coeff_two: VEC_COEFF;
--signal s_coeffint_one: VEC_KERINT:=(0,0,0,0,0,
--                                    0,1,2,1,0,
--                                    0,2,4,2,0,
--                                    0,1,2,1,0,
--                                    0,0,0,0,0);
signal s_coeffint_one: VEC_KERINT:=(0,0,0,0,0,
                                    0,0,0,0,0,
                                    0,0,1,0,0,
                                    0,0,0,0,0,
                                    0,0,0,0,0);
--signal s_coeffint_one: VEC_KERINT:=(0,0,0,0,0,
--                                    0,1,0,-1,0,
--        :                            0,2,0,-2,0,
--                                    0,1,0,-1,0,
--                                    0,0,0,0,0);

signal s_coeffint_two: VEC_KERINT:=(0,0,0,0,0,
                                    0,1,2,1,0,
                                    0,0,0,0,0,
                                    0,-1,-2,-1,0,
                                    0,0,0,0,0);




signal s_red : std_logic_vector(c_pixw-1 downto 0):="00000001";
signal s_green : std_logic_vector(c_pixw-1 downto 0):="00000010";
signal s_blue : std_logic_vector(c_pixw-1 downto 0):="00000011";

signal s_red_out,s_green_out,s_blue_out : std_logic_vector(c_pixw-1 downto 0);
signal s_grayin,s_grayout : std_logic_vector(2*c_pixw-1 downto 0):=(others=>'0');



begin

a_reserved <=(others=>'0');
a_color <= '0';
a_border <= "01";
a_kernelop <= "000";
a_norm_tresh <= '0';

--s_red <= std_logic_vector(to_unsigned(1,c_pixw));
--s_green <= std_logic_vector(to_unsigned(2,c_pixw));
--s_blue <= std_logic_vector(to_unsigned(3,c_pixw));

s_grayin <= c_color_fill & s_red;

-- correct coeeff mapping

coeff_con:for i in 0 to c_vecsize-1 generate
  s_coeff_one(i) <= std_logic_vector(to_signed(s_coeffint_one(i),c_regw));
  s_coeff_two(i) <= std_logic_vector(to_signed(s_coeffint_two(i),c_regw));
end generate;



uut: entity work.axi_pe_0
port map (

-----------------------------------
-----------Slave AXI Lite Ports----
-----------------------------------
-- System Signals
  S_AXI_ACLK    => s_axi_aclk, --in
  S_AXI_ARESETN  => s_axi_aresetn, -- in

  -- Slave Interface Write Address Ports
  S_AXI_AWADDR   => s_axi_awaddr, -- in regw
  --    S_AXI_AWPROT   : in  std_logic_vector(3-1 downto 0); -- required??
  S_AXI_AWVALID  => s_axi_awvalid, -- in
  S_AXI_AWREADY  => s_axi_awready, -- out

    -- Slave Interface Write Data Ports
  S_AXI_WDATA  => s_axi_wdata, --in dw
  S_AXI_WSTRB  => s_axi_wstrb, -- in
  S_AXI_WVALID => s_axi_wvalid, --in 
  S_AXI_WREADY => s_axi_wready, -- out

    -- Slave Interface Write Response Ports
  S_AXI_BRESP  => s_axi_bresp, -- out 2 bit
  S_AXI_BVALID => s_axi_bvalid, -- out
  S_AXI_BREADY => s_axi_bready, -- in

  -- Slave Interface Read Address Ports
  S_AXI_ARADDR  => s_axi_araddr, -- in regw
  --    S_AXI_ARPROT   : in  std_logic_vector(3-1 downto 0); -- required???
  S_AXI_ARVALID => s_axi_arvalid, -- in 
  S_AXI_ARREADY => s_axi_arready, -- out

  -- Slave Interface Read Data Ports
  S_AXI_RDATA => s_axi_rdata, -- out dw
  S_AXI_RRESP => s_axi_rresp, -- out 2 bit
  S_AXI_RVALID => s_axi_rvalid, -- out
  S_AXI_RREADY => s_axi_rready, -- in
  ---------------------------------
  ----- Slave AXI Stream Ports-----
  ---------------------------------
  S_AXIS_ACLK => s_axis_aclk, --in
  S_AXIS_ARESETN => s_axis_aresetn, --in
  S_AXIS_TVALID => s_axis_tvalid, -- in
  S_AXIS_TDATA  => s_axis_tdata, -- in dw
  S_AXIS_TKEEP  => s_axis_tkeep, -- in dw/8
  S_AXIS_TLAST  => s_axis_tlast, -- in
  S_AXIS_TREADY => s_axis_tready, -- out

  ---------------------------------
  ----- Master AXI Stream Ports----
  ---------------------------------
  M_AXIS_ACLK => m_axis_aclk, --in
  M_AXIS_ARESETN => m_axis_aresetn, -- in
  M_AXIS_TVALID => m_axis_tvalid, -- out
  M_AXIS_TDATA  => m_axis_tdata,  -- out dw
  M_AXIS_TKEEP  => m_axis_tkeep, -- out dw/8
  M_AXIS_TLAST  => m_axis_tlast, -- out
  M_AXIS_TREADY => m_axis_tready, -- in
  ---------------------------------
  ------------PE Ports ------------
  ---------------------------------
  --pe_clk => pe_clk, --in
  en  => en, --in
  rst_n => rst_n, --in
  start_read => start_read --in
);


pixel_to_axis_conv: entity work.pixel_to_axis
port map (
   --  pixel stream side
  rin => s_red,
  gin => s_green,
  bin => s_blue,
	nd => nd,
	gray => a_color,
	grayin => s_grayin,    
  ----- Master AXI Stream Ports----
  M_AXIS_ACLK => s_axis_aclk,
  M_AXIS_ARESETN => s_axis_aresetn,
  M_AXIS_TVALID => s_axis_tvalid,
  M_AXIS_TDATA  => s_axis_tdata,
  M_AXIS_TREADY => s_axis_tready
);

axis_to_pixel_conv: entity work.axis_to_pixel
port map (
   --  pixel stream side
  rout => s_red_out,
  gout => s_green_out,
  bout => s_blue_out,
	valid => valid_out,
	gray => a_color,
	grayout => s_grayout,    
  ----- Master AXI Stream Ports----
  S_AXIS_ACLK => m_axis_aclk,
  S_AXIS_ARESETN => m_axis_aresetn,
  S_AXIS_TVALID => m_axis_tvalid,
  S_AXIS_TDATA  => m_axis_tdata,
  S_AXIS_TREADY => m_axis_tready,
  S_AXIS_TLAST => m_axis_tlast
);


-- clock definitions

iclk_process: process
begin
  iclk <= '0';
  wait for iclk_period/2;
  iclk <= '1';
  wait for iclk_period/2;
end process;

oclk_process: process
begin
  oclk <= '0';
  wait for oclk_period/2;
  oclk <= '1';
  wait for oclk_period/2;
end process;

cclk_process: process
begin
  cclk <= '0';
  wait for cclk_period/2;
  cclk <= '1';
  wait for cclk_period/2;
end process;


conf_proc: process
begin
---------------------------------------------
-- initialize phase for all input signals----
---------------------------------------------

-- PE signals --
start_read <='0';
en <= '1';

-- AXI lite slave signals --

-- write side --
s_axi_awaddr <= (others=>'0');
s_axi_awvalid <= '0';
s_axi_wvalid <= '0';
s_axi_wdata <= (others=>'0');
s_axi_wstrb <= (others=>'1');

s_axi_bresp <= "00";
s_axi_bready <= '0';

-- read side should not be touched !!
s_axi_araddr <= (others=>'0');
s_axi_arvalid <= '0';
s_axi_rready <= '0';
s_axi_rdata <= (others=>'0');

-- setting resets
m_axis_aresetn <= '0';
s_axis_aresetn <= '0';
s_axi_aresetn <= '0';
rst_n <= '1';
wait for 2*iclk_period;
--en <= '2';
rst_n <= '0';
wait for 8*iclk_period;
m_axis_aresetn <= '1';
s_axis_aresetn <= '1';
s_axi_aresetn <= '1';
rst_n <= '1';
wait for iclk_period;

--------------------------
-- Configuration Phase ---
--------------------------

s_axi_awvalid <='1';
s_axi_wvalid <='1';

s_axi_wdata <= std_logic_vector(to_unsigned(s_imagewidth,s_axi_wdata'length)); 
s_axi_awaddr <= std_logic_vector(to_unsigned(0,s_axi_awaddr'length)); -- set address
wait for cclk_period;
s_axi_bready <='1';
wait for cclk_period;
s_axi_wdata <= std_logic_vector(to_unsigned(s_imageheight,s_axi_wdata'length)); 
s_axi_awaddr <= std_logic_vector(to_unsigned(4,s_axi_awaddr'length)); -- set address
wait for cclk_period;
s_axi_bready <='1';
wait for cclk_period;
s_axi_wdata <= std_logic_vector(to_unsigned(s_numpix,s_axi_wdata'length)); 
s_axi_awaddr <= std_logic_vector(to_unsigned(8,s_axi_awaddr'length)); -- set address
wait for cclk_period;
s_axi_bready <='1';
wait for cclk_period;
s_axi_wdata <= std_logic_vector(to_unsigned(s_windowwidth,s_axi_wdata'length)); 
s_axi_awaddr <= std_logic_vector(to_unsigned(12,s_axi_awaddr'length)); -- set address
wait for cclk_period;
s_axi_bready <='1';
wait for cclk_period;
s_axi_wdata <= std_logic_vector(to_unsigned(s_windowheight,s_axi_wdata'length)); 
s_axi_awaddr <= std_logic_vector(to_unsigned(16,s_axi_awaddr'length)); -- set address
wait for cclk_period;
s_axi_bready <='1';
wait for cclk_period;
s_axi_wdata <= s_operation;
s_axi_awaddr <= std_logic_vector(to_unsigned(20,s_axi_awaddr'length)); -- set address
wait for cclk_period;
s_axi_bready <='1';
wait for cclk_period;
s_axi_wdata <= std_logic_vector(to_unsigned(s_normval,s_axi_wdata'length)); 
s_axi_awaddr <= std_logic_vector(to_unsigned(24,s_axi_awaddr'length)); -- set address
wait for cclk_period;
s_axi_bready <='1';
wait for cclk_period;
s_axi_wdata <= std_logic_vector(to_unsigned(s_treshold,s_axi_wdata'length)); 
s_axi_awaddr <= std_logic_vector(to_unsigned(28,s_axi_awaddr'length)); -- set address
wait for cclk_period;
s_axi_bready <='1';
wait for cclk_period;


-- set coeffs one
for i in 0 to c_vecsize-1 loop
  s_axi_wdata <= s_coeff_one(i);
  s_axi_awaddr <= std_logic_vector(to_unsigned(c_base_coeff_one*4+(i*4),s_axi_awaddr'length)); -- set address
  wait for cclk_period;
  s_axi_bready <='1';
  wait for cclk_period;
end loop;

-- set coeffs two
for i in 0 to c_vecsize-1 loop
  s_axi_wdata <= s_coeff_two(i);
  s_axi_awaddr <= std_logic_vector(to_unsigned(c_base_coeff_two*4+(i*4),s_axi_awaddr'length)); -- set address
  wait for cclk_period;
  s_axi_bready <='1';
  wait for cclk_period;
end loop;

s_axi_awvalid <='0';
s_axi_wvalid <='0';
wait for cclk_period;

-- End configuration Phase --

-- Start processing
start_read <='1';
nd <='1';
wait for iclk_period;

start_read <='0';
for i in 0 to 200 loop
  if (i mod 2= 0) then
    nd <='0';
	else
		nd <='1';
	end if;
wait for iclk_period;
end loop;
nd <='1';

wait;
end process;



stream_proc: process
begin

-- AXI stream slave signals --

s_axis_tkeep <= (others=>'1');
s_axis_tlast <= '0';

wait until start_read='1'and iclk'event and iclk ='1';
--m_axis_tready <= '1';
s_color_cnt <= (others=>'0');
--s_axis_tvalid <='1';
loop
  wait until iclk'event and iclk ='1';
    if(nd='1') then
      s_green <= std_logic_vector(unsigned(s_green)+1);
--      s_red <= std_logic_vector(unsigned(s_red)+1);
	  end if;
	--	else
  --    s_color_cnt <= s_color_cnt+1;
  --  end if;
end loop;
end process;

--s_axis_tdata <= s_color;


--color_pattern: process(s_color_cnt)
--begin
--  if (s_color_cnt="00") then
--    s_color <= s_red & s_blue & s_green & s_red;
--      s_color <= s_green & s_red & s_red & s_red; -- pixel test
--  elsif(s_color_cnt="01") then
--	  s_color <= s_green & s_red & s_blue & s_green;
--      s_color <= s_blue & s_blue & s_green & s_green; -- pixel test
--  elsif(s_color_cnt="10") then
--    s_color <= s_blue & s_green & s_red & s_blue;
--      s_color <= s_red & s_red & s_red & s_blue; -- pixel test
--  end if;
--end process;

-- counter for pixel increase

--pixel_cnt: process(iclk)
--begin
--  if(iclk'event and iclk='1') then
--    if s_color_cnt="10" then
--			s_red <= std_logic_vector(unsigned(s_red)+1);
--			s_green <= std_logic_vector(unsigned(s_green)+1);
--			s_blue <= std_logic_vector(unsigned(s_blue)+1);
--		else
--			s_red <=s_red;
--			s_green <= s_green;
--			s_blue <= s_blue;
--		end if;
--	end if;
--end process;


-- signals for debug

s_byte_four <= M_AXIS_TDATA(31 downto 24);
s_byte_three <= M_AXIS_TDATA(23 downto 16);
s_byte_two <= M_AXIS_TDATA(15 downto 8);
s_byte_one <= M_AXIS_TDATA(7 downto 0);


end behavior;
