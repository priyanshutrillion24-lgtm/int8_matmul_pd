# Day 2: Accelerator Architecture

## 1. Functional operation

The accelerator computes C = A x B, where A, B and C are
8x8 matrices. A and B use signed 8-bit elements. C stores
signed 32-bit results.

C[i][j] = sum(A[i][k] * B[k][j]), for k = 0..7.

## 2. Datapath

- 64 signed 8-bit storage elements for A.
- 64 signed 8-bit storage elements for B.
- Eight parallel signed MAC lanes.
- Each lane has a signed 8x8 multiplier and a signed 32-bit
  accumulator.
- Eight accumulators are reused for all eight output rows.
- The output matrix contains 64 signed 32-bit registers.
- Output reads are combinational through rd_addr.

## 3. Indexing

Output row index: row_idx, 3 bits.
Reduction index: k_idx, 3 bits.
MAC lane index: j, from 0 to 7.

A index = 8*row_idx + k_idx.
B index for lane j = 8*k_idx + j.
C index for lane j = 8*row_idx + j.

Input write address 0..63 selects A.
Input write address 64..127 selects B.
The lower six address bits select an element in either matrix.

## 4. MAC operation

Each product is signed 16-bit.

Sign-extend the product to 32 bits before accumulation.

At k_idx == 0:
    next_accumulator = sign_extended_product

At k_idx > 0:
    next_accumulator = accumulator + sign_extended_product

At k_idx == 7:
    write next_accumulator to the corresponding C element.

Use next_accumulator so the final product is included in C.

## 5. Controller FSM

States: IDLE, COMPUTE, DONE.

IDLE:
- busy = 0, done = 0.
- Accept start and initialize row_idx and k_idx to zero.

COMPUTE:
- busy = 1, done = 0.
- Process one product per lane per clock.
- Advance k_idx from 0 to 7.
- At k_idx == 7, write eight C elements for the current row.
- Advance row_idx and reset k_idx for the next row.
- After row 7 and k_idx 7, enter DONE.

DONE:
- busy = 0, done = 1.
- Return to IDLE on the following clock.
- done is a one-cycle pulse.

Target computation: 64 MAC cycles, excluding the start
acceptance edge and completion indication.

## 6. Reset and validity

Reset is synchronous, active-high.

Reset the FSM and row/k indices. Do not reset A, B or C
storage arrays. Accumulators are overwritten at k_idx == 0.

All 128 input bytes must be loaded before start.
Outputs are valid only after a complete operation asserts done.
Reset during computation aborts the current operation.

Writes are ignored while COMPUTE is active. Start requests
are accepted only in IDLE.

## 7. Pipeline strategy

Initial baseline has no extra pipeline stages.
Multiplication and accumulation occur in one MAC cycle.
The provisional clock period is 10 ns (100 MHz).

The timing target is not guaranteed. Use reports to determine
whether optimization or pipelining is needed.

## 8. Candidate timing paths

1. A/B storage -> operand mux -> multiplier -> adder -> accumulator.
2. Accumulator -> adder -> accumulator feedback.
3. Accumulator -> final sum -> C output register.
4. Input ports -> write decode -> A/B storage registers.
5. C storage or rd_addr -> output mux -> rd_data.
6. FSM/index registers -> control logic and datapath registers.

These are hypotheses, not measured critical paths.

## 9. Day 2 deliverables

- Architecture and datapath defined.
- Three-state FSM specified.
- Indexing and arithmetic behavior documented.
- Reset, validity and pipeline assumptions documented.
- Candidate timing endpoints identified.

Functional verification and measured timing results remain
pending.
