#!/bin/sh
set -eu
ROM=${1:-build/amidiag-m3_8.rom}
OUT=${2:-build/m3_8-serial.txt}
PORT=${AMIDIAG_SERIAL_PORT:-1248}
FSUAE=${FS_UAE:-fs-uae}
PYTHON=${PYTHON:-python3}
mkdir -p build
CFG=build/m3_8.fs-uae
LOG=build/m3_8-fsuae.log
cat > "$CFG" <<EOF
[fs-uae]
amiga_model = A500
kickstart_file = $(pwd)/$ROM
chip_memory = 512
sound_output = none
serial_port = tcp://127.0.0.1:${PORT}/wait
EOF
$FSUAE "$CFG" >"$LOG" 2>&1 & PID=$!
trap 'kill "$PID" 2>/dev/null || true; wait "$PID" 2>/dev/null || true' EXIT INT TERM
if ! "$PYTHON" tools/capture_serial_tcp.py --port "$PORT" --output "$OUT" --connect-timeout 30 --read-timeout 15 \
  --expect 'AMIDIAG proto=1 milestone=M3.8 cpu=68000' \
  --expect 'TEST id=CPU.INSTR.SANITY status=PASS cpu=68000 tests=6' \
  --expect 'TEST id=CPU.BASELINE status=PASS cpu=68000 probe=instruction-sanity'; then
  cat "$LOG" >&2 || true
  cat "$CFG" >&2 || true
  exit 1
fi
"$PYTHON" tools/check_m3_8_serial.py "$OUT"
echo 'PASS: FS-UAE M3.8 68000 instruction sanity'
