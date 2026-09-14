#!/usr/bin/env python3
import argparse
from pathlib import Path

p = argparse.ArgumentParser()
p.add_argument("transcript")
p.add_argument("--chip-kib", type=int, required=True, choices=(512, 1024))
a = p.parse_args()
text = Path(a.transcript).read_text(errors="replace")

required = [
    "AMIDIAG proto=1 milestone=M3.5 cpu=68000",
    "BOOT phase=reset status=PASS",
    "TEST id=MEM.PROBE.GUARD status=PASS",
    "TEST id=MEM.CHIP.CANDIDATE status=PASS base=0x00001000 candidate=0x00081000 preserve=1 alias_check=1",
    "TEST id=CPU.BASELINE status=PASS cpu=68000 probe=guarded-memory",
]
for item in required:
    if item not in text:
        raise SystemExit(f"FAIL: missing serial record: {item}")

if " status=FAIL" in text or "EXCEPTION " in text:
    raise SystemExit("FAIL: failure/exception record present")

prefix = "PROBE class=MEM region=CHIP address=0x00081000 width=16 result="
probe = [line for line in text.splitlines() if line.startswith(prefix)]
if len(probe) != 1:
    raise SystemExit(f"FAIL: expected exactly one candidate PROBE record, got {len(probe)}")
result = probe[0].split("result=", 1)[1].split()[0]

if a.chip_kib == 1024 and result != "PRESENT":
    raise SystemExit(f"FAIL: 1024 KiB profile expected PRESENT at 0x00081000, got {result}")
if a.chip_kib == 512 and result == "PRESENT":
    raise SystemExit("FAIL: 512 KiB profile unexpectedly classified second bank as PRESENT")
if result not in {"PRESENT", "ALIAS", "OPEN_BUS", "BUS_ERROR"}:
    raise SystemExit(f"FAIL: unknown candidate result {result}")

print(f"PASS: M3.5 {a.chip_kib} KiB candidate classified as {result}")
