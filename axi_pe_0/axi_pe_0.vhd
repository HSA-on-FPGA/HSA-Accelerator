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
use work.pkg_config.all;
use work.pkg_functions.all;

entity axi_pe_0 is
  generic (
    -- Slave AXI Lite configuration
    C_S_AXI_ADDR_WIDTH   : integer := 32; 
    C_S_AXI_DATA_WIDTH   : integer := 32;
    C_BASEADDR           : std_logic_vector:= X"00000000"; 
    C_HIGHADDR           : std_logic_vector:= X"000000FF"; 
    -- Master AXI Stream configuration
    C_M_AXIS_TDATA_WIDTH : integer := 32;
    -- Slave AXI Stream configuration
    C_S_AXIS_TDATA_WIDTH : integer := 32;
    c_dev_ultra : boolean:= false
    );
  port(
    -----------------------------------
    -----------Slave AXI Lite Ports----
    -----------------------------------
    -- System Signals
    S_AXI_ACLK    : in std_logic;
    S_AXI_ARESETN : in std_logic;

    -- Slave Interface Write Address Ports
    S_AXI_AWADDR   : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
--    S_AXI_AWPROT   : in  std_logic_vector(3-1 downto 0); -- required??
    S_AXI_AWVALID  : in  std_logic;
    S_AXI_AWREADY  : out std_logic;

    -- Slave Interface Write Data Ports
    S_AXI_WDATA  : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    S_AXI_WSTRB  : in  std_logic_vector(C_S_AXI_DATA_WIDTH/8-1 downto 0);
    S_AXI_WVALID : in  std_logic;
    S_AXI_WREADY : out std_logic;

    -- Slave Interface Write Response Ports
    S_AXI_BRESP  : out std_logic_vector(1 downto 0);
    S_AXI_BVALID : out std_logic;
    S_AXI_BREADY : in  std_logic;

    -- Slave Interface Read Address Ports
    S_AXI_ARADDR   : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
--    S_AXI_ARPROT   : in  std_logic_vector(3-1 downto 0); -- required???
    S_AXI_ARVALID  : in  std_logic;
    S_AXI_ARREADY  : out std_logic;

    -- Slave Interface Read Data Ports
    S_AXI_RDATA  : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    S_AXI_RRESP  : out std_logic_vector(1 downto 0);
    S_AXI_RVALID : out std_logic;
    S_AXI_RREADY : in  std_logic;
    ---------------------------------
    ----- Slave AXI Stream Ports-----
    ---------------------------------
    S_AXIS_ACLK : in std_logic;
    S_AXIS_ARESETN  : in std_logic;
    S_AXIS_TVALID : in std_logic;
    S_AXIS_TDATA  : in std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
    S_AXIS_TKEEP  : in std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
    S_AXIS_TLAST  : in std_logic;
    S_AXIS_TREADY : out std_logic;

    ---------------------------------
    ----- Master AXI Stream Ports----
    ---------------------------------
    M_AXIS_ACLK : in std_logic;
    M_AXIS_ARESETN  : in std_logic;
    M_AXIS_TVALID : out std_logic;
    M_AXIS_TDATA  : out std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
    M_AXIS_TKEEP  : out std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0);
    M_AXIS_TLAST  : out std_logic;
    M_AXIS_TREADY : in std_logic;

    ---------------------------------
    ----- PE Ports-------------------
    ---------------------------------
--    pe_clk : in std_logic;
    en    : in std_logic;
    rst_n : in std_logic;
    start_read : in std_logic
    

    );

end axi_pe_0;

architecture behavior of axi_pe_0 is

------------ Constants from Package ----------

constant c_colw : integer:= c_dw_pix_max_0;
constant c_grayw : integer:= c_dw_pix_max_gray_0;
constant c_numcol: integer:= c_num_col_max_0;
constant c_par : integer:= c_par_0;
constant c_pew : integer:= (c_numcol-1)*c_colw+c_grayw; 

constant c_pack_size: integer:= c_pack_size_0; -- TODO see if correct
constant c_op_addr: integer:= c_op_addr_0; 
constant c_np_addr: integer:= c_numpix_addr_0; 
--constant c_dev_ultra: boolean:= c_dev_ultra_0; 
constant c_rst_interval: integer:= c_rst_interval_0; 


----------- Replacements of AXI constants , shorter for useing -------

constant c_saxisw : integer:= C_S_AXIS_TDATA_WIDTH;
constant c_maxisw : integer:= C_M_AXIS_TDATA_WIDTH;
constant c_saxiw : integer:= C_S_AXI_DATA_WIDTH;



----------- AXI Clock Signals -----------

signal axi_slave_clk, axi_master_clk, pe_clk: std_logic;


-----------Slave AXI Lite Signals-----------

constant c_wstrb_size: integer := C_S_AXI_DATA_WIDTH/8;

type write_state_type is (WAITING, WRITE_SUCCESS, WRITE_ERROR);
signal WRITE_STATE: write_state_type;

signal S_AXI_AWADDR_CUT: std_logic_vector(8 downto 0);

-----------Accelerator PE Signals-----------

signal s_conf_we, s_accel_nd,s_accel_valid,s_accel_ready, s_accel_ready_in,s_accel_last, s_rst_n: std_logic;
signal s_reg_addr: std_logic_vector(f_log2(c_saxiw)-1 downto 0); 
signal s_dreg, s_op_reg,s_numpix_reg : std_logic_vector(c_saxiw-1 downto 0);
signal s_accel_di, s_accel_do : VEC_DPEPAR_0;
signal s_accel_di_color, s_accel_do_color : std_logic_vector(c_par*c_colw*c_numcol-1 downto 0);
signal s_accel_di_gray, s_accel_do_gray : std_logic_vector(c_par*c_grayw-1 downto 0);

----------- AXI Interface Signals (Slave + Master + Conversion + FIFO)----

signal s_rst_init, s_tlast_flag : boolean;
signal s_fifo_out_we, s_fifo_out_re, s_fifo_out_empty, s_fifo_out_full, s_fifo_is_last: std_logic;
signal s_fifo_in_we, s_fifo_in_re, s_fifo_in_empty, s_fifo_in_full, s_control_in_valid,s_control_in_req: std_logic;
signal s_fifo_in_di,s_fifo_in_do,s_control_in_data : std_logic_vector(c_saxisw-1 downto 0); 
signal s_fifo_out_do,s_fifo_out_di : std_logic_vector(c_maxisw-1 downto 0); 
signal s_np_cnt : unsigned((c_np_addr_0+2)-1 downto 0);
signal s_rst_cnt: unsigned(f_log2(c_rst_interval)-1 downto 0);


----------- Alias for Mapping parts of Operation Register ----------

-- see package file for details

alias a_color_mode : std_logic is s_op_reg(6); -- 0 for color, 1 for gray
    
begin

--- Connecting Clock Signals -----

axi_slave_clk <= S_AXIS_ACLK;
axi_master_clk <= M_AXIS_ACLK;
pe_clk <= S_AXI_ACLK;
s_rst_n <= rst_n;


------------------------------------------
-----------Slave AXI Lite Architecture----
------------------------------------------

S_AXI_AWADDR_CUT <= S_AXI_AWADDR(10 downto 2);

-- always read x"00000000" - device is write only
S_AXI_ARREADY <= '1';
S_AXI_RDATA   <= (others => '0');
S_AXI_RRESP   <= "00";
S_AXI_RVALID  <= '1';


-- axi write outputs
S_AXI_AWREADY <= '0' when (WRITE_STATE = WAITING) else '1';
S_AXI_WREADY <= '0' when (WRITE_STATE = WAITING) else '1';
S_AXI_BVALID <= '0' when (WRITE_STATE = WAITING) else '1';
S_AXI_BRESP <= "11" when (WRITE_STATE = WRITE_ERROR) else "00";

axi_write_config:process(S_AXI_ACLK)
begin
  if (S_AXI_ACLK'event and S_AXI_ACLK = '1') then
    if (S_AXI_ARESETN = '0') then
      WRITE_STATE <= WAITING;
      s_conf_we <= '0';
      s_reg_addr <= (others => '0');
      s_dreg <= (others => '0');
      s_numpix_reg <= (others => '0');
      s_op_reg <= (others => '0');
    else
      s_conf_we <= '0';
      s_reg_addr <= (others => '0');
      s_dreg <= (others => '0');
      case WRITE_STATE is
          when WAITING =>
            if(S_AXI_AWVALID = '1' and S_AXI_WVALID = '1') then
                        -- failure
              if (not S_AXI_WSTRB = "1111") then
                WRITE_STATE <= WRITE_ERROR;
              else
                if(to_integer(unsigned(S_AXI_AWADDR_CUT)) = c_op_addr) then
                  s_op_reg <= S_AXI_WDATA;
                elsif(to_integer(unsigned(S_AXI_AWADDR_CUT)) = c_np_addr) then
                  s_numpix_reg <= S_AXI_WDATA;
                end if;
                s_conf_we <= '1';
                s_reg_addr<= std_logic_vector(resize(unsigned(S_AXI_AWADDR_CUT),s_reg_addr'length));
                s_dreg <= S_AXI_WDATA;
                WRITE_STATE <= WRITE_SUCCESS; 
              end if;
            end if;
          when WRITE_SUCCESS =>
            if(S_AXI_BREADY = '1') then
              WRITE_STATE <= WAITING;
            end if;
          when WRITE_ERROR =>
            if(S_AXI_BREADY = '1') then
              WRITE_STATE <= WAITING;
            end if;
          end case;
      end if;
  end if;
end process;

-------------------------------------------------------------------------------
----------- Slave Axi Stream + Fifo to Pixel Conversion -----------------------
-------------------------------------------------------------------------------


-- AXI slave to FIFO

axi_slave: entity work.axi_stream_to_fifo
generic map(
  AXIS_DATA_WIDTH => c_saxisw
)
port map (
  clk => axi_slave_clk,
  en => en,
  rst_n => S_AXIS_ARESETN,
  axi_tdata  => S_AXIS_TDATA,
  axi_tvalid => S_AXIS_TVALID,
  axi_tready => S_AXIS_TREADY, 
  fifo_data_in => s_fifo_in_di,
  fifo_write_enable => s_fifo_in_we,
  fifo_full => s_fifo_in_full 
);

-- FIFO on Data in --

fifo_in: entity work.fifo_wrapper
generic map(
  --g_device_ultra => c_dev_ultra,
  g_device_ultra => true,
  g_datawidth => c_saxisw
)
port map (
  rst_n => s_rst_n,
 -- write channel 
  wclk  => axi_slave_clk,
  we  => s_fifo_in_we,
  full => open,
	almostfull => s_fifo_in_full,
  di =>  s_fifo_in_di,
-- read channel
  rclk => pe_clk,
  re => s_fifo_in_re,
  empty => s_fifo_in_empty,
  almostempty => open,
  do => s_fifo_in_do
);

-- FIFO to Pixel Conversion


fifo_read_contoller: entity work.fifo_read_control
generic map(
  DATA_WIDTH => c_saxisw
)
port map(
  clk => pe_clk,
  rst_n => s_rst_n,
  -- Fifo side
  fifo_empty => s_fifo_in_empty,
  fifo_data_out => s_fifo_in_do,
  fifo_read_enable => s_fifo_in_re,
  -- control read side
  control_data_out => s_control_in_data,
  control_data_valid => s_control_in_valid,
  control_data_req => s_control_in_req
);




fifo_to_pixel_conv: entity work.fifo_to_pixel_gen
--fifo_to_pixel_conv: entity work.fifo_to_pixel
generic map(
  DATA_IN_WIDTH => c_saxisw,
  COLOR_WIDTH => c_colw,
  GRAY_WIDTH => c_grayw,
  COL_NUM => c_numcol,
  PAR => c_par
)
port map(
  clk => pe_clk,
  rst_n => s_rst_n,
  en => en, 
  gray => a_color_mode, 
  -- control side
  control_data_out => s_control_in_data,
  control_data_valid => s_control_in_valid,
  control_data_req => s_control_in_req,
  -- Fifo read side
  do_gray => s_accel_di_gray, --TODO fix name
  do_color => s_accel_di_color, -- TODO fix name
  valid => s_accel_nd,
  ready => s_accel_ready_in
);


-- mux for multi color processing, test if works with grayw=colw
gen_col_mux: if c_numcol>1 and c_grayw >= c_colw generate
  gen_par_mux: for i in 0 to c_par-1 generate 
    accel_in_col_mux: process(a_color_mode,s_accel_di_gray,s_accel_di_color)
    begin
      if(a_color_mode= '1') then
        s_accel_di(c_par-1-i)(c_grayw-1 downto 0) <= s_accel_di_gray((i+1)*c_grayw-1 downto i*c_grayw);
        s_accel_di(c_par-1-i)(c_pew-1 downto c_grayw) <= (others=>'0'); 
      else
        s_accel_di(c_par-1-i)(c_pew-1 downto c_grayw) <= s_accel_di_color((i+1)*c_numcol*c_colw-1 downto i*c_numcol*c_colw+c_colw);
        s_accel_di(c_par-1-i)(c_colw-1 downto 0) <= s_accel_di_color(i*c_numcol*c_colw+c_colw-1 downto i*c_numcol*c_colw);
        if c_grayw > c_colw then
          s_accel_di(c_par-1-i)(c_grayw-1 downto c_colw) <= (others=>'0');
        end if; 
      end if;
    end process;    
  end generate;
end generate;

-- same multi col mux but widthout filler in color in case c_grayw = c_colw

--gen_col_mux_less: if c_numcol>1 and c_grayw = c_colw generate
--  par_gen_mux_less: for i in 0 to c_par-1 generate 
--    accel_in_col_mux_less: process(a_color_mode,s_accel_di_gray,s_accel_di_color)
--    begin
--      if(a_color_mode= '1') then
--        s_accel_di(i)(c_grayw-1 downto 0) <= s_accel_di_gray((i+1)*c_grayw-1 downto i*c_grayw);
--        s_accel_di(i)(c_pew-1 downto c_grayw) <= (others=>'0'); 
--      else
--        s_accel_di(i)(c_pew-1 downto c_grayw) <= s_accel_di_color((i+1)*c_numcol*c_colw-1 downto i*c_numcol*c_colw+c_colw);
--        s_accel_di(i)(c_colw-1 downto 0) <= s_accel_di_color(i*c_numcol*c_colw+c_colw-1 downto i*c_numcol*c_colw);
--      end if;
--    end process;    
--  end generate;
--end generate;

-- in case c_numcol=1 no mux needed
gen_col_mux_num_one: if c_numcol=1 and c_grayw <= c_colw generate
  gen_par_mux_num_one: for i in 0 to c_par-1 generate 
    s_accel_di(i)(c_grayw-1 downto 0) <= s_accel_di_gray((i+1)*c_grayw-1 downto i*c_grayw);
  end generate;
end generate;


------------------------------------------
----------- Accelerator Architecture------
------------------------------------------

accelerator: entity work.accelerator_pe_0
generic map(
  REG_WIDTH => c_saxiw
)
port map (
  clk => pe_clk,
  rst_n => s_rst_n,
  en  => en,  
  valid_in  => s_accel_nd,
	ready_in => s_accel_ready_in, 
  start => start_read, 
  valid_out => s_accel_valid,
	ready_out => s_accel_ready,
  last => s_accel_last, -- for debug 
  init => s_conf_we,
  dreg => s_dreg,
  reg_addr => s_reg_addr, 
  di => s_accel_di,
  do => s_accel_do
);

--s_accel_valid <= s_accel_nd;
--s_accel_ready_in <= s_accel_ready;
--s_accel_do <= s_accel_di;


-------------------------------------------------------------------------------
---------- Pixel to Fifo Conversion + Master AXI Stream Architecture  ---------
-------------------------------------------------------------------------------

-- Signal conversion for accel_do mapping

gen_par_gray: for i in 0 to c_par-1 generate
  s_accel_do_gray((i+1)*c_grayw-1 downto i*c_grayw)<=s_accel_do(c_par-1-i)(c_grayw-1 downto 0);
end generate;

gen_col_sig: if c_numcol>1 generate
  gen_par_sig: for i in 0 to c_par-1 generate
    s_accel_do_color((i+1)*c_numcol*c_colw-1 downto i*c_numcol*c_colw+c_colw) <= s_accel_do(c_par-1-i)(c_pew-1 downto c_grayw);
    s_accel_do_color(i*c_numcol*c_colw+c_colw-1 downto i*c_numcol*c_colw)<=s_accel_do(c_par-1-i)(c_colw-1 downto 0);
  end generate;
end generate;

-- convert pixel to axi 32 bit data format

--pixel_to_fifo_conv: entity work.pixel_to_fifo
pixel_to_fifo_conv: entity work.pixel_to_fifo_gen
generic map(
  DATA_OUT_WIDTH => c_maxisw,
  COLOR_WIDTH => c_colw,
  GRAY_WIDTH => c_grayw,
  COL_NUM => c_numcol,
  PAR => c_par
)
port map(
  clk => pe_clk,
  rst_n => s_rst_n,
  en => en, 
  gray => a_color_mode,
  -- accelerator Side
  accel_do_gray => s_accel_do_gray,
  accel_do_color => s_accel_do_color,
  accel_valid => s_accel_valid, 
  accel_ready => s_accel_ready, 
  -- Fifo read side
  fifo_full => s_fifo_out_full,
  fifo_data_in => s_fifo_out_di,
  fifo_write_enable => s_fifo_out_we
);
  
-- fifo for write out

fifo_out: entity work.fifo_wrapper
generic map(
  --g_device_ultra => c_dev_ultra,
  g_device_ultra => true,
  g_datawidth => c_maxisw
)
port map (
  rst_n => s_rst_n, 
 -- write channel  
  wclk  => pe_clk,
  we  => s_fifo_out_we,
  full => open,
	almostfull => s_fifo_out_full,
  di =>  s_fifo_out_di,
-- read channel
  rclk => axi_master_clk,
  re => s_fifo_out_re,
  empty => s_fifo_out_empty,
  almostempty => open,
  do => s_fifo_out_do
);

-- genrate fifo_is last signal for last transfer of image

write_pix_cnt:process(axi_master_clk)
variable v_colorbytes : integer;
variable v_np_cnt_next : unsigned(s_np_cnt'length - 1 downto 0);
begin
  if axi_master_clk'event and axi_master_clk='1' then
	if s_rst_n='0' then
      s_np_cnt <= (others=>'0');
      s_fifo_is_last <='0';
      s_tlast_flag <= false;
    else
      if (a_color_mode = '1') then
          v_colorbytes := 2; -- TODO beautify
      else
          v_colorbytes := 3;
      end if;

      v_np_cnt_next := s_np_cnt;
      
      if s_fifo_out_re='1' then
        v_np_cnt_next := v_np_cnt_next+4;
      end if;

      if v_np_cnt_next < unsigned(s_numpix_reg) * to_unsigned(v_colorbytes, s_numpix_reg'length) then
        s_fifo_is_last <='0';
        s_tlast_flag <= false;
      elsif(s_tlast_flag = false and to_integer(unsigned(s_numpix_reg)) > 0) then
        s_fifo_is_last <='1'; 
        s_tlast_flag <= true;
      else
        s_fifo_is_last <='0';
      end if;
      
      s_np_cnt <= v_np_cnt_next;

    end if;
  end if;
end process;

--reset_proc: process(axi_master_clk)
--variable v_rst_init: boolean:= false;
--begin

--  if axi_master_clk'event and axi_master_clk='1' then
--	  if rst_n='0' or (s_fifo_is_last='1'and s_tlast_flag= true)  then
--      v_rst_init:= true;
--   else 
--      v_rst_init:= s_rst_init;
--    end if;

--    if (v_rst_init= true) then
--      if(s_rst_cnt < c_rst_interval) then
--        s_rst_cnt <= s_rst_cnt+1;
--        s_rst_n <= '0';
--      else
--        v_rst_init := false;
--        s_rst_cnt <= (others=>'0');
--        s_rst_n <= '1';
--      end if;
--    else
--      s_rst_n <= '1';
--    end if;
--  end if;

--  s_rst_init <= v_rst_init;
--end process;



-- read out from fifo an write to axi Master

axi_master: entity work.fifo_to_axi_stream
generic map(
  AXI_PACKAGE_SIZE => c_pack_size,
	AXIS_DATA_WIDTH => c_maxisw
)
port map (
  clk => axi_master_clk,
  reset => M_AXIS_ARESETN,
  -- fifo read side
  fifo_empty => s_fifo_out_empty,
  fifo_is_last => s_fifo_is_last, -- for last transmit
  fifo_read_enable => s_fifo_out_re,
  fifo_data_out => s_fifo_out_do,
  -- axi Master side
  axi_tdata => M_AXIS_TDATA,
  axi_tvalid => M_AXIS_TVALID,
  axi_tlast => M_AXIS_TLAST,
  axi_tready => M_AXIS_TREADY
);

M_AXIS_TKEEP <= (others => '1');

end behavior;




