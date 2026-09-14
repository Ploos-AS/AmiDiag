# Diagnostic protocol

AmiDiag uses a line-oriented serial protocol designed to remain readable to a technician while also being straightforward for host tools to parse.

## Transport baseline

M1 will define the exact early serial settings. The protocol itself is ASCII, one record per line, CR/LF tolerant on the host side.

## Record principles

- stable record names
- stable test IDs
- no localized text required for machine parsing
- key/value fields separated by spaces
- values that need richer representation should use conservative ASCII encoding
- human commentary may be emitted separately and must not be required to determine PASS/FAIL

## Initial record family

Examples of the intended shape (not yet an M1 wire-format freeze):

```text
AMIDIAG proto=1 build=<id>
BOOT phase=reset status=PASS
MACHINE profile=A500 chipset=OCS cpu=68000
TEST id=MEM.DATA status=PASS
TEST id=MEM.ADDR status=FAIL addr=0x00040000 expected=0x00040000 actual=0x00000000
SUMMARY pass=17 fail=1 warn=0 skip=2
```

## Test IDs

Test IDs are uppercase dotted identifiers grouped by subsystem. Planned namespaces include:

- `BOOT.*`
- `CPU.*`
- `MEM.*`
- `CIAA.*`
- `CIAB.*`
- `IRQ.*`
- `CUSTOM.*`
- `VIDEO.*`
- `AUDIO.*`
- `INPUT.*`
- `FLOPPY.*`
- `IDE.*`
- `ZORRO.*`
- `RTC.*`

IDs must not be recycled to mean a materially different test once included in a released protocol.

## Host tooling

Later host tools will parse these records into structured JSON and qualification reports. Machine-readable output is intentionally generated on the host side rather than requiring a JSON encoder inside the earliest ROM environment.
