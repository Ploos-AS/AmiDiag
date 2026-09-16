#!/bin/sh
set -eu
CPU=${1:-68000}; ROM=${2:-build/amidiag-m3_10c.rom}; OUT=${3:-build/m3_10c-${CPU}-serial.txt}; PORT=${AMIDIAG_SERIAL_PORT:-1252}
case "$CPU" in
  68000) MODEL=A500; EXPECT=68000; BASELINE_CPU=68000 ;;
  68010) MODEL=A500; EXPECT=68010; BASELINE_CPU=68k ;;
  68020) MODEL=A1200; EXPECT=68020; BASELINE_CPU=68k ;;
  68030) MODEL=A3000; EXPECT='68030+'; BASELINE_CPU=68k ;;
  *) echo "unsupported CPU profile: $CPU" >&2; exit 2 ;;
esac
CFG=build/m3_10c-${CPU}.fs-uae; LOG=build/m3_10c-${CPU}-fsuae.log
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
python3 tools/capture_serial_tcp.py --port "$PORT" --output "$OUT" --connect-timeout 30 --read-timeout 15 --expect 'AMIDIAG proto=1 milestone=M3.10c cpu=68k' --expect "TEST id=CPU.BASELINE status=PASS cpu=${BASELINE_CPU} probe=family-identification"
python3 tools/check_m3_10c_serial.py "$OUT" "$EXPECT"
echo "PASS: FS-UAE M3.10c profile=$CPU family=$EXPECT"
