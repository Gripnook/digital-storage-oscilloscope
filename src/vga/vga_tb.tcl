proc AddWaves {} {
    # Add waves we're interested in to the Wave window
    add wave -position end sim:/vga_tb/clock
    add wave -position end sim:/vga_tb/reset
    add wave -position end sim:/vga_tb/hsync
    add wave -position end sim:/vga_tb/vsync
    add wave -position end sim:/vga_tb/rgb
}

vlib work

# Compile components
vcom library/bcd_converter.vhd
vcom library/arbitrated_memory.vhd
vcom library/running_average.vhd
vcom vga/vga_parameters.vhd
vcom vga/vga_text_address_generator.vhd
vcom vga/vga_grid_generator.vhd
vcom vga/vga_text_generator.vhd
vcom vga/vga_font_rom.vhd
vcom vga/vga_rom.vhd
vcom vga/vga_timing_generator.vhd
vcom vga/vga_buffer.vhd
vcom vga/vga.vhd
vcom vga/vga_tb.vhd

# Start simulation
vsim -t ns vga_tb

# Generate a clock with 20 ns period
force -deposit clock 0 0 ns, 1 10 ns -repeat 20 ns

# Add the waves
AddWaves

# Load first test signal into memory
run 10ns
mem load -infile vga/test-signals/test_signal1.txt -format bin -filldata 0 /vga_tb/rom/mem/MEMORY/mem_data

# Load second test signal into memory
run 10ms
mem load -infile vga/test-signals/test_signal2.txt -format bin -filldata 0 /vga_tb/rom/mem/MEMORY/mem_data

# Run
run 20ms
