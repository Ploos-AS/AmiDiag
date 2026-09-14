#!/bin/sh
set -eu

ROM=${1:-build/amidiag-m3_3.rom}
OUT=${2:-build/m3_3-serial.txt}
PORT=${AMIDIAG_SERIAL_PORT:-1239}
FSUAE=${FS_UAE:-fs-uae}
PYTHON=${PYTHON:-python3}

mkdir -p build
CFG=build/m3_3.fs-uae
LOG=build/m3_3-fsuae.log
cat > "$CFG" <<EOF
[fs-uae]
amiga_model = A500
kickstart_file = $(pwd)/$ROM
chip_memory = 512
sound_output = none
serial_port = tcp://127.0.0.1:${PORT}/wait
EOF

# shellcheck disable=SC2086
$FSUAE "$CFG" >"$LOG" 2>&1 &
EMU_PID=$!
trap 'kill "$EMU_PID" 2>/dev/null || true; wait "$EMU_PID" 2>/dev/null || true' EXIT INT TERM

set +e
"$PYTHON" tools/capture_serial_tcp.py \
  --port "$PORT" --output "$OUT" \
  --connect-timeout 30 \
  --read-timeout 15 \
  --expect 'AMIDIAG proto=1 milestone=M3.3 cpu=68000' \
  --expect 'BOOT phase=reset status=PASS' \
  --expect 'TEST id=CPU.VECTORS status=PASS table=ram' \
  --expect 'TEST id=CPU.BUS.FRAME status=PASS source=synthetic frame=68000-14-byte' \
  --expect 'TEST id=CPU.BUS.RECOVER status=PASS source=synthetic frame=68000-14-byte return=unwind-jump' \
  --expect 'TEST id=CPU.BASELINE status=PASS cpu=68000 exception=bus-frame-handler'
CAPTURE_RC=$?
set -e

if [ "$CAPTURE_RC" -ne 0 ]; then
  echo "FAIL: M3.3 serial capture failed (rc=$CAPTURE_RC)" >&2
  if ! kill -0 "$EMU_PID" 2>/dev/null; then
    echo "FAIL: FS-UAE exited before serial qualification completed" >&2
  fi
  echo "--- FS-UAE log ---" >&2
  cat "$LOG" >&2 || true
  echo "--- FS-UAE config ---" >&2
  cat "$CFG" >&2 || true
  exit "$CAPTURE_RC"
fi

"$PYTHON" tools/check_m3_3_serial.py "$OUT"
echo "PASS: FS-UAE M3.3 bus-error frame handler/recovery; hardware BERR capability reported separately"
