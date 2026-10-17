# Design Specification v1.0

## 1. Project

Title: RTL-to-GDSII Physical Design and PPA Optimization
of an INT8 Matrix-Multiply Accelerator

Status: Initial specification frozen on Day 1.
Changes must be documented and justified.

## 2. Functional requirements

Compute the matrix multiplication:

    C[i][j] = sum(A[i][k] * B[k][j]), for k = 0 to 7

Matrix dimensions: 8x8.

Input operands: signed 8-bit two's-complement integers.
Individual product: signed 16-bit result.
Accumulator: signed 32-bit.
Output element: signed 32-bit.

There is no output quantization, saturation, or truncation
in this initial design.

Matrices A and B each contain 64 elements. Matrix C contains
64 output elements.

All matrix elements use row-major ordering.

## 3. Datapath architecture

Use eight parallel signed multiply-accumulate (MAC) lanes.

Each lane computes one output column for the currently
selected row of A.

For output row i and computation index k:

- Supply A[i][k] to all eight lanes.
- Supply B[k][j] to lane j, for j = 0 to 7.
- Each lane multiplies its signed 8-bit operands.
- Each lane accumulates the product in a signed 32-bit register.
- After eight products, store the eight completed results
  in the corresponding row of matrix C.

Reuse the eight lanes for all eight output rows.

The output matrix is stored in registers and remains available
until overwritten or reset.

The intended computation consists of 8 rows x 8 products,
or 64 MAC computation cycles, without stalls. Controller
overhead and exact done timing will be verified in simulation.

## 4. Top-level interface

Clock:
- clk: one synchronous clock domain.

Reset:
- rst: synchronous, active-high.

Input write interface:
- wr_en: write enable.
- wr_addr: 7-bit input byte address, from 0 to 127.
- wr_data: 8-bit write data.

Input address map:
- Addresses 0 to 63: matrix A.
- Addresses 64 to 127: matrix B.

For a matrix element X[i][j], its row-major element index
is 8*i + j.

For B, the byte address is 64 + 8*i + j.
For A, the byte address is 8*i + j.

Control:
- start: request a computation while idle.
- busy: high while computation is active.
- done: one-cycle completion pulse.

Output read interface:
- rd_addr: 6-bit output element address, from 0 to 63.
- rd_data: signed 32-bit output value represented on a 32-bit
  signal.
- Output selection is combinational.
- Output address maps to C[row][column] in row-major order.

Input writes are ignored while busy. Start requests received
while busy are ignored. Software or the testbench must write
all 128 input bytes before starting a computation.

Exact reset values, FSM transitions, and cycle-by-cycle
control timing will be specified during architecture design
and verified by simulation.

## 5. Timing assumptions

Initial target clock period: 10 ns.
Equivalent frequency: 100 MHz.

This is a provisional timing constraint, not a measured or
guaranteed achievable frequency.

Detailed SDC constraints, including clock uncertainty and
input/output delays, will be developed in a later stage.

## 6. Physical-design assumptions

Initial physical-design platform: SKY130HD.

Planned flow:
RTL -> synthesis -> floorplanning -> power planning ->
placement -> clock-tree synthesis -> routing ->
parasitic extraction -> timing analysis ->
physical verification -> GDSII.

The actual availability of each stage and verification capability
will be confirmed against the installed flow.

## 7. Verification requirements

The self-checking testbench will:

- Reset the accelerator.
- Load all 128 input bytes.
- Apply start and monitor busy/done.
- Read and compare all 64 outputs against a software reference.
- Test zero operands and positive/negative signed operands.
- Test negative products and accumulation behavior.
- Test boundary operand values and multiple input matrices.
- Check reset and control behavior.

No measured latency or correctness result is claimed until
simulation has been run.

## 8. Physical-design metrics

Collect where supported:

- Synthesized and physical cell area.
- Cell counts and buffer counts.
- Clock period, worst negative slack (WNS), and total negative
  slack (TNS).
- Setup and hold violations.
- Clock insertion delay and skew.
- Wirelength and half-perimeter wirelength (HPWL).
- Congestion and routing overflow.
- Power estimates, with methodology and limitations recorded.
- DRC/LVS or other supported physical-verification results.

All optimization claims must be based on saved tool reports.

## 9. Planned optimization studies

Extension 1: Timing closure.
Identify a critical path, investigate its root cause, apply
controlled fixes, and compare before/after timing.

Extension 2: Floorplan and congestion optimization.
Compare multiple floorplan or placement configurations while
recording area, timing, wirelength, and congestion.

Automation:
Use Python/Tcl to reproduce parameter sweeps and summarize
measured results.

## 10. Scope boundaries

The initial project focuses on the accelerator RTL and its
physical implementation.

Processor integration, AXI integration, external-memory
controllers, quantization, and production sign-off on a
commercial foundry process are outside the initial scope.

## 11. Baseline status

- Project directory created.
- Git repository initialized; branch renamed to main.
- Verilator and Yosys detected in the host environment.
- Docker-based ORFS environment launched successfully.
- SKY130HD GCD reference example completed through final
  GDSII generation.
- Accelerator RTL and functional verification remain pending.
