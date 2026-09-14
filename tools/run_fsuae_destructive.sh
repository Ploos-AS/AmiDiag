#!/bin/sh
set -eu

ROM=${1:-build/amidiag-destructive.rom}
OUT=${2:-build/m2_8-destructive-serial.txt}
PORT=${AMIDIAG_SERIAL_PORT:-1236}
FSUAE=${FS_UAE:-fs-uae}
PYTHON=${PYTHON:-python3}

mkdir -p build
CFG=build/m2_8-destructive.fs-uae
cat > "$CFG" <<EOF
[fs-uae]
amiga_model = A500
kickstart_file = $(pwd)/$ROM
chip_memory = 512
serial_port = tcp://127.0.0.1:${PORT}/wait
EOF

# shellcheck disable=SC2086
$FSUAE "$CFG" >build/m2_8-destructive-fsuae.log 2>&1 &
EMU_PID=$!
trap 'kill "$EMU_PID" 2>/dev/null || true; wait "$EMU_PID" 2>/dev/null || true' EXIT INT TERM

"$PYTHON" tools/capture_serial_tcp.py \
  --port "$PORT" --output "$OUT" \
  --expect 'AMIDIAG proto=1 milestone=M2.8 cpu=68000 profile=destructive-a500-512k' \
  --expect 'WARN id=MEM.DESTRUCTIVE status=PASS destructive=1 preserve=0' \
  --expect 'TEST id=MEM.DESTRUCTIVE.PROFILE status=PASS start=0x00008000 end=0x00070000 bytes=425984 patterns=4 destructive=1' \
  --expect 'TEST id=MEM.DESTRUCTIVE status=PASS start=0x00008000 end=0x00070000 bytes=425984 patterns=4 destructive=1 final=0x55555555'

echo "PASS: FS-UAE M2.8 destructive A500/512K profile"
