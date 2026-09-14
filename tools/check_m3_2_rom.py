#!/usr/bin/env python3
import pathlib
import sys

REQUIRED = [
    b"AMIDIAG proto=1 milestone=M3.2 cpu=68000",
    b"FRAME id=CPU.ADDRESS ssw=0x",
    b" address=0x",
    b" ir=0x",
    b" sr=0x",
    b" pc=0x",
    b"TEST id=CPU.ADDRESS.RECOVER status=PASS frame=68000-14-byte return=unwind-jump",
    b"TEST id=CPU.BUS.RECOVER status=SKIP reason=address-frame-first fatal=1",
    b"TEST id=CPU.BASELINE status=PASS cpu=68000 exception=address",
]


def fail(msg):
    print("FAIL: " + msg, file=sys.stderr)
    raise SystemExit(1)


def main():
    if len(sys.argv) != 2:
        fail("usage: check_m3_2_rom.py ROM")
    path = pathlib.Path(sys.argv[1])
    if not path.is_file():
        fail("ROM not found: %s" % path)
    data = path.read_bytes()
    for marker in REQUIRED:
        if marker not in data:
            fail("missing ROM marker: %s" % marker.decode())
    if len(data) != 524288:
        fail("ROM size is %d, expected 524288" % len(data))
    print("PASS: M3.2 address-error recovery markers and 512 KiB ROM image")


if __name__ == "__main__":
    main()
