
export DESIGN_NAME = npu_top
export DESIGN_NICKNAME = mnist_npu
export PLATFORM = nangate45

# Project Root
NPU_ROOT := $(abspath $(dir $(DESIGN_CONFIG))/../../../..)

# Output Root
export WORK_HOME = $(NPU_ROOT)/physical_design

# RTL
export VERILOG_FILES = $(sort $(filter-out %/fakeram45_512x64.sv, \
    $(wildcard $(NPU_ROOT)/rtl/*.sv)))

# Timing Constraints
export SDC_FILE = $(dir $(DESIGN_CONFIG))/constraint.sdc

# SRAM Macro
export ADDITIONAL_LEFS = $(PLATFORM_DIR)/lef/fakeram45_512x64.lef
export ADDITIONAL_LIBS = $(PLATFORM_DIR)/lib/fakeram45_512x64.lib

# Synthesis
export SYNTH_HDL_FRONTEND = slang
export LEC_CHECK = 0
export SYNTH_MEMORY_MAX_BITS = 8192

# Floorplan
export CORE_UTILIZATION = 60
export CORE_ASPECT_RATIO = 1
export CORE_MARGIN = 2

