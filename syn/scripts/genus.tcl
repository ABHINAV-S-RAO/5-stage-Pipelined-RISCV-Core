# Logic synthesis of riscv_core in SKY130 with Cadence Genus.
#
# Run through the Makefile (from the repo root):
#   make syn SKY130_LIB=/path/to/sky130_fd_sc_hd__tt_025C_1v80.lib CLK_PERIOD=10
#
# Environment (set by the Makefile):
#   ROOT        repo root
#   SKY130_LIB  standard-cell Liberty file (.lib)
#   CLK_PERIOD  clock period in ns
#   IO_PCT      fraction of the period budgeted for logic outside the core
#               on every input and output (memories / SRAM macros)
#
# Outputs go to build/syn/: reports/, netlist/riscv_core.v, riscv_core.sdc

set ROOT       $::env(ROOT)
set LIB        $::env(SKY130_LIB)
set CLK_PERIOD $::env(CLK_PERIOD)
set IO_PCT     $::env(IO_PCT)
set DESIGN     riscv_core

file mkdir reports netlist

# -----------------------------
# Library
# -----------------------------
set_db library $LIB

# -----------------------------
# RTL (file list shared with other tools)
# -----------------------------
set rtl_files {}
set fh [open $ROOT/rtl/core/core.f r]
foreach line [split [read $fh] "\n"] {
    set line [string trim $line]
    if {$line eq "" || [string match "//*" $line]} { continue }
    lappend rtl_files $ROOT/$line
}
close $fh

read_hdl $rtl_files
elaborate $DESIGN
check_design -unresolved

# -----------------------------
# Constraints
# -----------------------------
set io_delay [expr {$IO_PCT * $CLK_PERIOD}]

create_clock -name clk -period $CLK_PERIOD [get_ports clk]
set_clock_uncertainty 0.2 [get_clocks clk]
set_clock_transition  0.15 [get_clocks clk]

# Memories sit outside the core: their clock-to-q eats into input paths,
# their setup time into output paths. IO_PCT models that budget.
set in_ports [get_ports {rst imem_rdata* dmem_rdata*}]
set_input_delay  $io_delay -clock clk $in_ports
set_output_delay $io_delay -clock clk [all_outputs]
set_driving_cell -lib_cell sky130_fd_sc_hd__buf_2 -pin X $in_ports
set_load 0.02 [all_outputs]

# -----------------------------
# Synthesis
# -----------------------------
set_db syn_generic_effort medium
set_db syn_map_effort     medium
set_db syn_opt_effort     medium

syn_generic
syn_map
syn_opt

# -----------------------------
# Reports
# -----------------------------
report_qor                                       > reports/qor.rpt
report_area                                      > reports/area.rpt
report_gates                                     > reports/gates.rpt
report_power                                     > reports/power.rpt
report_timing -max_paths 10                      > reports/timing_worst.rpt
report_timing -from [all_registers] -to [all_registers] -max_paths 10 > reports/timing_reg2reg.rpt
report_timing -from [all_inputs]    -to [all_registers] -max_paths 5  > reports/timing_in2reg.rpt
report_timing -from [all_registers] -to [all_outputs]   -max_paths 5  > reports/timing_reg2out.rpt
report_timing -from [all_inputs]    -to [all_outputs]   -max_paths 5  > reports/timing_in2out.rpt

write_hdl > netlist/$DESIGN.v
write_sdc > netlist/$DESIGN.sdc

puts "\n=== Synthesis done: CLK_PERIOD=$CLK_PERIOD ns, IO budget=$io_delay ns ==="
puts "Reports in build/syn/reports, netlist in build/syn/netlist"
exit
