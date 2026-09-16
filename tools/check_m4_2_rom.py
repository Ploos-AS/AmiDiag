#!/usr/bin/env python3
import pathlib,sys
MARKERS=[b'AMIDIAG proto=1 milestone=M4.2 cpu=68000\r\n',b'CIAA.TIMERA status=PASS',b'CIAA.TIMERB status=PASS',b'CIAB.TIMERA status=PASS',b'CIAB.TIMERB status=PASS',b'TEST id=CIA.TIMERS status=PASS timers=4 restored=4\r\n']
def fail(s): print('FAIL: '+s); raise SystemExit(1)
def main():
 if len(sys.argv)!=2: fail('usage: check_m4_2_rom.py ROM')
 d=pathlib.Path(sys.argv[1]).read_bytes()
 if len(d)!=524288: fail('ROM size != 524288')
 for m in MARKERS:
  if d.count(m)!=1: fail('marker count != 1: '+repr(m))
 for a in (0x00BFE401,0x00BFE601,0x00BFEE01,0x00BFEF01,0x00BFD400,0x00BFD600,0x00BFDE00,0x00BFDF00):
  if a.to_bytes(4,'big') not in d: fail('missing register reference 0x%08X'%a)
 print('PASS: M4.2 ROM timer registers and records')
if __name__=='__main__': main()
