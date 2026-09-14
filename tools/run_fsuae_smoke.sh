#!/bin/sh
set -eu

ROM=${1:-build/amidiag.rom}
OUT=${2:-build/m2_2-fsuae-serial.txt}
CHIP_KIB=${CHIP_KIB:-512}
PORT=${AMIDIAG_SERIAL_PORT:-1234}
FSUAE=${FS_UAE:-fs-uae}
PYTHON=${PYTHON:-python3}

mkdir -p build
CFG=build/m2_2-${CHIP_KIB}.fs-uae
cat > "$CFG" <<EOF
[fs-uae]
amiga_model = A500
kickstart_file = $(pwd)/$ROM
chip_memory = ${CHIP_KIB}
serial_port = tcp://127.0.0.1:${PORT}/wait
EOF

# shellcheck disable=SC2086
$FSUAE "$CFG" >"build/m2_2-${CHIP_KIB}-fsuae.log" 2>&1 &
EMU_PID=$!
trap 'kill "$EMU_PID" 2>/dev/null || true; wait "$EMU_PID" 2>/dev/null || true' EXIT INT TERM

"$PYTHON" tools/capture_serial_tcp.py \
  --port "$PORT" --output "$OUT" \
  --expect 'AMIDIAG proto=1 milestone=M2.2 cpu=68000' \
  --expect 'BOOT phase=reset status=PASS' \
  --expect 'TEST id=BOOT.VECTORS status=PASS' \
  --expect 'TEST id=BOOT.SERIAL status=PASS' \
  --expect 'TEST id=MEM.CHIP.DISCOVER status=PASS step=524288 mode=preserve-alias'

"$PYTHON" tools/check_serial.py "$OUT" --chip-kib "$CHIP_KIB"
echo "PASS: FS-UAE M2.2 discovered ${CHIP_KIB} KiB Chip RAM"
