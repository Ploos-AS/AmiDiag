#!/usr/bin/env python3
import pathlib
import struct
import sys

ROM_BASE = 0x00F80000
ROM_SIZE = 512 * 1024
CHIP_RAM_MAX = 0x00200000
REQUIRED_MARKERS = (
    b"AMIDIAG proto=1 milestone=M2.5",
    b"BOOT phase=reset",
    b"BOOT.VECTORS",
    b"BOOT.SERIAL",
    b"MEM.DATA",
    b"patterns=64",
    b"MEM.ADDRESS",
    b"bits=A2-A18",
    b"probes=17",
    b"MEM.ARENA",
    b"bytes=4096",
    b"cells=1024",
    b"patterns=4",
    b"mode=preserve",
    b"MEM.CHIP.DISCOVER",
    b"confidence=discovered",
    b"bytes=524288",
    b"bytes=1048576",
    b"bytes=1572864",
    b"bytes=2097152",
    b"EXCEPTION id=CPU.BUS",
    b"EXCEPTION id=CPU.ADDRESS",
    b"EXCEPTION id=CPU.UNKNOWN",
)

def fail(message):
    print("FAIL: " + message, file=sys.stderr)
    raise SystemExit(1)

def main():
    if len(sys.argv) != 2:
        fail("usage: check_rom.py <amidiag.rom>")
    data = pathlib.Path(sys.argv[1]).read_bytes()
    if len(data) != ROM_SIZE:
        fail("ROM size is %d, expected %d" % (len(data), ROM_SIZE))
    initial_sp, reset_pc = struct.unpack_from(">II", data, 0)
    if initial_sp == 0 or initial_sp > CHIP_RAM_MAX or (initial_sp & 1):
        fail("implausible initial SP")
    if not (ROM_BASE <= reset_pc < ROM_BASE + ROM_SIZE) or (reset_pc & 1):
        fail("reset PC outside ROM")
    for marker in REQUIRED_MARKERS:
        if marker not in data:
            fail("missing marker %r" % (marker,))
    print("PASS: M2.5 ROM size/vectors/data/address/arena/discovery markers")

if __name__ == "__main__":
    main()
