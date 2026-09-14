# M1.2 Status — FS-UAE runtime qualification harness

Status: **PASS — GITHUB RUNNER RUNTIME QUALIFIED**

M1.2 turns the M1/M1.1 bootstrap into a reproducible runtime-qualification target.

## Implemented

- normal 68000/A500-class ROM build
- qualification-only ROM build with a deliberate 68000 `ILLEGAL` instruction
- TCP serial capture helper
- FS-UAE configuration generation using `serial_port = tcp://127.0.0.1:<port>/wait`
- deterministic normal-boot transcript validation
- deterministic expected-exception transcript validation
- separate normal and exception captures/logs
- `make qualify-m1_2` orchestration target
- GitHub Actions runner qualification on Ubuntu 24.04
- runner-installed `m68k-linux-gnu` cross-toolchain for the freestanding ROM build
- Xvfb-wrapped FS-UAE runtime execution
- automatic upload of ROMs, maps, transcripts, FS-UAE logs, generated configs, tool versions and ROM SHA-256 evidence

## Primary qualification path

The primary automated qualification path is `.github/workflows/m1_2-fsuae.yml`.

It runs on pushes to `main`, pull requests and manual `workflow_dispatch`. The runner installs the cross-toolchain and FS-UAE, then executes:

```sh
make clean qualify-m1_2
```

with:

```text
CROSS=m68k-linux-gnu-
FS_UAE=xvfb-run -a fs-uae
```

A complete automated M1.2 runtime PASS requires all of the following:

1. Both ROM variants build and pass host/static validation.
2. The normal ROM boots under the FS-UAE A500 profile.
3. Serial output contains, in order:
   - `AMIDIAG proto=1 milestone=M1.2 cpu=68000`
   - `BOOT phase=reset status=PASS`
   - `TEST id=BOOT.VECTORS status=PASS`
   - `TEST id=BOOT.SERIAL status=PASS`
4. The normal path emits no fatal exception record.
5. The qualification-only exception ROM boots through the same path and then emits exactly:
   - `EXCEPTION id=CPU.ILLEGAL status=FAIL fatal=1`
6. The deliberate exception is reached through the installed RAM vector table, proving that vector 4 and the fatal reporter are live after ROM overlay release.

## Qualification result

GitHub Actions run **#3**, run ID `34844888592`, completed successfully on Ubuntu 24.04.

Runner-observed PASS scope:

- 68000 cross-build: PASS
- normal ROM host validation: PASS
- exception ROM host validation: PASS
- normal FS-UAE serial boot path: PASS
- RAM vector-table path: PASS
- deliberate `CPU.ILLEGAL` exception path: PASS
- expected-exception transcript validation: PASS
- qualification artifact upload: PASS

This is sufficient to mark M1.2 runtime-qualified on the automated runner path.

## Local qualification

Local execution remains useful but is no longer required for routine automated qualification:

```sh
make clean
make check
make qualify-m1_2
```

For graphical-less hosts:

```sh
make qualify-m1_2 FS_UAE='xvfb-run -a fs-uae'
```

A later visible local FS-UAE run is retained as human-observable evidence and may be performed together with later visual/hardware milestones. It does not block M2 development.

## Evidence retained by the runner

The `amidiag-m1_2-qualification` artifact contains, where produced:

- both ROM variants
- linker maps
- ROM SHA-256 values
- cross-toolchain version
- FS-UAE version
- Python version
- generated `.fs-uae` configurations
- normal serial transcript
- exception serial transcript
- FS-UAE logs

## Current verdict

**M1.2 PASS.** The automated M1 bootstrap, serial path, low-RAM vector installation and deliberate exception path are runtime-qualified under FS-UAE on the GitHub runner. M1 may now be frozen at runner qualification level and development can proceed to M2 memory diagnostics.
