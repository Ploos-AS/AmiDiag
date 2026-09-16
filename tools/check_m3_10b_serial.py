#!/usr/bin/env python3
import pathlib, sys
if len(sys.argv)!=3 or sys.argv[2] not in ('68000','68010','68020+'):
    raise SystemExit('usage: check_m3_10b_serial.py FILE 68000|68010|68020+')
t=pathlib.Path(sys.argv[1]).read_text(errors='replace'); family=sys.argv[2]
common=['AMIDIAG proto=1 milestone=M3.10b cpu=68k','BOOT phase=reset status=PASS','TEST id=CPU.ID.GUARD status=PASS exception=ILLEGAL recovery=armed']
expected={
'68000':['PROBE class=CPU feature=VBR instruction=MOVEC result=ILLEGAL','CPU family=68000 confidence=architectural','TEST id=CPU.ID status=PASS family=68000','TEST id=CPU.BASELINE status=PASS cpu=68000 probe=family-identification'],
'68010':['PROBE class=CPU feature=VBR instruction=MOVEC result=PRESENT','PROBE class=CPU feature=CACR instruction=MOVEC result=ILLEGAL','CPU family=68010 confidence=architectural','TEST id=CPU.ID status=PASS family=68010','TEST id=CPU.BASELINE status=PASS cpu=68k probe=family-identification'],
'68020+':['PROBE class=CPU feature=VBR instruction=MOVEC result=PRESENT','PROBE class=CPU feature=CACR instruction=MOVEC result=PRESENT','CPU family=68020+ confidence=architectural','TEST id=CPU.ID status=PASS family=68020+','TEST id=CPU.BASELINE status=PASS cpu=68k probe=family-identification']}
for s in common+expected[family]:
    if s not in t: raise SystemExit('FAIL: missing '+s)
if 'status=FAIL' in t: raise SystemExit('FAIL: transcript contains status=FAIL')
print(f'PASS: M3.10b serial family={family}')
