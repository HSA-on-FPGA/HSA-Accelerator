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

do compile.tcl

#Start Simulation
vsim tb_axi_image_test

view wave

#Add wave forms
add wave -noupdate -divider -height 32 Testbench 
add wave -radix unsigned tb_axi_image_test/*

add wave -noupdate -divider -height 32 Pixel_Gen 
add wave -color orange -radix unsigned tb_axi_image_test/pix_gen/*


add wave -noupdate -divider -height 32 Axi_pe
add wave -radix unsigned tb_axi_image_test/uut/*

add wave -noupdate -divider -height 32 Axi_to_Pixel
add wave -radix unsigned -color yellow tb_axi_image_test/uut/axi_to_pixel/*

add wave -noupdate -divider -height 32 Pixel_to_Axi
add wave -radix unsigned -color yellow tb_axi_image_test/uut/pixel_to_axi/*

add wave -noupdate -divider -height 32 Accel_control
add wave -radix unsigned  tb_axi_image_test/uut/accelerator/accel_control/*

add wave -noupdate -divider -height 32 Axi_Master
add wave -radix unsigned -color green tb_axi_image_test/uut/axi_master/*


#Load image to memory of tb
mem load -infile tools/mem_init.mem -format hex /tb_axi_image_test/pix_gen/mem_r

#set short signal names
config wave -signalnamewidth 1

# Run simulation
run 200 us

wave zoom full

# Save resulting image
mem save -outfile tools/mem_res.mem -noaddress -wordsperline 1 -format hex /tb_axi_image_test/pix_gen/mem_w

# Convert mem file to image
exec tools/res
