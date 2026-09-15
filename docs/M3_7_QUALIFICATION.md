# M3.7 Qualification

Status: **PASS**

M3.7 qualifies clean-room, pre-OS guarded profile probes for Slow RAM and Fast RAM while preserving the 68000 baseline.

## Qualified source

- Commit: `62ebe7a7c75f7756b1e4398d4014f7ddcfc2b5db`
- GitHub Actions run: `34951373673`
- Job: `104322878614`
- Result: `success`

## Runtime matrix

| Profile | Result |
| --- | --- |
| A500, no expansion RAM | PASS |
| A500, 512 KiB Slow RAM | PASS |
| A500, 2 MiB Fast RAM mapped for the guarded pre-AutoConfig probe | PASS |

The Fast RAM qualification deliberately maps the emulator RAM directly at the M3.7 profile probe window. M3.7 is not Zorro AutoConfig enumeration; proper expansion enumeration belongs to the later Zorro/expansion milestone.

## Properties qualified

- 68000-safe diagnostic ROM boots without AmigaOS/Kickstart services.
- Slow/Fast candidate accesses are guarded against bus errors.
- RAM presence uses reversible preserve/write/read/restore probing.
- Absent candidate memory does not become a fatal diagnostic exception.
- Serial output deterministically classifies the selected profile probes.
- Qualification evidence is uploaded by the workflow.

## Frozen workflow

`.github/workflows/m3_7-fsuae.yml` is manual-only and checks out the exact qualified source commit above. This prevents later `main` changes from silently changing the historical M3.7 qualification result.

## Scope

M3.7 proves guarded profile probing, not general memory discovery or Zorro AutoConfig. Expansion-board enumeration and configured address discovery remain future work under M7.
