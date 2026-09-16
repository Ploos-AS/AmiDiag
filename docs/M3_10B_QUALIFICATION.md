# M3.10b Qualification

Status: **PASS**

M3.10b extends the clean-room guarded CPU-family identification chain to distinguish 68000, 68010, and 68020+ without weakening the 68000 baseline.

## Qualified source

- Source commit: `6b3e6f764a68ad8b14b075e95bf850beceeae629`
- GitHub Actions run: `35066920676`
- 68000 job: `104699168734`
- 68010 job: `104699168840`
- 68020 job: `104699168894`
- Runner: Ubuntu 24.04
- Emulator: FS-UAE under Xvfb

## Matrix

| CPU profile | Expected classification | Result |
| --- | --- | --- |
| 68000 | `68000` | PASS |
| 68010 | `68010` | PASS |
| 68020 | `68020+` | PASS |

## Qualified behaviour

The first guarded stage retains M3.10a's VBR/MOVEC capability boundary. A 68000 reaches the recoverable illegal-instruction path, while 68010+ proceeds to the second stage.

The second guarded stage probes CACR through MOVEC. The 68010 negative path is recovered through the armed illegal-instruction vector and reports `family=68010`. The 68020 profile takes the positive path and reports the deliberately bounded `family=68020+` classification.

All three profiles reached their final `CPU.BASELINE status=PASS` record and passed ROM and serial validation.

## Clean-room scope

The milestone uses public 68k architectural behaviour and emulator/toolchain behaviour only. No Kickstart, DiagROM, or proprietary diagnostic-ROM source is used.

The ROM is still built for the 68000 baseline. Later-family instructions are represented as guarded capability probes and are only reached after the required earlier capability has succeeded.

## Evidence

Each matrix job retained the ROM, linker/build products, serial transcript, FS-UAE configuration/log, ROM SHA-256, and FS-UAE version information.

## Freeze policy

After successful run `35066920676`, `.github/workflows/m3_10b-fsuae.yml` was changed to manual `workflow_dispatch` only and pinned to exact qualified source commit `6b3e6f764a68ad8b14b075e95bf850beceeae629`.

Any change to the qualified M3.10b implementation requires a new qualification run and frozen source reference.

## Next

M3.10c will add a clean-room guarded architectural discriminator for 68020 versus 68030, while preserving the already qualified 68000 and 68010 paths.
