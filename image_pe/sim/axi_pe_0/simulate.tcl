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

add wave -noupdate -divider -height 32 Axi_pe
add wave -radix unsigned tb_axi_image_test/uut/*

add wave -noupdate -divider -height 32 fifo_out
add wave -color orange -radix unsigned tb_axi_image_test/uut/fifo_out/*

# Load Image to Memory of tb
mem load -infile tools/mem_init.mem -format hex /tb_axi_image_test/pix_gen/mem_r

#set short signal names
config wave -signalnamewidth 1

# Run Simulation
run 200 us

# Save Resulting Image
mem save -outfile tools/mem_res.mem -noaddress -wordsperline 1 -format hex /tb_axi_image_test/pix_gen/mem_w

# Convert mem file to image
exec tools/res
