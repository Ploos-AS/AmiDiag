#!/usr/bin/env python3
import pathlib
import re
import sys

PATTERN = re.compile(
    r"^FAULT class=MEM test=(DATA|ADDRESS|ARENA|MARCH) "
    r"address=0x([0-9A-F]{8}) expected=0x([0-9A-F]{8}) actual=0x([0-9A-F]{8})$"
)

def fail(message):
    print("FAIL: " + message, file=sys.stderr)
    raise SystemExit(1)

def main():
    if len(sys.argv) != 2:
        fail("usage: check_fault_record.py <fixture>")
    path = pathlib.Path(sys.argv[1])
    if not path.is_file():
        fail("fixture not found: %s" % path)
    lines = [x.strip() for x in path.read_text(errors="replace").splitlines() if x.strip()]
    if not lines:
        fail("empty fixture")
    for line in lines:
        m = PATTERN.fullmatch(line)
        if not m:
            fail("invalid fault record: %s" % line)
        address = int(m.group(2), 16)
        if address & 3:
            fail("fault address is not longword-aligned: %s" % m.group(2))
        if m.group(3) == m.group(4):
            fail("fixture must model an actual mismatch")
    print("PASS: %d M2.7 RAM fault record fixture(s)" % len(lines))

if __name__ == "__main__":
    main()
