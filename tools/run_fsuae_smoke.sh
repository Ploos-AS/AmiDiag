#!/bin/sh
set -eu

ROM=${1:-build/amidiag.rom}
OUT=${2:-build/m2_1-fsuae-serial.txt}
PORT=${AMIDIAG_SERIAL_PORT:-1234}
FSUAE=${FS_UAE:-fs-uae}
PYTHON=${PYTHON:-python3}

mkdir -p build
CFG=build/m2_1.fs-uae
cat > "$CFG" <<EOF
[fs-uae]
amiga_model = A500
kickstart_file = $(pwd)/$ROM
chip_memory = 512
serial_port = tcp://127.0.0.1:${PORT}/wait
EOF

# shellcheck disable=SC2086
$FSUAE "$CFG" >build/m2_1-fsuae.log 2>&1 &
EMU_PID=$!
trap 'kill "$EMU_PID" 2>/dev/null || true; wait "$EMU_PID" 2>/dev/null || true' EXIT INT TERM

"$PYTHON" tools/capture_serial_tcp.py \
  --port "$PORT" \
  --output "$OUT" \
  --expect 'AMIDIAG proto=1 milestone=M2.1 cpu=68000' \
  --expect 'BOOT phase=reset status=PASS' \
  --expect 'TEST id=BOOT.VECTORS status=PASS' \
  --expect 'TEST id=BOOT.SERIAL status=PASS' \
  --expect 'TEST id=MEM.CHIP.PROBE status=PASS probes=8 mode=preserve' \
  --expect 'MEM region=CHIP start=0x00000000 end=0x00080000 bytes=524288 confidence=profile-verified'

"$PYTHON" tools/check_serial.py "$OUT"
echo "PASS: FS-UAE M2.1 bounded Chip RAM verification"
