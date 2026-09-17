#!/usr/bin/env python3
import pathlib,sys
MARK=[b'AMIDIAG proto=1 milestone=M4.4 cpu=68000\r\n',b'IRQ.PAULA status=PASS',b'IRQ.CPU status=PASS',b'TEST id=IRQ.CONTROLLER status=PASS paths=2 cleanup=2\r\n']
# Registers referenced by the current M4.4 implementation. INTENAR is part of
# the architectural documentation but is not read by this qualification ROM.
REG=(0x00BFED01,0x00DFF01E,0x00DFF09A,0x00DFF09C)
def die(x): print('FAIL: '+x); raise SystemExit(1)
def main():
 if len(sys.argv)!=2: die('usage: check_m4_4_rom.py ROM')
 d=pathlib.Path(sys.argv[1]).read_bytes()
 if len(d)!=524288: die('ROM size != 524288')
 for m in MARK:
  if d.count(m)!=1: die('marker count != 1: '+repr(m))
 for a in REG:
  if a.to_bytes(4,'big') not in d: die('missing register reference 0x%08X'%a)
 print('PASS: M4.4 ROM Paula/CIA markers')
if __name__=='__main__': main()
