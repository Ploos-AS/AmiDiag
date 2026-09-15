# M3.10 — Safe CPU Family Identification

## Goal

Identify the installed 68k CPU family as far as it can be distinguished safely, without weakening AmiDiag's 68000 baseline and without depending on AmigaOS or Kickstart.

## Clean-room rule

Implementation is based only on public Motorola/NXP 68k architectural documentation and documented instruction/exception behaviour. No Kickstart, DiagROM, or proprietary diagnostic-ROM source is used.

## Design rule

CPU identification must be capability-driven. AmiDiag must never execute a later-CPU instruction until a recoverable illegal-instruction exception path is installed and armed.

The baseline ROM remains valid 68000 code. Later-family probes are encoded as raw instruction words where necessary so the assembler cannot silently raise the minimum CPU target.

## Identification ladder

### Stage 1 — 68000 versus 68010+

Use a guarded probe of `MOVEC VBR,Dn`.

- 68000: illegal-instruction exception => classify baseline as `68000`.
- 68010 or later: instruction succeeds => classify `68010+` and continue.

The illegal-instruction handler must recover to a known continuation and report the probe outcome deterministically.

### Stage 2 — later-family refinement

Refinement beyond `68010+` is deliberately split into later M3.10 substeps. Each discriminator must satisfy all of these conditions before implementation:

1. documented architectural difference,
2. safe on every CPU that can reach the probe,
3. recoverable if unsupported,
4. no MMU/FPU assumption,
5. deterministic under supported emulator profiles,
6. does not alter the 68000 baseline binary contract.

Target classifications are:

- `68000`
- `68010`
- `68020`
- `68030`
- `68040`
- `68060`
- `UNKNOWN_68K` when safe discrimination is not possible

AmiDiag must prefer a conservative family/range result over an unsafe exact guess.

## M3.10a scope

The first implementation step is intentionally bounded to safe `68000` versus `68010+` discrimination.

Expected records:

```text
AMIDIAG proto=1 milestone=M3.10a cpu=68k
TEST id=CPU.ID.GUARD status=PASS exception=ILLEGAL recovery=armed
PROBE class=CPU feature=VBR instruction=MOVEC result=ILLEGAL
CPU family=68000 confidence=architectural
TEST id=CPU.ID status=PASS family=68000
TEST id=CPU.BASELINE status=PASS cpu=68000 probe=family-identification
```

On a later CPU where the VBR probe succeeds:

```text
PROBE class=CPU feature=VBR instruction=MOVEC result=PRESENT
CPU family=68010+ confidence=architectural
TEST id=CPU.ID status=PASS family=68010+
```

## Qualification plan

M3.10a must be qualified first on an A500/68000 FS-UAE profile. A later-CPU emulator profile must then demonstrate the positive `MOVEC` path before M3.10a is frozen.

Qualification evidence must retain:

- ROM
- linker map
- serial transcript for each CPU profile
- emulator configuration/log
- toolchain and emulator versions
- ROM SHA-256

As with earlier milestones, the successful workflow is frozen to the exact qualified source commit and changed to `workflow_dispatch` only.

## Future M3.10 substeps

- M3.10a: guarded 68000 vs 68010+ identification
- M3.10b: safe 68010 vs 68020+ discriminator
- M3.10c: 68020/68030 refinement
- M3.10d: 68040/68060 refinement
- M3.10e: consolidated CPU capability record and qualification matrix

Exact later-family discriminators are selected only after their safety and emulator qualification behaviour have been reviewed.
