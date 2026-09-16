# M3.10d Qualification

Status: **PASS**

M3.10d extends the clean-room guarded CPU-family classifier through the classic 68k families used by AmiDiag: 68000, 68010, 68020, 68030, 68040 and 68060.

## Qualified source

- Source commit: `65f88cf253282a2b9cfd9fd2720222406be46be5`
- GitHub Actions run: `35098492762`
- Backend: FS-UAE on Ubuntu 24.04 GitHub-hosted runners
- Build baseline: `-m68000`
- ROM size check: exactly 524288 bytes

## Qualification matrix

| FS-UAE CPU profile | Expected AmiDiag family | Result |
| --- | --- | --- |
| 68000 | 68000 | PASS |
| 68010 | 68010 | PASS |
| 68020 | 68020 | PASS |
| 68030 | 68030 | PASS |
| 68040 | 68040 | PASS |
| 68060 | 68060 | PASS |

Every matrix job completed ROM validation, serial qualification and evidence upload successfully.

## Identification chain

The qualified chain is capability-driven and guarded:

1. `MOVEC VBR,D0` distinguishes 68000 from 68010+.
2. `MOVEC CACR,D0` distinguishes 68010 from 68020+.
3. For 68020+, guarded read-only `MOVEC ITT0,D0` first separates 68040+ from 68020/68030.
4. If ITT0 is unavailable, the reversible CACR.ED bit-8 probe distinguishes 68020 from 68030 and restores the original CACR.
5. If ITT0 is available, guarded read-only `MOVEC PCR,D0` distinguishes 68040 from 68060.

The ITT0-before-CACR.ED ordering is required because the earlier M3.10c CACR.ED discriminator is not a valid 68030-vs-later-family discriminator. The first M3.10d qualification attempt exposed this and the ordering was corrected before qualification was accepted.

## Clean-room scope

The implementation is based on public Motorola/NXP architecture documentation, public toolchain behaviour and emulator-observable behaviour. No Kickstart source, DiagROM source or proprietary diagnostic-ROM source was used.

The later-family probes are encoded as raw instruction words so the ROM remains buildable with the 68000 baseline. ITT0 and PCR are read-only probes and do not intentionally alter translation or processor-control state.

## Evidence and limitations

Run `35098492762` demonstrates the complete six-family decision tree under the selected FS-UAE backend. This is emulator qualification, not proof of every physical CPU/revision or accelerator implementation. Real-hardware qualification remains desirable before making stronger hardware-wide claims, particularly around exception-frame recovery on later processors.

## Freeze

After the successful run, `.github/workflows/m3_10d-fsuae.yml` was changed to manual-only and pinned to the qualified source commit. This preserves the qualification as reproducible evidence rather than silently retesting later source under the M3.10d label.

Next: M3.10e consolidated CPU capability/matrix reporting.
