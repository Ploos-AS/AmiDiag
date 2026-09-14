#!/usr/bin/env python3
import sys
from pathlib import Path


def main() -> int:
    if len(sys.argv) != 2:
        print(f"usage: {sys.argv[0]} SERIAL", file=sys.stderr)
        return 2
    text = Path(sys.argv[1]).read_text(errors="replace")
    required = [
        "AMIDIAG proto=1 milestone=M3.4 cpu=68000",
        "BOOT phase=reset status=PASS",
        "TEST id=CPU.VECTORS status=PASS table=ram",
        "TEST id=CPU.PROBE.GUARD status=PASS armed=explicit bus=guarded address=guarded unexpected=fatal",
        "PROBE class=MEM address=0x00004000 width=16 result=READABLE",
        "PROBE class=MEM address=0x00000001 width=16 result=ADDRESS_ERROR",
        "TEST id=CPU.PROBE.RESULTS status=PASS readable=1 address_error=1 unmapped=classified",
        "TEST id=CPU.BASELINE status=PASS cpu=68000 probe=guarded",
    ]
    missing = [item for item in required if item not in text]
    if missing:
        print(f"FAIL: missing serial records: {missing}", file=sys.stderr)
        return 1
    unmapped = [
        "PROBE class=MEM address=0x00400000 width=16 result=BUS_ERROR",
        "PROBE class=MEM address=0x00400000 width=16 result=OPEN_BUS",
    ]
    seen = [item for item in unmapped if item in text]
    if len(seen) != 1:
        print(f"FAIL: expected exactly one unmapped classification, got {seen}", file=sys.stderr)
        return 1
    if "status=FAIL" in text or "EXCEPTION " in text:
        print("FAIL: fatal/failure record present", file=sys.stderr)
        return 1
    print(f"PASS: M3.4 guarded probes; unmapped result={seen[0].rsplit('=', 1)[-1]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
