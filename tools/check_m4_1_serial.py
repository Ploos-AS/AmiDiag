#!/usr/bin/env python3
import pathlib
import sys

REQUIRED = (
    "AMIDIAG proto=1 milestone=M4.1 cpu=68000",
    "BOOT phase=reset status=PASS",
    "CIAA.ACCESS status=PASS register=DDRA restore=PASS",
    "CIAB.ACCESS status=PASS register=DDRB restore=PASS",
    "TEST id=CIA.ACCESS status=PASS devices=2 restored=2",
)


def fail(message):
    print("FAIL: " + message)
    raise SystemExit(1)


def main():
    if len(sys.argv) != 2:
        fail("usage: check_m4_1_serial.py SERIAL_LOG")
    text = pathlib.Path(sys.argv[1]).read_text(errors="replace").replace("\r", "")
    lines = [line.strip() for line in text.splitlines() if line.strip()]
    for record in REQUIRED:
        if lines.count(record) != 1:
            fail("record count != 1: " + record)
    if any("status=FAIL" in line for line in lines):
        fail("transcript contains status=FAIL")
    positions = [lines.index(record) for record in REQUIRED]
    if positions != sorted(positions):
        fail("required records are out of order")
    print("PASS: M4.1 CIA-A/CIA-B access transcript")


if __name__ == "__main__":
    main()
