proc AddWaves {} {
    # Add waves we're interested in to the Wave window
    add wave -position end sim:/trigger_correction_tb/clock
    add wave -position end sim:/trigger_correction_tb/reset
}

vlib work

# Compile components
vcom library/arbitrated_memory.vhd
vcom sinc_interpolation/filter_parameters.vhd
vcom sinc_interpolation/Hlp2.vhd
vcom sinc_interpolation/Hlp4.vhd
vcom sinc_interpolation/Hlp8.vhd
vcom sinc_interpolation/Hlp16.vhd
vcom sinc_interpolation/lowpass_filter.vhd
vcom sinc_interpolation/sinc_interpolation.vhd
vcom sinc_interpolation/sinc_interpolation_tb.vhd

# Start simulation
vsim -t ns sinc_interpolation_tb

# Generate a clock with 20 ns period
force -deposit clock 0 0 ns, 1 10 ns -repeat 20 ns

# Add the waves
AddWaves

# Load first test signal into memory
run 10ns
mem load -infile triggering/test-signals/test_signal1.txt -format bin -filldata 0 /sinc_interpolation_tb/rom/MEMORY/read_data

# Run
run 25ms