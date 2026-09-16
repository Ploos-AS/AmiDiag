#!/usr/bin/env python3
import sys
from pathlib import Path

FAMILIES = ("68000", "68010", "68020", "68030", "68040", "68060")
CAPS = {
    "68000": {"VBR":"ABSENT","CACR":"ABSENT","CACR.ED":"ABSENT","ITT0":"ABSENT","PCR":"ABSENT"},
    "68010": {"VBR":"PRESENT","CACR":"ABSENT","CACR.ED":"ABSENT","ITT0":"ABSENT","PCR":"ABSENT"},
    "68020": {"VBR":"PRESENT","CACR":"PRESENT","CACR.ED":"ABSENT","ITT0":"ABSENT","PCR":"ABSENT"},
    "68030": {"VBR":"PRESENT","CACR":"PRESENT","CACR.ED":"PRESENT","ITT0":"ABSENT","PCR":"ABSENT"},
    "68040": {"VBR":"PRESENT","CACR":"PRESENT","CACR.ED":"UNAVAILABLE","ITT0":"PRESENT","PCR":"ABSENT"},
    "68060": {"VBR":"PRESENT","CACR":"PRESENT","CACR.ED":"UNAVAILABLE","ITT0":"PRESENT","PCR":"PRESENT"},
}
PROBES = {
    "68000": ["feature=VBR instruction=MOVEC result=ILLEGAL"],
    "68010": ["feature=VBR instruction=MOVEC result=PRESENT", "feature=CACR instruction=MOVEC result=ILLEGAL"],
    "68020": ["feature=VBR instruction=MOVEC result=PRESENT", "feature=CACR instruction=MOVEC result=PRESENT", "feature=ITT0 instruction=MOVEC result=ILLEGAL", "feature=CACR.ED bit=8 result=IGNORED restore=PASS"],
    "68030": ["feature=VBR instruction=MOVEC result=PRESENT", "feature=CACR instruction=MOVEC result=PRESENT", "feature=ITT0 instruction=MOVEC result=ILLEGAL", "feature=CACR.ED bit=8 result=PRESENT restore=PASS"],
    "68040": ["feature=VBR instruction=MOVEC result=PRESENT", "feature=CACR instruction=MOVEC result=PRESENT", "feature=ITT0 instruction=MOVEC result=PRESENT", "feature=PCR instruction=MOVEC result=ILLEGAL"],
    "68060": ["feature=VBR instruction=MOVEC result=PRESENT", "feature=CACR instruction=MOVEC result=PRESENT", "feature=ITT0 instruction=MOVEC result=PRESENT", "feature=PCR instruction=MOVEC result=PRESENT"],
}

def require(text: str, needle: str, errors: list[str]) -> None:
    if needle not in text:
        errors.append(f"missing: {needle}")

def main() -> int:
    if len(sys.argv) != 3 or sys.argv[2] not in FAMILIES:
        print(f"usage: {sys.argv[0]} SERIAL_LOG FAMILY", file=sys.stderr)
        return 2
    text = Path(sys.argv[1]).read_text(errors="replace")
    family = sys.argv[2]
    errors: list[str] = []
    require(text, "AMIDIAG proto=1 milestone=M3.10e cpu=68k", errors)
    require(text, "BOOT phase=reset status=PASS", errors)
    require(text, "TEST id=CPU.ID.GUARD status=PASS exception=ILLEGAL recovery=armed", errors)
    for probe in PROBES[family]:
        require(text, probe, errors)
    require(text, f"CPU family={family} confidence=architectural", errors)
    require(text, f"TEST id=CPU.ID status=PASS family={family}", errors)
    for name, status in CAPS[family].items():
        record = f"CAP class=CPU name={name} status={status} source=probe"
        count = text.count(record)
        if count != 1:
            errors.append(f"expected exactly once ({count}): {record}")
    require(text, f"CPU.SUMMARY family={family} id_status=PASS capabilities=5 confidence=architectural", errors)
    baseline = "cpu=68000" if family == "68000" else "cpu=68k"
    require(text, f"TEST id=CPU.BASELINE status=PASS {baseline} probe=family-identification", errors)
    if "status=FAIL" in text:
        errors.append("unexpected status=FAIL")
    other_families = [f for f in FAMILIES if f != family]
    for other in other_families:
        if f"CPU family={other} confidence=architectural" in text:
            errors.append(f"unexpected family record: {other}")
        if f"CPU.SUMMARY family={other} " in text:
            errors.append(f"unexpected summary: {other}")
    if errors:
        for error in errors:
            print(f"FAIL {error}", file=sys.stderr)
        return 1
    print(f"PASS M3.10e serial family={family} capabilities=5")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
