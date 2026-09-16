#!/usr/bin/env python3
import pathlib, sys
p=pathlib.Path(sys.argv[1]); data=p.read_bytes()
if len(data)!=524288: raise SystemExit(f'FAIL: ROM size {len(data)} != 524288')
markers=[b'AMIDIAG proto=1 milestone=M3.10c cpu=68k',b'TEST id=CPU.ID.GUARD status=PASS',b'CPU family=68000 confidence=architectural',b'CPU family=68010 confidence=architectural',b'CPU family=68020 confidence=architectural',b'CPU family=68030+ confidence=architectural',b'feature=CACR.ED bit=8']
for m in markers:
    if m not in data: raise SystemExit(f'FAIL: missing ROM marker {m!r}')
print('PASS: M3.10c ROM markers and size')
