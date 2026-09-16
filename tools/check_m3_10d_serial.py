#!/usr/bin/env python3
import pathlib,sys
families=('68000','68010','68020','68030','68040','68060')
if len(sys.argv)!=3 or sys.argv[2] not in families: raise SystemExit('usage: check_m3_10d_serial.py FILE FAMILY')
t=pathlib.Path(sys.argv[1]).read_text(errors='replace'); f=sys.argv[2]
req=['AMIDIAG proto=1 milestone=M3.10d cpu=68k','BOOT phase=reset status=PASS','TEST id=CPU.ID.GUARD status=PASS exception=ILLEGAL recovery=armed']
paths={
'68000':['PROBE class=CPU feature=VBR instruction=MOVEC result=ILLEGAL'],
'68010':['PROBE class=CPU feature=VBR instruction=MOVEC result=PRESENT','PROBE class=CPU feature=CACR instruction=MOVEC result=ILLEGAL'],
'68020':['PROBE class=CPU feature=CACR instruction=MOVEC result=PRESENT','PROBE class=CPU feature=CACR.ED bit=8 result=IGNORED restore=PASS'],
'68030':['PROBE class=CPU feature=CACR.ED bit=8 result=PRESENT restore=PASS','PROBE class=CPU feature=ITT0 instruction=MOVEC result=ILLEGAL'],
'68040':['PROBE class=CPU feature=ITT0 instruction=MOVEC result=PRESENT','PROBE class=CPU feature=PCR instruction=MOVEC result=ILLEGAL'],
'68060':['PROBE class=CPU feature=ITT0 instruction=MOVEC result=PRESENT','PROBE class=CPU feature=PCR instruction=MOVEC result=PRESENT']}
req += paths[f]+[f'CPU family={f} confidence=architectural',f'TEST id=CPU.ID status=PASS family={f}',f'TEST id=CPU.BASELINE status=PASS cpu={"68000" if f=="68000" else "68k"} probe=family-identification']
for s in req:
    if s not in t: raise SystemExit('FAIL: missing '+s)
if 'status=FAIL' in t: raise SystemExit('FAIL: transcript contains status=FAIL')
print('PASS: M3.10d serial family='+f)
