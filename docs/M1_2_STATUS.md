# M1.2 Status — FS-UAE runtime qualification harness

Status: **IMPLEMENTED / GITHUB RUNNER QUALIFICATION ENABLED**

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

A later visible FS-UAE run is retained as human-observable qualification evidence, rather than blocking every milestone on local execution.

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

The GitHub runner qualification path is now implemented. A runtime PASS is claimed only when the workflow itself completes successfully; workflow setup alone is not treated as qualification evidence.
