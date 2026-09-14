#!/usr/bin/env python3
import pathlib
import re
import sys

FRAME = re.compile(
    r"^FRAME id=CPU\.BUS ssw=0x([0-9A-F]{4}) address=0x([0-9A-F]{8}) "
    r"ir=0x([0-9A-F]{4}) sr=0x([0-9A-F]{4}) pc=0x([0-9A-F]{8})$"
)

REQUIRED = [
    "AMIDIAG proto=1 milestone=M3.3 cpu=68000",
    "BOOT phase=reset status=PASS",
    "TEST id=CPU.VECTORS status=PASS table=ram",
    "TEST id=CPU.BUS.PROBE status=PASS address=0x00400000 width=16 expected=bus-error",
    "TEST id=CPU.BUS.RECOVER status=PASS frame=68000-14-byte return=unwind-jump",
    "TEST id=CPU.BASELINE status=PASS cpu=68000 exception=bus",
]

def fail(msg):
    print("FAIL: " + msg, file=sys.stderr)
    raise SystemExit(1)

def main():
    if len(sys.argv) != 2:
        fail("usage: check_m3_3_serial.py TRANSCRIPT")
    path = pathlib.Path(sys.argv[1])
    if not path.is_file():
        fail("transcript not found: %s" % path)
    lines = [x.strip() for x in path.read_text(errors="replace").splitlines() if x.strip()]
    for expected in REQUIRED:
        if expected not in lines:
            fail("missing expected record: %s" % expected)
    matches = [FRAME.match(x) for x in lines]
    matches = [m for m in matches if m]
    if len(matches) != 1:
        fail("expected exactly one CPU.BUS frame, got %d" % len(matches))
    m = matches[0]
    address = int(m.group(2), 16)
    pc = int(m.group(5), 16)
    if address != 0x00400000:
        fail("bus-error frame captured unexpected access address 0x%08X" % address)
    if not (0x00F80000 <= pc <= 0x00FFFFFF):
        fail("fault PC is outside 512 KiB ROM window: 0x%08X" % pc)
    fatal = [x for x in lines if x.startswith("EXCEPTION ") and "status=FAIL" in x]
    if fatal:
        fail("unexpected fatal exception: %s" % fatal[0])
    failed = [x for x in lines if x.startswith("TEST ") and "status=FAIL" in x]
    if failed:
        fail("failed test record present: %s" % failed[0])
    print("PASS: M3.3 captured 68000 bus-error frame and resumed safely")

if __name__ == "__main__":
    main()
