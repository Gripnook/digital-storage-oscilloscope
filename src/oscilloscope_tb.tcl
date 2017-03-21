proc AddWaves {} {
    # Add waves we're interested in to the Wave window
    add wave -position end sim:/oscilloscope_tb/clock
    add wave -position end sim:/oscilloscope_tb/reset_n
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
vcom vga/bcd_converter/bcd_converter.vhd
vcom vga/vga_rom/vga_text_address_generator.vhd
vcom vga/vga_rom/vga_grid_generator.vhd
vcom vga/vga_rom/vga_text_generator.vhd
vcom vga/vga_rom/font_rom.vhd
vcom vga/vga_rom/vga_rom.vhd
vcom vga/vga_timing_generator.vhd
vcom vga/vga_buffer.vhd
vcom vga/vga.vhd
vcom memory/arbitrated_memory.vhd
vcom data_acquisition/triggering.vhd
vcom data_acquisition/data_acquisition.vhd
vcom oscilloscope.vhd
vcom oscilloscope_tb.vhd

# Start simulation
vsim -t ns oscilloscope_tb

# Generate a clock with 20 ns period
force -deposit clock 0 0 ns, 1 10 ns -repeat 20 ns

# Add the waves
AddWaves

# Run
run 40ms
