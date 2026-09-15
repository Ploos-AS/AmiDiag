#!/usr/bin/env python3
import struct, sys
from pathlib import Path
p=Path(sys.argv[1] if len(sys.argv)>1 else 'build/amidiag-m3_7.rom')
d=p.read_bytes()
assert len(d)==524288
sp,pc=struct.unpack('>II',d[:8])
assert sp==0x0007fffc
assert 0x00f80000 <= pc <= 0x00ffffff
for m in (b'milestone=M3.7',b'MEM.EXPANSION.PROBE.GUARD',b'region=SLOW',b'0x00C00000',b'region=FAST',b'0x00200000',b'guarded-profile-probe'):
    assert m in d,m
print('PASS: M3.7 ROM structure and guarded Slow/Fast markers')
