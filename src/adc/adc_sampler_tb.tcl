proc AddWaves {} {
    # Add waves we're interested in to the Wave window
    add wave -position end sim:/adc_sampler_tb/clock
    add wave -position end sim:/adc_sampler_tb/reset
    add wave -position end sim:/adc_sampler_tb/adc_sclk
    add wave -position end sim:/adc_sampler_tb/adc_din
    add wave -position end sim:/adc_sampler_tb/adc_dout
    add wave -position end sim:/adc_sampler_tb/adc_convst
    add wave -position end sim:/adc_sampler_tb/adc_sample
    add wave -position end sim:/adc_sampler_tb/adc_data
}

vlib work

# Compile components
vcom adc/adc_sampler.vhd
vcom adc/adc_sampler_tb.vhd

# Start simulation
vsim -t ps adc_sampler_tb

# Generate a clock with 25 ns period
force -deposit clock 0 0 ns, 1 12.5 ns -repeat 25 ns

# Add the waves
AddWaves

# Run
run 5us
