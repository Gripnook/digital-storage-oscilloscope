proc AddWaves {} {
    # Add waves we're interested in to the Wave window
    add wave -position end sim:/vga_timing_generator_tb/clock
    add wave -position end sim:/vga_timing_generator_tb/reset
    add wave -position end sim:/vga_timing_generator_tb/row
    add wave -position end sim:/vga_timing_generator_tb/column
    add wave -position end sim:/vga_timing_generator_tb/hsync
    add wave -position end sim:/vga_timing_generator_tb/vsync
    add wave -position end sim:/vga_timing_generator_tb/blank_n
    add wave -position end sim:/vga_timing_generator_tb/rgb
}

vlib work

# Compile components
vcom vga/vga_timing_generator.vhd
vcom vga/vga_timing_generator_tb.vhd

# Start simulation
vsim -t ns vga_timing_generator_tb

# Generate a clock with 20 ns period
force -deposit clock 0 0 ns, 1 10 ns -repeat 20 ns

# Add the waves
AddWaves

# Run
run 20ms
