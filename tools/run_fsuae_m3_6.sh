#!/bin/sh
set -eu
ROM=${1:-build/amidiag-m3_6.rom}
OUT=${2:-build/m3_6-serial.txt}
CHIP_KIB=${CHIP_KIB:-512}
PORT=${AMIDIAG_SERIAL_PORT:-1243}
FSUAE=${FS_UAE:-fs-uae}
PYTHON=${PYTHON:-python3}
mkdir -p build
CFG="build/m3_6-${CHIP_KIB}.fs-uae"
LOG="build/m3_6-${CHIP_KIB}-fsuae.log"
cat > "$CFG" <<EOF
[fs-uae]
amiga_model = A500
kickstart_file = $(pwd)/$ROM
chip_memory = ${CHIP_KIB}
sound_output = none
serial_port = tcp://127.0.0.1:${PORT}/wait
EOF
$FSUAE "$CFG" >"$LOG" 2>&1 &
EMU_PID=$!
trap 'kill "$EMU_PID" 2>/dev/null || true; wait "$EMU_PID" 2>/dev/null || true' EXIT INT TERM
if ! "$PYTHON" tools/capture_serial_tcp.py --port "$PORT" --output "$OUT" --connect-timeout 30 --read-timeout 15 \
 --expect 'AMIDIAG proto=1 milestone=M3.6 cpu=68000' \
 --expect 'TEST id=MEM.CHIP.DISCOVER.GUARDED status=PASS' \
 --expect 'TEST id=CPU.BASELINE status=PASS cpu=68000 probe=guarded-memory-discovery'; then
  cat "$LOG" >&2 || true
  cat "$CFG" >&2 || true
  exit 1
fi
"$PYTHON" tools/check_m3_6_serial.py "$OUT" --chip-kib "$CHIP_KIB"
echo "PASS: FS-UAE M3.6 guarded Chip discovery (${CHIP_KIB} KiB)"
