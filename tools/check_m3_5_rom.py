#!/usr/bin/env python3
import struct
import sys
from pathlib import Path

rom = Path(sys.argv[1] if len(sys.argv) > 1 else "build/amidiag-m3_5.rom")
data = rom.read_bytes()

if len(data) != 524288:
    raise SystemExit(f"FAIL: M3.5 ROM size is {len(data)}, expected 524288")

sp, pc = struct.unpack(">II", data[:8])
if sp != 0x0007FFFC:
    raise SystemExit(f"FAIL: initial SP is 0x{sp:08X}")
if not 0x00F80000 <= pc <= 0x00FFFFFF:
    raise SystemExit(f"FAIL: reset PC 0x{pc:08X} is outside ROM")

required = [
    b"AMIDIAG proto=1 milestone=M3.5 cpu=68000",
    b"TEST id=MEM.PROBE.GUARD status=PASS",
    b"result=PRESENT mode=preserve-alias",
    b"result=ALIAS base=0x00001000 mode=preserve-alias",
    b"result=OPEN_BUS mode=preserve-alias",
    b"result=BUS_ERROR mode=preserve-alias",
    b"TEST id=MEM.CHIP.CANDIDATE status=PASS",
    b"TEST id=CPU.BASELINE status=PASS cpu=68000 probe=guarded-memory",
    b"unexpected-or-unarmed",
]
for marker in required:
    if marker not in data:
        raise SystemExit(f"FAIL: missing ROM marker: {marker.decode()}")

print("PASS: M3.5 guarded preserve/alias Chip RAM candidate ROM")
