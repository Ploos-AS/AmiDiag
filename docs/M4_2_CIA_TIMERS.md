# M4.2 CIA Timer A/B diagnostics

Status: **DESIGN / ACTIVE**

M4.2 extends the qualified M4.1 register-access baseline with bounded, reversible timer diagnostics for both 8520 CIAs. It remains a clean-room 68000-safe ROM diagnostic and keeps Paula serial independent of the CIA tests.

## Goals

Test CIA-A and CIA-B Timer A and Timer B without requiring interrupts. Each probe must save touched writable state, stop the selected timer, load a known non-zero latch, start it in continuous mode, observe bounded counter progress, stop it, and restore the saved control/latch state where restoration is architecturally meaningful.

M4.2 proves timer register access and counting. Interrupt generation and ICR semantics belong to M4.3.

## Required records

Successful qualification emits exactly one record for each timer:

- `CIAA.TIMERA status=PASS mode=poll progress=observed restore=PASS`
- `CIAA.TIMERB status=PASS mode=poll progress=observed restore=PASS`
- `CIAB.TIMERA status=PASS mode=poll progress=observed restore=PASS`
- `CIAB.TIMERB status=PASS mode=poll progress=observed restore=PASS`
- `TEST id=CIA.TIMERS status=PASS timers=4 restored=4`

A bounded no-progress condition is `FAIL`, never an infinite wait. Tests that cannot safely establish their clock source on a later machine/profile must report `SKIP` or `UNAVAILABLE` rather than fabricate PASS.

## Safety contract

- Preserve unrelated CIA control bits.
- Do not modify port data/direction as part of timer testing.
- Do not enable CIA interrupt sources in M4.2.
- Stop a timer before changing its latch/control state.
- Every wait loop is bounded.
- Restore touched state before reporting completion where practical.
- A failure in one timer must still attempt cleanup and permit deterministic reporting of the remaining tests.

## Qualification plan

1. Host/static ROM validator verifies M4.2 markers and CIA timer/control register references.
2. FS-UAE A500/68000 runtime captures Paula serial output.
3. Serial validator requires four PASS records, one PASS summary, deterministic ordering, and no FAIL.
4. On PASS, freeze the workflow manual-only and pin it to the qualified source commit.
5. Visible-emulator and real-hardware evidence remain separate qualification layers.

## Clean-room boundary

Use public MOS/CSG 8520 and Amiga hardware documentation plus independently observed emulator/hardware behavior. Do not inspect Kickstart, DiagROMV2, or proprietary diagnostic-ROM source.
