#!/usr/bin/env python3
import pathlib
import struct
import sys

ROM_BASE = 0x00F80000
ROM_SIZE = 512 * 1024
REQUIRED = (
    b"milestone=M2.8",
    b"profile=destructive-a500-512k",
    b"MEM.DESTRUCTIVE.PROFILE",
    b"start=0x00008000",
    b"end=0x00070000",
    b"bytes=425984",
    b"patterns=4",
    b"destructive=1",
    b"preserve=0",
    b"MEM.DESTRUCTIVE status=PASS",
    b"FAULT class=MEM test=DESTRUCTIVE",
)

def fail(msg):
    print("FAIL: " + msg, file=sys.stderr)
    raise SystemExit(1)

def main():
    if len(sys.argv) != 2:
        fail("usage: check_destructive_rom.py <rom>")
    data = pathlib.Path(sys.argv[1]).read_bytes()
    if len(data) != ROM_SIZE:
        fail("ROM size mismatch")
    sp, pc = struct.unpack_from(">II", data, 0)
    if sp != 0x0007FFFC:
        fail("unexpected initial SP")
    if not (ROM_BASE <= pc < ROM_BASE + ROM_SIZE):
        fail("reset PC outside ROM")
    for marker in REQUIRED:
        if marker not in data:
            fail("missing marker %r" % (marker,))
    print("PASS: M2.8 destructive ROM profile markers and vectors")

if __name__ == "__main__":
    main()
