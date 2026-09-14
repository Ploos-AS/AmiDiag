# M0 Architecture

## Purpose

AmiDiag is a standalone diagnostic ROM and test framework for classic Commodore Amiga hardware. It must remain useful on partially broken systems and must not assume that AmigaOS, Kickstart services, expansion drivers, filesystems, or normal startup state are available.

## Design principles

1. **68000-safe core first** — shared core code must run on the lowest intended CPU unless isolated behind a machine/CPU profile.
2. **Serial-first observability** — the earliest useful execution path reports progress through the serial port before depending on graphics, RAM beyond the minimum required, or higher-level peripherals.
3. **Fail locally** — individual diagnostic failures should be reported and, where safe, allow later independent tests to continue.
4. **Deterministic results** — tests have stable IDs and structured result records so emulator runs and repair-bench runs can be compared.
5. **No OS dependency** — diagnostic core code talks directly to documented hardware interfaces.
6. **Layered hardware support** — chipset/model-specific code sits behind explicit capabilities and profiles.
7. **Evidence over inference** — report observed failures separately from repair advice or likely causes.
8. **Reproducible builds** — release ROMs must record source revision, toolchain/build metadata and cryptographic hashes.

## Logical layers

### Reset / bootstrap

Minimal reset-vector entry, CPU state normalization, stack establishment and conservative early initialization. The bootstrap must avoid assumptions about expansion hardware and should minimize RAM dependency until memory viability is known.

### Early console

Provides serial output as soon as possible. Screen output is an additional backend, never the only source of startup diagnostics.

### Diagnostic core

Owns test registration, stable test IDs, result states, sequencing, failure accounting and common reporting.

Suggested result states:

- PASS
- FAIL
- SKIP
- WARN
- UNAVAILABLE
- ABORT

### Hardware abstraction

Very small interfaces for capabilities needed by tests: serial, timers, memory ranges, display, input, CIA/custom register access and storage controllers. This is not intended to become an operating system abstraction layer.

### Machine profile

Defines known-safe assumptions and applicable tests for a model/family. Detection may refine a profile at runtime, but uncertain detection must not silently enable unsafe accesses.

### Test modules

Independent modules for memory, CPU, CIA, custom chips, interrupts, human input, storage and expansion hardware.

### User interface

Technician-oriented menu/status display built only after the diagnostic core can already run and report over serial.

## Repository structure

Planned initial structure:

```text
AmiDiag/
├── Makefile
├── README.md
├── ROADMAP.md
├── LICENSE
├── docs/
│   ├── CLEAN_ROOM.md
│   ├── DIAGNOSTIC_PROTOCOL.md
│   ├── M0_ARCHITECTURE.md
│   └── M0_STATUS.md
├── include/
├── src/
│   ├── boot/
│   ├── core/
│   ├── hw/
│   ├── profiles/
│   ├── tests/
│   └── ui/
├── tools/
├── tests/
└── build/
```

`build/` is generated and should not contain hand-maintained source.

## Build direction

The executable implementation should use a reproducible m68k toolchain and explicit 68000-safe flags for the common core. Assembly is appropriate for reset/bootstrap, exception stubs and places where exact machine state matters; C may be used where it improves maintainability and generated code can be bounded and inspected.

The project must not depend on proprietary Kickstart ROMs to build its own ROM image.

## Qualification tiers

### Tier A — host/static

Repository policy checks, generated ROM size/layout checks, symbol/map validation, protocol parser tests and deterministic host fixtures.

### Tier B — emulated runtime

Boot and execute under supported emulators, capture serial output and compare stable records against expected fixtures. Human-observable video/audio/input tests may require visible runs and explicit evidence.

### Tier C — real hardware

Run on explicitly named Amiga profiles and preserve ROM hash, hardware profile, transcript and operator-observed outcomes.

A milestone may pass one tier and remain unqualified at a higher tier; documentation must state this plainly.
