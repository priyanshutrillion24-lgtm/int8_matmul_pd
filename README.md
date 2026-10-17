# RTL-to-GDSII Physical Design and PPA Optimization
## of an INT8 Matrix-Multiply Accelerator

### Project objective

Implement an 8x8 signed INT8 matrix-multiply accelerator in
SystemVerilog and take it through a reproducible RTL-to-GDSII
physical-design flow.

The project will investigate power, performance, and area (PPA),
timing closure, floorplanning, placement, routing, and congestion.

### Planned EDA toolchain

- SystemVerilog
- Verilator for RTL linting and functional simulation
- Yosys for synthesis
- OpenROAD and OpenROAD-flow-scripts for physical implementation
- OpenROAD-integrated timing analysis
- KLayout for layout inspection
- Python and Tcl for automation
- SKY130HD as the initial physical-design platform

### Initial design

- Matrix dimensions: 8x8
- Operand format: signed INT8
- Arithmetic operation: C = A x B
- MAC lanes: 8 parallel lanes
- Accumulator width: signed 32 bits
- Clock target: 10 ns (100 MHz), provisional
- Interface: memory-mapped byte writes and indexed output reads
- Reset: synchronous, active-high

See docs/design_spec.md for the complete initial specification.

### Project stages

1. Define architecture and implement RTL.
2. Verify functionality with a self-checking testbench.
3. Establish timing constraints and synthesis baseline.
4. Explore floorplanning, placement, CTS, and routing.
5. Investigate timing closure and PPA trade-offs.
6. Automate experiments and report generation.
7. Document results and prepare the project for a portfolio.

### Environment validation

The OpenROAD-flow-scripts SKY130HD GCD example completed
the flow through final GDSII generation in the development
environment.

This was an environment smoke test only. Its results are not
PPA results for the INT8 matrix-multiply accelerator.

The accelerator implementation and its own measured PPA
results are still pending.

### Repository structure

- rtl/              SystemVerilog RTL
- tb/               Testbench and test vectors
- constraints/       SDC timing constraints
- flow/              Physical-design flow configuration
- scripts/           Automation and report parsing
- floorplan/         Floorplan experiments
- placement/         Placement experiments
- timing_closure/    Timing optimization case studies
- reports/           Tool reports and logs
- results/           Generated layouts and experiment results
- images/            Screenshots and visualizations
- docs/              Specifications and technical notes

### Reproducibility

Preserve tool versions, flow configuration, raw reports, and
run logs. Record the changes made in every experiment.
Do not claim PPA improvements without measured before-and-after
results from comparable runs.
