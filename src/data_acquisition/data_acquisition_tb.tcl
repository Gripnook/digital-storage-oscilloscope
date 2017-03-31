proc AddWaves {} {
    # Add waves we're interested in to the Wave window
    add wave -position end sim:/data_acquisition_tb/clock
    add wave -position end sim:/data_acquisition_tb/reset
    add wave -position end -radix unsigned sim:/data_acquisition_tb/adc_data
    add wave -position end sim:/data_acquisition_tb/adc_sample
    add wave -position end sim:/data_acquisition_tb/trigger
    add wave -position end sim:/data_acquisition_tb/dut/state
}

vlib work

# Compile components
vcom signal_generator/delay_equalizer.vhd
vcom signal_generator/accumulator.vhd
vcom signal_generator/bit_slice.vhd
vcom signal_generator/pipelined_frequency_synthesizer.vhd
vcom signal_generator/analog_waveform_generator.vhd
vcom library/arbitrated_memory.vhd
vcom triggering/triggering.vhd
vcom data_acquisition/data_acquisition.vhd
vcom data_acquisition/data_acquisition_tb.vhd

# Start simulation
vsim -t ns data_acquisition_tb

# Generate a clock with 20 ns period
force -deposit clock 0 0 ns, 1 10 ns -repeat 20 ns

# Add the waves
AddWaves

# Run
run 1ms
