# M1.2 Status — FS-UAE runtime qualification harness

Status: **IMPLEMENTED / RUNTIME QUALIFICATION PENDING**

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

## Qualification contract

A complete M1.2 runtime PASS requires all of the following:

1. `make clean && make check` passes.
2. The normal ROM boots under FS-UAE A500 profile.
3. Serial output contains, in order:
   - `AMIDIAG proto=1 milestone=M1.2 cpu=68000`
   - `BOOT phase=reset status=PASS`
   - `TEST id=BOOT.VECTORS status=PASS`
   - `TEST id=BOOT.SERIAL status=PASS`
4. The normal path emits no fatal exception record.
5. The qualification-only exception ROM boots through the same path and then emits exactly:
   - `EXCEPTION id=CPU.ILLEGAL status=FAIL fatal=1`
6. The deliberate exception must be reached through the installed RAM vector table, proving that vector 4 and the fatal reporter are live after ROM overlay release.

## Running

```sh
make clean
make check
make qualify-m1_2
```

For graphical-less hosts, `FS_UAE` may be set to a suitable display wrapper, for example:

```sh
make qualify-m1_2 FS_UAE='xvfb-run -a fs-uae'
```

A visible FS-UAE run should still be retained as the final human-observable qualification before M1 is frozen.

## Evidence to retain

- ROM SHA-256 for both ROM variants
- toolchain version
- FS-UAE version
- generated `.fs-uae` configurations
- normal serial transcript
- exception serial transcript
- FS-UAE logs

## Current verdict

The harness is implemented but no runtime PASS is claimed by this document until it has actually been executed on a host with FS-UAE and the resulting evidence has been recorded.
