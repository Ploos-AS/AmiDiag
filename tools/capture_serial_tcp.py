#!/usr/bin/env python3
import argparse
import socket
import sys
import time
from pathlib import Path


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--host", default="127.0.0.1")
    p.add_argument("--port", type=int, default=1234)
    p.add_argument("--output", required=True)
    p.add_argument("--expect", action="append", default=[])
    p.add_argument("--connect-timeout", type=float, default=10.0)
    p.add_argument("--read-timeout", type=float, default=10.0)
    args = p.parse_args()

    deadline = time.monotonic() + args.connect_timeout
    sock = None
    last_error = None
    while time.monotonic() < deadline:
        try:
            sock = socket.create_connection((args.host, args.port), timeout=1.0)
            break
        except OSError as exc:
            last_error = exc
            time.sleep(0.1)
    if sock is None:
        print(f"FAIL: could not connect to serial socket: {last_error}", file=sys.stderr)
        return 1

    sock.settimeout(0.25)
    data = bytearray()
    read_deadline = time.monotonic() + args.read_timeout
    try:
        while time.monotonic() < read_deadline:
            try:
                chunk = sock.recv(4096)
            except socket.timeout:
                chunk = b""
            if chunk:
                data.extend(chunk)
                text = data.decode("ascii", errors="replace")
                if args.expect and all(marker in text for marker in args.expect):
                    break
            elif args.expect:
                text = data.decode("ascii", errors="replace")
                if all(marker in text for marker in args.expect):
                    break
    finally:
        sock.close()

    Path(args.output).write_bytes(bytes(data))
    text = data.decode("ascii", errors="replace")
    missing = [marker for marker in args.expect if marker not in text]
    if missing:
        print(f"FAIL: missing serial markers: {missing}", file=sys.stderr)
        return 1
    print(f"PASS: captured {len(data)} serial bytes to {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
