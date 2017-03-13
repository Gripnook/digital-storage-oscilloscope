proc AddWaves {} {
    # Add waves we're interested in to the Wave window
    add wave -position end sim:/vga_tb/clock
    add wave -position end sim:/vga_tb/reset
    add wave -position end sim:/vga_tb/hsync
    add wave -position end sim:/vga_tb/vsync
    add wave -position end sim:/vga_tb/rgb
    add wave -position end sim:/vga_tb/dut/row
    add wave -position end sim:/vga_tb/dut/column
    add wave -position end sim:/vga_tb/dut/rom_address
    add wave -position end sim:/vga_tb/dut/background_rgb
    add wave -position end sim:/vga_tb/dut/display_data
    add wave -position end sim:/vga_tb/dut/blank_n
}

vlib work

# Compile components
vcom vga_timing_generator.vhd
vcom memory_arbiter.vhd
vcom vga.vhd
vcom vga_tb.vhd

# Start simulation
vsim -t ns vga_tb

# Generate a clock with 20 ns period
force -deposit clock 0 0 ns, 1 10 ns -repeat 20 ns

# Add the waves
AddWaves

# Load test signal into memory
run 10ns
mem load -infile test_signal.txt -format bin -filldata 0 /vga_tb/rom/mem/MEMORY/mem_data

# Run
run 20ms
