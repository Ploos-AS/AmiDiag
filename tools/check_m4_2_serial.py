#!/usr/bin/env python3
import pathlib, sys
REQ=[
"AMIDIAG proto=1 milestone=M4.2 cpu=68000",
"BOOT phase=reset status=PASS",
"CIAA.TIMERA status=PASS mode=poll progress=observed restore=PASS",
"CIAA.TIMERB status=PASS mode=poll progress=observed restore=PASS",
"CIAB.TIMERA status=PASS mode=poll progress=observed restore=PASS",
"CIAB.TIMERB status=PASS mode=poll progress=observed restore=PASS",
"TEST id=CIA.TIMERS status=PASS timers=4 restored=4"]
def fail(s): print('FAIL: '+s); raise SystemExit(1)
def main():
 if len(sys.argv)!=2: fail('usage: check_m4_2_serial.py LOG')
 lines=[x.strip() for x in pathlib.Path(sys.argv[1]).read_text(errors='replace').replace('\r','').splitlines() if x.strip()]
 for r in REQ:
  if lines.count(r)!=1: fail('record count != 1: '+r)
 if any('status=FAIL' in x for x in lines): fail('transcript contains status=FAIL')
 if [lines.index(r) for r in REQ] != sorted(lines.index(r) for r in REQ): fail('records out of order')
 print('PASS: M4.2 four CIA timers')
if __name__=='__main__': main()
