#!/usr/bin/env python3
import sys
from pathlib import Path

REQUIRED = [
    "AMIDIAG proto=1 milestone=M3.8 cpu=68000",
    "BOOT phase=reset status=PASS",
    "TEST id=CPU.INSTR.MOVE status=PASS width=32",
    "TEST id=CPU.INSTR.ARITH status=PASS ops=ADD,SUB width=32",
    "TEST id=CPU.INSTR.LOGIC status=PASS ops=AND,OR,EOR width=32",
    "TEST id=CPU.INSTR.SHIFT status=PASS ops=LSL,LSR,ROL width=32",
    "TEST id=CPU.INSTR.CCR status=PASS flags=Z,N branches=BEQ,BNE,BPL",
    "TEST id=CPU.INSTR.ADDRESS status=PASS mode=indirect width=32",
    "TEST id=CPU.INSTR.SANITY status=PASS cpu=68000 tests=6",
    "TEST id=CPU.BASELINE status=PASS cpu=68000 probe=instruction-sanity",
]

def main() -> int:
    if len(sys.argv) != 2:
        print(f"usage: {sys.argv[0]} SERIAL", file=sys.stderr)
        return 2
    text = Path(sys.argv[1]).read_text(errors="replace")
    missing = [x for x in REQUIRED if x not in text]
    if missing:
        print("FAIL: missing serial markers: " + repr(missing), file=sys.stderr)
        return 1
    if "status=FAIL" in text:
        print("FAIL: serial stream contains status=FAIL", file=sys.stderr)
        return 1
    print("M3.8 SERIAL PASS")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
