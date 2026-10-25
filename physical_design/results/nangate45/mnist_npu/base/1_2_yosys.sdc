
# ============================================================
# MNIST-NPU Timing Constraints
# Platform : Nangate45
# Top      : npu_top
# ============================================================

# 1. Clock Definition
set CLOCK_PERIOD 6.0

create_clock -name MAIN_CLOCK \
    -period $CLOCK_PERIOD [get_ports clk]

create_clock -name VIRTUAL_CLOCK \
    -period $CLOCK_PERIOD


# 2. Clock Latency
set_clock_latency 0.210 [get_clocks MAIN_CLOCK]
set_clock_latency 0.210 [get_clocks VIRTUAL_CLOCK]


# 3. Clock Uncertainty
set_clock_uncertainty -setup 0.4 \
    [get_clocks {MAIN_CLOCK VIRTUAL_CLOCK}]

set_clock_uncertainty -hold 0.2 \
    [get_clocks {MAIN_CLOCK VIRTUAL_CLOCK}]


# 4. I/O Timing
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

set IO_DELAY [expr {$CLOCK_PERIOD * 0.20}]

set_input_delay -clock VIRTUAL_CLOCK \
    -max $IO_DELAY $DATA_INPUTS

set_input_delay -clock VIRTUAL_CLOCK \
    -min 0.0 $DATA_INPUTS

set_output_delay -clock VIRTUAL_CLOCK \
    -max $IO_DELAY $DATA_OUTPUTS

set_output_delay -clock VIRTUAL_CLOCK \
    -min 0.0 $DATA_OUTPUTS


# 5. Input Driving Cell
set_driving_cell -lib_cell DFF_X1 -pin Q \
    $DATA_INPUTS


# 6. Output Load
set INV_PIN [get_lib_pins */INV_X1/A]
set INV_CAP [get_property $INV_PIN capacitance]

set_load [expr {3.0 * $INV_CAP}] \
    $DATA_OUTPUTS


# 7. Maximum Fanout
set_max_fanout 16 [current_design]

