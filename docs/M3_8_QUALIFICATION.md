# M3.8 Qualification

## Status

**PASS**

M3.8 qualifies the AmiDiag clean-room 68000 instruction sanity diagnostics in FS-UAE on the GitHub Actions runner.

## Qualified source

- Source head: `9a0b68800b8b7eb375f41167aaecd6b9cfc13063`
- Successful workflow run: `34969043632`
- Successful job: `104380488933`
- Runner: `ubuntu-24.04`
- Emulator: FS-UAE under Xvfb
- Machine profile: A500
- CPU baseline: 68000
- Chip RAM: 512 KiB
- ROM size: 512 KiB

The frozen workflow checks out the exact qualified source head rather than current `main`.

## Qualified tests

The runtime qualification requires deterministic PASS records for:

1. `CPU.INSTR.MOVE` — 32-bit MOVE/register data path.
2. `CPU.INSTR.ARITH` — ADD/SUB arithmetic.
3. `CPU.INSTR.LOGIC` — AND/OR/EOR logical operations.
4. `CPU.INSTR.SHIFT` — LSL/LSR/ROL shift and rotate operations.
5. `CPU.INSTR.CCR` — Z/N condition codes and BEQ/BNE/BPL branch behavior.
6. `CPU.INSTR.ADDRESS` — address-register indirect 32-bit memory round-trip.

The serial stream must also contain:

- `TEST id=CPU.INSTR.SANITY status=PASS cpu=68000 tests=6`
- `TEST id=CPU.BASELINE status=PASS cpu=68000 probe=instruction-sanity`

Any `status=FAIL` record causes qualification failure.

## Scratch RAM correction

The first M3.8 workflow run (`34967770055`) failed during linking because the initial implementation placed the address-test scratch word in `.bss`, while the ROM linker script discards `.bss`.

The qualified source instead uses fixed low Chip RAM at `0x00003020`. This is outside the M3 guarded-probe state beginning at `0x00003000` and avoids requiring writable storage in the ROM image.

## Successful workflow stages

Run `34969043632` / job `104380488933` passed all stages:

- install 68000 toolchain and FS-UAE — PASS
- build M3.8 ROM — PASS
- static ROM validation — PASS
- FS-UAE 68000 instruction sanity qualification — PASS
- serial protocol validation — PASS
- evidence recording — PASS
- evidence artifact upload — PASS

## Evidence

The workflow records and uploads:

- `amidiag-m3_8.rom`
- linker map
- captured M3.8 serial output
- FS-UAE log/configuration files produced by the harness
- toolchain version
- FS-UAE version
- ROM SHA-256

## Freeze policy

`.github/workflows/m3_8-fsuae.yml` is frozen after the successful qualification:

- trigger: `workflow_dispatch` only
- checkout: exact qualified source head `9a0b68800b8b7eb375f41167aaecd6b9cfc13063`

Future milestone development must use a new qualification workflow rather than silently changing the M3.8 evidence baseline.
