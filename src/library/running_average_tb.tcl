proc AddWaves {} {
    # Add waves we're interested in to the Wave window
    add wave -position end sim:/running_average_tb/clock
    add wave -position end sim:/running_average_tb/reset
    add wave -position end -radix unsigned sim:/running_average_tb/data_in
    add wave -position end sim:/running_average_tb/load
    add wave -position end -radix unsigned sim:/running_average_tb/average
    add wave -position end -radix unsigned sim:/running_average_tb/dut/running_sum
}

vlib work

# Compile components
vcom library/running_average.vhd
vcom library/running_average_tb.vhd

# Start simulation
vsim -t ns running_average_tb

# Generate a clock with 20 ns period
force -deposit clock 0 0 ns, 1 10 ns -repeat 20 ns

# Add the waves
AddWaves

# Run
run 5us
