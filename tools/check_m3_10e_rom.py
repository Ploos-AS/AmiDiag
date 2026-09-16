#!/usr/bin/env python3
import sys
from pathlib import Path

EXPECTED_SIZE = 524288
MARKERS = [
    b"AMIDIAG proto=1 milestone=M3.10e cpu=68k",
    b"TEST id=CPU.ID.GUARD status=PASS",
    b"CPU family=68000 confidence=architectural",
    b"CPU family=68010 confidence=architectural",
    b"CPU family=68020 confidence=architectural",
    b"CPU family=68030 confidence=architectural",
    b"CPU family=68040 confidence=architectural",
    b"CPU family=68060 confidence=architectural",
    b"CAP class=CPU name=VBR",
    b"CAP class=CPU name=CACR",
    b"CAP class=CPU name=CACR.ED",
    b"CAP class=CPU name=ITT0",
    b"CAP class=CPU name=PCR",
    b"CPU.SUMMARY family=68000",
    b"CPU.SUMMARY family=68010",
    b"CPU.SUMMARY family=68020",
    b"CPU.SUMMARY family=68030",
    b"CPU.SUMMARY family=68040",
    b"CPU.SUMMARY family=68060",
]

def main() -> int:
    if len(sys.argv) != 2:
        print(f"usage: {sys.argv[0]} ROM", file=sys.stderr)
        return 2
    path = Path(sys.argv[1])
    data = path.read_bytes()
    if len(data) != EXPECTED_SIZE:
        print(f"FAIL size={len(data)} expected={EXPECTED_SIZE}", file=sys.stderr)
        return 1
    missing = [m.decode() for m in MARKERS if m not in data]
    if missing:
        for marker in missing:
            print(f"FAIL missing marker: {marker}", file=sys.stderr)
        return 1
    print(f"PASS M3.10e ROM size={len(data)} markers={len(MARKERS)}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
