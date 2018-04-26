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
--use work.pkg_functions.all;
use work.pkg_config.all;

entity accelerator_pe_0 is
generic(
  REG_WIDTH : integer range 16 to 128:=32
);
port(
  clk   : in  std_logic;
  rst_n : in  std_logic;
  en    : in  std_logic; -- Global enable signal
  -- Control Line Infertace
  start : in  std_logic; -- New Data for valid input pixel
  valid_in    : in  std_logic; -- New Data for valid input pixel
  ready_in   : out  std_logic; -- read request from reader side
	ready_out : in std_logic;
  valid_out : out std_logic;  -- Output has valid information
  last  : out std_logic; -- Signals last Pixel tranfer
  
  -- Config interface, must be constant, should only be changed, if not in processing mode 
  init    : in std_logic;
  dreg    : in  std_logic_vector(REG_WIDTH-1 downto 0); -- instruction for kernel operation
  reg_addr: in  std_logic_vector(integer(CEIL(log2(real(c_num_reg_0))))-1 downto 0);

  -- Data Interace
  di : in VEC_DPEPAR_0;
  do : out VEC_DPEPAR_0

);
end accelerator_pe_0;

architecture behavior of accelerator_pe_0 is

constant c_dw_pe: integer:= c_dw_pe_0;
constant c_dw: integer:= c_dw_pix_max_0; 
constant c_dw_gray: integer:= c_dw_pix_max_gray_0; 

constant c_regw: integer:= REG_WIDTH;
constant c_cw: integer:= c_coeffw_0;
constant c_par: integer:= c_par_0;

constant c_en_border_handling: boolean:= c_en_border_handling_0;

constant c_iw: integer:= c_iw_max_0;
constant c_ih: integer:= c_ih_max_0;
constant c_np: integer:= c_np_max_0;
constant c_ww: integer:= c_ww_max_0;
constant c_wh: integer:= c_wh_max_0;





constant c_kinstrw: integer:= c_kinstrw_0;
constant c_num_kernel: integer:= c_num_kernel_0;
constant c_num_bmodes: integer:= c_num_bmodes_0;
constant c_bmodesw: integer:= integer(ceil(log2(real(c_num_bmodes))));
constant c_num_para: integer:= c_num_im_para_0;
constant c_num_reg: integer:= c_num_reg_0;

constant c_col: integer:= c_num_col_max_0; 
constant c_col_chan: integer:= c_num_col_chan_0;
constant c_num_colbits: integer:= c_col_chan*c_dw; 

constant c_buf_delay: integer:= (c_wh*c_ww)/2 + (c_wh/2*(c_iw-c_ww))/c_par + 1 ; --  Mask + Buffer + 1 TODO check for higher c_par
constant c_vecsize: integer:= c_ww*c_wh;

-- constant conversion to unsigend for better overview of buf_delay calculation 

constant cu_wh: unsigned:= to_unsigned(c_wh,c_buf_delay);
constant cu_ww: unsigned:= to_unsigned(c_ww,c_buf_delay);
constant cu_par: unsigned:= to_unsigned(c_par,c_buf_delay);

signal s_di : VEC_DCOL_0;
signal s_d_control: VEC_DPEPAR_0; 
signal s_do,s_do_kernel: VEC_DCOL_0; 
signal s_di_gray : std_logic_vector(c_dw_gray*c_par-1 downto 0); 
signal s_do_gray,s_do_kernel_gray : std_logic_vector(c_dw_gray*c_par-1 downto 0); 
signal s_pipe_we,s_ker_we,s_border_we, s_ker_valid, s_buf_filled, s_buf_filled_next,s_buf_valid,
s_last, s_image_rst_n: std_logic;
signal s_border_en: std_logic;
signal s_cnt_lat: unsigned(integer(ceil(log2(real(c_buf_delay))))-1 downto 0);
signal s_buf_delay: unsigned(integer(ceil(log2(real(c_buf_delay))))-1 downto 0);

 

signal s_iw : std_logic_vector(c_iw_addr_0-1 downto 0);
signal s_ih : std_logic_vector(c_ih_addr_0-1 downto 0);
signal s_np : std_logic_vector(c_np_addr_0-1 downto 0);
signal s_ww : std_logic_vector(c_ww_addr_0-1 downto 0);
signal s_wh : std_logic_vector(c_wh_addr_0-1 downto 0);
signal s_kernel_op : std_logic_vector(c_kinstrw-1 downto 0);
signal s_border_op : std_logic_vector(c_bmodesw-1 downto 0);
signal s_border_vec,s_border_vec_sec: std_logic_vector(((c_ww+c_par-1)*c_wh)-1 downto 0);
signal s_norm: std_logic_vector(c_normw_0-1 downto 0);
signal s_norm_gray: std_logic_vector(c_normw_gray_0-1 downto 0);
signal s_tresh: std_logic_vector(c_treshw_0-1 downto 0);
signal s_tresh_gray: std_logic_vector(c_treshw_gray_0-1 downto 0);


-- Test Signals for debug 

signal s_up_left,s_up_right,s_down_left,s_down_right : std_logic;

signal s_mo : ARRAY_MASKPARCOL_0;
signal s_mo_gray : ARRAY_MASKPAR_GRAY_0;

type VEC_REG is array(0 to c_num_reg-1) of std_logic_vector(REG_WIDTH-1 downto 0);
signal s_reg: VEC_REG;

signal s_coeff_one: VEC_COEFF_0;
signal s_coeff_two: VEC_COEFF_0;

-- Types and Signals for State Mashines 

type ACCELERATOR_STATE is (idle,fill_accel,stream_pixel,empty_accel);
signal s_accel_st, s_next_accel_st : ACCELERATOR_STATE;

-- Signal for Border State

signal s_border_st : BORDER_STATE_0; 

--- Alias for Register file

alias a_resx   : std_logic_vector(c_regw-1 downto 0) is s_reg(0);
alias a_resy   : std_logic_vector(c_regw-1 downto 0) is s_reg(1);
alias a_numpix : std_logic_vector(c_regw-1 downto 0) is s_reg(2);
alias a_ww     : std_logic_vector(c_regw-1 downto 0) is s_reg(3);
alias a_wh     : std_logic_vector(c_regw-1 downto 0) is s_reg(4);
-- Operation Register is splitted in kernel mode and border mode
alias a_kernel_op : std_logic_vector(c_kinstrw-1 downto 0) is s_reg(5)(c_kinstrw-1 downto 0);
alias a_border_op : std_logic_vector(c_bmodesw-1 downto 0) is s_reg(5)(c_kinstrw+c_bmodesw-1 downto c_kinstrw);

alias a_norm   : std_logic_vector(c_regw-1 downto 0) is s_reg(6);
alias a_tresh  : std_logic_vector(c_regw-1 downto 0) is s_reg(7);

begin

-- Mapping of registers to parameters

s_iw <= std_logic_vector(resize(unsigned(a_resx),s_iw'length));
s_ih <= std_logic_vector(resize(unsigned(a_resy),s_ih'length));
s_np <= std_logic_vector(resize(unsigned(a_numpix),s_np'length));
s_ww <= std_logic_vector(resize(unsigned(a_ww),s_ww'length));
s_wh <= std_logic_vector(resize(unsigned(a_wh),s_wh'length));
s_kernel_op <= std_logic_vector(resize(unsigned(a_kernel_op),s_kernel_op'length)); 
s_border_op <= std_logic_vector(resize(unsigned(a_border_op),s_border_op'length)); 
s_norm <= std_logic_vector(resize(unsigned(a_norm),s_norm'length));
s_norm_gray <= std_logic_vector(resize(unsigned(a_norm),s_norm_gray'length));
s_tresh <= std_logic_vector(resize(unsigned(a_tresh),s_tresh'length));
s_tresh_gray <= std_logic_vector(resize(unsigned(a_tresh),s_tresh_gray'length));


-- Mapping registers to coeffs
gen_coeffsig: for i in 0 to c_vecsize-1 generate
  s_coeff_one(i) <= std_logic_vector(resize(signed(s_reg(c_num_para+i)),c_coeffw_0));
  s_coeff_two(i) <= std_logic_vector(resize(signed(s_reg(c_num_para+c_vecsize+i)),c_coeffw_0));
end generate;

-- mapping from data port to correct color cell


par_map: for i in 0 to c_par-1  generate
    s_di_gray((i+1)*c_dw_gray-1 downto i*c_dw_gray) <= di(i)(c_dw_gray-1 downto 0);
    --do(i)(c_dw_gray-1 downto 0) <= s_do_gray((i+1)*c_dw_gray-1 downto i*c_dw_gray);
    s_d_control(i)(c_dw_gray-1 downto 0) <= s_do_gray((i+1)*c_dw_gray-1 downto i*c_dw_gray);
      col_map: for j in 0 to c_col_chan-1 generate
        s_di(j)((i+1)*c_dw-1 downto i*c_dw) <= di(i)((c_dw_gray+(j+1)*c_dw)-1 downto c_dw_gray+(j*c_dw));
        --do(i)((c_dw_gray+(j+1)*c_dw)-1 downto c_dw_gray+(j*c_dw)) <= s_do(j)((i+1)*c_dw-1 downto i*c_dw);
        s_d_control(i)((c_dw_gray+(j+1)*c_dw)-1 downto c_dw_gray+(j*c_dw)) <= s_do(j)((i+1)*c_dw-1 downto i*c_dw);
      end generate;
end generate;

-- register file for holding config parameters

regfile: process(clk)
begin
  if (clk'event and clk ='1') then
    if(init='1') then
      s_reg(to_integer(unsigned(reg_addr))) <= dreg;
    end if;
  end if;
end process;

-- processor for reseting image data

process(rst_n,s_last)
begin
  if (rst_n='0' or s_last='1') then
    s_image_rst_n <= '0';
  else
    s_image_rst_n <= '1';
  end if;
end process;

-- Border control only needed if border handling is supported 

 
border_control_gen: if c_en_border_handling = true generate 

uborder_control: entity work.border_control
generic map(
  WW => c_ww,
  WH => c_wh,
  IW_MAX => c_iw,
  IH_MAX => c_ih,
  PAR => c_par
)
port map(
  clk => clk,
  rst_n => s_image_rst_n,
  nd => s_ker_we,
  iw => s_iw,
  ih => s_ih,
  border_en => s_border_en,
  border_vec => s_border_vec
);



process(s_iw)
  variable v_iw : unsigned(s_iw'length -1 downto 0);
begin
  v_iw := unsigned(s_iw);
  s_buf_delay <= resize(((cu_wh)/2*v_iw)/cu_par + (cu_ww/2),s_buf_delay'length); 
end process;


border_mux:process(s_border_op)
begin
  if s_border_op="01" or s_border_op="10" then
    s_border_en <='1'; -- enable border handling
  else
    s_border_en <='0'; -- disable border handling
  end if;
end process;

-- Process for cutting out correct Mask section
-- FIXME check for even mask size
process(s_border_vec,s_ww,s_wh)
variable v_i,v_x_rel,v_x_rel_abs, v_y_rel,v_y_rel_abs,v_iw,v_ww_half,v_wh_half: integer;
variable v_up_left_corner, v_up_right_corner, v_down_left_corner, v_down_right_corner: std_logic;

begin
  v_wh_half:= to_integer(unsigned(s_wh))/2;
  v_ww_half:= to_integer(unsigned(s_ww))/2;
  v_up_left_corner:= '0';
  v_up_right_corner:= '0';
  v_down_left_corner:= '0';
  v_down_right_corner:= '0';
  s_up_left <= '0';
  s_up_right <= '0';
  s_down_left <= '0';
  s_down_right <= '0';
  for y in c_wh-1 downto 0 loop
    for x in c_ww+c_par-2 downto 0 loop
      v_i:= y*(c_ww+c_par-1)+x; -- get linear index in mask
      v_x_rel:= x-c_ww/2;
      v_y_rel:= y-c_wh/2;
      v_x_rel_abs:= to_integer(abs(to_signed(v_x_rel,32))); -- calculate index value relative to middle pixel of mask
      v_y_rel_abs:= to_integer(abs(to_signed(y-c_wh/2,32))); -- calculate index value relative to middle pixel of mask
      if v_y_rel_abs <= v_wh_half and (v_x_rel_abs <= v_ww_half or (v_x_rel > 0 and v_x_rel <= v_ww_half+c_par-1))  then
        s_border_vec_sec(v_i) <= s_border_vec(v_i);
        if v_x_rel = v_ww_half+c_par-1 and v_y_rel = v_wh_half then
          v_up_left_corner := s_border_vec(v_i);
          s_up_left <= s_border_vec(v_i);
        elsif v_x_rel= -(v_ww_half) and v_y_rel = v_wh_half then
          v_up_right_corner := s_border_vec(v_i);
          s_up_right <= s_border_vec(v_i);
        elsif v_x_rel = v_ww_half+c_par-1 and v_y_rel = -(v_wh_half) then
          v_down_left_corner := s_border_vec(v_i);
          s_down_left <= s_border_vec(v_i);
        elsif v_x_rel = -(v_ww_half) and v_y_rel = -(v_wh_half) then
          v_down_right_corner := s_border_vec(v_i);
          s_down_right <= s_border_vec(v_i);
        else
        end if;
      else
        s_border_vec_sec(v_i) <= '0';
      end if;
    end loop;
  end loop;

  -- Selecting Border State

  if (v_up_left_corner and v_up_right_corner and v_down_left_corner) = '1' then
    s_border_st <= up_left;
  elsif(v_up_left_corner and v_up_right_corner) = '1' and v_down_right_corner = '0' and v_down_left_corner = '0' then
    s_border_st <= up;
  elsif(v_up_left_corner and v_up_right_corner and v_down_right_corner) = '1' then
    s_border_st <= up_right;
  elsif(v_up_left_corner and v_down_left_corner) = '1' and v_up_right_corner= '0' and v_down_right_corner = '0' then
    s_border_st <= left;
  elsif(v_up_right_corner and v_down_right_corner) = '1' and v_up_left_corner = '0' and v_down_left_corner = '0' then
    s_border_st <= right;
  elsif(v_up_left_corner and v_down_left_corner and v_down_right_corner) = '1' then
    s_border_st <= down_left;
  elsif(v_down_right_corner and v_down_left_corner) = '1' and v_up_left_corner = '0' and v_up_right_corner = '0' then
    s_border_st <= down;
  elsif(v_up_right_corner and v_down_right_corner  and v_down_left_corner) = '1' then
    s_border_st <= down_right;
  else
    s_border_st <= no_border;
  end if;


end process;


end generate;

-- In case border handling is not supported

no_border_control:if c_en_border_handling = false generate 
  s_border_vec <= (others =>'0');
end generate;



fill_cnt: process(clk)
begin
if(clk'event and clk = '1') then
  if(s_image_rst_n='0') then
    s_cnt_lat <= (others=>'0');
    s_buf_filled <= '0';

  elsif(s_pipe_we = '1') then 
      if(s_cnt_lat < s_buf_delay) then
        s_cnt_lat <= s_cnt_lat+1;
        s_buf_filled <='0';  
      else
        s_buf_filled <='1';
      end if;
  end if;
end if;
end process;

s_ker_we <= s_pipe_we when s_buf_filled='1' else '0';


accel_control: entity work.accel_control
port map (
  clk => clk,
  rst_n => rst_n,
  start => start,
  valid_in  => valid_in,
  ready_in  => ready_in,
  valid_out  => valid_out,
  ready_out  => ready_out,
  pipe_filled => s_ker_valid,
  pipe_we => s_pipe_we,
  np => s_np,
  last => s_last,
  di => s_d_control, 
  do => do  
);

last <= s_last;


buffer_clb_gray : entity work.buffer_clb_gray_0
port map (
  clk => clk,
  rst_n => s_image_rst_n,
  en  => en,
  nd  => s_pipe_we,
  border_vec => s_border_vec_sec, 
  border_st => s_border_st,
  border_op => s_border_op,
  iw => s_iw,
  ww => s_ww,
  wh => s_wh,
  di => s_di_gray, 
  mo => s_mo_gray  
);

kernel_clb_gray: entity work.kernel_clb_gray_0
port map (
  clk => clk,
  rst_n => s_image_rst_n,
  en  => en,
  nd  => s_ker_we, 
  valid => s_ker_valid,
  next_valid => open,
  ww => s_ww,
  wh => s_wh,
  kinstr => s_kernel_op,
  norm => s_norm_gray,
  tresh => s_tresh_gray,
  coeff_one => s_coeff_one,
  coeff_two => s_coeff_two, 
  di => s_mo_gray, 
  do => s_do_gray 
);


-- multi color generation


multicol_gen: if c_col > 1 generate
  col_gen: for i in 0 to c_col_chan-1 generate

  buffer_clb : entity work.buffer_clb_0
  port map (
    clk => clk,
    rst_n => s_image_rst_n,
    en  => en,
    nd  => s_pipe_we,
    border_vec => s_border_vec_sec, 
    border_st => s_border_st, 
    border_op => s_border_op,
    iw => s_iw,
    ww => s_ww,
    wh => s_wh,
    di => s_di(i),
    mo => s_mo(i)  
  );
  
  kernel_uut: entity work.kernel_clb_0
  port map (
    clk => clk,
    rst_n => s_image_rst_n,
    en  => en,
    nd  => s_ker_we,
    valid => open, --FIXME
    ww => s_ww,
    wh => s_wh,
    kinstr => s_kernel_op,
    norm => s_norm,
    tresh => s_tresh,
    coeff_one => s_coeff_one,
    coeff_two => s_coeff_two, 
    di => s_mo(i),
    do => s_do(i)
  );


  end generate;
end generate;  


end behavior;
