# M3.10c Qualification

Status: **PASS**

M3.10c extends clean-room guarded CPU identification through a bounded `68030+` classification while retaining the 68000-safe baseline.

## Qualified source

- Source commit: `bb293f420ab03a404c631808e97f6ac61793207d`
- GitHub Actions run: `35086136881`
- 68000 job: `104761290258`
- 68010 job: `104761290285`
- 68020 job: `104761290289`
- 68030 job: `104761290025`
- Runner: Ubuntu 24.04
- Emulator: FS-UAE under Xvfb

## Matrix

| CPU profile | Expected classification | Result |
| --- | --- | --- |
| 68000 | `68000` | PASS |
| 68010 | `68010` | PASS |
| 68020 | `68020` | PASS |
| 68030 | `68030+` | PASS |

All profiles passed ROM validation, deterministic serial validation, evidence generation, and artifact upload.

## M3.10c discriminator

After the previously qualified VBR and CACR capability guards, the 68020+ path performs a reversible CACR bit-8 probe. The complete original CACR is retained, only bit 8 is requested, CACR is read back, and the original value is restored before the result is reported.

The qualified 68020 profile reports the bit as ignored and classifies as `68020`; the qualified 68030 profile reports it present and classifies as the deliberately bounded `68030+` family.

## Clean-room scope

The implementation is based on public 68k architectural behaviour and public emulator/toolchain behaviour. No Kickstart, DiagROM, or proprietary diagnostic-ROM source is used.

Qualification here establishes the tested FS-UAE behaviour. Real-hardware qualification remains a later qualification layer and should not be inferred from emulator PASS alone.

## Evidence and freeze

Each matrix job retained the ROM/build output, linker map, serial transcript, emulator configuration/log, ROM SHA-256, and FS-UAE version information.

After successful run `35086136881`, `.github/workflows/m3_10c-fsuae.yml` was frozen to manual `workflow_dispatch` only and pinned to exact qualified source `bb293f420ab03a404c631808e97f6ac61793207d`.

Any modification to the qualified M3.10c implementation requires a new qualification run and new frozen source reference.

## Next

M3.10d will refine the `68030+` result to distinguish later CPU families, targeting 68030, 68040, and 68060 with guarded clean-room capability probes.
