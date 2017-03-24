onbreak resume
onerror resume
vsim -novopt work.Hlp32_tb
add wave sim:/Hlp32_tb/u_Hlp32/clock
add wave sim:/Hlp32_tb/u_Hlp32/enable
add wave sim:/Hlp32_tb/u_Hlp32/reset
add wave sim:/Hlp32_tb/u_Hlp32/filter_in
add wave sim:/Hlp32_tb/u_Hlp32/filter_out
add wave sim:/Hlp32_tb/filter_out_ref
run -all
