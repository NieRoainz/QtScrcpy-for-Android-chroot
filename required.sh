#!/usr/bin/env bash
# QtScrcpy ARM64 hybrid dependency installer.
# Supports glibc-based APT, DNF, Pacman and Zypper distributions.
# Never substitutes FFmpeg SONAMEs across incompatible ABI versions.
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
APP="$ROOT/bin/QtScrcpy"

# Normalize package permissions automatically. The installer itself must
# already be executable (or be started with: bash required.sh).
fix_permissions() {
  echo "[*] Setting safe application permissions..."
  chmod 755 "$ROOT"
  find "$ROOT" -type d -exec chmod 755 {} +
  find "$ROOT" -type f -exec chmod 644 {} +
  for f in \
    "$ROOT/QtScrcpy" \
    "$ROOT/required.sh" \
    "$ROOT/check-deps.sh" \
    "$ROOT/bin/QtScrcpy" \
    "$ROOT/bin/adb" \
    "$ROOT/bin/sndcpy.sh"; do
    [[ ! -f "$f" ]] || chmod 755 "$f"
  done
}
fix_permissions

if [[ "${EUID}" -ne 0 ]]; then
  echo "[!] Run as root: sudo bash $0" >&2
  exit 1
fi

ARCH="$(uname -m)"
if [[ "$ARCH" != "aarch64" && "$ARCH" != "arm64" ]]; then
  echo "[!] ARM64/aarch64 required; detected: $ARCH" >&2
  exit 1
fi
if [[ ! -x "$APP" ]]; then
  echo "[!] Missing ARM64 executable: $APP" >&2
  exit 1
fi

. /etc/os-release 2>/dev/null || true
echo "[*] Distribution: ${PRETTY_NAME:-unknown}"
echo "[*] Architecture: $ARCH"

install_apt() {
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  local candidates=(
    adb
    libqt5core5t64 libqt5core5 libqt5gui5t64 libqt5gui5
    libqt5widgets5t64 libqt5widgets5 libqt5network5t64 libqt5network5
    libqt5dbus5t64 libqt5dbus5 libqt5opengl5t64 libqt5opengl5
    libqt5multimedia5t64 libqt5multimedia5 libqt5x11extras5
    libpulse0 libasound2t64 libasound2 libgl1 libglx0 libegl1
    libx11-6 libx11-xcb1 libxext6 libxrender1 libxcb1
    libxcb-icccm4 libxcb-image0 libxcb-keysyms1 libxcb-randr0
    libxcb-render-util0 libxcb-shape0 libxcb-sync1 libxcb-xfixes0
    libxcb-xinerama0 libxcb-xkb1 libxcb-xinput0 libxcb-util1
    libxkbcommon-x11-0 libsm6 libice6 libfontconfig1 libfreetype6
    libusb-1.0-0 libudev1 android-libbase android-libcutils
    android-liblog android-libcrypto android-libssl android-libziparchive
  )
  local selected=() p
  for p in "${candidates[@]}"; do
    if apt-cache show "$p" >/dev/null 2>&1; then
      case " ${selected[*]} " in *" $p "*) ;; *) selected+=("$p");; esac
    fi
  done
  (("${#selected[@]}" > 0)) || { echo "[!] No matching APT packages found." >&2; return 1; }
  apt-get install -y --no-install-recommends "${selected[@]}"
}

install_dnf() {
  dnf install -y qt5-qtbase qt5-qtmultimedia qt5-qtx11extras \
    pulseaudio-libs alsa-lib mesa-libGL libglvnd-glx \
    libX11 libXext libXrender libxcb libxkbcommon-x11 \
    fontconfig freetype libusb1 systemd-libs android-tools-libs
}
install_pacman() {
  pacman -Sy --needed --noconfirm qt5-base qt5-multimedia qt5-x11extras \
    libpulse alsa-lib mesa libglvnd libx11 libxext libxrender libxcb \
    xcb-util xcb-util-image xcb-util-keysyms xcb-util-renderutil \
    xcb-util-wm libxkbcommon fontconfig freetype2 libusb systemd android-tools
}
install_zypper() {
  zypper --non-interactive refresh
  zypper --non-interactive install libQt5Core5 libQt5Gui5 libQt5Widgets5 \
    libQt5Network5 libQt5DBus5 libQt5OpenGL5 libQt5Multimedia5 \
    libQt5X11Extras5 libpulse0 alsa-lib Mesa-libGL1 libX11-6 libXext6 \
    libXrender1 libxcb1 libxkbcommon-x11-0 fontconfig freetype2 libusb-1_0-0
}

if [[ "${1:-}" == "--check-only" ]]; then
  exec "$ROOT/check-deps.sh"
fi

if command -v apt-get >/dev/null 2>&1; then
  install_apt
elif command -v dnf >/dev/null 2>&1; then
  install_dnf
elif command -v pacman >/dev/null 2>&1; then
  install_pacman
elif command -v zypper >/dev/null 2>&1; then
  install_zypper
elif command -v apk >/dev/null 2>&1; then
  echo "[!] Alpine/musl is not compatible with this glibc-linked binary." >&2
  echo "    Use a glibc chroot or build a separate Alpine/musl binary." >&2
  exit 2
else
  echo "[!] Unsupported package manager. Supported: APT, DNF, Pacman, Zypper." >&2
  exit 2
fi

echo
echo "[*] Checking runtime dependencies..."
"$ROOT/check-deps.sh"
echo "[+] Installer completed."
echo "[*] Launch using: $ROOT/QtScrcpy"
