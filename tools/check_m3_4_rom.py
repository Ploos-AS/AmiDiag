#!/usr/bin/env python3
import sys
from pathlib import Path


def main() -> int:
    if len(sys.argv) != 2:
        print(f"usage: {sys.argv[0]} ROM", file=sys.stderr)
        return 2
    data = Path(sys.argv[1]).read_bytes()
    if len(data) != 524288:
        print(f"FAIL: ROM size {len(data)} != 524288", file=sys.stderr)
        return 1
    if int.from_bytes(data[0:4], "big") != 0x0007FFFC:
        print("FAIL: initial stack pointer is not 0x0007FFFC", file=sys.stderr)
        return 1
    reset_pc = int.from_bytes(data[4:8], "big")
    if not 0x00F80000 <= reset_pc <= 0x00FFFFFF:
        print(f"FAIL: reset PC 0x{reset_pc:08X} outside ROM", file=sys.stderr)
        return 1

    required = [
        b"AMIDIAG proto=1 milestone=M3.4 cpu=68000",
        b"TEST id=CPU.PROBE.GUARD status=PASS",
        b"result=READABLE",
        b"result=ADDRESS_ERROR",
        b"result=BUS_ERROR",
        b"result=OPEN_BUS",
        b"unexpected=fatal",
        b"TEST id=CPU.PROBE.RESULTS status=PASS",
        b"TEST id=CPU.BASELINE status=PASS cpu=68000 probe=guarded",
    ]
    missing = [item.decode() for item in required if item not in data]
    if missing:
        print(f"FAIL: missing ROM markers: {missing}", file=sys.stderr)
        return 1
    print("PASS: M3.4 guarded probe ROM markers and vectors")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
