# Clean-room policy

AmiDiag is an independent implementation.

## Prohibited inputs

Do not copy, translate, mechanically transform, disassemble into source, or otherwise derive implementation code from proprietary or source-available diagnostic ROMs whose terms do not permit derivative redistribution. In particular, DiagROM/DiagROMV2 source is not an implementation source for AmiDiag.

Do not copy Commodore/Amiga Kickstart ROM code or Apple ROM code into this repository.

## Permitted references

Implementation may be based on independently usable technical facts, including:

- public hardware datasheets and programming documentation
- hardware register descriptions and electrical/interface documentation that may lawfully be used
- emulator documentation and independently implemented emulator source under compatible terms where appropriate
- observations from real hardware
- independently designed test algorithms
- published standards and processor documentation

When a reference has licensing or attribution requirements, preserve them in the relevant documentation/source file.

## Behavioural comparison

Black-box comparison may be used to learn whether hardware behaves as expected, but AmiDiag should define its own user interface, protocol, test organisation, messages and implementation.

## Contributions

Contributors should confirm that submitted implementation is their own work or comes from a source whose license permits inclusion. Contributions that appear copied from incompatible ROM/source projects should be rejected or rewritten independently.

## Clean-room documentation

Architecture and tests should explain what hardware property is being measured, not how another diagnostic product implemented the same feature. Stable AmiDiag test IDs, wire formats and UI conventions are project-original interfaces.
