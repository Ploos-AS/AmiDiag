#!/usr/bin/env python3
import argparse
import pathlib
import sys

BASE = [
    "AMIDIAG proto=1 milestone=M2.7 cpu=68000",
    "BOOT phase=reset status=PASS",
    "TEST id=BOOT.VECTORS status=PASS",
    "TEST id=BOOT.SERIAL status=PASS",
    "TEST id=MEM.FAULT.REPORT status=PASS fields=test,address,expected,actual format=hex32",
    "TEST id=MEM.DATA status=PASS width=32 patterns=64 mode=preserve",
    "TEST id=MEM.ADDRESS status=PASS bits=A2-A18 probes=17 mode=preserve-alias",
    "TEST id=MEM.ARENA status=PASS start=0x00006000 bytes=4096 cells=1024 patterns=4 mode=preserve",
    "TEST id=MEM.MARCH status=PASS start=0x00006000 bytes=4096 cells=1024 pairs=512 algorithm=paired-c-minus mode=preserve",
    "TEST id=MEM.CHIP.DISCOVER status=PASS step=524288 mode=preserve-alias",
]
MAPS = {
    512: "MEM region=CHIP start=0x00000000 end=0x00080000 bytes=524288 confidence=discovered",
    1024: "MEM region=CHIP start=0x00000000 end=0x00100000 bytes=1048576 confidence=discovered",
    1536: "MEM region=CHIP start=0x00000000 end=0x00180000 bytes=1572864 confidence=discovered",
    2048: "MEM region=CHIP start=0x00000000 end=0x00200000 bytes=2097152 confidence=discovered",
}

def fail(message):
    print("FAIL: " + message, file=sys.stderr)
    raise SystemExit(1)

def main():
    p = argparse.ArgumentParser()
    p.add_argument("transcript")
    p.add_argument("--chip-kib", type=int, choices=sorted(MAPS), default=512)
    a = p.parse_args()
    path = pathlib.Path(a.transcript)
    if not path.is_file():
        fail("transcript not found: %s" % path)
    lines = [x.strip() for x in path.read_text(errors="replace").splitlines() if x.strip()]
    pos = 0
    for expected in BASE + [MAPS[a.chip_kib]]:
        try:
            idx = lines.index(expected, pos)
        except ValueError:
            fail("missing expected record: %s" % expected)
        pos = idx + 1
    failed_tests = [x for x in lines if x.startswith("TEST ") and "status=FAIL" in x]
    if failed_tests:
        fail("failed test record present: %s" % failed_tests[0])
    faults = [x for x in lines if x.startswith("FAULT ")]
    if faults:
        fail("unexpected fault record present: %s" % faults[0])
    fatal = [x for x in lines if x.startswith("EXCEPTION ") and "status=FAIL" in x]
    if fatal:
        fail("fatal exception record present: %s" % fatal[0])
    print("PASS: M2.7 fault-report capability and RAM diagnostics with %d KiB Chip RAM" % a.chip_kib)

if __name__ == "__main__":
    main()
