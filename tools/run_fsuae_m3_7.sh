#!/bin/sh
set -eu
ROM=${1:-build/amidiag-m3_7.rom}; OUT=${2:-build/m3_7-serial.txt}
SLOW_KIB=${SLOW_KIB:-0}; FAST_KIB=${FAST_KIB:-0}; PORT=${AMIDIAG_SERIAL_PORT:-1245}; FSUAE=${FS_UAE:-fs-uae}; PYTHON=${PYTHON:-python3}
mkdir -p build
PROFILE="slow${SLOW_KIB}-fast${FAST_KIB}"; CFG="build/m3_7-${PROFILE}.fs-uae"; LOG="build/m3_7-${PROFILE}-fsuae.log"
cat > "$CFG" <<EOF
[fs-uae]
amiga_model = A500
kickstart_file = $(pwd)/$ROM
chip_memory = 512
slow_memory = ${SLOW_KIB}
fast_memory = ${FAST_KIB}
# M3.7 is a pre-OS guarded physical-memory probe, not Zorro AutoConfig.
# Disable Z2 Fast RAM autoconfiguration so FS-UAE wires the requested
# qualification RAM directly at 0x00200000, the documented UAE mapping.
uae_fastmem_autoconfig = 0
sound_output = none
serial_port = tcp://127.0.0.1:${PORT}/wait
EOF
$FSUAE "$CFG" >"$LOG" 2>&1 & PID=$!
trap 'kill "$PID" 2>/dev/null || true; wait "$PID" 2>/dev/null || true' EXIT INT TERM
if ! "$PYTHON" tools/capture_serial_tcp.py --port "$PORT" --output "$OUT" --connect-timeout 30 --read-timeout 15 --expect 'AMIDIAG proto=1 milestone=M3.7 cpu=68000' --expect 'TEST id=MEM.EXPANSION.PROBE status=PASS' --expect 'TEST id=CPU.BASELINE status=PASS cpu=68000 probe=guarded-expansion-memory'; then cat "$LOG" >&2 || true; cat "$CFG" >&2 || true; exit 1; fi
SLOW=absent; FAST=absent; [ "$SLOW_KIB" -gt 0 ] && SLOW=present; [ "$FAST_KIB" -gt 0 ] && FAST=present
"$PYTHON" tools/check_m3_7_serial.py "$OUT" --slow "$SLOW" --fast "$FAST"
echo "PASS: FS-UAE M3.7 $PROFILE"
