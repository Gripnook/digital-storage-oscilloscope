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
vcom vga/vga_timing_generator.vhd
vcom memory/arbitrated_memory.vhd
vcom vga/vga_buffer.vhd
vcom vga/vga.vhd
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
