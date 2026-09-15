#!/usr/bin/env python3
import sys
p=sys.argv[1]
data=open(p,'rb').read()
if len(data)!=524288: raise SystemExit(f'FAIL: ROM size {len(data)}')
for m in [b'AMIDIAG proto=1 milestone=M3.10a cpu=68k',b'TEST id=CPU.ID.GUARD status=PASS',b'CPU family=68000 confidence=architectural',b'CPU family=68010+ confidence=architectural']:
    if m not in data: raise SystemExit(f'FAIL: missing {m!r}')
print('M3.10a ROM STATIC PASS')
