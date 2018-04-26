
# Author:      Tobias Lieske, Philipp Holzinger
# Email:       tobias.lieske@fau.de, philipp.holzinger@fau.de
# Date:        28.11.2016

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

