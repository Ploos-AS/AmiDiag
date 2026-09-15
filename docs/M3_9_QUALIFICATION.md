# M3.9 Qualification

## Status

**PASS**

M3.9 qualifies the AmiDiag clean-room 68000 supervisor/user-mode and privilege-exception diagnostics in FS-UAE on GitHub Actions.

## Qualified source

- Source head: `2489c465556dfa1f7ee52c4bbdebb2b645456351`
- Successful workflow run: `35007872996`
- Successful job: `104512097516`
- Runner: `ubuntu-24.04`
- Emulator: FS-UAE under Xvfb
- Machine profile: A500
- CPU baseline: 68000
- Chip RAM: 512 KiB
- ROM size: 512 KiB

The frozen workflow checks out the exact qualified source head rather than current `main`.

## Qualified tests

M3.9 validates four related CPU-mode behaviors:

1. `CPU.MODE.SUPERVISOR` — reset entry is executing with the 68000 S bit set.
2. `CPU.MODE.USER` — controlled transition to user mode succeeds after setting a dedicated USP.
3. `CPU.EXCEPTION.PRIVILEGE` — executing the privileged `STOP` instruction from user mode reaches vector 8.
4. `CPU.MODE.RECOVERY` — the privilege handler discards the normal six-byte 68000 exception frame and continues at a known supervisor-mode continuation.

The final transcript requires:

- `TEST id=CPU.MODE status=PASS cpu=68000 tests=4`
- `TEST id=CPU.BASELINE status=PASS cpu=68000 probe=supervisor-user-mode`

Any `status=FAIL` record causes qualification failure.

## Exception-frame basis

The M3.9 privilege handler uses the documented normal 68000 exception stack frame: a saved SR word followed by a saved PC longword, six bytes total. It does not depend on AmigaOS, Kickstart internals, or proprietary diagnostic-ROM source.

The handler deliberately does not `RTE` to the faulting `STOP` instruction. It removes the six-byte frame and transfers control to a known continuation so the qualification is deterministic.

## Clean-room scope

M3.9 was implemented from public 68000 architectural behavior and the existing AmiDiag clean-room hardware interface. No DiagROM, Kickstart, or proprietary diagnostic ROM source is used.

## Successful workflow stages

Run `35007872996` / job `104512097516` completed successfully. The following stages all passed:

- checkout
- install 68000 toolchain and FS-UAE
- build M3.9 ROM
- static ROM validation
- FS-UAE supervisor/user-mode qualification
- serial transcript validation
- evidence recording
- evidence artifact upload

## Evidence

The workflow records and uploads:

- `amidiag-m3_9.rom`
- linker map
- captured M3.9 serial output
- FS-UAE log/configuration produced by the harness
- toolchain version
- FS-UAE version
- ROM SHA-256

## Freeze policy

`.github/workflows/m3_9-fsuae.yml` is frozen after successful qualification:

- trigger: `workflow_dispatch` only
- checkout: exact qualified source head `2489c465556dfa1f7ee52c4bbdebb2b645456351`
- historical evidence: run `35007872996`, job `104512097516`

Future milestone development must use a new qualification workflow rather than changing the M3.9 evidence baseline.
