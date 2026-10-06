#!/usr/bin/env python3
"""Print a CPI comparison table: no predictor vs 2-bit direct-mapped predictor.

usage: bp_report.py <run_none dir> <run_dm dir> <test> [<test> ...]
Reads [STATS] lines from <dir>/<test>/sim.log.
"""
import re
import sys


def stats(path):
    try:
        text = open(path).read()
    except OSError:
        return None
    s = {k: float(v) for k, v in re.findall(r"\[STATS\] (\w+)=([\d.]+)", text)}
    s["pass"] = "[tb] PASS" in text
    return s if "cycles" in s else None


def main():
    if len(sys.argv) < 4:
        sys.exit(__doc__)
    none_dir, dm_dir, tests = sys.argv[1], sys.argv[2], sys.argv[3:]

    hdr = ("| Test | Instr | Cycles (no BP) | Cycles (2-bit BP) | CPI (no BP) | CPI (2-bit BP) "
           "| Speedup | Cycles saved | Control-flow instr | Mispredicts (no BP) | Mispredicts (2-bit BP) | Accuracy (2-bit BP) |")
    print()
    print(hdr)
    print("|" + "---|" * (hdr.count("|") - 1))
    tot_n = tot_d = 0
    for t in tests:
        n = stats(f"{none_dir}/{t}/sim.log")
        d = stats(f"{dm_dir}/{t}/sim.log")
        if not n or not d:
            print(f"| {t} | missing results | | | | | | | | | | |")
            continue
        flag = "" if (n["pass"] and d["pass"]) else " (FAIL)"
        if n["instret"] != d["instret"]:
            flag += " (instret differs!)"
        cf = d["branches"] + d["jal"] + d["jalr"]
        acc = 100.0 * (1 - d["mispredicts"] / cf) if cf else 100.0
        speedup = n["cycles"] / d["cycles"]
        saved = 100.0 * (n["cycles"] - d["cycles"]) / n["cycles"]
        print(f"| {t}{flag} | {int(d['instret'])} | {int(n['cycles'])} | {int(d['cycles'])} "
              f"| {n['cpi']:.3f} | {d['cpi']:.3f} | {speedup:.3f}x | {saved:.1f}% | {int(cf)} "
              f"| {int(n['mispredicts'])} | {int(d['mispredicts'])} | {acc:.1f}% |")
        if t.startswith("bench_"):
            tot_n += n["cycles"]
            tot_d += d["cycles"]
    if tot_d:
        print(f"\nBenchmarks overall (bench_*): {int(tot_n)} -> {int(tot_d)} cycles, "
              f"speedup {tot_n / tot_d:.3f}x ({100.0 * (tot_n - tot_d) / tot_n:.1f}% fewer cycles)")


if __name__ == "__main__":
    main()
