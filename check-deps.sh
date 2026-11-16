#!/usr/bin/env bash
# Report unresolved shared-library dependencies for QtScrcpy and bundled ADB.
set -uo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
status=0

if ! command -v ldd >/dev/null 2>&1; then
  echo "[!] ldd is unavailable. Install the libc/binutils diagnostics for your distro." >&2
  exit 2
fi

check_binary() {
  local binary="$1"
  if [[ ! -f "$binary" ]]; then
    echo "[!] Missing file: $binary"
    status=1
    return
  fi
  echo
  echo "===== $binary ====="
  local output
  output="$(ldd "$binary" 2>&1 || true)"
  printf '%s\n' "$output"
  if grep -qE 'not found|No such file or directory' <<<"$output"; then
    status=1
  fi
}

check_binary "$ROOT/bin/QtScrcpy"
check_binary "$ROOT/bin/adb"

if (( status != 0 )); then
  echo
  echo "[!] Unresolved runtime libraries detected."
  if grep -Eq 'libav(format|codec)\.so\.60|libavutil\.so\.58|libswscale\.so\.7' <<<"$(ldd "$ROOT/bin/QtScrcpy" 2>&1 || true)"; then
    echo "[!] This build requires FFmpeg 6 ABI libraries:"
    echo "    libavformat.so.60, libavcodec.so.60, libavutil.so.58, libswscale.so.7"
    echo "    Newer FFmpeg SONAMEs are not drop-in replacements."
    echo "    Rebuild QtScrcpy against the host FFmpeg or bundle the exact ABI runtime."
  fi
  exit 1
fi

echo
echo "[+] No unresolved shared libraries reported by ldd."
exit 0
