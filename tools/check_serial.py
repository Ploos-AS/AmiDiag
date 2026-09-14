#!/usr/bin/env python3
import pathlib
import sys

EXPECTED = [
    "AMIDIAG proto=1 milestone=M1.1 cpu=68000",
    "BOOT phase=reset status=PASS",
    "TEST id=BOOT.VECTORS status=PASS",
    "TEST id=BOOT.SERIAL status=PASS",
]


def fail(message: str) -> None:
    print(f"FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    if len(sys.argv) != 2:
        fail("usage: check_serial.py <serial-transcript>")

    path = pathlib.Path(sys.argv[1])
    if not path.is_file():
        fail(f"transcript not found: {path}")

    lines = [line.strip() for line in path.read_text(errors="replace").splitlines() if line.strip()]
    pos = 0
    for expected in EXPECTED:
        try:
            idx = lines.index(expected, pos)
        except ValueError:
            fail(f"missing expected record after line {pos}: {expected}")
        pos = idx + 1

    fatal = [line for line in lines if line.startswith("EXCEPTION ") and "status=FAIL" in line]
    if fatal:
        fail(f"fatal exception record present: {fatal[0]}")

    print(f"PASS: serial transcript contains {len(EXPECTED)} ordered M1.1 records and no fatal exception")


if __name__ == "__main__":
    main()
