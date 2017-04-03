proc AddWaves {} {
    # Add waves we're interested in to the Wave window
    add wave -position end sim:/statistics_tb/clock
    add wave -position end sim:/statistics_tb/reset
    add wave -position end sim:/statistics_tb/enable
    add wave -position end sim:/statistics_tb/clear
    add wave -position end -radix unsigned sim:/statistics_tb/data
    add wave -position end -radix unsigned sim:/statistics_tb/spread
    add wave -position end -radix unsigned sim:/statistics_tb/average
    add wave -position end -radix unsigned sim:/statistics_tb/maximum
    add wave -position end -radix unsigned sim:/statistics_tb/minimum
}

vlib work

# Compile components
vcom library/statistics.vhd
vcom library/statistics_tb.vhd

# Start simulation
vsim -t ns statistics_tb

# Generate a clock with 20 ns period
force -deposit clock 0 0 ns, 1 10 ns -repeat 20 ns

# Add the waves
AddWaves

# Run
run 5us
