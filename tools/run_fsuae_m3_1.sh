#!/bin/sh
set -eu

ROM=${1:-build/amidiag-m3_1.rom}
OUT=${2:-build/m3_1-serial.txt}
PORT=${AMIDIAG_SERIAL_PORT:-1237}
FSUAE=${FS_UAE:-fs-uae}
PYTHON=${PYTHON:-python3}

mkdir -p build
CFG=build/m3_1.fs-uae
cat > "$CFG" <<EOF
[fs-uae]
amiga_model = A500
kickstart_file = $(pwd)/$ROM
chip_memory = 512
serial_port = tcp://127.0.0.1:${PORT}/wait
EOF

# shellcheck disable=SC2086
$FSUAE "$CFG" >build/m3_1-fsuae.log 2>&1 &
EMU_PID=$!
trap 'kill "$EMU_PID" 2>/dev/null || true; wait "$EMU_PID" 2>/dev/null || true' EXIT INT TERM

"$PYTHON" tools/capture_serial_tcp.py \
  --port "$PORT" --output "$OUT" \
  --expect 'AMIDIAG proto=1 milestone=M3.1 cpu=68000' \
  --expect 'BOOT phase=reset status=PASS' \
  --expect 'TEST id=CPU.VECTORS status=PASS table=ram' \
  --expect 'TEST id=CPU.EXCEPTION.RECOVER status=PASS vector=TRAP0 frame=sr-pc return=RTE' \
  --expect 'TEST id=CPU.BASELINE status=PASS cpu=68000 exception=trap0'

"$PYTHON" tools/check_m3_1_serial.py "$OUT"
echo "PASS: FS-UAE M3.1 recoverable TRAP0 exception round-trip"
