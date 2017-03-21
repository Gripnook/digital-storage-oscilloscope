proc AddWaves {} {
    ;#Add waves we're interested in to the Wave window
    add wave -position end sim:/pipelined_frequency_synthesizer_tb/clock
    add wave -position end sim:/pipelined_frequency_synthesizer_tb/reset
    add wave -position end sim:/pipelined_frequency_synthesizer_tb/update
    add wave -position end sim:/pipelined_frequency_synthesizer_tb/frequency_control
    add wave -position end sim:/pipelined_frequency_synthesizer_tb/frequency
}

vlib work

;# Compile components
vcom signal_generator/delay_equalizer.vhd
vcom signal_generator/accumulator.vhd
vcom signal_generator/bit_slice.vhd
vcom signal_generator/pipelined_frequency_synthesizer.vhd
vcom signal_generator/pipelined_frequency_synthesizer_tb.vhd

;# Start simulation
vsim -t ps pipelined_frequency_synthesizer_tb

;# Generate a clock
force -deposit clock 0 0 ns, 1 7.8125 ns -repeat 15.625 ns

;# Add the waves
AddWaves

;# Run
run 16000ns
