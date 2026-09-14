#!/usr/bin/env python3
import pathlib
import struct
import sys

ROM_BASE = 0x00F80000
ROM_SIZE = 512 * 1024
CHIP_RAM_MAX = 0x00200000

REQUIRED_MARKERS = (
    b"AMIDIAG proto=1 milestone=M2.1",
    b"BOOT phase=reset",
    b"BOOT.VECTORS",
    b"BOOT.SERIAL",
    b"MEM.CHIP.PROBE",
    b"MEM region=CHIP",
    b"confidence=profile-verified",
    b"EXCEPTION id=CPU.BUS",
    b"EXCEPTION id=CPU.ADDRESS",
    b"EXCEPTION id=CPU.UNKNOWN",
)


def fail(message: str) -> None:
    print(f"FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    if len(sys.argv) != 2:
        fail("usage: check_rom.py <amidiag.rom>")
    path = pathlib.Path(sys.argv[1])
    data = path.read_bytes()
    if len(data) != ROM_SIZE:
        fail(f"ROM size is {len(data)}, expected {ROM_SIZE}")
    initial_sp, reset_pc = struct.unpack_from(">II", data, 0)
    if initial_sp == 0 or initial_sp > CHIP_RAM_MAX or (initial_sp & 1):
        fail(f"implausible 68000 initial SP 0x{initial_sp:08X}")
    if not (ROM_BASE <= reset_pc < ROM_BASE + ROM_SIZE) or (reset_pc & 1):
        fail(f"reset PC outside ROM: 0x{reset_pc:08X}")
    for marker in REQUIRED_MARKERS:
        if marker not in data:
            fail(f"missing marker {marker!r}")
    print(f"PASS: size={len(data)} sp=0x{initial_sp:08X} reset=0x{reset_pc:08X} markers={len(REQUIRED_MARKERS)}")


if __name__ == "__main__":
    main()
