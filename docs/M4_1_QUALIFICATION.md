# M4.1 CIA register-access qualification

Status: **PASS / FROZEN**

M4.1 establishes the clean-room CIA-A/CIA-B register-access baseline on the 68000 ROM path. The runtime probe saves the selected CIA data-direction register, toggles one direction bit, verifies readback, restores the exact saved byte, and verifies restoration. Paula serial remains the reporting path.

## Qualified implementation

- Source: `src/cia/m4_1_boot.S`
- Qualified source/workflow commit: `b0db69ac7e6ec09a58d4c66aacac19e0a144bff1`
- GitHub Actions run: `35135520623`
- Job: `104926787430`
- Profile: FS-UAE, A500, 68000, 512 KiB chip RAM
- Result: PASS

The successful job passed tool installation, ROM build/static validation, A500/68000 runtime qualification, evidence collection, and artifact upload.

## Required runtime records

- `CIAA.ACCESS status=PASS register=DDRA restore=PASS`
- `CIAB.ACCESS status=PASS register=DDRB restore=PASS`
- `TEST id=CIA.ACCESS status=PASS devices=2 restored=2`

`tools/check_m4_1_rom.py` checks the ROM shape, protocol markers and CIA register references. `tools/check_m4_1_serial.py` checks deterministic successful runtime records, ordering, uniqueness and absence of `status=FAIL`.

## Freeze

After PASS, `.github/workflows/m4_1-fsuae.yml` was changed to manual-only and pinned to the qualified commit. Semantic changes to M4.1 require reopening qualification rather than silently changing the frozen evidence.

## Scope

This is emulator qualification of the deterministic M4.1 subset, not a claim of exhaustive CIA electrical/hardware validation. Visible-emulator and real-machine qualification remain separate evidence layers.

## Clean-room boundary

M4.1 uses public Amiga/8520 hardware behavior and independently observed emulator/hardware behavior. No Kickstart, DiagROMV2, or proprietary diagnostic-ROM source is used.
