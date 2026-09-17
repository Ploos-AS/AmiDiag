# M4.4 Amiga interrupt-controller diagnostics

Status: **DESIGN / ACTIVE**

M4.4 extends the qualified CIA-local interrupt path into the Amiga custom-chip interrupt controller and 68000 CPU interrupt path. The automated baseline uses CIA-A Timer A as a controlled source, Paula `INTENA`/`INTREQ` as the routing layer, and a temporary level-2 CPU vector.

## Goals

1. Establish a known interrupt state with CPU interrupts masked while setup is in progress.
2. Install a temporary level-2 autovector handler in writable RAM/vector space appropriate to the 68000 baseline.
3. Clear stale CIA-A Timer A pending state and disable its CIA mask.
4. Clear stale Paula PORTS request and configure only the required `INTENA` source plus master interrupt enable while preserving unrelated state where observable/practical.
5. Configure CIA-A Timer A with a short bounded interval and enable its CIA-local mask.
6. Lower the CPU interrupt mask and wait with a bounded foreground loop.
7. The level-2 handler records observation, acknowledges CIA-A ICR and clears the Paula PORTS request before returning with RTE.
8. Mask CPU interrupts again, disable the test source, clean up CIA/Paula state, and restore the temporary vector/state where practical.
9. Report deterministic serial evidence only after the interrupt path has been safely disabled.

## Required records

Successful qualification emits:

- `IRQ.PAULA status=PASS source=PORTS intena=enabled intreq=observed cleanup=PASS`
- `IRQ.CPU status=PASS level=2 vector=autovector handler=observed cleanup=PASS`
- `TEST id=IRQ.CONTROLLER status=PASS paths=2 cleanup=2`

Timeout, unexpected interrupt level/source, missing handler observation, or cleanup failure is FAIL.

## Safety contract

- CPU interrupt mask remains raised during setup and cleanup.
- Never leave CIA Timer A, Paula PORTS, or master interrupt enable enabled solely because of the diagnostic.
- Acknowledge the CIA source before/with clearing Paula PORTS so a level-triggered source cannot immediately retrigger.
- Every foreground wait is bounded.
- Handler work is minimal: record, acknowledge, return.
- Serial output is not performed from the interrupt handler.
- Preserve unrelated interrupt-controller state where safely observable; document any state that cannot be losslessly reconstructed from write-only/set-clear semantics.
- Failure paths converge on cleanup before reporting.

## Qualification plan

Automated qualification initially targets FS-UAE A500/68000. Static validation checks the ROM markers, CIA-A ICR/Timer A addresses, Paula `INTENA`/`INTREQ` addresses, and the level-2 vector contract. Runtime serial validation requires both PASS records and the summary exactly once and rejects any `status=FAIL`.

Real-hardware and additional model qualification remain separate evidence layers.

## Clean-room boundary

Use public Motorola 68000, MOS/CSG 8520 and Amiga hardware documentation plus independently observed emulator/hardware behavior. Do not inspect Kickstart, DiagROMV2, or proprietary diagnostic-ROM source.
