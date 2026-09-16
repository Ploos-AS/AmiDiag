# M3.10c — guarded 68020 vs 68030 identification

Status: design

## Goal

Extend the already-qualified M3.10b chain so AmiDiag can distinguish a 68020 from a 68030 while preserving the 68000-safe baseline and deterministic serial protocol.

Target chain after this milestone:

`68000 -> 68010 -> 68020 -> 68030+`

M3.10c deliberately stops at `68030+`. Separation of 68030 from 68040/68060 remains M3.10d.

## Clean-room rules

Only public Motorola/NXP architectural documentation, public assembler/toolchain behaviour, and emulator behaviour may be used. Do not inspect Kickstart, DiagROM, or proprietary diagnostic-ROM source.

## Capability strategy

M3.10b remains the entry guard:

1. guarded `MOVEC VBR,D0`: 68000 is rejected through vector #4;
2. guarded `MOVEC CACR,D0`: 68010 is rejected through vector #4;
3. only a CPU already classified as `68020+` reaches the M3.10c discriminator.

The M3.10c discriminator will use an architectural 68030-only control/MMU capability encoded as raw instruction words and protected by the same recoverable illegal-instruction mechanism. The exact instruction/control-register encoding must be verified against public architecture documentation and/or GNU binutils before implementation is frozen.

Expected classification semantics:

- discriminator illegal on a qualified `68020+` path -> `family=68020`;
- discriminator present -> bounded `family=68030+`;
- unexpected exception/frame behaviour -> `FAIL` rather than guessing a family.

No MMU configuration or persistent machine-state change is permitted merely to identify the CPU. If the chosen capability reads architectural state, the probe must be read-only. If a write is unavoidable, original state must be captured and restored before PASS.

## Protocol

Common records:

```
AMIDIAG proto=1 milestone=M3.10c cpu=68k
BOOT phase=reset status=PASS
TEST id=CPU.ID.GUARD status=PASS exception=ILLEGAL recovery=armed
```

68020 path:

```
PROBE class=CPU feature=68030 discriminator=<verified-capability> result=ILLEGAL
CPU family=68020 confidence=architectural
TEST id=CPU.ID status=PASS family=68020
TEST id=CPU.BASELINE status=PASS cpu=68k probe=family-identification
```

68030 positive path:

```
PROBE class=CPU feature=68030 discriminator=<verified-capability> result=PRESENT
CPU family=68030+ confidence=architectural
TEST id=CPU.ID status=PASS family=68030+
TEST id=CPU.BASELINE status=PASS cpu=68k probe=family-identification
```

Existing 68000 and 68010 classifications remain unchanged except for the milestone banner.

## Qualification matrix

GitHub Actions/FS-UAE qualification should cover at least:

| CPU | Expected |
| --- | --- |
| 68000 | 68000 |
| 68010 | 68010 |
| 68020 | 68020 |
| 68030 | 68030+ |

Every profile must build the same 68000-baseline ROM and pass static ROM validation plus deterministic serial validation.

## Evidence

Retain per profile:

- ROM and linker map;
- serial transcript;
- FS-UAE configuration/log;
- tool versions;
- ROM SHA-256.

## Freeze gate

Do not freeze M3.10c until:

1. the exact 68030 discriminator and raw encoding are independently verified from public architecture/toolchain evidence;
2. both 68020 negative and 68030 positive paths pass in the automated matrix;
3. 68000 and 68010 regression profiles remain PASS.
