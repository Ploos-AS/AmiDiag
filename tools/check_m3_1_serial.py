#!/usr/bin/env python3
import pathlib
import re
import sys

EXPECTED = [
    "AMIDIAG proto=1 milestone=M3.1 cpu=68000",
    "BOOT phase=reset status=PASS",
    "TEST id=CPU.VECTORS status=PASS table=ram",
]
FRAME_RE = re.compile(r"^FRAME id=CPU\.TRAP0 sr=0x([0-9A-F]{4}) pc=0x([0-9A-F]{8})$")
RECOVER = "TEST id=CPU.EXCEPTION.RECOVER status=PASS vector=TRAP0 frame=sr-pc return=RTE"
BASELINE = "TEST id=CPU.BASELINE status=PASS cpu=68000 exception=trap0"

def fail(msg):
    print("FAIL: " + msg, file=sys.stderr)
    raise SystemExit(1)

def main():
    if len(sys.argv) != 2:
        fail("usage: check_m3_1_serial.py <transcript>")
    lines = [x.strip() for x in pathlib.Path(sys.argv[1]).read_text(errors="replace").splitlines() if x.strip()]
    pos = 0
    for expected in EXPECTED:
        try:
            pos = lines.index(expected, pos) + 1
        except ValueError:
            fail("missing expected record: %s" % expected)
    frame_index = None
    frame_match = None
    for i in range(pos, len(lines)):
        m = FRAME_RE.match(lines[i])
        if m:
            frame_index = i
            frame_match = m
            break
    if frame_match is None:
        fail("missing or malformed TRAP0 frame record")
    pc = int(frame_match.group(2), 16)
    if not (0x00F80000 <= pc < 0x01000000):
        fail("captured return PC is outside ROM: 0x%08X" % pc)
    try:
        recover_i = lines.index(RECOVER, frame_index + 1)
        lines.index(BASELINE, recover_i + 1)
    except ValueError as exc:
        fail("missing recovery/baseline PASS record: %s" % exc)
    bad = [x for x in lines if (x.startswith("TEST ") or x.startswith("EXCEPTION ")) and "status=FAIL" in x]
    if bad:
        fail("failure record present: %s" % bad[0])
    print("PASS: M3.1 TRAP0 frame captured and RTE returned; pc=0x%08X" % pc)

if __name__ == "__main__":
    main()
