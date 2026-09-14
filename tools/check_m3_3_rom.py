#!/usr/bin/env python3
import pathlib
import sys

REQUIRED = [
    b"AMIDIAG proto=1 milestone=M3.3 cpu=68000",
    b"TEST id=CPU.BUS.HARDWARE status=PASS address=0x00400000 width=16 source=vector2",
    b"TEST id=CPU.BUS.HARDWARE status=UNAVAILABLE address=0x00400000 width=16 reason=no-berr",
    b"FRAME id=CPU.BUS ssw=0x",
    b" source=synthetic",
    b"TEST id=CPU.BUS.FRAME status=PASS source=synthetic frame=68000-14-byte",
    b"TEST id=CPU.BUS.RECOVER status=PASS source=synthetic frame=68000-14-byte return=unwind-jump",
    b"TEST id=CPU.BASELINE status=PASS cpu=68000 exception=bus-frame-handler",
]


def fail(msg):
    print("FAIL: " + msg, file=sys.stderr)
    raise SystemExit(1)


def main():
    if len(sys.argv) != 2:
        fail("usage: check_m3_3_rom.py ROM")
    path = pathlib.Path(sys.argv[1])
    if not path.is_file():
        fail("ROM not found: %s" % path)
    data = path.read_bytes()
    for marker in REQUIRED:
        if marker not in data:
            fail("missing ROM marker: %s" % marker.decode())
    if len(data) != 524288:
        fail("ROM size is %d, expected 524288" % len(data))
    print("PASS: M3.3 separates hardware BERR availability from 68000 frame recovery")


if __name__ == "__main__":
    main()
