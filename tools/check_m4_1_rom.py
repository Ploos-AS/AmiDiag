#!/usr/bin/env python3
import pathlib
import sys

EXPECTED_SIZE = 524288
MARKERS = (
    b"AMIDIAG proto=1 milestone=M4.1 cpu=68000\r\n",
    b"CIAA.ACCESS status=PASS register=DDRA restore=PASS\r\n",
    b"CIAB.ACCESS status=PASS register=DDRB restore=PASS\r\n",
    b"TEST id=CIA.ACCESS status=PASS devices=2 restored=2\r\n",
)


def fail(message):
    print("FAIL: " + message)
    raise SystemExit(1)


def main():
    if len(sys.argv) != 2:
        fail("usage: check_m4_1_rom.py ROM")
    data = pathlib.Path(sys.argv[1]).read_bytes()
    if len(data) != EXPECTED_SIZE:
        fail("ROM size %d != %d" % (len(data), EXPECTED_SIZE))
    for marker in MARKERS:
        if data.count(marker) != 1:
            fail("marker count != 1: %r" % marker)

    # CIA addresses are absolute 24-bit values encoded in 32-bit operands.
    for address in (0x00BFE201, 0x00BFD300):
        encoded = address.to_bytes(4, "big")
        if encoded not in data:
            fail("missing CIA register address 0x%08X" % address)

    print("PASS: M4.1 ROM size, records and CIA register references")


if __name__ == "__main__":
    main()
