proc AddWaves {} {
    # Add waves we're interested in to the Wave window
    add wave -position end sim:/bcd_converter_tb/clock
    add wave -position end sim:/bcd_converter_tb/reset
    add wave -position end -radix unsigned sim:/bcd_converter_tb/binary
    add wave -position end sim:/bcd_converter_tb/start
    add wave -position end -radix hexadecimal sim:/bcd_converter_tb/bcd
    add wave -position end sim:/bcd_converter_tb/done
    add wave -position end sim:/bcd_converter_tb/dut/state
    add wave -position end -radix hexadecimal sim:/bcd_converter_tb/dut/bcd_internal
}

vlib work

# Compile components
vcom library/bcd_converter.vhd
vcom library/bcd_converter_tb.vhd

# Start simulation
vsim -t ns bcd_converter_tb

# Generate a clock with 20 ns period
force -deposit clock 0 0 ns, 1 10 ns -repeat 20 ns

# Add the waves
AddWaves

# Run
run 5us
