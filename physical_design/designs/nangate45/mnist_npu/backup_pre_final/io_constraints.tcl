# ============================================
# MNIST NPU - I/O Pin Placement
# Technology: Nangate45
# ============================================

# Control inputs
set_io_pin_constraint \
    -pin_names {clk rst_n start} \
    -region top:*

# Input buffer interface
set_io_pin_constraint \
    -pin_names {input_load_en input_load_addr[*] input_load_data[*]} \
    -region top:*

# Weight SRAM loading interface
set_io_pin_constraint \
    -pin_names {weight_load_en weight_load_addr[*] weight_load_data[*]} \
    -region top:*

# NPU outputs
set_io_pin_constraint \
    -pin_names {digit[*] done} \
    -region bottom:*
