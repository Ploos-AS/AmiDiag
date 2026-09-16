# M4.3 CIA interrupt-control diagnostics

Status: **DESIGN / ACTIVE**

M4.3 extends the qualified M4.2 timer baseline with controlled 8520 Interrupt Control Register (ICR) diagnostics. This milestone tests CIA interrupt-source mask/set-clear behavior and timer-generated pending sources while keeping Amiga custom-chip interrupt routing and CPU-level handlers for M4.4.

## Goals

For both CIA-A and CIA-B:

1. Establish a known, bounded test state without disturbing unrelated machine state more than necessary.
2. Clear the selected timer interrupt mask using ICR set/clear semantics.
3. Configure a short Timer A interval using the qualified M4.2 timer access path.
4. Clear stale pending state by reading ICR before the test.
5. Enable only the selected Timer A source in the CIA ICR mask.
6. Start the timer and poll ICR with a bounded loop until the Timer A pending bit is observed.
7. Verify the master/request indication is consistent with an enabled pending source where the public 8520 contract provides it.
8. Disable the test source, acknowledge/clear pending state, stop the timer, and restore touched timer/control state where practical.
9. Continue deterministic serial reporting even if one CIA fails.

M4.3 deliberately does not install CPU interrupt vectors or prove Paula `INTREQ`/`INTENA` routing. Those belong to M4.4.

## Required records

Successful qualification emits:

- `CIAA.ICR status=PASS source=TIMERA pending=observed mask=set-clear cleanup=PASS`
- `CIAB.ICR status=PASS source=TIMERA pending=observed mask=set-clear cleanup=PASS`
- `TEST id=CIA.ICR status=PASS devices=2 cleanup=2`

Timeout, inconsistent pending state, or cleanup failure is FAIL. Unsupported or unsafe platform-specific behavior must use `SKIP` or `UNAVAILABLE`, not fabricated PASS.

## Safety and cleanup contract

- Never leave a test interrupt source enabled.
- Clear stale pending state before enabling the source.
- Use only the selected Timer A source for the deterministic automated test.
- Do not enable the Amiga custom-chip interrupt path in M4.3.
- Every wait is bounded.
- Stop and clean up the timer even after failure.
- Preserve unrelated CIA control bits and restore timer/control state where practical.
- Paula serial reporting remains independent of the CIA interrupt test.

## Qualification plan

The automated subset targets FS-UAE A500/68000. Static validation verifies ROM/protocol markers and CIA ICR/Timer A register references. Runtime serial validation requires both CIA records and the summary exactly once, in order, with no FAIL. After PASS, freeze the workflow and pin the qualified source commit.

Visible-emulator and real-hardware qualification remain separate evidence layers.

## Clean-room boundary

Use public MOS/CSG 8520 and Amiga hardware documentation plus independently observed emulator/hardware behavior. Do not inspect Kickstart, DiagROMV2, or proprietary diagnostic-ROM source.
