# ============================================================
# MNIST-NPU Timing Constraints
# Platform : Nangate45
# Top      : npu_top
# ============================================================

# 1. Clock
create_clock -name MAIN_CLOCK \
    -period 5.0 [get_ports clk]

create_clock -name VIRTUAL_CLOCK \
    -period 5.0

# 2. Clock Uncertainty
set_clock_uncertainty -setup 0.2 \
    [get_clocks {MAIN_CLOCK VIRTUAL_CLOCK}]

set_clock_uncertainty -hold 0.1 \
    [get_clocks {MAIN_CLOCK VIRTUAL_CLOCK}]

# 3. I/O Ports
set DATA_INPUTS [get_ports {
    start
    weight_load_en
    weight_load_addr*
    weight_load_data*
    input_load_en
    input_load_addr*
    input_load_data*
}]

set DATA_OUTPUTS [all_outputs]

# 4. Input Delay
set_input_delay -clock VIRTUAL_CLOCK \
    -max 1.0 $DATA_INPUTS

set_input_delay -clock VIRTUAL_CLOCK \
    -min 0.0 $DATA_INPUTS

# 5. Output Delay
set_output_delay -clock VIRTUAL_CLOCK \
    -max 1.0 $DATA_OUTPUTS

set_output_delay -clock VIRTUAL_CLOCK \
    -min 0.0 $DATA_OUTPUTS

# 6. Input Driving Cell
set_driving_cell -lib_cell DFF_X1 -pin Q \
    $DATA_INPUTS

# 7. Output Load
set INV_PIN [get_lib_pins */INV_X1/A]
set INV_CAP [get_property $INV_PIN capacitance]

set_load [expr {3.0 * $INV_CAP}] \
    $DATA_OUTPUTS

