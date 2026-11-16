#!/usr/bin/env bash
# QtScrcpy ARM64 Linux runtime dependency installer
# Supported target: Ubuntu/Debian ARM64 userspace (including Android chroot).
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
packages=(
  adb
  libqt5core5t64 libqt5gui5t64 libqt5widgets5t64 libqt5network5t64
  libqt5dbus5t64 libqt5opengl5t64 libqt5multimedia5 libqt5x11extras5 libqt5xcbqpa5
  libavcodec60 libavformat60 libavutil58 libswscale7
  libasound2t64 libpulse0
  libgl1 libglx0 libx11-6 libx11-xcb1 libxext6 libxrender1
  libxcb1 libxcb-icccm4 libxcb-image0 libxcb-keysyms1 libxcb-randr0
  libxcb-render-util0 libxcb-shape0 libxcb-sync1 libxcb-xfixes0
  libxcb-xinerama0 libxcb-xkb1 libxcb-xinput0 libxcb-util1
  libxkbcommon-x11-0 libsm6 libice6 libfontconfig1 libfreetype6
  libusb-1.0-0 libudev1
)

echo "[*] Updating APT package indexes..."
apt-get update
echo "[*] Installing QtScrcpy ARM64 runtime dependencies..."
apt-get install -y --no-install-recommends "${packages[@]}"
echo
echo "[+] Runtime dependencies installed."
echo "[*] If the GUI display is not detected, set DISPLAY (for example: export DISPLAY=:1)."
echo "[*] Launch QtScrcpy from this directory: ./QtScrcpy"
