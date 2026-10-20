# Day 7: Synthesis Baseline

## Design and platform
- Top module: int8_matmul_accel
- Technology: SKY130HD
- Flow: OpenROAD-flow-scripts
- Target clock period: 10 ns (100 MHz)
- Timing constraints: constraints/int8_matmul.sdc

## Synthesis results
- Mapped standard-cell count: 8,584
- Mapped cell area: 155,226.3744 um^2
- Sequential area: 100,176.0768 um^2
- Sequential area fraction: 64.54%
- Calculated combinational area: 55,050.2976 um^2
- Calculated combinational area fraction: 35.46%
- Enabled flip-flops (edfxtp_1): 3,328
- Other flip-flops (dfxtp_1): 12
- Full-adder cells (fa_1): 456
- Half-adder cells (ha_1): 477
- 4:1 mux cells (mux4_2): 927
- Yosys synthesis check: 0 problems reported

## Interpretation
The 3,328 enabled flip-flops match the expected storage bits:
- Matrix A: 512 bits
- Matrix B: 512 bits
- Matrix C: 2,048 bits
- Eight 32-bit accumulators: 256 bits

The mapped design contains no retained memories at this stage.
The arrays have been mapped into flip-flops and combinational logic.

## Warning to investigate
OpenROAD reported:
"master sky130_ef_sc_hd__decap_12 has signal pins but no liberty cell"

The flow continued and generated the synthesis database.
This warning is recorded for later investigation.

## Limitations
These are synthesis statistics. They are not final placed area,
routed area, post-route timing, or power results.

No claim that the 10 ns clock target is met is made here.
Pre-layout STA and critical-path analysis remain pending.

## Evidence
- reports/day7/synth_stat.txt
- reports/day7/synth_check.txt
- results/day7/1_2_yosys.v
- results/day7/1_synth.odb
- logs/day7/1_2_yosys.log
- logs/day7/1_synth.log
