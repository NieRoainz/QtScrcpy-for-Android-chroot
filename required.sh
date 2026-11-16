#!/usr/bin/env bash
# QtScrcpy ARM64 Linux runtime dependency installer
# Target: Ubuntu/Debian ARM64 userspace, including Android chroots.
set -Eeuo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root: sudo ./required.sh" >&2
  exit 1
fi

arch="$(dpkg --print-architecture 2>/dev/null || true)"
if [[ "$arch" != "arm64" ]]; then
  echo "Unsupported architecture: $arch (this build requires ARM64/aarch64)." >&2
  exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
  echo "This installer supports Ubuntu/Debian systems using apt-get." >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

# Qt 5 GUI and XCB platform plugin
# FFmpeg runtime libraries
# X11/XCB, OpenGL, audio, and ADB runtime libraries
packages=(
  adb

  libqt5core5t64
  libqt5gui5t64
  libqt5widgets5t64
  libqt5network5t64
  libqt5dbus5t64
  libqt5opengl5t64
  libqt5multimedia5
  libqt5x11extras5
  libqt5xcbqpa5

  libavcodec60
  libavformat60
  libavutil58
  libswscale7

  libasound2t64
  libpulse0

  libgl1
  libglx0
  libx11-6
  libx11-xcb1
  libxext6
  libxrender1
  libxcb1
  libxcb-icccm4
  libxcb-image0
  libxcb-keysyms1
  libxcb-randr0
  libxcb-render-util0
  libxcb-shape0
  libxcb-sync1
  libxcb-xfixes0
  libxcb-xinerama0
  libxcb-xkb1
  libxcb-xinput0
  libxcb-util1
  libxkbcommon-x11-0
  libsm6
  libice6

  libfontconfig1
  libfreetype6
  libusb-1.0-0
  libudev1
)

echo "[*] Updating package indexes..."
apt-get update

echo "[*] Installing QtScrcpy ARM64 runtime dependencies..."
apt-get install -y --no-install-recommends "${packages[@]}"

echo
echo "[+] Dependencies installed."
echo "    Start the GUI from the extracted QtScrcpy package directory:"
echo "    ./QtScrcpy"
echo
echo "    If your chroot X server uses display :1, set it first:"
echo "    export DISPLAY=:1"
