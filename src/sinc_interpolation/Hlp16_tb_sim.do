onbreak resume
onerror resume
vsim -novopt work.Hlp16_tb
add wave sim:/Hlp16_tb/u_Hlp16/clock
add wave sim:/Hlp16_tb/u_Hlp16/enable
add wave sim:/Hlp16_tb/u_Hlp16/reset
add wave sim:/Hlp16_tb/u_Hlp16/filter_in
add wave sim:/Hlp16_tb/u_Hlp16/filter_out
add wave sim:/Hlp16_tb/filter_out_ref
run -all
