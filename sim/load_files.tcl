#
# Copyright 2017 Konrad Haeublein
#
# konrad.haeublein@fau.de
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

set load_files_script_dir "[file dirname "[file normalize "[info script]"]"]"

if {! [file exists ${load_files_script_dir}/xilinx_libs]} {
    error "Please source 'build_xilinx_libs.tcl' with vivado to generate xilinx simulation libraries."
    exit
}


#if {! [file exists ${load_files_script_dir}/../custom/kuwahara/proj_kuwahara]} {
#    error "Please source 'run_hls.tcl' in '/../custom/kuwahara/' with vivado hls to generate custom kernel."
#    exit
#}

vmap unisim ${load_files_script_dir}/xilinx_libs/unisim
vmap unimacro ${load_files_script_dir}/xilinx_libs/unimacro
vmap xpm ${load_files_script_dir}/xilinx_libs/xpm

vcom -93 -explicit ${load_files_script_dir}/../pkg_functions.vhd
vcom -93 -explicit ${load_files_script_dir}/../pkg_config.vhd
vcom -93 -explicit ${load_files_script_dir}/../generic/acc.vhd
vcom -93 -explicit ${load_files_script_dir}/../generic/add2.vhd
vcom -93 -explicit ${load_files_script_dir}/../generic/add3.vhd
vcom -93 -explicit ${load_files_script_dir}/../generic/axis/axi_stream_to_fifo.vhd
vcom -93 -explicit ${load_files_script_dir}/../generic/axis/fifo_to_axi_stream.vhd
vcom -93 -explicit ${load_files_script_dir}/../generic/conv.vhd
vcom -93 -explicit ${load_files_script_dir}/../generic/mux2.vhd
vcom -93 -explicit ${load_files_script_dir}/../generic/raminfr.vhd
vcom -93 -explicit ${load_files_script_dir}/../generic/reg.vhd
vcom -93 -explicit ${load_files_script_dir}/../generic/swap.vhd
vcom -93 -explicit ${load_files_script_dir}/../generic/valshiftreg.vhd
vcom -93 -explicit ${load_files_script_dir}/../generic/bitonic_sort/bitonic_merge_1.vhd
vcom -93 -explicit ${load_files_script_dir}/../generic/bitonic_sort/bitonic_merge_2.vhd
vcom -93 -explicit ${load_files_script_dir}/../generic/bitonic_sort/bitonic_sort_impl.vhd
vcom -93 -explicit ${load_files_script_dir}/../generic/bitonic_sort/bitonic_sort.vhd
vcom -93 -explicit ${load_files_script_dir}/../generic/scale/scale.vhd

# for custom kernel
#vcom -93 -explicit ${load_files_script_dir}/../custom/pkg_custom_config.vhd
#vcom -93 -explicit ${load_files_script_dir}/../custom/kuwahara/proj_kuwahara/solution1/syn/vhdl/kuwahara_*.vhd
#vcom -93 -explicit ${load_files_script_dir}/../custom/kuwahara/proj_kuwahara/solution1/syn/vhdl/kuwahara.vhd
#vcom -93 -explicit ${load_files_script_dir}/../custom/kuwahara/kernel_0.vhd

vcom -93 -explicit ${load_files_script_dir}/../buffer_clb_0/pkg_buffer_0.vhd
vcom -93 -explicit ${load_files_script_dir}/../buffer_clb_0/fbpar_0.vhd
vcom -93 -explicit ${load_files_script_dir}/../buffer_clb_0/buffer_clb_0.vhd 
vcom -93 -explicit ${load_files_script_dir}/../buffer_clb_gray_0/pkg_buffer_gray_0.vhd
vcom -93 -explicit ${load_files_script_dir}/../buffer_clb_gray_0/fbpar_gray_0.vhd
vcom -93 -explicit ${load_files_script_dir}/../buffer_clb_gray_0/buffer_clb_gray_0.vhd
vcom -93 -explicit ${load_files_script_dir}/../kernel_clb_0/kernel_clb_0.vhd
vcom -93 -explicit ${load_files_script_dir}/../kernel_clb_gray_0/kernel_clb_gray_0.vhd
vcom -93 -explicit ${load_files_script_dir}/../accelerator_pe_0/border_control.vhd
vcom -93 -explicit ${load_files_script_dir}/../accelerator_pe_0/accel_control.vhd
vcom -93 -explicit ${load_files_script_dir}/../accelerator_pe_0/accelerator_pe_0.vhd
vcom -93 -explicit ${load_files_script_dir}/../axi_pe_0/fifo_read_control.vhd
vcom -93 -explicit ${load_files_script_dir}/../axi_pe_0/fifo_to_pixel_gen.vhd
vcom -93 -explicit ${load_files_script_dir}/../axi_pe_0/fifo_wrapper.vhd
vcom -93 -explicit ${load_files_script_dir}/../axi_pe_0/pixel_to_fifo_gen.vhd
vcom -93 -explicit ${load_files_script_dir}/../axi_pe_0/axi_pe_0.vhd
 
vcom -93 -explicit ${load_files_script_dir}/../axi_aligned_pe_0/axi_master.vhd 
vcom -93 -explicit ${load_files_script_dir}/../axi_aligned_pe_0/axi_to_pixel.vhd 
vcom -93 -explicit ${load_files_script_dir}/../axi_aligned_pe_0/pixel_to_axi.vhd 
vcom -93 -explicit ${load_files_script_dir}/../axi_aligned_pe_0/axi_aligned_pe_0.vhd 
