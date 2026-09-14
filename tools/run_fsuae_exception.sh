#!/bin/sh
set -eu

ROM=${1:-build/amidiag-exception.rom}
OUT=${2:-build/m1_2-fsuae-exception-serial.txt}
PORT=${AMIDIAG_SERIAL_PORT:-1235}
FSUAE=${FS_UAE:-fs-uae}
PYTHON=${PYTHON:-python3}

mkdir -p build
CFG=build/m1_2-exception.fs-uae
cat > "$CFG" <<EOF
[fs-uae]
amiga_model = A500
kickstart_file = $(pwd)/$ROM
chip_memory = 512
serial_port = tcp://127.0.0.1:${PORT}/wait
EOF

# shellcheck disable=SC2086
$FSUAE "$CFG" >build/m1_2-fsuae-exception.log 2>&1 &
EMU_PID=$!
trap 'kill "$EMU_PID" 2>/dev/null || true; wait "$EMU_PID" 2>/dev/null || true' EXIT INT TERM

"$PYTHON" tools/capture_serial_tcp.py \
  --port "$PORT" \
  --output "$OUT" \
  --expect 'AMIDIAG proto=1 milestone=M1.2 cpu=68000' \
  --expect 'TEST id=BOOT.VECTORS status=PASS' \
  --expect 'TEST id=BOOT.SERIAL status=PASS' \
  --expect 'EXCEPTION id=CPU.ILLEGAL status=FAIL fatal=1'

"$PYTHON" tools/check_serial.py "$OUT" --expect-exception CPU.ILLEGAL
echo "PASS: FS-UAE M1.2 deliberate exception smoke capture"
