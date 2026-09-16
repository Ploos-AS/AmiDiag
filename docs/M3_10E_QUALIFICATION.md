# M3.10e Qualification

Status: **PASS / FROZEN**

M3.10e consolidates the clean-room guarded CPU-family probes qualified in M3.10a through M3.10d into deterministic family and capability records.

## Qualified source

- Source/head: `247a699251b5e090d956ceaef466f0fbe3f1234d`
- Qualification run: `35125320235`
- Result: `success`
- Workflow: `.github/workflows/m3_10e-fsuae.yml`

## Matrix

All six FS-UAE CPU profiles passed the ROM validator, serial/capability validator and evidence stage:

| CPU | Job | Result |
| --- | ---: | --- |
| 68000 | 104892827604 | PASS |
| 68010 | 104892827607 | PASS |
| 68020 | 104892827242 | PASS |
| 68030 | 104892827448 | PASS |
| 68040 | 104892827645 | PASS |
| 68060 | 104892827428 | PASS |

## Qualified decision order

The identification path is intentionally ordered:

1. VBR MOVEC: 68000 vs 68010+
2. CACR MOVEC: 68010 vs 68020+
3. ITT0 MOVEC: 68020/68030 path vs 68040+
4. CACR.ED on the 68020/68030 path
5. PCR MOVEC on the 68040+ path

ITT0 must remain before CACR.ED. This ordering is inherited from the M3.10d qualification and avoids treating later-family CACR behavior as the 68020/68030 discriminator.

## Capability contract

Each successful family emits exactly one record for each stable capability name:

- `VBR`
- `CACR`
- `CACR.ED`
- `ITT0`
- `PCR`

Statuses are `PRESENT`, `ABSENT`, or `UNAVAILABLE`. `CACR.ED` is deliberately `UNAVAILABLE` on 68040/68060 because it is not used as an architectural promise on that path.

Each run also emits exactly one matching `CPU.SUMMARY` with `id_status=PASS`, `capabilities=5`, and `confidence=architectural`.

## Validators

- `tools/check_m3_10e_rom.py` verifies ROM size and required M3.10e protocol markers.
- `tools/check_m3_10e_serial.py` verifies the family-specific probe path, family identity, all five capability records exactly once, summary, baseline record, absence of other family records, and absence of `status=FAIL`.
- `tools/run_fsuae_m3_10e.sh` captures and validates serial output under FS-UAE.

## Freeze

After PASS run `35125320235`, the M3.10e workflow was changed to manual-only and pinned to qualified source `247a699251b5e090d956ceaef466f0fbe3f1234d`. The freeze commit is `471a46736fd4e73b5b898ce69db0ffd946fa2612`.

Any semantic change to the M3.10e CPU identification, capability contract, validators, or qualification environment requires reopening qualification rather than silently changing this frozen evidence path.

## Scope and limitations

This is emulator qualification under FS-UAE, not a claim of electrical or silicon-level qualification on every physical Motorola CPU or Amiga model. Real-hardware qualification can be added separately without weakening this reproducible CI evidence.

The implementation remains clean-room: no DiagROMV2 source, Kickstart source, or proprietary diagnostic-ROM source is used. The probes are based on publicly documented 68k architectural behavior and qualified emulator behavior.
