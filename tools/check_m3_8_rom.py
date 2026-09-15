#!/usr/bin/env python3
import sys
from pathlib import Path

REQUIRED = [
    b"AMIDIAG proto=1 milestone=M3.8 cpu=68000",
    b"TEST id=CPU.INSTR.MOVE status=PASS",
    b"TEST id=CPU.INSTR.ARITH status=PASS",
    b"TEST id=CPU.INSTR.LOGIC status=PASS",
    b"TEST id=CPU.INSTR.SHIFT status=PASS",
    b"TEST id=CPU.INSTR.CCR status=PASS",
    b"TEST id=CPU.INSTR.ADDRESS status=PASS",
    b"TEST id=CPU.INSTR.SANITY status=PASS cpu=68000 tests=6",
]

def main() -> int:
    if len(sys.argv) != 2:
        print(f"usage: {sys.argv[0]} ROM", file=sys.stderr)
        return 2
    data = Path(sys.argv[1]).read_bytes()
    if len(data) != 524288:
        print(f"FAIL: ROM size {len(data)}, expected 524288", file=sys.stderr)
        return 1
    missing = [x.decode() for x in REQUIRED if x not in data]
    if missing:
        print("FAIL: missing ROM markers: " + repr(missing), file=sys.stderr)
        return 1
    print("M3.8 ROM STATIC PASS")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
