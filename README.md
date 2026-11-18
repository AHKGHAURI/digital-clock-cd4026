# 24-Hour Digital Clock — CD4026 Hardware & Verilog

A six-digit **HH:MM:SS** digital clock, built three ways for a Digital Logic Design (DLD) project at NUST:

1. **Schematic simulation** in Proteus, using CD4026 decade counters and an NE555 timer.
2. **Physical hardware**, built from the same circuit.
3. **Verilog re-implementation** of the same counter chain, simulated in ModelSim and Icarus Verilog.

The goal was to see how one design maps from discrete ICs to an HDL description — each Verilog module corresponds to a part of the hardware circuit.

## How the clock works

```
 NE555 (1 Hz)        CD4026          CD4026          CD4026          CD4026          CD4026          CD4026
 ───────────►  [ sec units ] ─► [ sec tens ] ─► [ min units ] ─► [ min tens ] ─► [ hr units ] ─► [ hr tens ]
                  0–9            0–5              0–9             0–5             0–9 ┐          0–2 ┐
                                                                                      └── reset at 24 ┘
```

- The **NE555** in astable mode produces a 1 Hz clock.
- Each **CD4026** counts 0–9, drives its own common-cathode 7-segment display, and its carry-out clocks the next digit.
- **7411 AND gates** detect 6 on the tens digits (to roll seconds and minutes over at 60) and 24 on the hours (to reset to 00).

## Verilog implementation

| Module | Hardware equivalent | Function |
|---|---|---|
| [`clk_divider`](rtl/clk_divider.v) | NE555 astable | Divides the board clock (default 50 MHz) to a one-cycle 1 Hz tick |
| [`bcd_counter`](rtl/bcd_counter.v) | CD4026 counter | Parameterised BCD counter (`MAX`) with a carry pulse for the next stage |
| [`seg7_decoder`](rtl/seg7_decoder.v) | CD4026 internal decoder | BCD → 7-segment, common cathode, `{a,b,c,d,e,f,g}` |
| [`digital_clock`](rtl/digital_clock.v) | Full circuit | Top level: six counters, 24-hour reset logic, six decoders |

The design is fully synchronous: every counter runs on the system clock and advances when its `tick` (the previous stage's carry) is high, instead of rippling clocks between chips as the hardware does.

### Running the simulation

With [Icarus Verilog](https://steveicarus.github.io/iverilog/):

```bash
iverilog -o clock_tb sim/digital_clock_tb.v rtl/*.v
vvp clock_tb
```

The testbench sets `CLK_FREQ = 10` so ten clock cycles equal one simulated second, runs 90 seconds (covering a minute rollover), prints the time and segment patterns, and checks that no digit goes out of range. It also writes `clock_tb.vcd` for viewing in GTKWave.

In **ModelSim**, add the files in `rtl/` and `sim/` to a project, compile, and simulate `digital_clock_tb`.

To target an FPGA board, set `CLK_FREQ` on `digital_clock` to the board's oscillator frequency. Invert the segment outputs (`~seg`) for common-anode displays.

## Repository structure

```
rtl/        Verilog design modules
sim/        Testbench
proteus/    Proteus 8 schematic of the CD4026 hardware circuit
```

## Hardware

The circuit was also assembled as physical hardware. The wiring is a first attempt; a cleaner version would move it onto a PCB.

## Credits

- The Proteus schematic is adapted from an existing CD4026 digital-clock circuit shared online, and modified for this project.
- Group project for the Digital Logic Design course, NUST.

### Team

- [Ahmad Hassan](https://github.com/AHKGHAURI)
- M Haseeb
- Abdur Rehman
- Sultan Ali
