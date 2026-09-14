#!/usr/bin/env python3
import pathlib
import re
import sys

FRAME = re.compile(
    r"^FRAME id=CPU\.BUS ssw=0x([0-9A-F]{4}) address=0x([0-9A-F]{8}) "
    r"ir=0x([0-9A-F]{4}) sr=0x([0-9A-F]{4}) pc=0x([0-9A-F]{8}) source=synthetic$"
)

REQUIRED = [
    "AMIDIAG proto=1 milestone=M3.3 cpu=68000",
    "BOOT phase=reset status=PASS",
    "TEST id=CPU.VECTORS status=PASS table=ram",
    "TEST id=CPU.BUS.FRAME status=PASS source=synthetic frame=68000-14-byte",
    "TEST id=CPU.BUS.RECOVER status=PASS source=synthetic frame=68000-14-byte return=unwind-jump",
    "TEST id=CPU.BASELINE status=PASS cpu=68000 exception=bus-frame-handler",
]

HARDWARE_PREFIX = "TEST id=CPU.BUS.HARDWARE "


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

    hardware = [x for x in lines if x.startswith(HARDWARE_PREFIX)]
    if len(hardware) != 1:
        fail("expected exactly one CPU.BUS.HARDWARE record, got %d" % len(hardware))
    if "status=PASS" not in hardware[0] and "status=UNAVAILABLE" not in hardware[0]:
        fail("unexpected hardware BERR result: %s" % hardware[0])

    matches = [FRAME.match(x) for x in lines]
    matches = [m for m in matches if m]
    if len(matches) != 1:
        fail("expected exactly one synthetic CPU.BUS frame, got %d" % len(matches))
    m = matches[0]
    ssw = int(m.group(1), 16)
    address = int(m.group(2), 16)
    ir = int(m.group(3), 16)
    sr = int(m.group(4), 16)
    pc = int(m.group(5), 16)
    if ssw != 0x1234:
        fail("synthetic SSW mismatch: 0x%04X" % ssw)
    if address != 0x00400000:
        fail("synthetic access address mismatch: 0x%08X" % address)
    if ir != 0x4E71:
        fail("synthetic IR mismatch: 0x%04X" % ir)
    if sr != 0x2700:
        fail("synthetic SR mismatch: 0x%04X" % sr)
    if not (0x00F80000 <= pc <= 0x00FFFFFF):
        fail("synthetic PC is outside 512 KiB ROM window: 0x%08X" % pc)

    fatal = [x for x in lines if x.startswith("EXCEPTION ") and "status=FAIL" in x]
    if fatal:
        fail("unexpected fatal exception: %s" % fatal[0])
    failed = [x for x in lines if x.startswith("TEST ") and "status=FAIL" in x]
    if failed:
        fail("failed test record present: %s" % failed[0])

    print("PASS: M3.3 hardware BERR capability reported and bus-error frame recovery verified")


if __name__ == "__main__":
    main()
