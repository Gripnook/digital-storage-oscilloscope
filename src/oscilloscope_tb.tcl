proc AddWaves {} {
    # Add waves we're interested in to the Wave window
    add wave -position end sim:/oscilloscope_tb/clock
    add wave -position end sim:/oscilloscope_tb/reset
    add wave -position end sim:/oscilloscope_tb/hsync
    add wave -position end sim:/oscilloscope_tb/vsync
    add wave -position end sim:/oscilloscope_tb/r
    add wave -position end sim:/oscilloscope_tb/g
    add wave -position end sim:/oscilloscope_tb/b
}

vlib work

# Compile components
vcom signal_generator/delay_equalizer.vhd
vcom signal_generator/accumulator.vhd
vcom signal_generator/bit_slice.vhd
vcom signal_generator/pipelined_frequency_synthesizer.vhd
vcom signal_generator/analog_waveform_generator.vhd
vcom library/bcd_converter.vhd
vcom library/divider.vhd
vcom library/running_average.vhd
vcom library/arbitrated_memory.vhd
vcom library/statistics.vhd
vcom vga/vga_parameters.vhd
vcom vga/vga_text_address_generator.vhd
vcom vga/vga_grid_generator.vhd
vcom vga/vga_text_generator.vhd
vcom vga/vga_font_rom.vhd
vcom vga/vga_rom.vhd
vcom vga/vga_timing_generator.vhd
vcom vga/vga_buffer.vhd
vcom vga/vga.vhd
vcom triggering/triggering.vhd
vcom triggering/trigger_correction.vhd
vcom data_acquisition/data_acquisition.vhd
vcom sinc_interpolation/Hlp2.vhd
vcom sinc_interpolation/Hlp4.vhd
vcom sinc_interpolation/Hlp8.vhd
vcom sinc_interpolation/Hlp16.vhd
vcom sinc_interpolation/filter_parameters.vhd
vcom sinc_interpolation/lowpass_filter.vhd
vcom sinc_interpolation/sinc_interpolation.vhd
vcom oscilloscope.vhd
vcom oscilloscope_tb.vhd

# Start simulation
vsim -t ns oscilloscope_tb

# Generate a clock with 20 ns period
force -deposit clock 0 0 ns, 1 10 ns -repeat 20 ns

# Add the waves
#AddWaves

# Run
run 100ms
