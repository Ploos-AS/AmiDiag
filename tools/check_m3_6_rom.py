#!/usr/bin/env python3
import struct
import sys
from pathlib import Path

p = Path(sys.argv[1] if len(sys.argv) > 1 else "build/amidiag-m3_6.rom")
data = p.read_bytes()
assert len(data) == 524288, f"ROM size {len(data)} != 524288"
sp, pc = struct.unpack(">II", data[:8])
assert sp == 0x0007FFFC, hex(sp)
assert 0x00F80000 <= pc <= 0x00FFFFFF, hex(pc)
for marker in (
    b"milestone=M3.6",
    b"MEM.PROBE.GUARD",
    b"0x00081000",
    b"0x00101000",
    b"0x00181000",
    b"MEM.CHIP.DISCOVER.GUARDED",
    b"confidence=guarded-discovered",
):
    assert marker in data, marker
print("PASS: M3.6 ROM structure and guarded discovery markers")
