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
vcom -93 -explicit sim_toplevel.vhd

#Start Simulation
vsim -novopt sim_toplevel
view wave

add wave -noupdate -divider -height 32 Testbench
add wave -radix unsigned sim_toplevel/*

#add wave -noupdate -divider -height 32 Template_0
#add wave -radix unsigned sim_toplevel/uut/*


# Run Simulation
run 1 us

