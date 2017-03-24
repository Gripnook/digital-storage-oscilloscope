onbreak resume
onerror resume
vsim -novopt work.Hlp8_tb
add wave sim:/Hlp8_tb/u_Hlp8/clock
add wave sim:/Hlp8_tb/u_Hlp8/enable
add wave sim:/Hlp8_tb/u_Hlp8/reset
add wave sim:/Hlp8_tb/u_Hlp8/filter_in
add wave sim:/Hlp8_tb/u_Hlp8/filter_out
add wave sim:/Hlp8_tb/filter_out_ref
run -all
