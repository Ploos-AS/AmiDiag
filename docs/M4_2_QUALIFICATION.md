# M4.2 CIA Timer A/B qualification

Status: **PASS / FROZEN**

M4.2 qualifies bounded polling diagnostics for CIA-A and CIA-B Timer A and Timer B on the 68000 baseline. The diagnostic does not enable CIA interrupt sources; interrupt-control semantics are reserved for M4.3.

## Qualified implementation

- Source: `src/cia/m4_2_boot.S`
- Qualified source commit: `759f45fea2b74058c5ea5379a51876f7ee9b708e`
- GitHub Actions run: `35139348108`
- Job: `104939659463`
- Profile: FS-UAE, A500, 68000, 512 KiB chip RAM
- Result: PASS

The successful job passed ROM build, static validation, A500/68000 runtime qualification, serial transcript validation, and artifact upload.

## Runtime contract

Qualification requires PASS for CIA-A Timer A/B and CIA-B Timer A/B, followed by `TEST id=CIA.TIMERS status=PASS timers=4 restored=4`. Every polling loop is bounded and a no-progress condition is FAIL rather than an infinite wait.

The first qualification attempt failed during linking because ROM-only `linker.ld` deliberately discards `.data`. Runtime failure state was therefore moved to CPU register D7. The revised ROM then qualified successfully.

## Freeze

`.github/workflows/m4_2-fsuae.yml` is manual-only after PASS and checks out the qualified source commit explicitly. Semantic changes require reopening M4.2 qualification.

## Scope

This is deterministic FS-UAE qualification of timer register access and counter progress. It is not exhaustive electrical or real-hardware CIA validation. Visible-emulator and real-machine evidence remain separate layers.

## Clean-room boundary

M4.2 uses public 8520/Amiga hardware documentation and independently observed emulator/hardware behavior. No Kickstart, DiagROMV2, or proprietary diagnostic-ROM source is used.
