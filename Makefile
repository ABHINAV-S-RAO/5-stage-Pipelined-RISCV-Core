# Top-level flow for the 5-stage RV32I core.
#
#   make sim     TEST=<name>   build the test program and run RTL simulation
#   make spike   TEST=<name>   run the same program on Spike (golden model)
#   make compare TEST=<name>   sim + spike + commit-trace diff
#   make regress               compare every test in verif/tests/asm
#   make clean
#
# Options:  SIM=xcelium|icarus   WAVES=1   MAX_CYCLES=<n>
# Every tool is a variable, e.g.  make compare SPIKE=/path/to/spike RISCV_PREFIX=riscv32-unknown-elf-

ROOT  := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
BUILD ?= $(ROOT)/build

TEST       ?= smoke
SIM        ?= xcelium
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
IVERILOG ?= iverilog
VVP     ?= vvp

# ---- sources ---------------------------------------------------------------
SW_COMMON := $(ROOT)/verif/sw/common
RTL_SRCS  := $(sort $(wildcard $(ROOT)/rtl/core/*.v))
TB_SRCS   := $(ROOT)/verif/tb/tb_memory.sv $(ROOT)/verif/tb/tb_top.sv
TESTS     ?= $(sort $(basename $(notdir $(wildcard $(ROOT)/verif/tests/asm/*.S))))

CFLAGS  := -march=rv32i -mabi=ilp32 -O2 -static -nostdlib -nostartfiles -ffreestanding \
           -I$(SW_COMMON) $(RV_CFLAGS_EXTRA)
LDFLAGS := -T$(SW_COMMON)/link.ld -lgcc

T := $(BUILD)/tests/$(TEST)

PLUSARGS = +hex=$(T)/prog.hex +tohost=$$(cat $(T)/tohost.addr) +trace=$(T)/rtl_trace.log \
           +max_cycles=$(MAX_CYCLES) $(if $(filter 1,$(WAVES)),+vcd)

.PHONY: sw sim spike compare regress clean
.SECONDARY:

# ---- software --------------------------------------------------------------
sw: $(T)/prog.hex $(T)/tohost.addr

$(BUILD)/tests/%/prog.elf: $(ROOT)/verif/tests/asm/%.S $(SW_COMMON)/crt0.S $(SW_COMMON)/link.ld $(SW_COMMON)/test_macros.h
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
sim: sw
ifeq ($(SIM),xcelium)
	cd $(T) && $(XRUN) -64bit -sv -timescale 1ns/1ps -access +r -top tb_top \
	    -xmlibdirname $(BUILD)/xcelium.d -l xrun.log \
	    $(RTL_SRCS) $(TB_SRCS) $(PLUSARGS) | tee sim.log
else ifeq ($(SIM),icarus)
	@mkdir -p $(BUILD)/icarus
	$(IVERILOG) -g2012 $(IVERILOG_FLAGS_EXTRA) -s tb_top -o $(BUILD)/icarus/tb.vvp $(RTL_SRCS) $(TB_SRCS)
	cd $(T) && $(VVP) $(VVP_FLAGS_EXTRA) $(BUILD)/icarus/tb.vvp $(PLUSARGS) | tee sim.log
else
	$(error SIM must be xcelium or icarus)
endif

# ---- comparison ------------------------------------------------------------
compare: sim spike
	$(PYTHON) $(ROOT)/verif/scripts/spike_diff.py $(T)/rtl_trace.log $(T)/spike.log \
	    --tohost $$(cat $(T)/tohost.addr) --base $(MEM_BASE) --sim-log $(T)/sim.log

regress:
	@mkdir -p $(BUILD)
	@fails=0; for t in $(TESTS); do \
	    if $(MAKE) --no-print-directory compare TEST=$$t > $(BUILD)/regress_$$t.log 2>&1; then \
	        echo "PASS  $$t"; \
	    else \
	        echo "FAIL  $$t   (log: build/regress_$$t.log)"; fails=$$((fails + 1)); \
	    fi; \
	done; \
	echo "$$fails failing test(s)"; [ $$fails -eq 0 ]

clean:
	rm -rf $(BUILD)
