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

open_project -reset proj_kuwahara
set_top kuwahara
add_files cplusplus/kuwahara.cpp
open_solution -reset "solution1"
set_part  {xcvu095-ffva2104-2-e} 
create_clock -period 5
config_bind -effort high
config_schedule -effort high

csynth_design
exit
