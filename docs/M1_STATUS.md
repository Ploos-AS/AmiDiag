# M1 Status — Minimal boot and serial heartbeat

Status: **M1.1 IMPLEMENTED / NOT YET RUNTIME QUALIFIED**

## Implemented

- 68000-safe reset entry
- explicit initial stack pointer vector
- Amiga ROM overlay release before using low Chip RAM
- direct Paula serial initialization; no Kickstart/AmigaOS calls
- serial polling/transmit primitive
- deterministic boot records
- 512 KiB ROM linker layout at the classic Amiga ROM window
- host-side ROM size/vector/marker validation
- freestanding cross-build Makefile
- low-RAM 68000 exception-vector installation after ROM overlay release
- fatal handlers for bus error, address error, illegal instruction, divide by zero, CHK, TRAPV, privilege violation, trace, Line-A and Line-F
- deterministic generic fatal-exception fallback
- host-side serial transcript checker
- expected transcript fixture and `make check-transcript` qualification hook

Expected M1.1 transcript:

```text
AMIDIAG proto=1 milestone=M1.1 cpu=68000
BOOT phase=reset status=PASS
TEST id=BOOT.VECTORS status=PASS
TEST id=BOOT.SERIAL status=PASS
```

Fatal exceptions emit an `EXCEPTION ... status=FAIL fatal=1` record and halt.

## Why RAM vectors are required

The 68000 has no movable vector base register. During reset, the Amiga ROM overlay makes the reset vectors visible at address zero. AmiDiag then releases the overlay so low addresses become Chip RAM. M1.1 therefore installs vectors 2..255 into low Chip RAM before normal diagnostics continue. This makes exception behaviour explicit instead of assuming the ROM vectors remain visible.

## Host qualification

Run:

```sh
make clean
make check
```

`make check` builds the ROM, validates ROM size/reset vectors/required markers, and validates the canonical serial transcript fixture.

After an emulator or hardware run has produced a real transcript:

```sh
make check-transcript TRANSCRIPT=build/m1_1-serial.txt
```

The checker requires all expected M1.1 records in order and rejects transcripts containing fatal exception records.

## Runtime qualification still required

M1.1 is not marked runtime PASS until the ROM has actually booted and the serial heartbeat has been captured. Qualification should verify at minimum:

1. `make clean && make check` with the configured m68k toolchain.
2. Boot the produced ROM as an A500-class diagnostic/replacement ROM.
3. Capture serial output and run `make check-transcript` against it.
4. Repeat using visible FS-UAE for human-observable qualification.
5. Record emulator version, machine profile, ROM SHA-256, toolchain version and raw serial transcript.
6. Exercise at least one deliberately triggered exception in a dedicated qualification build before M1 is frozen.

FS-UAE supports mapping the emulated Amiga serial port to a host device using its `serial_port` configuration option; the concrete PTY/logging harness should be kept separate from the deterministic transcript checker because host serial plumbing varies by environment.

## Known M1.1 limitations

- PAL/A500-class timing is the initial serial baseline.
- the stack location is an early bootstrap assumption and will be replaced/refined by M2 memory discovery.
- exception handlers report the class but do not yet decode the saved 68000 exception frame.
- fatal exceptions halt intentionally.
- no screen UI exists yet.
- no hardware diagnosis is claimed from a successful heartbeat; it proves only that the CPU executed sufficiently far to install vectors and drive the serial path.
