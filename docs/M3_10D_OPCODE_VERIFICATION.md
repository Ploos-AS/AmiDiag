# M3.10d MOVEC discriminator verification

Status: verified design inputs

This note records the public architectural inputs that are allowed to drive the M3.10d implementation. It intentionally contains no Kickstart, DiagROM, or proprietary diagnostic-ROM material.

## 68060 MOVEC table

The public Motorola/NXP M68060 User's Manual MOVEC table defines these control-register selectors:

- `0x004` — ITT0
- `0x005` — ITT1
- `0x006` — DTT0
- `0x007` — DTT1
- `0x008` — BUSCR
- `0x808` — PCR

The same table states that other unsupported control-register codes cause an illegal-instruction exception. PCR (`0x808`) is therefore the preferred read-only 68060 discriminator after a processor has already reached the later-family path.

## 68040 boundary

Public Motorola/NXP 68040 documentation identifies the 68040 family as having instruction/data transparent-translation facilities. M3.10d will use read-only `MOVEC ITT0,Dn` as the candidate 68040+ discriminator. The exact selector is `0x004`, shared with the later 68060 MOVEC table.

Before freeze, automated qualification must demonstrate the intended negative path on 68030 and positive path on 68040/68060. Emulator disagreement is a qualification failure or backend limitation, not permission to weaken the classifier.

## Raw MOVEC encoding

Existing qualified AmiDiag M3.10a-c uses the architectural MOVEC register-to-general-register first word `0x4E7A`. The extension word encodes the destination data register in the upper nibble and the 12-bit control-register selector below it.

For D0 reads used by M3.10d:

- `MOVEC ITT0,D0` -> `.word 0x4E7A,0x0004`
- `MOVEC PCR,D0`  -> `.word 0x4E7A,0x0808`

These raw words keep the complete ROM assemblable with the 68000 baseline toolchain; execution is reached only after earlier guarded CPU classification.

## Planned decision tree

After M3.10c has established `68030+`:

1. guarded `MOVEC ITT0,D0`
   - illegal -> `68030`
   - present -> `68040+`
2. guarded `MOVEC PCR,D0`
   - illegal -> `68040`
   - present -> `68060`

Both probes are reads only. They do not enable the MMU, alter translation state, or change PCR.

## Qualification requirement

The implementation is not frozen by this note. M3.10d still requires automated 68030/68040/68060 positive/negative qualification plus 68000/68010/68020 regression coverage. Exception recovery must also be proven on the actual tested later-family profiles.

## Public references

- Motorola/NXP, *M68060 User's Manual*, MOVEC instruction/control-register table.
- Motorola/NXP, *M68040 User's Manual*.
- GNU binutils `as`, M680x0 architecture options, used as an independent public toolchain reference for distinct 68030/68040/68060 architecture targets.
