onbreak resume
onerror resume
vsim -novopt work.Hlp4_tb
add wave sim:/Hlp4_tb/u_Hlp4/clock
add wave sim:/Hlp4_tb/u_Hlp4/enable
add wave sim:/Hlp4_tb/u_Hlp4/reset
add wave sim:/Hlp4_tb/u_Hlp4/filter_in
add wave sim:/Hlp4_tb/u_Hlp4/filter_out
add wave sim:/Hlp4_tb/filter_out_ref
run -all
