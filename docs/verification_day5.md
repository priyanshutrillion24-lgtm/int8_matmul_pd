# Day 5: Functional Verification

## Environment
- Simulator: Verilator 5.032
- Testbench: tb/tb_int8_matmul_accel.sv
- DUT: int8_matmul_accel

## Test cases
1. Directed boundary-value matrix inputs.
2. Deterministic pseudorandom signed INT8 inputs.
3. Zero-valued input matrices.

## Checks
- Compared all 64 output elements against a software reference.
- Checked that each operation completed in 64 MAC cycles.
- Checked that busy was low when done was asserted.
- Checked that done deasserted one clock later.
- Ran multiple operations without resetting between each test,
  exercising accumulator overwrite behavior.

## Recorded simulation result
The initial simulation reported:
- 3 matrix tests passed.
- 192 output elements checked.
- 64 MAC cycles per operation.
- Zero reported failures.

The waveform-enabled run must also complete successfully
before the Day 5 checkpoint is finalized.

## Limitations
These directed tests do not prove correctness for every possible
input or every control sequence. Reset during computation,
writes while busy, and start requests while busy require
additional dedicated tests. The simulation is not a formal proof.
