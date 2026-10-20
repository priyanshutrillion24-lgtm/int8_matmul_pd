# INT8 Matrix-Multiply Accelerator
# Day 7: Initial synthesis baseline

export PLATFORM = sky130hd

export DESIGN_NAME = int8_matmul_accel
export DESIGN_NICKNAME = int8_matmul_accel

export VERILOG_FILES = \
    /workspace/int8_matmul_pd/rtl/mac_lane.sv \
    /workspace/int8_matmul_pd/rtl/mac_array.sv \
    /workspace/int8_matmul_pd/rtl/matmul_controller.sv \
    /workspace/int8_matmul_pd/rtl/int8_matmul_accel.sv

export SDC_FILE = /workspace/int8_matmul_pd/constraints/int8_matmul.sdc

# Initial implementation settings
export CORE_UTILIZATION = 40
export PLACE_DENSITY = 0.60
export TNS_END_PERCENT = 100
