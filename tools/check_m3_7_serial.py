#!/usr/bin/env python3
import argparse
from pathlib import Path
ap=argparse.ArgumentParser(); ap.add_argument('serial'); ap.add_argument('--slow',choices=('absent','present'),required=True); ap.add_argument('--fast',choices=('absent','present'),required=True); a=ap.parse_args()
s=Path(a.serial).read_text(errors='replace')
for x in ('AMIDIAG proto=1 milestone=M3.7 cpu=68000','TEST id=MEM.EXPANSION.PROBE.GUARD status=PASS','TEST id=MEM.EXPANSION.PROBE status=PASS','TEST id=CPU.BASELINE status=PASS cpu=68000 probe=guarded-expansion-memory'):
    assert x in s,x
for region,address,want in (('SLOW','0x00C00000',a.slow),('FAST','0x00200000',a.fast)):
    prefix=f'PROBE class=MEM region={region} address={address}'
    lines=[l for l in s.splitlines() if l.startswith(prefix)]
    assert len(lines)==1,(region,lines)
    if want=='present': assert 'result=PRESENT' in lines[0],lines[0]
    else: assert 'result=PRESENT' not in lines[0],lines[0]
assert 'status=FAIL' not in s
assert 'EXCEPTION id=' not in s
print(f'PASS: M3.7 serial slow={a.slow} fast={a.fast}')
