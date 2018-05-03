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

# compile sources


# sources
vcom -reportprogress 300 -work work scale.vhd
vcom -reportprogress 300 -work work tb_scale.vhd

# start simulation

vsim -t 1ps -novopt work.tb_scale_top
view wave

config wave -signalnamewidth 1

add wave -noupdate -divider -height 32 testbench
add wave -radix hex sim:/tb_scale_top/*

add wave -noupdate -divider -height 32 scale
add wave -radix hex sim:/tb_scale_top/scale_inst/*

run 400 ns

