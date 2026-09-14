#!/bin/sh
set -eu

ROM=${1:-build/amidiag.rom}
OUT=${2:-build/m1_2-fsuae-serial.txt}
PORT=${AMIDIAG_SERIAL_PORT:-1234}
FSUAE=${FS_UAE:-fs-uae}
PYTHON=${PYTHON:-python3}

mkdir -p build
CFG=build/m1_2.fs-uae
cat > "$CFG" <<EOF
[fs-uae]
amiga_model = A500
kickstart_file = $(pwd)/$ROM
chip_memory = 512
serial_port = tcp://127.0.0.1:${PORT}/wait
EOF

# FS_UAE may be overridden with a wrapper, for example:
#   FS_UAE='xvfb-run -a fs-uae' tools/run_fsuae_smoke.sh
# shellcheck disable=SC2086
$FSUAE "$CFG" >build/m1_2-fsuae.log 2>&1 &
EMU_PID=$!
trap 'kill "$EMU_PID" 2>/dev/null || true; wait "$EMU_PID" 2>/dev/null || true' EXIT INT TERM

"$PYTHON" tools/capture_serial_tcp.py \
  --port "$PORT" \
  --output "$OUT" \
  --expect 'AMIDIAG proto=1 milestone=M1.2 cpu=68000' \
  --expect 'BOOT phase=reset status=PASS' \
  --expect 'TEST id=BOOT.VECTORS status=PASS' \
  --expect 'TEST id=BOOT.SERIAL status=PASS'

"$PYTHON" tools/check_serial.py "$OUT"
echo "PASS: FS-UAE M1.2 normal-boot smoke capture"
