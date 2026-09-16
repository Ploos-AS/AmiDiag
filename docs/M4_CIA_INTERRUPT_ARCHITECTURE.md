# M4 — CIA and Interrupt Diagnostics Architecture

Status: **DESIGN / ACTIVE**

M4 starts AmiDiag diagnostics for the two MOS 8520 CIA devices and the Amiga interrupt subsystem. The implementation remains ROM-resident, AmigaOS-independent and 68000-safe.

## Clean-room boundary

M4 may use public Amiga hardware documentation, public 8520 documentation and independently observed emulator/hardware behaviour. It must not inspect or derive implementation from Kickstart, DiagROMV2, or proprietary diagnostic-ROM source.

## Safety rules

CIA registers are shared with machine control functions. Tests must preserve unrelated bits, save writable state before modification where practical, restore state after each probe, and avoid assuming a specific Amiga model beyond the active profile.

A failed CIA probe must not prevent serial reporting where reporting remains physically possible. Destructive or externally visible I/O tests belong behind explicit later test modes.

## M4 subdivision

### M4.1 — CIA register access baseline

- Define CIA-A and CIA-B base addresses and byte-wide access helpers.
- Establish deterministic read/write probe framework.
- Test safe data-direction/register behaviour without driving external lines unnecessarily.
- Save and restore touched writable registers.
- Emit separate `CIAA.*` and `CIAB.*` records.
- Add host/static validators before runtime qualification.

### M4.2 — CIA timers

- Timer A load/read/count behaviour.
- Timer B load/read/count behaviour.
- one-shot/continuous behaviour where safely testable.
- deterministic timeout handling so a broken timer cannot hang AmiDiag.

### M4.3 — CIA interrupt control

- Verify CIA interrupt mask/set-clear semantics.
- Generate controlled timer interrupt sources.
- Observe and acknowledge CIA interrupt state.
- Restore interrupt masks after each test.

### M4.4 — Amiga interrupt controller

- Verify custom-chip `INTENA`/`INTREQ` set-clear behaviour.
- Install controlled level handlers in the AmiDiag vector table.
- Correlate CIA-A and CIA-B sources with expected Amiga interrupt levels.
- Detect missing, unexpected and stuck interrupt sources.
- Never leave an enabled source active on exit from a test.

### M4.5 — TOD baseline

- Non-destructive TOD observation.
- Progress/change test with bounded timeout.
- Avoid resetting a running TOD clock merely to prove access.
- Report `SKIP`/`UNAVAILABLE` when a profile cannot safely establish the expected clock source.

### M4.6 — Keyboard serial path

- Observe CIA-A serial/keyboard path without requiring AmigaOS.
- Separate electrical/input availability from protocol-level observations.
- Interactive key tests remain optional and must not block automated qualification.

### M4.7 — Serial/parallel assisted diagnostics

- Preserve the existing Paula serial-first diagnostic channel.
- Add optional serial loopback-assisted checks without making loopback mandatory.
- Add CIA parallel-port direction/data diagnostics behind explicit safe/interactive profiles.
- Automated CI must report absent external loopback as `SKIP` or `UNAVAILABLE`, not `FAIL`.

### M4.8 — Consolidated M4 qualification

- Stable CIA capability/status summary.
- Automated FS-UAE regression for deterministic non-interactive tests.
- Preserve emulator evidence and ROM provenance.
- Keep visible/real-hardware tests as separate qualification evidence.

## Record contract

M4 extends the existing machine-readable protocol rather than inventing a second format. Representative records:

```text
CIAA.ACCESS status=PASS
CIAB.ACCESS status=PASS
CIAA.TIMERA status=PASS
CIAB.TIMERB status=PASS
IRQ source=CIAA_TIMERA level=2 status=PASS
IRQ source=CIAB_TIMERA level=6 status=PASS
CIAA.TOD status=PASS
```

Failures should include concrete observed/expected fields where meaningful. Optional hardware-dependent checks use the established `PASS/FAIL/SKIP/WARN/UNAVAILABLE/ABORT` vocabulary.

## Qualification strategy

M4 qualification is layered:

1. static/ROM validation;
2. deterministic FS-UAE serial qualification for safe automated probes;
3. visible emulator qualification for human-observable I/O;
4. real-hardware qualification across retained machine profiles later.

A GitHub Actions PASS is evidence for the emulator-qualified subset only; it is not a claim that physical CIA chips, keyboard wiring, serial loopback, or parallel-port pins have been electrically tested.

## First implementation target

M4.1 is intentionally narrow: prove safe, restorable CIA-A/CIA-B register access and deterministic reporting before timer or interrupt generation is introduced. This gives later M4 stages a qualified CIA access primitive instead of mixing register-access uncertainty with interrupt debugging.
