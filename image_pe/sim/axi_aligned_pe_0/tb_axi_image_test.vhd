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

entity tb_axi_image_test is
end tb_axi_image_test;

architecture behavior of tb_axi_image_test is

constant c_vecsize : integer:= c_ww_max_0 * c_wh_max_0;

constant c_par : integer:= c_par_0;
constant c_dw : integer:= 32;
constant c_dw_data : integer:= 32*c_par_0;
constant c_pixw: integer:= c_dw_pix_max_0;
constant c_pixw_gray: integer:= c_dw_pix_max_gray_0;
constant c_regw : integer:= 32;

constant c_base_coeff_one : integer:=c_num_im_para_0;
constant c_base_coeff_two : integer:=c_num_im_para_0+c_vecsize;

type VEC_KERINT is array(0 to c_vecsize-1) of integer;
type VEC_COEFF is array(0 to c_vecsize-1) of std_logic_vector(c_regw-1 downto 0);

signal en,nd,start_read,pixel_read, pixel_valid, pixel_rst_n : std_logic;
-- signal for input
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
--signal s_axis_aclk, s_axis_aresetn : std_logic;
signal s_axis_tvalid, s_axis_tready, s_axis_tlast : std_logic;
signal s_axis_tdata : std_logic_vector(c_dw_data-1 downto 0);
signal s_axis_tkeep : std_logic_vector(c_dw_data/8-1 downto 0);

------ axis master  -------
--signal m_axis_aclk, m_axis_aresetn : std_logic;
signal m_axis_tvalid, m_axis_tready, m_axis_tlast : std_logic;
signal m_axis_tdata : std_logic_vector(c_dw_data-1 downto 0);
signal m_axis_tkeep : std_logic_vector(c_dw_data/8-1 downto 0);




----- Signals for Operation

signal s_operation: std_logic_vector(c_regw-1 downto 0);

alias a_reserved : std_logic_vector(24 downto 0) is s_operation(31 downto 7);
alias a_color : std_logic is s_operation(6); -- for color mode
alias a_boarder : std_logic_vector(1 downto 0) is s_operation(5 downto 4); -- off for now, for future use
alias a_kernelop : std_logic_vector(2 downto 0) is s_operation(3 downto 1); -- set to single conv for testing
alias a_norm_tresh : std_logic is s_operation(0); -- treshold off

-- Alias for different clk --

alias clk : std_logic is s_axi_aclk;
alias rst_n : std_logic is s_axi_aresetn;



constant clk_period : time:= 3 ns;


--- Setting Configurations for Image

constant c_imagewidth: integer:= 128;
constant c_imageheight: integer:= 128;
--constant c_imagewidth: integer:= 20;
--constant c_imageheight: integer:= 20;
constant c_numpix: integer:= c_imagewidth*c_imageheight; 
constant c_windowwidth: integer:= 3;
constant c_windowheight: integer:= 3;
constant c_treshold: integer:= 300;
constant c_normval: integer:= 4;



--- Setting Configurations for Kernel Operation, see package file


signal s_coeff_one: VEC_COEFF;
signal s_coeff_two: VEC_COEFF;
-- uncomment for gauss 5x5
--signal s_coeffint_one: VEC_KERINT:=(1,4,6,4,1,
--                                    4,16,24,16,4,
--                                    6,24,36,24,6,
--                                    4,16,24,16,4,
--                                    1,4,6,4,1);


signal s_coeffint_one: VEC_KERINT:=(0,0,0,0,0,
                                    0,1,2,1,0,
                                    0,2,4,2,0,
                                    0,1,2,1,0,
                                    0,0,0,0,0);
--signal s_coeffint_one: VEC_KERINT:=(0,0,0,0,0,
--                                    0,0,0,0,0,
--                                    0,0,1,0,0,
--                                    0,0,0,0,0,
--                                    0,0,0,0,0);
--signal s_coeffint_one: VEC_KERINT:=(0,0,0,0,0,
--                                    0,1,0,-1,0,
--                                    0,2,0,-2,0,
--                                    0,1,0,-1,0,
--                                    0,0,0,0,0);

signal s_coeffint_two: VEC_KERINT:=(0,0,0,0,0,
                                    0,1,2,1,0,
                                    0,0,0,0,0,
                                    0,-1,-2,-1,0,
                                    0,0,0,0,0);


signal s_red : std_logic_vector(c_par*c_pixw-1 downto 0);  --:="00000001";
signal s_green : std_logic_vector(c_par*c_pixw-1 downto 0);  --:="00000010";
signal s_blue : std_logic_vector(c_par*c_pixw-1 downto 0);  --:="00000011";
signal s_color, s_color_out: std_logic_vector(c_par*3*c_pixw-1 downto 0);

signal s_gray,s_gray_out : std_logic_vector(c_par*2*c_pixw-1 downto 0):=(others=>'0');

signal s_red_out,s_green_out,s_blue_out : std_logic_vector(c_par*c_pixw-1 downto 0);
signal s_valid_out : std_logic;



begin

a_reserved <=(others=>'0');
a_color <= '0';
a_boarder <= "01";
a_kernelop <= "000";
a_norm_tresh <= '1';

--s_red <= std_logic_vector(to_unsigned(1,c_pixw));
--s_green <= std_logic_vector(to_unsigned(2,c_pixw));
--s_blue <= std_logic_vector(to_unsigned(3,c_pixw));

-- correct coeeff mapping

coeff_con:for i in 0 to c_vecsize-1 generate
  s_coeff_one(i) <= std_logic_vector(to_signed(s_coeffint_one(i),c_regw));
  s_coeff_two(i) <= std_logic_vector(to_signed(s_coeffint_two(i),c_regw));
end generate;



uut: entity work.axi_aligned_pe_0
generic map(
  C_M_AXIS_TDATA_WIDTH => c_dw_data,
  C_S_AXIS_TDATA_WIDTH => c_dw_data
)
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
--  S_AXIS_ACLK => s_axis_aclk, --in
--  S_AXIS_ARESETN => s_axis_aresetn, --in
  S_AXIS_TVALID => s_axis_tvalid, -- in
  S_AXIS_TDATA  => s_axis_tdata, -- in dw
  S_AXIS_TKEEP  => s_axis_tkeep, -- in dw/8
  S_AXIS_TLAST  => s_axis_tlast, -- in
  S_AXIS_TREADY => s_axis_tready, -- out

  ---------------------------------
  ----- Master AXI Stream Ports----
  ---------------------------------
--  M_AXIS_ACLK => m_axis_aclk, --in
--  M_AXIS_ARESETN => m_axis_aresetn, -- in
  M_AXIS_TVALID => m_axis_tvalid, -- out
  M_AXIS_TDATA  => m_axis_tdata,  -- out dw
  M_AXIS_TKEEP  => m_axis_tkeep, -- out dw/8
  M_AXIS_TLAST  => m_axis_tlast, -- out
  M_AXIS_TREADY => m_axis_tready, -- in
  ---------------------------------
  ------------PE Ports ------------
  ---------------------------------
--  pe_clk => pe_clk, --in
  en  => en, --in
--  rst_n => rst_n, --in
  start_read => start_read --in
);


pixel_read <= pixel_valid and s_axis_tready;


--color_in_mux: process(a_color,s_red, s_blue, s_green, s_gray)
--begin
--  if a_color='0' then
--    s_axis_tdata <= std_logic_vector(resize(unsigned(s_color),s_axis_tdata'length));
--  else
--    s_axis_tdata <= std_logic_vector(resize(unsigned(s_gray),s_axis_tdata'length));
--  end if;
--end process;

pix_gen: entity work.pixel_gen
generic map(
  g_pixwidth => c_pixw,
  g_imagesize => c_numpix,
  g_par => c_par
)
port map(
  rclk => clk,
  wclk => clk,
  rst_n => pixel_rst_n,
  nd => nd,
  valid => s_valid_out,
  rin => s_red,
  gin => s_green,
  bin => s_blue,
  rout => s_red_out,
  gout => s_green_out,
  bout => s_blue_out,
  read_valid => pixel_valid
);


--s_axis_tvalid <= pixel_read;


s_color <= s_blue & s_green & s_red; -- TODO see if order correct
s_gray <= std_logic_vector(resize(unsigned(s_red),c_par*c_pixw_gray));

pixel_to_axi: entity work.pixel_to_axi
generic map(
  DATA_WIDTH => c_dw_data,
  GRAY_WIDTH => c_pixw_gray,
  COLOR_WIDTH => c_pixw,
  NUM_COL => 3, --fixme
  PAR => c_par
)
port map(
  clk => clk,
  rst_n => rst_n,
  gray => a_color,
  in_gray => s_gray,
  in_color => s_color,
  in_valid => pixel_read,
  in_ready => open,
  out_data => s_axis_tdata,
  out_valid=> s_axis_tvalid,
  out_ready=> s_axis_tready
);

axi_to_pix: entity work.axi_to_pixel
generic map(
  DATA_WIDTH => c_dw_data,
  GRAY_WIDTH => c_pixw_gray,
  COLOR_WIDTH => c_pixw,
  NUM_COL => 3, --fixme
  PAR => c_par
)
port map(
  clk => clk,
  rst_n => rst_n,
  gray => a_color,
  in_data => m_axis_tdata,
  in_valid => m_axis_tvalid,
  in_ready => m_axis_tready,
  out_gray => s_gray_out,
  out_color => s_color_out,
  out_valid=> s_valid_out,
  out_ready=> '1'
);

--s_gray_out <= m_axis_tdata(c_par*c_pixw_gray-1 downto 0);
--m_axis_tready <= '1';

color_mux: process(a_color,s_color_out, s_gray_out)
begin

  if(a_color='0') then
		s_red_out <= s_color_out(c_par*c_pixw-1 downto 0);
		s_green_out <= s_color_out(2*c_par*c_pixw-1 downto c_par*c_pixw);
		s_blue_out <= s_color_out(3*c_par*c_pixw-1 downto 2*c_par*c_pixw);
  else -- TODO change later to 16 bit output
    s_red_out <= std_logic_vector(resize(unsigned(s_gray_out),s_red_out'length));
    s_green_out <= std_logic_vector(resize(unsigned(s_gray_out),s_green_out'length));
    s_blue_out <= std_logic_vector(resize(unsigned(s_gray_out),s_blue_out'length));
  end if;
end process;


-- clock definitions

clk_process: process
begin
  clk <= '0';
  wait for clk_period/2;
  clk <= '1';
  wait for clk_period/2;
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
--s_axi_aresetn <= '0';
rst_n <= '1';
pixel_rst_n <= '1';
wait for clk_period;
--en <= '2';
rst_n <= '0'; 
pixel_rst_n <= '0';
wait for clk_period;
--s_axi_aresetn <= '1';
rst_n <= '1';
pixel_rst_n <= '1';

wait for 20*c_rst_interval_0*clk_period;
--------------------------
-- Configuration Phase ---
--------------------------

s_axi_awvalid <='1';
s_axi_wvalid <='1';
s_axi_bready <='1';

s_axi_wdata <= std_logic_vector(to_unsigned(c_imagewidth,s_axi_wdata'length)); 
s_axi_awaddr <= std_logic_vector(to_unsigned(0,s_axi_awaddr'length)); -- set address
wait for clk_period;
wait for clk_period;
s_axi_wdata <= std_logic_vector(to_unsigned(c_imageheight,s_axi_wdata'length)); 
s_axi_awaddr <= std_logic_vector(to_unsigned(4,s_axi_awaddr'length)); -- set address
wait for clk_period;
wait for clk_period;
s_axi_wdata <= std_logic_vector(to_unsigned(c_numpix,s_axi_wdata'length)); 
s_axi_awaddr <= std_logic_vector(to_unsigned(8,s_axi_awaddr'length)); -- set address
wait for clk_period;
wait for clk_period;
s_axi_wdata <= std_logic_vector(to_unsigned(c_windowwidth,s_axi_wdata'length)); 
s_axi_awaddr <= std_logic_vector(to_unsigned(12,s_axi_awaddr'length)); -- set address
wait for clk_period;
wait for clk_period;
s_axi_wdata <= std_logic_vector(to_unsigned(c_windowheight,s_axi_wdata'length)); 
s_axi_awaddr <= std_logic_vector(to_unsigned(16,s_axi_awaddr'length)); -- set address
wait for clk_period;
wait for clk_period;
s_axi_wdata <= s_operation;
s_axi_awaddr <= std_logic_vector(to_unsigned(20,s_axi_awaddr'length)); -- set address
wait for clk_period;
wait for clk_period;
s_axi_wdata <= std_logic_vector(to_unsigned(c_normval,s_axi_wdata'length)); 
s_axi_awaddr <= std_logic_vector(to_unsigned(24,s_axi_awaddr'length)); -- set address
wait for clk_period;
wait for clk_period;
s_axi_wdata <= std_logic_vector(to_unsigned(c_treshold,s_axi_wdata'length)); 
s_axi_awaddr <= std_logic_vector(to_unsigned(28,s_axi_awaddr'length)); -- set address
wait for clk_period;
wait for clk_period;

-- set coeffs one
for i in 0 to c_vecsize-1 loop
  s_axi_wdata <= s_coeff_one(i);
  s_axi_awaddr <= std_logic_vector(to_unsigned(c_base_coeff_one*4+(i*4),s_axi_awaddr'length)); -- set address
  wait for clk_period;
  wait for clk_period;
end loop;

-- set coeffs two
for i in 0 to c_vecsize-1 loop
  s_axi_wdata <= s_coeff_two(i);
  s_axi_awaddr <= std_logic_vector(to_unsigned(c_base_coeff_two*4+(i*4),s_axi_awaddr'length)); -- set address
  wait for clk_period;
  wait for clk_period;
end loop;

s_axi_awvalid <='0';
s_axi_wvalid <='0';
wait for clk_period;

-- End configuration Phase --

-- Start processing
start_read <='1';
wait for clk_period;

s_axis_tkeep <= (others=>'1');
s_axis_tlast <= '0';

wait for clk_period;

nd <='1';
--nd <='1';
start_read <='0';

-- for testing not consistent new data on axi uncomment the following lines

wait for 30*clk_period;
for i in 0 to 10000 loop
    if (i mod 3 = 0) then
    nd <= '0';
		 else
    nd <='1';
  end if;
  wait for 1*clk_period;
end loop;

nd <='1';
-- end of consistence testing

-- Wait for axi last

wait until m_axis_tlast='1';
wait for 30*clk_period;


pixel_rst_n<='0';
nd <='0';
wait for clk_period;
pixel_rst_n<='1';
wait for clk_period;
start_read <='1';
wait for clk_period;
start_read <='0';
nd <='1';

wait for 30*clk_period;
for i in 0 to 10000 loop
    if (i mod 3 = 0) then
    nd <= '0';
		 else
    nd <='1';
  end if;
  wait for 1*clk_period;
end loop;


wait;
end process;



s_byte_four <= M_AXIS_TDATA(31 downto 24);
s_byte_three <= M_AXIS_TDATA(23 downto 16);
s_byte_two <= M_AXIS_TDATA(15 downto 8);
s_byte_one <= M_AXIS_TDATA(7 downto 0);


end behavior;
