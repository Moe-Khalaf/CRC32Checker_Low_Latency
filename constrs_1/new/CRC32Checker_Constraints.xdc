# ==============================================================================
# Clock Constraints
# ==============================================================================

# Primary clock constraint - 200MHz (5ns period)
# Replace 'clk' with your actual clock port name
create_clock -period 5.000 -name sys_clk -waveform {0.000 2.500} [get_ports clk_i]

# Input delays - how long after clock edge your inputs are stable
# Assumes inputs come from external logic with some delay
set_input_delay -clock sys_clk -max 1.000 [get_ports {data_i[*]}]
set_input_delay -clock sys_clk -min 0.500 [get_ports {data_i[*]}]
set_input_delay -clock sys_clk -max 1.000 [get_ports {rst_i}]
set_input_delay -clock sys_clk -min 0.500 [get_ports {rst_i}]
set_input_delay -clock sys_clk -max 1.000 [get_ports {data_valid_i}]
set_input_delay -clock sys_clk -min 0.500 [get_ports {data_valid_i}]
set_input_delay -clock sys_clk -max 1.000 [get_ports {data_last_i}]
set_input_delay -clock sys_clk -min 0.500 [get_ports {data_last_i}]
set_input_delay -clock sys_clk -max 1.000 [get_ports {polynomial_i[*]}]
set_input_delay -clock sys_clk -min 0.500 [get_ports {polynomial_i[*]}]

# Output delays - how long external logic needs data stable after clock
# set_output_delay -clock sys_clk -max 1.000 [get_ports {crc_o[*]}]
# set_output_delay -clock sys_clk -min 0.500 [get_ports {crc_o[*]}]
# set_output_delay -clock sys_clk -max 1.000 [get_ports {crc_valid_o}]
# set_output_delay -clock sys_clk -min 0.500 [get_ports {crc_valid_o}]

# ==============================================================================
# Additional Timing Constraints
# ==============================================================================

# Clock uncertainty (accounts for jitter, skew)
set_clock_uncertainty 0.100 [get_clocks sys_clk]