#!/usr/bin/env python3
"""Compare the RTL commit trace against `spike --log-commits`.

Both logs use Spike's commit format:
    core   0: 3 0x<pc> (0x<inst>) [x<rd> 0x<val>] [mem 0x<addr>] [mem 0x<addr> 0x<data>]

Spike's log is filtered to instructions at/above the program base (dropping
its bootrom) and cut at the store to tohost, which is where the RTL testbench
stops. Exit status is 0 only if the simulation reported PASS and every
retired instruction matches.
"""
import argparse
import re
import sys

LINE_RE = re.compile(r"^core\s+\d+:\s+\d+\s+0x([0-9a-fA-F]+)\s+\((0x[0-9a-fA-F]+)\)(.*)$")


def parse(path, base, tohost=None):
    recs = []
    with open(path) as f:
        for raw in f:
            m = LINE_RE.match(raw.strip())
            if not m:
                continue
            pc = int(m.group(1), 16)
            if pc < base:
                continue
            inst = int(m.group(2), 16)
            effects = m.group(3).split()
            recs.append((pc, inst, " ".join(effects), raw.rstrip()))
            if tohost is not None and is_tohost_store(effects, tohost):
                break
    return recs


def is_tohost_store(effects, tohost):
    # store effect = "mem <addr> <data>"
    for i, tok in enumerate(effects[:-2]):
        if tok == "mem" and int(effects[i + 1], 16) == tohost and effects[i + 2].startswith("0x"):
            return True
    return False


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("rtl_trace")
    ap.add_argument("spike_log")
    ap.add_argument("--tohost", required=True, help="tohost address (hex)")
    ap.add_argument("--base", default="0x80000000", help="program base address")
    ap.add_argument("--sim-log", help="simulator stdout log to check for [tb] PASS")
    ap.add_argument("--context", type=int, default=5)
    args = ap.parse_args()

    tohost = int(args.tohost, 16)
    base = int(args.base, 16)

    ok = True
    if args.sim_log:
        sim = open(args.sim_log).read()
        if "[tb] PASS" not in sim:
            res = re.search(r"\[tb\] (FAIL.*|TIMEOUT.*)", sim)
            print(f"SIM: {res.group(1) if res else 'no PASS/FAIL line found'}")
            ok = False
        else:
            print("SIM: PASS")

    rtl = parse(args.rtl_trace, base)
    iss = parse(args.spike_log, base, tohost)

    for i, (r, s) in enumerate(zip(rtl, iss)):
        if r[:3] != s[:3]:
            print(f"TRACE: MISMATCH at retired instruction #{i}")
            for j in range(max(0, i - args.context), i):
                print(f"   {rtl[j][3]}")
            print(f"  rtl:   {r[3]}")
            print(f"  spike: {s[3]}")
            return 1
    if len(rtl) != len(iss):
        shorter, longer, name = (rtl, iss, "spike") if len(rtl) < len(iss) else (iss, rtl, "rtl")
        print(f"TRACE: LENGTH MISMATCH rtl={len(rtl)} spike={len(iss)}; "
              f"{name} continues with:")
        print(f"   {longer[len(shorter)][3]}")
        return 1

    print(f"TRACE: MATCH ({len(rtl)} instructions)")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
