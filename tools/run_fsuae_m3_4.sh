#!/bin/sh
set -eu

ROM=${1:-build/amidiag-m3_4.rom}
OUT=${2:-build/m3_4-serial.txt}
PORT=${AMIDIAG_SERIAL_PORT:-1240}
FSUAE=${FS_UAE:-fs-uae}
PYTHON=${PYTHON:-python3}

mkdir -p build
CFG=build/m3_4.fs-uae
cat > "$CFG" <<EOF
[fs-uae]
amiga_model = A500
kickstart_file = $(pwd)/$ROM
chip_memory = 512
sound_output = none
serial_port = tcp://127.0.0.1:${PORT}/wait
EOF

# shellcheck disable=SC2086
$FSUAE "$CFG" >build/m3_4-fsuae.log 2>&1 &
EMU_PID=$!
trap 'kill "$EMU_PID" 2>/dev/null || true; wait "$EMU_PID" 2>/dev/null || true' EXIT INT TERM

if ! "$PYTHON" tools/capture_serial_tcp.py \
  --port "$PORT" --output "$OUT" --connect-timeout 30 --read-timeout 15 \
  --expect 'AMIDIAG proto=1 milestone=M3.4 cpu=68000' \
  --expect 'BOOT phase=reset status=PASS' \
  --expect 'TEST id=CPU.PROBE.GUARD status=PASS' \
  --expect 'PROBE class=MEM address=0x00004000 width=16 result=READABLE' \
  --expect 'PROBE class=MEM address=0x00000001 width=16 result=ADDRESS_ERROR' \
  --expect 'TEST id=CPU.PROBE.RESULTS status=PASS' \
  --expect 'TEST id=CPU.BASELINE status=PASS cpu=68000 probe=guarded'; then
  echo '--- FS-UAE log ---' >&2
  cat build/m3_4-fsuae.log >&2 || true
  echo '--- FS-UAE config ---' >&2
  cat "$CFG" >&2 || true
  if ! kill -0 "$EMU_PID" 2>/dev/null; then
    echo 'FAIL: FS-UAE exited before serial qualification completed' >&2
  fi
  exit 1
fi

"$PYTHON" tools/check_m3_4_serial.py "$OUT"
echo "PASS: FS-UAE M3.4 guarded probe primitive"
