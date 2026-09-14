#!/usr/bin/env python3
import pathlib
import re
import sys

FRAME = re.compile(
    r"^FRAME id=CPU\.ADDRESS ssw=0x([0-9A-F]{4}) address=0x([0-9A-F]{8}) "
    r"ir=0x([0-9A-F]{4}) sr=0x([0-9A-F]{4}) pc=0x([0-9A-F]{8})$"
)

REQUIRED = [
    "AMIDIAG proto=1 milestone=M3.2 cpu=68000",
    "BOOT phase=reset status=PASS",
    "TEST id=CPU.VECTORS status=PASS table=ram",
    "TEST id=CPU.ADDRESS.RECOVER status=PASS frame=68000-14-byte return=unwind-jump",
    "TEST id=CPU.BUS.RECOVER status=SKIP reason=address-frame-first fatal=1",
    "TEST id=CPU.BASELINE status=PASS cpu=68000 exception=address",
]


def fail(msg):
    print("FAIL: " + msg, file=sys.stderr)
    raise SystemExit(1)


def main():
    if len(sys.argv) != 2:
        fail("usage: check_m3_2_serial.py TRANSCRIPT")
    path = pathlib.Path(sys.argv[1])
    if not path.is_file():
        fail("transcript not found: %s" % path)
    lines = [x.strip() for x in path.read_text(errors="replace").splitlines() if x.strip()]
    pos = 0
    for expected in REQUIRED[:3]:
        try:
            idx = lines.index(expected, pos)
        except ValueError:
            fail("missing expected record: %s" % expected)
        pos = idx + 1

    matches = [FRAME.match(x) for x in lines]
    matches = [m for m in matches if m]
    if len(matches) != 1:
        fail("expected exactly one CPU.ADDRESS frame, got %d" % len(matches))
    m = matches[0]
    address = int(m.group(2), 16)
    pc = int(m.group(5), 16)
    if address != 1:
        fail("address-error frame captured unexpected access address 0x%08X" % address)
    if not (0x00F80000 <= pc <= 0x00FFFFFF):
        fail("fault PC is outside 512 KiB ROM window: 0x%08X" % pc)

    for expected in REQUIRED[3:]:
        if expected not in lines:
            fail("missing expected record: %s" % expected)
    fatal = [x for x in lines if x.startswith("EXCEPTION ") and "status=FAIL" in x]
    if fatal:
        fail("unexpected fatal exception: %s" % fatal[0])
    failed = [x for x in lines if x.startswith("TEST ") and "status=FAIL" in x]
    if failed:
        fail("failed test record present: %s" % failed[0])
    print("PASS: M3.2 captured 68000 address-error frame and resumed safely")


if __name__ == "__main__":
    main()
