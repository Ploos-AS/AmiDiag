#!/bin/sh
set -eu
CPU=${1:-68000}; ROM=${2:-build/amidiag-m3_10e.rom}; OUT=${3:-build/m3_10e-${CPU}-serial.txt}; PORT=${AMIDIAG_SERIAL_PORT:-1253}
case "$CPU" in
  68000) MODEL=A500; BASELINE=68000 ;;
  68010) MODEL=A500; BASELINE=68k ;;
  68020) MODEL=A1200; BASELINE=68k ;;
  68030) MODEL=A3000; BASELINE=68k ;;
  68040) MODEL=A4000; BASELINE=68k ;;
  68060) MODEL=A4000; BASELINE=68k ;;
  *) echo "unsupported CPU: $CPU" >&2; exit 2 ;;
esac
CFG=build/m3_10e-${CPU}.fs-uae; LOG=build/m3_10e-${CPU}-fsuae.log
mkdir -p build
cat >"$CFG" <<EOF
[fs-uae]
amiga_model = $MODEL
cpu = $CPU
kickstart_file = $(pwd)/$ROM
chip_memory = 512
accuracy = 1
sound_output = none
serial_port = tcp://127.0.0.1:${PORT}/wait
EOF
${FS_UAE:-fs-uae} "$CFG" >"$LOG" 2>&1 & PID=$!
trap 'kill "$PID" 2>/dev/null || true; wait "$PID" 2>/dev/null || true' EXIT INT TERM
python3 tools/capture_serial_tcp.py --port "$PORT" --output "$OUT" --connect-timeout 30 --read-timeout 15 --expect 'AMIDIAG proto=1 milestone=M3.10e cpu=68k' --expect "TEST id=CPU.BASELINE status=PASS cpu=${BASELINE} probe=family-identification"
python3 tools/check_m3_10e_serial.py "$OUT" "$CPU"
echo "PASS: FS-UAE M3.10e cpu=$CPU"
