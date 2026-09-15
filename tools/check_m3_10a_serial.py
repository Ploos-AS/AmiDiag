#!/usr/bin/env python3
import sys
text=open(sys.argv[1],encoding='utf-8',errors='replace').read().replace('\r','')
family=sys.argv[2]
common=['AMIDIAG proto=1 milestone=M3.10a cpu=68k','BOOT phase=reset status=PASS','TEST id=CPU.ID.GUARD status=PASS exception=ILLEGAL recovery=armed']
if family=='68000':
    required=common+['PROBE class=CPU feature=VBR instruction=MOVEC result=ILLEGAL','CPU family=68000 confidence=architectural','TEST id=CPU.ID status=PASS family=68000','TEST id=CPU.BASELINE status=PASS cpu=68000 probe=family-identification']
elif family=='68010+':
    required=common+['PROBE class=CPU feature=VBR instruction=MOVEC result=PRESENT','CPU family=68010+ confidence=architectural','TEST id=CPU.ID status=PASS family=68010+','TEST id=CPU.BASELINE status=PASS cpu=68k probe=family-identification']
else: raise SystemExit('usage: check_m3_10a_serial.py FILE 68000|68010+')
for line in required:
    if line not in text: raise SystemExit('FAIL: missing '+line)
if 'status=FAIL' in text: raise SystemExit('FAIL: status=FAIL present')
print('M3.10a SERIAL PASS family='+family)
