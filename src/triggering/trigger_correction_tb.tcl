proc AddWaves {} {
    # Add waves we're interested in to the Wave window
    add wave -position end sim:/trigger_correction_tb/clock
    add wave -position end sim:/trigger_correction_tb/reset
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
vcom triggering/trigger_correction.vhd
vcom triggering/trigger_correction_tb.vhd

# Start simulation
vsim -t ns trigger_correction_tb

# Generate a clock with 20 ns period
force -deposit clock 0 0 ns, 1 10 ns -repeat 20 ns

# Add the waves
AddWaves

# Load first test signal into memory
run 10ns
mem load -infile triggering/test-signals/test_signal1.txt -format bin -filldata 0 /trigger_correction_tb/rom/mem/MEMORY/mem_data

# Load second test signal into memory
run 20ms
mem load -infile triggering/test-signals/test_signal2.txt -format bin -filldata 0 /trigger_correction_tb/rom/mem/MEMORY/mem_data

# Run
run 25ms
