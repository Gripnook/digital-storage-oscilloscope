onbreak resume
onerror resume
vsim -novopt work.Hlp2_tb
add wave sim:/Hlp2_tb/u_Hlp2/clock
add wave sim:/Hlp2_tb/u_Hlp2/enable
add wave sim:/Hlp2_tb/u_Hlp2/reset
add wave sim:/Hlp2_tb/u_Hlp2/filter_in
add wave sim:/Hlp2_tb/u_Hlp2/filter_out
add wave sim:/Hlp2_tb/filter_out_ref
run -all
