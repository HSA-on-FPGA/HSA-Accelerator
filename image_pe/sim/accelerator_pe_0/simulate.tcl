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
vsim tb_image_test

view wave

#Add wave forms
add wave -noupdate -divider -height 32 Testbench 
add wave -radix unsigned tb_image_test/*

add wave -noupdate -divider -height 32 Pixgen
add wave -radix unsigned tb_image_test/pix_gen/*


add wave -noupdate -divider -height 32 Acclerator
add wave -radix unsigned tb_image_test/uut/*

add wave -noupdate -divider -height 32 Acclerator_control
add wave -radix unsigned tb_image_test/uut/accel_control/*

add wave -noupdate -divider -height 32 Kernel
add wave -radix unsigned tb_image_test/uut/multicol_gen/col_gen(0)/kernel_uut/*

#add wave -noupdate -divider -height 32 Kernel_gray
#add wave -radix unsigned tb_image_test/uut/kernel_clb_gray/*


# Load Image to Memory of tb
mem load -infile tools/mem_init.mem -format hex /tb_image_test/pix_gen/mem_r

#set short signal names
config wave -signalnamewidth 1

# Run Simulation
run 380 us

# Save Resulting Image
mem save -outfile tools/mem_res.mem -noaddress -wordsperline 1 -format hex /tb_image_test/pix_gen/mem_w
# Convert mem file to image
exec tools/res
# open image, requires gimp
# gimp tools/output.ppm
