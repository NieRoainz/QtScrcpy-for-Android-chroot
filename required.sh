#!/usr/bin/env bash
# QtScrcpy ARM64 Linux runtime dependency installer
# Supports APT-based Debian/Ubuntu derivatives, including Parrot OS.
set -Eeuo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Please run as root: sudo ./required.sh" >&2
  exit 1
fi

if [[ "$(dpkg --print-architecture 2>/dev/null || true)" != "arm64" ]]; then
  echo "This package is intended for ARM64 (aarch64) Linux userspace." >&2
  exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
  echo "This installer requires an Ubuntu/Debian system with apt-get." >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

echo "[*] Updating APT package indexes..."
apt-get update

# Select the first package name available in this distro's repositories.
choose_package() {
  local candidate
  for candidate in "$@"; do
    if apt-cache show "$candidate" >/dev/null 2>&1; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  echo "[!] None of these package variants are available: $*" >&2
  return 1
}

packages=(
  adb
  "$(choose_package libqt5core5t64 libqt5core5)"
  "$(choose_package libqt5gui5t64 libqt5gui5)"
  "$(choose_package libqt5widgets5t64 libqt5widgets5)"
  "$(choose_package libqt5network5t64 libqt5network5)"
  "$(choose_package libqt5dbus5t64 libqt5dbus5)"
  "$(choose_package libqt5opengl5t64 libqt5opengl5)"
  "$(choose_package libqt5multimedia5t64 libqt5multimedia5)"
  libqt5x11extras5
  # Debian/Parrot package the Qt xcb platform plugin with the Qt GUI runtime;
  # libqt5xcbqpa5 is not a package name in these repositories.
  "$(choose_package libavcodec61 libavcodec60 libavcodec59)"
  "$(choose_package libavformat61 libavformat60 libavformat59)"
  "$(choose_package libavutil59 libavutil58 libavutil57)"
  "$(choose_package libswscale8 libswscale7 libswscale6)"
  "$(choose_package libasound2t64 libasound2)"
  libpulse0
  libgl1 libglx0 libx11-6 libx11-xcb1 libxext6 libxrender1
  libxcb1 libxcb-icccm4 libxcb-image0 libxcb-keysyms1 libxcb-randr0
  libxcb-render-util0 libxcb-shape0 libxcb-sync1 libxcb-xfixes0
  libxcb-xinerama0 libxcb-xkb1 libxcb-xinput0 libxcb-util1
  libxkbcommon-x11-0 libsm6 libice6 libfontconfig1 libfreetype6
  libusb-1.0-0 libudev1
)

echo "[*] Installing QtScrcpy ARM64 runtime dependencies..."
apt-get install -y --no-install-recommends "${packages[@]}"

echo
echo "[+] Runtime dependencies installed."
echo "[*] If the GUI display is not detected, set DISPLAY (for example: export DISPLAY=:1)."
echo "[*] Launch QtScrcpy from this directory: ./QtScrcpy"
