# 5-stage-Pipelined-RISCV-Core
A fully functional 5-stage pipelined processor implementing a RISC-style architecture with complete support for R, I, S, B, and J-type instructions. This design focuses on performance optimization through hazard detection, data forwarding, and pipeline stall mechanisms, closely mirroring real-world CPU pipeline behavior.

- ISA: RV32I (FENCE / ECALL / EBREAK execute as NOPs, no CSRs or traps)
- Branches and jumps resolve in ID; 2-bit saturating-counter predictor with a 32-entry BTB
- Synchronous (SRAM-style) instruction and data memory ports; memories are outside the core

## Repository layout

```
rtl/core/          synthesizable core (top: riscv_core), core.f filelist
verif/tb/          testbench top (commit logger, tohost, perf counters) and memory model
verif/sw/common/   crt0, linker script, assembly test macros
verif/tests/asm/   directed self-checking tests
verif/scripts/     bin2hex, Spike trace comparison
syn/ pnr/ sta/     backend flow (SKY130), to come
build/             all generated output (git-ignored)
```

## Requirements

- `riscv64-unknown-elf-gcc` / binutils (rv32i multilib)
- [Spike](https://github.com/riscv-software-src/riscv-isa-sim)
- Cadence Xcelium (`xrun`), or Icarus Verilog with `SIM=icarus`
- Python 3

## Running

```
make sim     TEST=hazards        # RTL simulation only
make compare TEST=hazards        # RTL + Spike + commit-trace diff
make regress                     # every test in verif/tests/asm
make compare TEST=mem WAVES=1    # also dump build/tests/mem/waves.vcd
```

Each test's output lands in `build/tests/<test>/`: `prog.dis` (disassembly), `sim.log`,
`rtl_trace.log`, `spike.log`. The simulation prints `[STATS]` lines (cycles, CPI, branch
and mispredict counts, stall counts) and `[tb] PASS` / `[tb] FAIL (code N)`; the code is
the number of the failing check in the test source.
