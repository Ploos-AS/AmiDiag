#!/usr/bin/env python3
import pathlib
import struct
import sys

ROM_BASE = 0x00F80000
ROM_SIZE = 512 * 1024
CHIP_RAM_MAX = 0x00200000
REQUIRED = (
    b"AMIDIAG proto=1 milestone=M3.1 cpu=68000",
    b"TEST id=CPU.VECTORS status=PASS table=ram",
    b"FRAME id=CPU.TRAP0 sr=0x",
    b"TEST id=CPU.EXCEPTION.RECOVER status=PASS vector=TRAP0 frame=sr-pc return=RTE",
    b"TEST id=CPU.BASELINE status=PASS cpu=68000 exception=trap0",
    b"EXCEPTION id=CPU.BUS status=FAIL fatal=1",
    b"EXCEPTION id=CPU.ADDRESS status=FAIL fatal=1",
)

def fail(msg):
    print("FAIL: " + msg, file=sys.stderr)
    raise SystemExit(1)

def main():
    if len(sys.argv) != 2:
        fail("usage: check_m3_1_rom.py <rom>")
    data = pathlib.Path(sys.argv[1]).read_bytes()
    if len(data) != ROM_SIZE:
        fail("ROM size is %d, expected %d" % (len(data), ROM_SIZE))
    sp, pc = struct.unpack_from(">II", data, 0)
    if sp == 0 or sp > CHIP_RAM_MAX or (sp & 1):
        fail("implausible initial SP")
    if not (ROM_BASE <= pc < ROM_BASE + ROM_SIZE) or (pc & 1):
        fail("reset PC outside ROM")
    for marker in REQUIRED:
        if marker not in data:
            fail("missing marker %r" % (marker,))
    print("PASS: M3.1 ROM vectors/recoverable-exception markers")

if __name__ == "__main__":
    main()
