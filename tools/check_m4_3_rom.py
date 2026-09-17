#!/usr/bin/env python3
import pathlib,sys
MARKERS=[b'AMIDIAG proto=1 milestone=M4.3 cpu=68000\r\n',b'CIAA.ICR status=PASS',b'CIAB.ICR status=PASS',b'TEST id=CIA.ICR status=PASS devices=2 cleanup=2\r\n']
REGS=(0x00BFE401,0x00BFED01,0x00BFEE01,0x00BFD400,0x00BFDD00,0x00BFDE00)
def fail(s): print('FAIL: '+s); raise SystemExit(1)
def main():
 if len(sys.argv)!=2: fail('usage: check_m4_3_rom.py ROM')
 d=pathlib.Path(sys.argv[1]).read_bytes()
 if len(d)!=524288: fail('ROM size != 524288')
 for m in MARKERS:
  if d.count(m)!=1: fail('marker count != 1: '+repr(m))
 for a in REGS:
  if a.to_bytes(4,'big') not in d: fail('missing register reference 0x%08X'%a)
 print('PASS: M4.3 ROM ICR/Timer A registers and records')
if __name__=='__main__': main()
