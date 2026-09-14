# AmiDiag Roadmap

AmiDiag is developed as a clean-room diagnostic ROM and hardware test platform for classic Amiga computers.

## M0 — Foundation

- [x] Define clean-room development policy
- [x] Define high-level ROM architecture
- [x] Define deterministic diagnostic/test ID model
- [x] Define serial-first reporting strategy
- [x] Define repository structure
- [x] Define machine-family strategy
- [x] Define emulator and real-hardware qualification strategy
- [x] Add AtariDiag and MacDiag as future sister projects

## M1 — Minimal boot and serial heartbeat

- 68000-safe reset entry and stack setup
- conservative hardware initialization
- serial initialization without AmigaOS
- stable boot banner and build ID
- machine-readable `BOOT` and `TEST` records
- fatal exception capture where practical
- ROM image build with checksum/size validation
- first automated emulator smoke test

Initial machine profile: A500-class OCS/ECS baseline. Keep CPU assumptions at 68000 unless a machine profile explicitly permits more.

## M2 — Memory diagnostics

- discover plausible Chip RAM ranges without trusting AmigaOS
- destructive RAM test modes with explicit warnings/profiles
- address-line test
- data-line test
- walking-bit patterns
- stuck-bit and alias detection
- Slow/Fast RAM probing where safely possible
- deterministic failure address/value reporting
- memory-map summary over serial and screen

## M3 — CPU and exception diagnostics

- CPU family identification where safe
- basic instruction sanity tests
- vector-table/exception verification
- bus/address error reporting
- supervisor/user mode tests where applicable
- optional 68010/020/030/040/060 profile extensions without weakening the 68000 baseline

## M4 — CIA and interrupt subsystem

- CIA-A/CIA-B register tests
- timers
- TOD where safely testable
- interrupt levels and sources
- keyboard serial path
- serial-port loopback-assisted tests
- parallel-port diagnostics

## M5 — Amiga custom chips

- Agnus/Alice capability discovery
- Denise/Lisa capability discovery
- Paula diagnostics
- DMA channel tests
- copper/blitter diagnostics
- audio channel tests
- display timing and chipset capability report
- graceful fallback when display output itself is suspect

## M6 — Human I/O and display diagnostics

- diagnostic screen renderer independent of AmigaOS
- keyboard matrix/input tests
- mouse and joystick ports
- video test patterns
- audio test patterns
- LED/status feedback where available

## M7 — Storage and expansion diagnostics

- floppy controller/drive tests
- disk-change/index/track diagnostics where available
- IDE diagnostics for machines that provide it
- Gayle diagnostics
- Zorro/autoconfig inspection
- expansion-board inventory without requiring expansion drivers
- RTC/battery-backed clock diagnostics where applicable

## M8 — Machine profiles and preserved ROM variants

Build, test and retain explicit variants rather than treating one ROM as implicitly valid everywhere.

Planned profiles include:

- A1000
- A500
- A500+
- A600
- A1200
- A2000
- A2500/20
- A2500/30
- A3000
- A3000T
- A4000
- A4000T
- CDTV
- CD32

Profiles may share binaries when proven equivalent, but release artifacts and qualification evidence remain machine-profile aware.

## M9 — Automated qualification

- headless/automated emulator regression where useful
- visible emulator qualification for human-observable tests
- FS-UAE qualification
- Amiberry qualification
- AmiSandbox integration
- deterministic serial transcript comparison
- ROM hash/build provenance
- negative/fault-injection tests where emulator facilities permit
- real-hardware qualification matrix

## M10 — Technician mode

- interactive test selection
- burn-in loops
- configurable repetitions
- failure counters
- RAM-region selection
- guided repair hints that distinguish observation from diagnosis
- stable test IDs suitable for manuals and service records

## M11 — Host tooling

- serial log collector
- parser for machine-readable records
- human-readable report generator
- JSON export on the host side
- comparison of two qualification runs
- optional Prometheus metrics exporter for benches/labs

## M12 — Advanced hardware diagnostics

- accelerator-aware tests
- FPU tests when present
- MMU-assisted diagnostics on supported CPUs
- SCSI-controller-assisted tests where hardware permits
- network/expansion diagnostics via optional modules
- prolonged burn-in/stress profiles

## Future sister projects

### AtariDiag

Independent clean-room diagnostics for Atari 16/32-bit systems. Planned scope should include ST/STe/TT/Falcon families, 68000 baseline where applicable, RAM, GLUE/MMU/DMA/MFP/ACIA/shifter/VIDEL and storage/I/O diagnostics. Architecture lessons from AmiDiag may be reused, but Atari hardware gets a native implementation and its own qualification matrix.

### MacDiag

Independent clean-room diagnostics for classic 68k Macintosh systems. Planned scope should include early compact Macs through later 68k families, ROM-independent startup where technically feasible, RAM/CPU/exception tests, VIA/SCC/SCSI/ADB/video diagnostics and model-specific profiles. No Apple ROM code is to be copied or redistributed.

## Release philosophy

No version is called qualified merely because it builds. Milestones distinguish host/static checks, emulator runtime qualification and real-hardware qualification. Evidence should be preserved alongside milestone documentation.
