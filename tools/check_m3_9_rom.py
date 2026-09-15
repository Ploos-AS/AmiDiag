#!/usr/bin/env python3
import sys

p = sys.argv[1]
data = open(p, 'rb').read()
if len(data) != 524288:
    raise SystemExit(f'FAIL: ROM size {len(data)}, expected 524288')
markers = [
    b'AMIDIAG proto=1 milestone=M3.9 cpu=68000',
    b'TEST id=CPU.MODE.SUPERVISOR status=PASS',
    b'TEST id=CPU.MODE.USER status=PASS',
    b'TEST id=CPU.EXCEPTION.PRIVILEGE status=PASS',
    b'TEST id=CPU.MODE.RECOVERY status=PASS',
    b'TEST id=CPU.MODE status=PASS cpu=68000 tests=4',
    b'TEST id=CPU.BASELINE status=PASS cpu=68000 probe=supervisor-user-mode',
]
for marker in markers:
    if marker not in data:
        raise SystemExit(f'FAIL: missing ROM marker {marker!r}')
print('M3.9 ROM STATIC PASS')
