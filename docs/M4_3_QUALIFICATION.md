# M4.3 CIA interrupt-control qualification

Status: **PASS / FROZEN**

M4.3 qualifies controlled 8520 ICR set/clear semantics and Timer A pending-request observation for CIA-A and CIA-B on the 68000 baseline. CPU and Paula interrupt routing are intentionally outside this milestone.

## Qualified implementation

- Qualified source commit: `11b15839cee19f2bf623c24e88452c1c7b70284f`
- GitHub Actions run: `35201024264`
- Job: `105135532844`
- Profile: FS-UAE, A500, 68000
- Result: PASS

The job passed ROM build/static validation, runtime qualification, serial validation and evidence artifact upload.

## Runtime contract

The test clears stale CIA pending state, disables the selected source, configures Timer A, enables only its CIA-local interrupt mask, starts the timer, observes the bounded pending request, verifies the request/master indication, disables the source and performs cleanup. Both CIA-A and CIA-B must PASS before the summary can PASS.

Required summary: `TEST id=CIA.ICR status=PASS devices=2 cleanup=2`.

## Freeze

`.github/workflows/m4_3-fsuae.yml` is manual-only after PASS and explicitly checks out the qualified source commit. Semantic changes require reopening M4.3 qualification.

## Scope

This proves CIA-local interrupt-control behavior in FS-UAE. It does not prove Paula `INTENA`/`INTREQ`, CPU interrupt vectors, electrical timing, or real-hardware behavior; those are separate qualification layers and M4.4 work.

## Clean-room boundary

M4.3 uses public 8520/Amiga hardware documentation and independently observed emulator/hardware behavior. No Kickstart, DiagROMV2, or proprietary diagnostic-ROM source is used.
