# M3.10a Qualification

Status: **PASS**

M3.10a qualifies the first clean-room CPU-family identification boundary: a 68000 baseline versus a CPU with the 68010+ VBR/MOVEC capability.

## Qualified source

- Source commit: `2749585fece6961442a632cfee294487209b37c8`
- GitHub Actions run: `35031480310`
- 68000 job: `104590756538`
- 68020 job: `104590756232`
- Runner: Ubuntu 24.04
- Emulator: FS-UAE under Xvfb

## Matrix

| Profile | Machine | Expected classification | Result |
| --- | --- | --- | --- |
| 68000 | A500 | `68000` | PASS |
| 68020 | A1200 | `68010+` | PASS |

The 68020 profile is intentionally only a positive test of the M3.10a `68010+` capability boundary. Exact 68010/68020 separation is deferred to M3.10b.

## Qualified behaviour

The ROM installs a recoverable illegal-instruction path before attempting the guarded VBR/MOVEC probe.

On the 68000 profile, the guarded probe raises the expected illegal-instruction exception and AmiDiag reports `family=68000`. On the 68020 profile, the instruction is present and AmiDiag reports the bounded classification `family=68010+`.

Both profiles reached their final `CPU.BASELINE status=PASS` record and passed the serial transcript validator.

## Clean-room scope

M3.10a is implemented from public 68k architectural behaviour and toolchain/emulator behaviour. No Kickstart, DiagROM, or proprietary diagnostic-ROM source is used.

The baseline ROM remains assembled for 68000. The later-family capability is probed only after the recoverable illegal-instruction path is armed, so unsupported execution does not weaken the 68000 baseline.

## Evidence

The qualification workflow retains, per matrix profile:

- the 512 KiB ROM image;
- linker map and build products;
- serial transcript;
- FS-UAE log/configuration;
- ROM SHA-256;
- FS-UAE version information.

## Freeze policy

After successful run `35031480310`, `.github/workflows/m3_10a-fsuae.yml` was changed to manual `workflow_dispatch` only and pinned to the exact qualified source commit `2749585fece6961442a632cfee294487209b37c8`.

Any later M3.10a change requires a new qualification run and a new frozen source reference.

## Next

M3.10b will add a guarded architectural discriminator for `68010` versus `68020+`, while retaining the M3.10a 68000-safe identification path.
