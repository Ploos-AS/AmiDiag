#!/usr/bin/env python3
import argparse
import pathlib
import sys

NORMAL_EXPECTED = [
    "AMIDIAG proto=1 milestone=M1.2 cpu=68000",
    "BOOT phase=reset status=PASS",
    "TEST id=BOOT.VECTORS status=PASS",
    "TEST id=BOOT.SERIAL status=PASS",
]


def fail(message: str) -> None:
    print(f"FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("transcript")
    p.add_argument("--expect-exception")
    args = p.parse_args()

    path = pathlib.Path(args.transcript)
    if not path.is_file():
        fail(f"transcript not found: {path}")

    lines = [line.strip() for line in path.read_text(errors="replace").splitlines() if line.strip()]
    pos = 0
    for expected in NORMAL_EXPECTED:
        try:
            idx = lines.index(expected, pos)
        except ValueError:
            fail(f"missing expected record after line {pos}: {expected}")
        pos = idx + 1

    fatal = [line for line in lines if line.startswith("EXCEPTION ") and "status=FAIL" in line]
    if args.expect_exception:
        expected = f"EXCEPTION id={args.expect_exception} status=FAIL fatal=1"
        if expected not in lines[pos:]:
            fail(f"missing expected exception record after boot records: {expected}")
        unexpected = [line for line in fatal if line != expected]
        if unexpected:
            fail(f"unexpected fatal exception record present: {unexpected[0]}")
        print(f"PASS: M1.2 boot records followed by expected {args.expect_exception} exception")
    else:
        if fatal:
            fail(f"fatal exception record present: {fatal[0]}")
        print(f"PASS: serial transcript contains {len(NORMAL_EXPECTED)} ordered M1.2 records and no fatal exception")


if __name__ == "__main__":
    main()
