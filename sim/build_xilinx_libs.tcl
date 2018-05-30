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

# source this file with vivado

set script_dir "[file dirname "[file normalize "[info script]"]"]"

file delete -force "${script_dir}/xilinx_libs"
file mkdir "${script_dir}/xilinx_libs"
cd "${script_dir}/xilinx_libs"
compile_simlib -language all -dir ${script_dir}/xilinx_libs -simulator questa -library all -family all
