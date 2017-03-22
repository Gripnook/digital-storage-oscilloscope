proc AddWaves {} {
    # Add waves we're interested in to the Wave window
    add wave -position end sim:/divider_tb/clock
    add wave -position end sim:/divider_tb/reset
    add wave -position end -radix unsigned sim:/divider_tb/dividend
    add wave -position end -radix unsigned sim:/divider_tb/divisor
    add wave -position end sim:/divider_tb/start
    add wave -position end -radix unsigned sim:/divider_tb/quotient
    add wave -position end -radix unsigned sim:/divider_tb/remainder
    add wave -position end sim:/divider_tb/done
    add wave -position end sim:/divider_tb/dut/state
}

vlib work

# Compile components
vcom library/divider.vhd
vcom library/divider_tb.vhd

# Start simulation
vsim -t ns divider_tb

# Generate a clock with 20 ns period
force -deposit clock 0 0 ns, 1 10 ns -repeat 20 ns

# Add the waves
AddWaves

# Run
run 5us
