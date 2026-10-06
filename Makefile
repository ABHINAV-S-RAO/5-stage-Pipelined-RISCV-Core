# Top-level flow for the 5-stage RV32I core.
#
#   make sim     TEST=<name>   build the test program and run RTL simulation
#   make spike   TEST=<name>   run the same program on Spike (golden model)
#   make compare TEST=<name>   sim + spike + commit-trace diff
#   make regress               compare every test in verif/tests/asm and verif/tests/c
#   make bp_compare            run everything with BP=none and BP=dm, print the CPI table
#   make syn SKY130_LIB=<.lib> [CLK_PERIOD=10] [IO_PCT=0.2]   Genus synthesis (SKY130)
#   make golden                rebuild verif/golden/ (needs RISC-V gcc + Spike)
#   make clean
#
# Machines without a RISC-V toolchain (e.g. the Xcelium server) automatically
# use the committed images and Spike logs in verif/golden/ (PREBUILT=1).
#
# Options:  SIM=xcelium|icarus   BP=dm|none   WAVES=1   MAX_CYCLES=<n>
# Every tool is a variable, e.g.  make compare SPIKE=/path/to/spike RISCV_PREFIX=riscv32-unknown-elf-

ROOT  := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
BUILD ?= $(ROOT)/build

TEST       ?= smoke
SIM        ?= xcelium
BP         ?= dm
WAVES      ?= 0
MAX_CYCLES ?= 10000000

MEM_BASE := 0x80000000
MEM_SIZE := 0x100000

# ---- tools -----------------------------------------------------------------
RISCV_PREFIX ?= riscv64-unknown-elf-
CC      := $(RISCV_PREFIX)gcc
OBJCOPY := $(RISCV_PREFIX)objcopy
OBJDUMP := $(RISCV_PREFIX)objdump
NM      := $(RISCV_PREFIX)nm
SPIKE   ?= spike
PYTHON  ?= python3
XRUN    ?= xrun
GENUS   ?= genus

# ---- synthesis -------------------------------------------------------------
SKY130_LIB ?=
CLK_PERIOD ?= 10
IO_PCT     ?= 0.2
IVERILOG ?= iverilog
VVP     ?= vvp

# ---- sources ---------------------------------------------------------------
SW_COMMON := $(ROOT)/verif/sw/common
RTL_SRCS  := $(sort $(wildcard $(ROOT)/rtl/core/*.v))
TB_SRCS   := $(ROOT)/verif/tb/tb_memory.sv $(ROOT)/verif/tb/tb_top.sv
ASM_TESTS := $(sort $(basename $(notdir $(wildcard $(ROOT)/verif/tests/asm/*.S))))
C_TESTS   := $(sort $(basename $(notdir $(wildcard $(ROOT)/verif/tests/c/*.c))))
TESTS     ?= $(ASM_TESTS) $(C_TESTS)

CFLAGS  := -march=rv32i -mabi=ilp32 -O2 -static -nostdlib -nostartfiles -ffreestanding \
           -fno-tree-loop-distribute-patterns \
           -I$(SW_COMMON) $(RV_CFLAGS_EXTRA)
LDFLAGS := -T$(SW_COMMON)/link.ld -lgcc

T      := $(BUILD)/tests/$(TEST)
RUN    := $(BUILD)/run_$(BP)/$(TEST)
GOLDEN := $(ROOT)/verif/golden

# Where the program image and Spike log come from: built here, or prebuilt.
PREBUILT ?= $(if $(shell command -v $(CC) 2>/dev/null),0,1)
ifeq ($(PREBUILT),1)
SRC    := $(GOLDEN)/$(TEST)
SW_DEP :=
ISS_DEP :=
else
SRC    := $(T)
SW_DEP := sw
ISS_DEP := spike
endif

# Branch predictor configuration: dm = 2-bit direct-mapped (default), none = always not-taken
ifeq ($(BP),none)
SIM_DEFS_XRUN := -define NO_BP
SIM_DEFS_IVL  := -DNO_BP
else ifeq ($(BP),dm)
SIM_DEFS_XRUN :=
SIM_DEFS_IVL  :=
else
$(error BP must be dm or none)
endif

PLUSARGS = +hex=$(SRC)/prog.hex +tohost=$$(cat $(SRC)/tohost.addr) +trace=$(RUN)/rtl_trace.log \
           +max_cycles=$(MAX_CYCLES) $(if $(filter 1,$(WAVES)),+vcd)

.PHONY: sw sim spike compare regress bp_compare syn golden clean
.SECONDARY:

# ---- software --------------------------------------------------------------
sw: $(T)/prog.hex $(T)/tohost.addr

$(BUILD)/tests/%/prog.elf: $(ROOT)/verif/tests/asm/%.S $(SW_COMMON)/crt0.S $(SW_COMMON)/link.ld $(SW_COMMON)/test_macros.h
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) $(SW_COMMON)/crt0.S $< -o $@ $(LDFLAGS)
	$(OBJDUMP) -d $@ > $(@D)/prog.dis

$(BUILD)/tests/%/prog.elf: $(ROOT)/verif/tests/c/%.c $(SW_COMMON)/crt0.S $(SW_COMMON)/link.ld
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) $(SW_COMMON)/crt0.S $< -o $@ $(LDFLAGS)
	$(OBJDUMP) -d $@ > $(@D)/prog.dis

$(BUILD)/tests/%/prog.hex: $(BUILD)/tests/%/prog.elf
	$(OBJCOPY) -O binary $< $(@D)/prog.bin
	$(PYTHON) $(ROOT)/verif/scripts/bin2hex.py $(@D)/prog.bin $@

$(BUILD)/tests/%/tohost.addr: $(BUILD)/tests/%/prog.elf
	$(NM) $< | awk '$$3 == "tohost" { print $$1 }' > $@

# ---- golden model ----------------------------------------------------------
spike: $(T)/spike.log

$(BUILD)/tests/%/spike.log: $(BUILD)/tests/%/prog.elf
	-$(SPIKE) --isa=rv32i_zicsr -m$(MEM_BASE):$(MEM_SIZE) --log-commits $< 2> $@

# ---- RTL simulation --------------------------------------------------------
sim: $(SW_DEP)
	@mkdir -p $(RUN)
ifeq ($(SIM),xcelium)
	cd $(RUN) && $(XRUN) -64bit -sv -timescale 1ns/1ps -access +r -top tb_top $(SIM_DEFS_XRUN) \
	    -xmlibdirname $(BUILD)/xcelium_$(BP).d -l xrun.log \
	    $(RTL_SRCS) $(TB_SRCS) $(PLUSARGS) | tee sim.log
else ifeq ($(SIM),icarus)
	@mkdir -p $(BUILD)/icarus_$(BP)
	$(IVERILOG) -g2012 $(IVERILOG_FLAGS_EXTRA) $(SIM_DEFS_IVL) -s tb_top -o $(BUILD)/icarus_$(BP)/tb.vvp $(RTL_SRCS) $(TB_SRCS)
	cd $(RUN) && $(VVP) $(VVP_FLAGS_EXTRA) $(BUILD)/icarus_$(BP)/tb.vvp $(PLUSARGS) | tee sim.log
else
	$(error SIM must be xcelium or icarus)
endif

# ---- comparison ------------------------------------------------------------
compare: sim $(ISS_DEP)
	$(PYTHON) $(ROOT)/verif/scripts/spike_diff.py $(RUN)/rtl_trace.log $(SRC)/spike.log \
	    --tohost $$(cat $(SRC)/tohost.addr) --base $(MEM_BASE) --sim-log $(RUN)/sim.log

regress:
	@mkdir -p $(BUILD)
	@fails=0; for t in $(TESTS); do \
	    if $(MAKE) --no-print-directory compare TEST=$$t > $(BUILD)/regress_$(BP)_$$t.log 2>&1; then \
	        echo "PASS  $$t  [BP=$(BP)]"; \
	    else \
	        echo "FAIL  $$t  [BP=$(BP)]  (log: build/regress_$(BP)_$$t.log)"; fails=$$((fails + 1)); \
	    fi; \
	done; \
	echo "$$fails failing test(s)"; [ $$fails -eq 0 ]

bp_compare:
	-@$(MAKE) --no-print-directory regress BP=none
	-@$(MAKE) --no-print-directory regress BP=dm
	@$(PYTHON) $(ROOT)/verif/scripts/bp_report.py $(BUILD)/run_none $(BUILD)/run_dm $(TESTS)

syn:
ifeq ($(SKY130_LIB),)
	$(error set SKY130_LIB=/path/to/sky130_fd_sc_hd__tt_025C_1v80.lib)
endif
	@mkdir -p $(BUILD)/syn
	cd $(BUILD)/syn && ROOT=$(ROOT) SKY130_LIB=$(SKY130_LIB) CLK_PERIOD=$(CLK_PERIOD) IO_PCT=$(IO_PCT) \
	    $(GENUS) -files $(ROOT)/syn/scripts/genus.tcl -log genus

golden:
	@for t in $(TESTS); do \
	    $(MAKE) --no-print-directory PREBUILT=0 TEST=$$t sw spike || exit 1; \
	    mkdir -p $(GOLDEN)/$$t; \
	    cp $(BUILD)/tests/$$t/prog.hex $(BUILD)/tests/$$t/tohost.addr \
	       $(BUILD)/tests/$$t/spike.log $(BUILD)/tests/$$t/prog.dis $(GOLDEN)/$$t/; \
	done

clean:
	rm -rf $(BUILD)
