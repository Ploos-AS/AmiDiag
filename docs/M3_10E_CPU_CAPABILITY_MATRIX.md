# M3.10e — Consolidated CPU Capability Matrix

Status: DESIGN

M3.10e consolidates the qualified M3.10a–M3.10d guarded probes into one stable capability report. It does not add a new destructive CPU probe and does not weaken the 68000 build baseline.

## Goals

- Report the identified CPU family and the architectural evidence used to reach it.
- Expose a machine-readable capability set for later AmiDiag diagnostics.
- Keep family identification separate from optional feature availability.
- Preserve deterministic serial output and the existing PASS/FAIL/SKIP/WARN/UNAVAILABLE vocabulary.
- Remain clean-room and buildable as 68000 code; later instructions stay raw guarded words where needed.

## Qualified identification inputs

| Probe | Architectural meaning in AmiDiag | Qualified families |
| --- | --- | --- |
| VBR MOVEC | unavailable on 68000; available on 68010+ | M3.10a+ |
| CACR MOVEC | unavailable on 68010; available on 68020+ | M3.10b+ |
| ITT0 MOVEC | separates 68040+ from the 68020/68030 path | M3.10d |
| CACR.ED bit 8 | on the ITT0-unavailable path, separates 68020 from 68030 | M3.10c/d |
| PCR MOVEC | on the ITT0-present path, separates 68040 from 68060 | M3.10d |

The qualified decision order is VBR → CACR → ITT0 → {CACR.ED or PCR}. ITT0 must precede CACR.ED for later-family classification.

## Stable family result

M3.10e retains these family values:

- `68000`
- `68010`
- `68020`
- `68030`
- `68040`
- `68060`
- `UNKNOWN_68K`

A family is emitted only when the guarded decision tree reaches a qualified architectural classification. An unexpected or contradictory probe combination must not be guessed into a family.

## Capability records

After `TEST id=CPU.ID`, M3.10e emits deterministic capability records:

`CAP class=CPU name=<capability> status=<PRESENT|ABSENT|UNAVAILABLE> source=<probe>`

Initial capabilities:

| Capability | 68000 | 68010 | 68020 | 68030 | 68040 | 68060 |
| --- | --- | --- | --- | --- | --- | --- |
| VBR | ABSENT | PRESENT | PRESENT | PRESENT | PRESENT | PRESENT |
| CACR | ABSENT | ABSENT | PRESENT | PRESENT | PRESENT | PRESENT |
| CACR.ED | ABSENT | ABSENT | ABSENT | PRESENT | UNAVAILABLE | UNAVAILABLE |
| ITT0 | ABSENT | ABSENT | ABSENT | ABSENT | PRESENT | PRESENT |
| PCR | ABSENT | ABSENT | ABSENT | ABSENT | ABSENT | PRESENT |

`UNAVAILABLE` for CACR.ED on 68040/68060 is intentional: M3.10e does not treat that M3.10c discriminator as a meaningful later-family capability. This avoids turning an identification implementation detail into a false architectural promise.

## Summary record

The final consolidated record is:

`CPU.SUMMARY family=<family> id_status=<PASS|FAIL> capabilities=<count> confidence=architectural`

For a normal classified CPU, `id_status=PASS`. Contradictory or unrecoverable probe state produces `family=UNKNOWN_68K id_status=FAIL` and must not continue into family-specific diagnostics as though identification succeeded.

## Consumer contract

Later milestones should consume capability records where a diagnostic depends on a specific architectural facility. They may consume the family value where model/family identity itself is required. A future accelerator or unusual implementation can therefore report a capability conservatively without forcing AmiDiag to pretend it is another CPU family.

## Qualification plan

M3.10e qualification reuses the six FS-UAE profiles already proven by M3.10d:

- 68000
- 68010
- 68020
- 68030
- 68040
- 68060

For each profile the serial validator must verify:

1. the expected `CPU family=` result;
2. `TEST id=CPU.ID status=PASS`;
3. every capability row exactly once with the expected state;
4. one matching `CPU.SUMMARY` record;
5. no `status=FAIL` record.

The M3.10e workflow should be active only until qualification passes, then be frozen manual-only and pinned to its qualified source, following the M3.10d pattern.

## Clean-room boundary

No Kickstart source, DiagROM source, or proprietary diagnostic-ROM source is used. The consolidated report is derived only from AmiDiag's own previously qualified clean-room probes and public architecture behaviour.
