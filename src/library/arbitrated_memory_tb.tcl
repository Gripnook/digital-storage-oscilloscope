proc AddWaves {} {
    # Add waves we're interested in to the Wave window
    add wave -position end sim:/arbitrated_memory_tb/clock
    add wave -position end sim:/arbitrated_memory_tb/reset
    add wave -position end sim:/arbitrated_memory_tb/write_bus_acquire
    add wave -position end sim:/arbitrated_memory_tb/write_address
    add wave -position end sim:/arbitrated_memory_tb/write_en
    add wave -position end sim:/arbitrated_memory_tb/write_data
    add wave -position end sim:/arbitrated_memory_tb/write_bus_grant
    add wave -position end sim:/arbitrated_memory_tb/read_bus_acquire
    add wave -position end sim:/arbitrated_memory_tb/read_address
    add wave -position end sim:/arbitrated_memory_tb/read_bus_grant
    add wave -position end sim:/arbitrated_memory_tb/read_data
    add wave -position end sim:/arbitrated_memory_tb/dut/state
}

vlib work

# Compile components
vcom library/arbitrated_memory.vhd
vcom library/arbitrated_memory_tb.vhd

# Start simulation
vsim -t ns arbitrated_memory_tb

# Generate a clock with 20 ns period
force -deposit clock 0 0 ns, 1 10 ns -repeat 20 ns

# Add the waves
AddWaves

# Run
run 400ns
