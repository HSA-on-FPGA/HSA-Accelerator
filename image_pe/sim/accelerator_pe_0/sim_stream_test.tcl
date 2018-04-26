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
#do compile.tcl

# Testbench
vcom -93 -explicit tb_stream_test.vhd

#Start Simulation
vsim -novopt tb_stream_test
view wave

add wave -noupdate -divider -height 32 Testbench
add wave -radix unsigned tb_stream_test/*

add wave -noupdate -divider -height 32 Accelerator
add wave -color yellow -radix unsigned tb_stream_test/uut/*

#add wave -noupdate -divider -height 32 Kernel
#add wave -radix unsigned tb_stream_test/kernel_uut/*

#add wave -noupdate -divider -height 32 Convolution
#add wave -color orange -radix unsigned tb_stream_test/kernel_uut/par_gen(0)/conv_one/*

#add wave -noupdate -divider -height 32 Accumulate
#add wave -color green -radix unsigned tb_stream_test/kernel_uut/par_gen(0)/conv_one/addall/*



# Run Simulation
run  100 us

