#!/usr/bin/env python3
import argparse
from pathlib import Path

ap = argparse.ArgumentParser()
ap.add_argument("serial")
ap.add_argument("--chip-kib", type=int, required=True, choices=(512, 1024, 1536, 2048))
a = ap.parse_args()
s = Path(a.serial).read_text(errors="replace")
for required in (
    "AMIDIAG proto=1 milestone=M3.6 cpu=68000",
    "TEST id=MEM.PROBE.GUARD status=PASS",
    "TEST id=MEM.CHIP.DISCOVER.GUARDED status=PASS",
    "TEST id=CPU.BASELINE status=PASS cpu=68000 probe=guarded-memory-discovery",
):
    assert required in s, required
expected = {
    512: "end=0x00080000 bytes=524288 confidence=guarded-discovered",
    1024: "end=0x00100000 bytes=1048576 confidence=guarded-discovered",
    1536: "end=0x00180000 bytes=1572864 confidence=guarded-discovered",
    2048: "end=0x00200000 bytes=2097152 confidence=guarded-discovered",
}[a.chip_kib]
assert expected in s, expected
# Every bank below installed RAM must classify PRESENT; the first boundary
# beyond installed RAM must not classify PRESENT.
for addr, threshold in (("0x00081000", 1024), ("0x00101000", 1536), ("0x00181000", 2048)):
    if a.chip_kib >= threshold:
        assert f"address={addr} result=PRESENT" in s, addr
    elif a.chip_kib == threshold - 512:
        assert f"address={addr} result=PRESENT" not in s, addr
print(f"PASS: M3.6 serial guarded Chip discovery ({a.chip_kib} KiB)")
