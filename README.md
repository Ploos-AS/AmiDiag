# AmiDiag

Clean-room diagnostic ROM and hardware test suite for classic Commodore Amiga computers.

AmiDiag is an independent implementation. It does not copy or derive source code from DiagROM, Kickstart, or other proprietary diagnostic ROMs. Public hardware documentation, datasheets, independently developed tests, and behaviour observed on real hardware/emulators may be used as references.

## Goals

- boot without a working AmigaOS/Kickstart installation
- run on a minimal 68000-class baseline first
- diagnose RAM, CPU, CIA, custom chips, interrupts, input, floppy and expansion hardware
- provide useful output even when graphics are unavailable
- deterministic, scriptable diagnostics suitable for repair benches and automated qualification
- serial diagnostics with stable test IDs and machine-readable records
- build and preserve machine-specific ROM variants
- run reproducible regression tests under emulation and later on real hardware

## M0 status

M0 establishes the clean-room rules, architecture, project layout, initial diagnostic protocol, supported-machine roadmap and qualification strategy. No third-party diagnostic ROM source is imported.

See:

- `ROADMAP.md`
- `docs/M0_ARCHITECTURE.md`
- `docs/CLEAN_ROOM.md`
- `docs/DIAGNOSTIC_PROTOCOL.md`
- `docs/M0_STATUS.md`

## Initial target

The first executable target will be a 68000-safe diagnostic ROM for the OCS/ECS Amiga family, with serial output as the earliest dependable reporting channel. Hardware-specific functionality is layered so later AGA and 32-bit machines can share the same diagnostic core.

## Sister projects

The architecture is intended to inform two later, independent projects:

- **AtariDiag** — clean-room diagnostic ROM/tools for Atari 16/32-bit systems
- **MacDiag** — clean-room diagnostic ROM/tools for classic 68k Macintosh systems

They are roadmap items, not code-sharing assumptions: platform-specific implementations must remain technically appropriate for their hardware.

## License

MIT. See `LICENSE`.
