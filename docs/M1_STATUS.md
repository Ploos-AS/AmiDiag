# M1 Status — Minimal boot and serial heartbeat

Status: **IMPLEMENTED / NOT YET RUNTIME QUALIFIED**

## Implemented

- 68000-safe reset entry
- explicit initial stack pointer vector
- Amiga ROM overlay release before using low Chip RAM
- direct Paula serial initialization; no Kickstart/AmigaOS calls
- serial polling/transmit primitive
- deterministic M1 boot records
- 512 KiB ROM linker layout at the classic Amiga ROM window
- host-side ROM size/vector/marker validation
- freestanding cross-build Makefile

Expected initial transcript:

```text
AMIDIAG proto=1 milestone=M1 cpu=68000
BOOT phase=reset status=PASS
TEST id=BOOT.SERIAL status=PASS
```

## Qualification still required

M1 is not marked runtime PASS until the ROM has actually booted in an emulator and the serial heartbeat has been captured. Qualification should verify at minimum:

1. `make clean && make check` with the configured m68k toolchain.
2. Boot the produced ROM as an A500-class diagnostic/replacement ROM.
3. Capture serial output and compare the three deterministic records.
4. Repeat on visible FS-UAE for human-observable qualification.
5. Record emulator version, machine profile, ROM SHA-256, toolchain version and raw serial transcript.

AmiSandbox/Amiberry automation may be added after the first known-good runtime result.

## Known M1 limitations

- PAL/A500-class timing is the initial serial baseline.
- the stack location is an M1 bootstrap assumption and will be replaced/refined by M2 memory discovery.
- no screen UI exists yet.
- no exception reporter exists yet beyond the reset path; this remains an M1 follow-up before qualification freeze if practical.
- no hardware diagnosis is claimed from a successful heartbeat; it proves only that the CPU executed sufficiently far to drive the serial path.
