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

add_files "./generic/scale/scale.vhd"
add_files "./generic/axis/fifo_to_axi_stream.vhd"
add_files "./generic/axis/axi_stream_to_fifo.vhd"
add_files "./generic/raminfr.vhd"
add_files "./generic/mux2.vhd"
add_files "./generic/bitonic_sort/swap.vhd"
add_files "./generic/bitonic_sort/bitonic_merge_1.vhd"
add_files "./generic/bitonic_sort/bitonic_sort.vhd"
add_files "./generic/bitonic_sort/bitonic_merge_2.vhd"
add_files "./generic/bitonic_sort/bitonic_sort_impl.vhd"
add_files "./generic/valshiftreg.vhd"
add_files "./generic/add2.vhd"
add_files "./generic/acc.vhd"
add_files "./generic/reg.vhd"
add_files "./generic/conv.vhd"
add_files "./generic/add3.vhd"
add_files "./axi_pe_0/fifo_read_control.vhd"
add_files "./axi_pe_0/fifo_wrapper.vhd"
add_files "./axi_pe_0/fifo_to_pixel_gen.vhd"
#add_files "./axi_pe_0/axi_pe_0.vhd"
add_files "./axi_aligned_pe_0/axi_to_pixel.vhd"
add_files "./axi_aligned_pe_0/pixel_to_axi.vhd"
add_files "./axi_aligned_pe_0/axi_master.vhd"
add_files "./axi_aligned_pe_0/axi_aligned_pe_0.vhd"
add_files "./axi_pe_0/pixel_to_fifo_gen.vhd"
add_files "./buffer_clb_gray_0/pkg_buffer_gray_0.vhd"
add_files "./buffer_clb_gray_0/buffer_clb_gray_0.vhd"
add_files "./buffer_clb_gray_0/fbpar_gray_0.vhd"
add_files "./kernel_clb_gray_0/kernel_clb_gray_0.vhd"
add_files "./buffer_clb_0/pkg_buffer_0.vhd"
add_files "./buffer_clb_0/buffer_clb_0.vhd"
add_files "./buffer_clb_0/fbpar_0.vhd"
add_files "./pkg_functions.vhd"
add_files "./pkg_config.vhd"
add_files "./kernel_clb_0/kernel_clb_0.vhd"
add_files "./accelerator_pe_0/accelerator_pe_0.vhd"
add_files "./accelerator_pe_0/accel_control.vhd"
add_files "./accelerator_pe_0/border_control.vhd"
