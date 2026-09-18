#!/usr/bin/env python3
import pathlib,sys

MARK=[
 b'AMIDIAG proto=1 milestone=M4.4 cpu=68000\r\n',
 b'IRQ.DIAG paula=PORTS intreq=software-set status=PASS\r\n',
 b'IRQ.PAULA status=PASS',
 b'IRQ.CPU status=PASS',
 b'TEST id=IRQ.CONTROLLER status=PASS paths=2 cleanup=2\r\n',
]

# M4.4 isolates the Amiga interrupt-controller path:
# Paula PORTS request -> Paula enable/request state -> 68000 level-2 autovector.
# CIA-local Timer-A/ICR behavior is qualified separately by M4.3.
#
# INTENAR is deliberately required: the ROM must snapshot Paula's original
# interrupt-enable state so cleanup can restore it after the takeover test.
REG=(
 0x00DFF01C, # INTENAR
 0x00DFF01E, # INTREQR
 0x00DFF09A, # INTENA
 0x00DFF09C, # INTREQ
)

def die(x):
 print('FAIL: '+x)
 raise SystemExit(1)

def main():
 if len(sys.argv)!=2:
  die('usage: check_m4_4_rom.py ROM')
 d=pathlib.Path(sys.argv[1]).read_bytes()
 if len(d)!=524288:
  die('ROM size != 524288')
 for m in MARK:
  if d.count(m)!=1:
   die('marker count != 1: '+repr(m))
 for a in REG:
  if a.to_bytes(4,'big') not in d:
   die('missing register reference 0x%08X'%a)
 print('PASS: M4.4 ROM Paula/68000 interrupt-controller markers')

if __name__=='__main__':
 main()
