# M3.10d — guarded 68030 / 68040 / 68060 identification

Status: design

## Goal

Refine the qualified M3.10c `68030+` result into explicit later-family classifications while preserving the 68000-safe baseline and all earlier guarded paths.

Target classifications after M3.10d:

`68000`, `68010`, `68020`, `68030`, `68040`, `68060`, or `UNKNOWN_68K`.

## Clean-room rules

Only public Motorola/NXP architectural documentation, public GNU/binutils behaviour, and emulator behaviour may be used. Kickstart, DiagROM, and proprietary diagnostic-ROM source remain out of scope.

## Entry condition

M3.10d executes only after the existing guarded VBR/CACR/CACR.ED chain has established `68030+`. Earlier families retain their already-qualified exits.

## Identification strategy

The later-family probes must be capability based, guarded, deterministic, and non-destructive.

The preferred direction is `MOVEC` access to later-family control registers because it avoids MMU table setup and can be encoded as raw words while the ROM itself remains assembled for the 68000 baseline.

Candidate architecture distinctions to verify before implementation:

1. **68030 vs 68040+** — probe a control register introduced with the 68040, preferably a translation-transparent register such as ITT0/ITT1/DTT0/DTT1, using a read-only `MOVEC <CR>,Dn`. An unavailable register must take the guarded illegal-instruction path on 68030.
2. **68040 vs 68060** — probe a control register documented as 68060-specific, preferably PCR (Processor Configuration Register), using read-only `MOVEC PCR,Dn`. An unavailable register must take the guarded illegal-instruction path on 68040.

These are candidates, not frozen opcodes. Exact control-register selectors, raw encodings, privilege requirements, and exception behaviour must be verified from public architecture documentation and/or GNU binutils before source implementation is accepted.

## Exception recovery

No probe may assume a 68000 exception frame on a later CPU. Before implementation, the normal illegal-instruction frame format for 68030/68040/68060 must be verified. The handler must either:

- safely patch the documented stacked PC for the applicable format and return with `RTE`; or
- discard a fully verified bounded frame and jump to a continuation.

Unexpected format/vector state is `FAIL`; AmiDiag must not guess the CPU family.

## Proposed protocol

68030:

```
PROBE class=CPU feature=68040-control result=ILLEGAL
CPU family=68030 confidence=architectural
TEST id=CPU.ID status=PASS family=68030
```

68040:

```
PROBE class=CPU feature=68040-control result=PRESENT
PROBE class=CPU feature=68060-control result=ILLEGAL
CPU family=68040 confidence=architectural
TEST id=CPU.ID status=PASS family=68040
```

68060:

```
PROBE class=CPU feature=68040-control result=PRESENT
PROBE class=CPU feature=68060-control result=PRESENT
CPU family=68060 confidence=architectural
TEST id=CPU.ID status=PASS family=68060
```

Every successful path ends with:

```
TEST id=CPU.BASELINE status=PASS cpu=68k probe=family-identification
```

## Qualification matrix

Automated qualification should retain regressions and add later CPUs:

| Emulator CPU | Expected |
| --- | --- |
| 68000 | 68000 |
| 68010 | 68010 |
| 68020 | 68020 |
| 68030 | 68030 |
| 68040 | 68040 |
| 68060 | 68060 |

If FS-UAE cannot faithfully expose one of these profiles/control registers, that profile is `UNAVAILABLE` for that backend rather than silently weakened. A second emulator backend can be added later without weakening the architectural classifier.

## Freeze gate

Do not freeze M3.10d until:

1. exact later-family control-register selectors/opcodes are verified from public sources/toolchain;
2. exception-frame recovery is verified for every CPU that can take the guarded illegal path;
3. 68030, 68040, and 68060 positive/negative paths are qualified where the emulator supports them;
4. 68000/68010/68020 regressions remain PASS;
5. evidence and exact successful source are retained and the workflow is frozen manual-only.
