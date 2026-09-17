#!/usr/bin/env python3
import pathlib,sys
REQ=["AMIDIAG proto=1 milestone=M4.4 cpu=68000","BOOT phase=reset status=PASS","IRQ.PAULA status=PASS source=PORTS intena=enabled intreq=observed cleanup=PASS","IRQ.CPU status=PASS level=2 vector=autovector handler=observed cleanup=PASS","TEST id=IRQ.CONTROLLER status=PASS paths=2 cleanup=2"]
def die(x): print('FAIL: '+x); raise SystemExit(1)
def main():
 if len(sys.argv)!=2: die('usage: check_m4_4_serial.py LOG')
 ls=[x.strip() for x in pathlib.Path(sys.argv[1]).read_text(errors='replace').replace('\r','').splitlines() if x.strip()]
 for r in REQ:
  if ls.count(r)!=1: die('record count != 1: '+r)
 if any('status=FAIL' in x for x in ls): die('transcript contains FAIL')
 if [ls.index(x) for x in REQ]!=sorted(ls.index(x) for x in REQ): die('records out of order')
 print('PASS: M4.4 Paula/CPU interrupt records')
if __name__=='__main__': main()
