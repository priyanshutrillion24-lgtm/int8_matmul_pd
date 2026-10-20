# Day 6: Initial Timing Constraints

## Timing target
- Clock: core_clock
- Clock port: clk
- Clock period: 10 ns
- Target frequency: 100 MHz
- Setup uncertainty: 0.2 ns
- Hold uncertainty: 0.1 ns
- Clock transition assumption: 0.1 ns

## I/O assumptions
- Maximum input delay: 2.0 ns
- Minimum input delay: 0.2 ns
- Maximum output delay: 2.0 ns
- Minimum output delay: 0.2 ns
- Input transition assumption: 0.1 ns

These values are provisional assumptions for a standalone
accelerator. They are not derived from external device timing
specifications.

## Design-rule assumptions
- Maximum transition: 0.5 ns
- Maximum fanout: 8

Confirm compatibility with the selected technology library
and the OpenROAD flow before interpreting timing results.

## Status
- Initial SDC created.
- SDC syntax and port matching must be validated in the
  configured physical-design flow.
- No synthesis or STA timing result is claimed yet.
