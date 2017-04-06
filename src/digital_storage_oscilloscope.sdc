# Constrain clock port with a 20-ns requirement

create_clock -period 20 [get_ports clock]

# Automatically apply a generate clock on the output of phase-locked loops (PLLs)
# This command can be safely left in the SDC even if no PLLs exist in the design

derive_pll_clocks

# Constrain the reset signal

set_false_path -from [get_ports reset_n]

# Constrain the pixel clock

set_false_path -from clock -to [get_ports pixel_clock]

# Constrain the ADC clock

set_false_path -from adc_clk_pll|adc_clock_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk -to [get_ports adc_sclk]

# Constrain the input I/O path

set_input_delay -clock clock -max 2 [get_ports timebase*]
set_input_delay -add_delay -clock clock -min 0 [get_ports timebase*]

set_input_delay -clock clock -max 3 [get_ports interpolation_enable]
set_input_delay -add_delay -clock clock -min 2 [get_ports interpolation_enable]

set_input_delay -clock clock -max 2 [get_ports trigger*]
set_input_delay -add_delay -clock clock -min 0 [get_ports trigger*]

set_input_delay -clock adc_clk_pll|adc_clock_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk -max 2 [get_ports adc_dout]
set_input_delay -add_delay -clock adc_clk_pll|adc_clock_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk -min 0 [get_ports adc_dout]

# Constrain the output I/O path

set_output_delay -clock clock -max 2 [get_ports *sync]
set_output_delay -add_delay -clock clock -min 0 [get_ports *sync]

set_output_delay -clock clock -max 2 [get_ports r[*]]
set_output_delay -add_delay -clock clock -min 0 [get_ports r[*]]

set_output_delay -clock clock -max 2 [get_ports g[*]]
set_output_delay -add_delay -clock clock -min 0 [get_ports g[*]]

set_output_delay -clock clock -max 2 [get_ports b[*]]
set_output_delay -add_delay -clock clock -min 0 [get_ports b[*]]

set_output_delay -clock adc_clk_pll|adc_clock_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk -clock_fall -max 2 [get_ports adc_din]
set_output_delay -add_delay -clock adc_clk_pll|adc_clock_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk -clock_fall -min 0 [get_ports adc_din]

set_output_delay -clock adc_clk_pll|adc_clock_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk -max 2 [get_ports adc_convst]
set_output_delay -add_delay -clock adc_clk_pll|adc_clock_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk -min 0 [get_ports adc_convst]
