#!/bin/sh
set -eu
CPU=${1:-68000}
ROM=${2:-build/amidiag-m3_10a.rom}
OUT=${3:-build/m3_10a-${CPU}-serial.txt}
PORT=${AMIDIAG_SERIAL_PORT:-1250}
case "$CPU" in
  68000) MODEL=A500; EXPECT=68000 ;;
  68020) MODEL=A1200; EXPECT='68010+' ;;
  *) echo "unsupported CPU profile: $CPU" >&2; exit 2 ;;
esac
CFG=build/m3_10a-${CPU}.fs-uae; LOG=build/m3_10a-${CPU}-fsuae.log
mkdir -p build
cat >"$CFG" <<EOF
[fs-uae]
amiga_model = $MODEL
kickstart_file = $(pwd)/$ROM
chip_memory = 512
accuracy = 1
sound_output = none
serial_port = tcp://127.0.0.1:${PORT}/wait
EOF
${FS_UAE:-fs-uae} "$CFG" >"$LOG" 2>&1 & PID=$!
trap 'kill "$PID" 2>/dev/null || true; wait "$PID" 2>/dev/null || true' EXIT INT TERM
python3 tools/capture_serial_tcp.py --port "$PORT" --output "$OUT" --connect-timeout 30 --read-timeout 15 --expect 'AMIDIAG proto=1 milestone=M3.10a cpu=68k' --expect 'TEST id=CPU.BASELINE status=PASS cpu=68k probe=family-identification'
python3 tools/check_m3_10a_serial.py "$OUT" "$EXPECT"
echo "PASS: FS-UAE M3.10a profile=$CPU family=$EXPECT"
