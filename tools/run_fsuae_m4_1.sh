#!/bin/sh
set -eu
ROM=${1:-build/amidiag-m4_1.rom}
OUT=${2:-build/m4_1-serial.txt}
PORT=${AMIDIAG_SERIAL_PORT:-1253}
CFG=build/m4_1.fs-uae
LOG=build/m4_1-fsuae.log
mkdir -p build
cat >"$CFG" <<EOF
[fs-uae]
amiga_model = A500
cpu = 68000
kickstart_file = $(pwd)/$ROM
chip_memory = 512
accuracy = 1
sound_output = none
serial_port = tcp://127.0.0.1:${PORT}/wait
EOF
${FS_UAE:-fs-uae} "$CFG" >"$LOG" 2>&1 & PID=$!
trap 'kill "$PID" 2>/dev/null || true; wait "$PID" 2>/dev/null || true' EXIT INT TERM
python3 tools/capture_serial_tcp.py --port "$PORT" --output "$OUT" --connect-timeout 30 --read-timeout 15 --expect 'AMIDIAG proto=1 milestone=M4.1 cpu=68000' --expect 'TEST id=CIA.ACCESS status=PASS devices=2 restored=2'
python3 tools/check_m4_1_serial.py "$OUT"
echo "PASS: FS-UAE M4.1 CIA access baseline"
