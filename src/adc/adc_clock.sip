set_global_assignment -entity "adc_clock" -library "lib_adc_clock" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "adc_clock" -library "lib_adc_clock" -name IP_TOOL_VERSION "15.0"
set_global_assignment -entity "adc_clock" -library "lib_adc_clock" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_adc_clock" -name SPD_FILE [file join $::quartus(sip_path) "adc_clock.spd"]

set_global_assignment -library "lib_adc_clock" -name MISC_FILE [file join $::quartus(sip_path) "adc_clock_sim/adc_clock.vho"]
