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

vlib work

source ../load_files.tcl

# Testbench
vcom -93 -explicit ../image_test_files/*.vhd
vcom -93 -explicit tb_axi_pe_test.vhd

#Start Simulation
vsim -novopt tb_axi_pe_test
view wave

#Add Wave forms
add wave -noupdate -divider -height 32 Testbench
add wave -radix unsigned tb_axi_pe_test/*

#add wave -noupdate -divider -height 32 axis_pixel_conv
#add wave -color yellow -radix unsigned tb_axi_pe_test/axis_to_pixel_conv/*


#add wave -noupdate -divider -height 32 Axi_Pe
#add wave -color red -radix unsigned tb_axi_pe_test/uut/*

#add wave -noupdate -divider -height 32 Axi_to_fifo
#add wave -color orange -radix unsigned tb_axi_pe_test/uut/axi_slave/*

#add wave -noupdate -divider -height 32 fifo_in
#add wave -color brown -radix unsigned tb_axi_pe_test/uut/fifo_in/*

#add wave -noupdate -divider -height 32 fifo_to_pixel
#add wave -color green -radix unsigned tb_axi_pe_test/uut/fifo_to_pixel_conv/*

#add wave -noupdate -divider -height 32 fifo_to_pixel_gen
#add wave -color green -radix unsigned tb_axi_pe_test/uut/fifo_to_pixel_conv/*

#add wave -noupdate -divider -height 32 down_scale_gray
#add wave -color yellow -radix unsigned tb_axi_pe_test/uut/fifo_to_pixel_conv/gray_inst/*

add wave -noupdate -divider -height 32 Accelerator
add wave -color yellow -radix unsigned tb_axi_pe_test/uut/accelerator/*

#add wave -noupdate -divider -height 32 border_control
#add wave -color orange -radix unsigned tb_axi_pe_test/uut/accelerator/border_control_gen/uborder_control/*


add wave -noupdate -divider -height 32 buffer_gray
add wave -color green -radix unsigned tb_axi_pe_test/uut/accelerator/buffer_clb_gray/*

#add wave -noupdate -divider -height 32 fullbuffer
#add wave -color yellow -radix unsigned tb_axi_pe_test/uut/accelerator/buffer_clb_gray/ufbpar0/*

#add wave -noupdate -divider -height 32 kernel_clb_gray
#add wave -color yellow -radix unsigned tb_axi_pe_test/uut/accelerator/kernel_clb_gray/*

#add wave -noupdate -divider -height 32 acc
#add wave -color yellow -radix unsigned tb_axi_pe_test/uut/accelerator/kernel_clb_gray/par_gen(0)/conv_one/addall/*

#add wave -noupdate -divider -height 32 buffer_clb_gray
#add wave -color green -radix unsigned tb_axi_pe_test/uut/accelerator/buffer_clb_gray/*



#add wave -noupdate -divider -height 32 pixel_to_fifo


#add wave -noupdate -divider -height 32 fullbuffer
#add wave -color yellow -radix unsigned tb_axi_pe_test/uut/accelerator/buffer_clb_gray/ufbpar0/*

add wave -noupdate -divider -height 32 kernel_clb_gray
add wave -color yellow -radix unsigned tb_axi_pe_test/uut/accelerator/kernel_clb_gray/*

#add wave -noupdate -divider -height 32 acc
#add wave -color yellow -radix unsigned tb_axi_pe_test/uut/accelerator/kernel_clb_gray/par_gen(0)/conv_one/addall/*

#add wave -noupdate -divider -height 32 buffer_clb_gray
#add wave -color green -radix unsigned tb_axi_pe_test/uut/accelerator/buffer_clb_gray/*



#add wave -noupdate -divider -height 32 pixel_to_fifo
#add wave -color orange -radix unsigned tb_axi_pe_test/uut/pixel_to_fifo_conv/*

#add wave -noupdate -divider -height 32 scale_up
#add wave -color yellow -radix unsigned tb_axi_pe_test/uut/pixel_to_fifo_conv/color_inst/*


#add wave -noupdate -divider -height 32 fifo_to_Axi
#add wave -color brown -radix unsigned tb_axi_pe_test/uut/axi_master/*

#set short names
config wave -signalnamewidth 1

# Run Simulation
run  100 us

