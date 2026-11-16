#!/usr/bin/env bash
# QtScrcpy ARM64 runtime dependency installer.
# Supports glibc-based ARM64 distributions with APT, DNF, Pacman or Zypper.
# FFmpeg SONAMEs are validated against the executable; incompatible majors are
# never substituted and no fake SONAME symlinks are created.
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
APP="$ROOT/bin/QtScrcpy"

if [[ "${EUID}" -ne 0 ]]; then
  echo "[!] Run as root: sudo $0" >&2
  exit 1
fi

ARCH="$(uname -m)"
if [[ "$ARCH" != "aarch64" && "$ARCH" != "arm64" ]]; then
  echo "[!] This package currently targets ARM64/aarch64; detected: $ARCH" >&2
  exit 1
fi

if [[ ! -x "$APP" ]]; then
  echo "[!] Missing executable: $APP" >&2
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
    libqt5core5t64 libqt5core5
    libqt5gui5t64 libqt5gui5
    libqt5widgets5t64 libqt5widgets5
    libqt5network5t64 libqt5network5
    libqt5dbus5t64 libqt5dbus5
    libqt5opengl5t64 libqt5opengl5
    libqt5multimedia5t64 libqt5multimedia5
    libqt5x11extras5
    libpulse0 libasound2t64 libasound2
    libgl1 libglx0 libegl1
    libx11-6 libx11-xcb1 libxext6 libxrender1
    libxcb1 libxcb-icccm4 libxcb-image0 libxcb-keysyms1
    libxcb-randr0 libxcb-render-util0 libxcb-shape0 libxcb-sync1
    libxcb-xfixes0 libxcb-xinerama0 libxcb-xkb1 libxcb-xinput0
    libxcb-util1 libxkbcommon-x11-0 libsm6 libice6
    libfontconfig1 libfreetype6 libusb-1.0-0 libudev1
    android-libbase android-libcutils android-liblog
    android-libcrypto android-libssl android-libziparchive
  )
  local selected=() p
  for p in "${candidates[@]}"; do
    if apt-cache show "$p" >/dev/null 2>&1; then
      # Avoid duplicate package names in the install request.
      case " ${selected[*]} " in *" $p "*) ;; *) selected+=("$p");; esac
    fi
  done
  if (("${#selected[@]}" == 0)); then
    echo "[!] No matching APT runtime packages were found." >&2
    return 1
  fi
  apt-get install -y --no-install-recommends "${selected[@]}"
}

install_dnf() {
  dnf install -y     qt5-qtbase qt5-qtmultimedia qt5-qtx11extras     pulseaudio-libs alsa-lib mesa-libGL libglvnd-glx     libX11 libXext libXrender libxcb libxkbcommon-x11     fontconfig freetype libusb1 systemd-libs android-tools-libs || {
      echo "[!] Some DNF package names vary by Fedora/RHEL release." >&2
      return 1
    }
}

install_pacman() {
  pacman -Sy --needed --noconfirm     qt5-base qt5-multimedia qt5-x11extras     libpulse alsa-lib mesa libglvnd libx11 libxext libxrender     libxcb xcb-util xcb-util-image xcb-util-keysyms     xcb-util-renderutil xcb-util-wm libxkbcommon fontconfig freetype2     libusb systemd android-tools
}

install_zypper() {
  zypper --non-interactive refresh
  zypper --non-interactive install     libQt5Core5 libQt5Gui5 libQt5Widgets5 libQt5Network5     libQt5DBus5 libQt5OpenGL5 libQt5Multimedia5 libQt5X11Extras5     libpulse0 alsa-lib Mesa-libGL1 libX11-6 libXext6 libXrender1     libxcb1 libxkbcommon-x11-0 fontconfig freetype2 libusb-1_0-0
}

if [[ "${1:-}" == "--check-only" ]]; then
  exec "$ROOT/check-deps.sh"
fi

if command -v apt-get >/dev/null 2>&1; then
  echo "[*] Installing available APT runtime packages..."
  install_apt
elif command -v dnf >/dev/null 2>&1; then
  echo "[*] Installing DNF runtime packages..."
  install_dnf
elif command -v pacman >/dev/null 2>&1; then
  echo "[*] Installing Pacman runtime packages..."
  install_pacman
elif command -v zypper >/dev/null 2>&1; then
  echo "[*] Installing Zypper runtime packages..."
  install_zypper
elif command -v apk >/dev/null 2>&1; then
  echo "[!] Alpine uses musl libc. This glibc-linked QtScrcpy binary is not supported natively." >&2
  echo "    Use a glibc-based container/chroot or build a separate Alpine/musl target." >&2
  exit 2
else
  echo "[!] No supported package manager found (APT, DNF, Pacman, Zypper)." >&2
  exit 2
fi

echo
echo "[*] Checking actual ELF dependencies..."
if "$ROOT/check-deps.sh"; then
  echo "[+] Required system libraries appear to be available."
else
  status=$?
  echo
  echo "[!] Some required shared libraries are still missing."
  echo "[!] Package names alone cannot fix an FFmpeg SONAME/ABI mismatch."
  echo "[!] Rebuild QtScrcpy against this distro's FFmpeg, or bundle the exact"
  echo "    compatible FFmpeg runtime and its transitive dependencies."
  echo "[!] Never symlink a different FFmpeg major version to a required SONAME."
  exit "$status"
fi

echo
echo "[+] Dependency installation/check completed."
echo "[*] Set DISPLAY to your Android X11 display (for example: export DISPLAY=:1)."
echo "[*] Launch with: $ROOT/QtScrcpy"
