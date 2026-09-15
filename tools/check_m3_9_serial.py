#!/usr/bin/env python3
import sys

text = open(sys.argv[1], 'r', encoding='utf-8', errors='replace').read().replace('\r', '')
required = [
    'AMIDIAG proto=1 milestone=M3.9 cpu=68000',
    'BOOT phase=reset status=PASS',
    'TEST id=CPU.MODE.SUPERVISOR status=PASS phase=reset',
    'TEST id=CPU.MODE.USER status=PASS transition=SR.S-clear',
    'TEST id=CPU.EXCEPTION.PRIVILEGE status=PASS vector=8 instruction=STOP',
    'TEST id=CPU.MODE.RECOVERY status=PASS mode=supervisor',
    'TEST id=CPU.MODE status=PASS cpu=68000 tests=4',
    'TEST id=CPU.BASELINE status=PASS cpu=68000 probe=supervisor-user-mode',
]
for line in required:
    if line not in text:
        raise SystemExit(f'FAIL: missing serial record: {line}')
if 'status=FAIL' in text:
    raise SystemExit('FAIL: serial transcript contains status=FAIL')
print('M3.9 SERIAL PASS')
