#!/bin/sh
set -eu

ROM=${1:-build/amidiag.rom}
OUT=${2:-build/m2_4-fsuae-serial.txt}
CHIP_KIB=${CHIP_KIB:-512}
PORT=${AMIDIAG_SERIAL_PORT:-1234}
FSUAE=${FS_UAE:-fs-uae}
PYTHON=${PYTHON:-python3}

case "$CHIP_KIB" in
  512)
    MEM_RECORD='MEM region=CHIP start=0x00000000 end=0x00080000 bytes=524288 confidence=discovered'
    ;;
  1024)
    MEM_RECORD='MEM region=CHIP start=0x00000000 end=0x00100000 bytes=1048576 confidence=discovered'
    ;;
  1536)
    MEM_RECORD='MEM region=CHIP start=0x00000000 end=0x00180000 bytes=1572864 confidence=discovered'
    ;;
  2048)
    MEM_RECORD='MEM region=CHIP start=0x00000000 end=0x00200000 bytes=2097152 confidence=discovered'
    ;;
  *)
    echo "unsupported CHIP_KIB=$CHIP_KIB" >&2
    exit 2
    ;;
esac

mkdir -p build
CFG=build/m2_4-${CHIP_KIB}.fs-uae
cat > "$CFG" <<EOF
[fs-uae]
amiga_model = A500
kickstart_file = $(pwd)/$ROM
chip_memory = ${CHIP_KIB}
serial_port = tcp://127.0.0.1:${PORT}/wait
EOF

# shellcheck disable=SC2086
$FSUAE "$CFG" >"build/m2_4-${CHIP_KIB}-fsuae.log" 2>&1 &
EMU_PID=$!
trap 'kill "$EMU_PID" 2>/dev/null || true; wait "$EMU_PID" 2>/dev/null || true' EXIT INT TERM

"$PYTHON" tools/capture_serial_tcp.py \
  --port "$PORT" --output "$OUT" \
  --expect 'AMIDIAG proto=1 milestone=M2.4 cpu=68000' \
  --expect 'BOOT phase=reset status=PASS' \
  --expect 'TEST id=BOOT.VECTORS status=PASS' \
  --expect 'TEST id=BOOT.SERIAL status=PASS' \
  --expect 'TEST id=MEM.DATA status=PASS width=32 patterns=64 mode=preserve' \
  --expect 'TEST id=MEM.ADDRESS status=PASS bits=A2-A18 probes=17 mode=preserve-alias' \
  --expect 'TEST id=MEM.CHIP.DISCOVER status=PASS step=524288 mode=preserve-alias' \
  --expect "$MEM_RECORD"

"$PYTHON" tools/check_serial.py "$OUT" --chip-kib "$CHIP_KIB"
echo "PASS: FS-UAE M2.4 data/address-line tests and ${CHIP_KIB} KiB discovery"
