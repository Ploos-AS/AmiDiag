#!/usr/bin/env python3
import pathlib, sys
REQ=[
"AMIDIAG proto=1 milestone=M4.3 cpu=68000",
"BOOT phase=reset status=PASS",
"CIAA.ICR status=PASS source=TIMERA pending=observed mask=set-clear cleanup=PASS",
"CIAB.ICR status=PASS source=TIMERA pending=observed mask=set-clear cleanup=PASS",
"TEST id=CIA.ICR status=PASS devices=2 cleanup=2"]
def fail(s): print('FAIL: '+s); raise SystemExit(1)
def main():
 if len(sys.argv)!=2: fail('usage: check_m4_3_serial.py LOG')
 lines=[x.strip() for x in pathlib.Path(sys.argv[1]).read_text(errors='replace').replace('\r','').splitlines() if x.strip()]
 for r in REQ:
  if lines.count(r)!=1: fail('record count != 1: '+r)
 if any('status=FAIL' in x for x in lines): fail('transcript contains status=FAIL')
 idx=[lines.index(r) for r in REQ]
 if idx!=sorted(idx): fail('records out of order')
 print('PASS: M4.3 CIA ICR records')
if __name__=='__main__': main()
