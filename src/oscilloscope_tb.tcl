proc AddWaves {} {
    # Add waves we're interested in to the Wave window
    add wave -position end sim:/oscilloscope_tb/clock
    add wave -position end sim:/oscilloscope_tb/reset_n
    add wave -position end sim:/oscilloscope_tb/hsync
    add wave -position end sim:/oscilloscope_tb/vsync
    add wave -position end sim:/oscilloscope_tb/r
    add wave -position end sim:/oscilloscope_tb/g
    add wave -position end sim:/oscilloscope_tb/b
    add wave -position end sim:/oscilloscope_tb/dut/data_acquisition_subsystem/trigger
    add wave -position end sim:/oscilloscope_tb/dut/data_acquisition_subsystem/adc_en
    add wave -position end sim:/oscilloscope_tb/dut/data_acquisition_subsystem/adc_data
    add wave -position end sim:/oscilloscope_tb/dut/data_acquisition_subsystem/adc_address
    add wave -position end sim:/oscilloscope_tb/dut/data_acquisition_subsystem/ram_address
    add wave -position end sim:/oscilloscope_tb/dut/data_acquisition_subsystem/address
    add wave -position end sim:/oscilloscope_tb/dut/data_acquisition_subsystem/trigger_address
    add wave -position end sim:/oscilloscope_tb/dut/data_acquisition_subsystem/trigger_start_address
    add wave -position end sim:/oscilloscope_tb/dut/data_acquisition_subsystem/trigger_end_address
    add wave -position end sim:/oscilloscope_tb/dut/data_acquisition_subsystem/data_acquired
    add wave -position end sim:/oscilloscope_tb/dut/data_acquisition_subsystem/data_written
    add wave -position end sim:/oscilloscope_tb/dut/data_acquisition_subsystem/state
    add wave -position end sim:/oscilloscope_tb/dut/data_acquisition_subsystem/write_en
    add wave -position end sim:/oscilloscope_tb/dut/data_acquisition_subsystem/write_data
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
