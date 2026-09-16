#!/bin/sh
set -eu
ROM=${1:-build/amidiag-m4_2.rom}; OUT=${2:-build/m4_2-serial.txt}; PORT=${AMIDIAG_SERIAL_PORT:-1254}
CFG=build/m4_2.fs-uae; LOG=build/m4_2-fsuae.log; mkdir -p build
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
python3 tools/capture_serial_tcp.py --port "$PORT" --output "$OUT" --connect-timeout 30 --read-timeout 15 --expect 'AMIDIAG proto=1 milestone=M4.2 cpu=68000' --expect 'TEST id=CIA.TIMERS status=PASS timers=4 restored=4'
python3 tools/check_m4_2_serial.py "$OUT"
echo 'PASS: FS-UAE M4.2 CIA timers'
