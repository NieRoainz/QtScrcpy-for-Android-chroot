#!/usr/bin/env bash
# Diagnose unresolved shared-library dependencies for Roainxztar.
set -uo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
status=0

if ! command -v ldd >/dev/null 2>&1; then
  echo "[ERROR] ldd is unavailable; install the libc diagnostics package for this distro." >&2
  exit 2
fi

check_binary() {
  local binary="$1" output
  if [[ ! -f "$binary" ]]; then
    echo "[WARN] Missing file: $binary"
    status=1
    return
  fi
  echo
  echo "===== $binary ====="
  output="$(ldd "$binary" 2>&1 || true)"
  printf '%s\n' "$output"
  if grep -qE 'not found|No such file or directory' <<<"$output"; then status=1; fi
}
check_binary "$ROOT/bin/QtScrcpy"
check_binary "$ROOT/bin/adb"

if (( status != 0 )); then
  echo
  echo "[ERROR] One or more shared libraries are unresolved."
  if [[ -f "$ROOT/bin/QtScrcpy" ]] && readelf -d "$ROOT/bin/QtScrcpy" 2>/dev/null | grep -q 'libavformat.so.60'; then
    echo "[ABI] This QtScrcpy executable is linked to FFmpeg 6:"
    echo "      libavformat.so.60 libavcodec.so.60 libavutil.so.58 libswscale.so.7"
    echo "      FFmpeg 7/8 SONAMEs are not drop-in replacements. Do not symlink them."
  fi
  echo "[HINT] Install the exact ABI libraries or rebuild the application for this distribution."
  exit 1
fi

echo
echo "[OK] ldd reports no unresolved shared libraries."
exit 0
