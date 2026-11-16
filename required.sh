#!/usr/bin/env bash
# Roainxztar ARM64 runtime dependency installer.
# Supports common glibc Linux package managers; this does not make a
# glibc executable compatible with musl or repair incompatible SONAMEs.
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
APP="$ROOT/bin/QtScrcpy"
CHECK="$ROOT/check-deps.sh"

die() { printf '[ERROR] %s\n' "$*" >&2; exit 1; }
note() { printf '[*] %s\n' "$*"; }
warn() { printf '[!] %s\n' "$*" >&2; }

# Safe permissions only inside this package. Never chmod the whole host.
if [[ -d "$ROOT" ]]; then
  find "$ROOT" -type d -exec chmod u+rwx,go+rx {} + 2>/dev/null || true
  for f in "$ROOT/QtScrcpy" "$ROOT/required.sh" "$ROOT/check-deps.sh" \
           "$ROOT/bin/QtScrcpy" "$ROOT/bin/adb" "$ROOT/bin/sndcpy.sh"; do
    [[ ! -f "$f" ]] || chmod u+rwx,go+rx "$f" 2>/dev/null || true
  done
fi

ARCH="$(uname -m)"
[[ "$ARCH" == aarch64 || "$ARCH" == arm64 ]] || die "ARM64 required; detected $ARCH."
[[ -x "$APP" ]] || die "Application binary missing: $APP. Extract the complete package first."
[[ -r /etc/os-release ]] || die "Cannot identify Linux distribution (/etc/os-release missing)."
. /etc/os-release
note "Distribution: ${PRETTY_NAME:-unknown}"
note "Architecture: $ARCH"

# Native Termux uses Android/Bionic, not glibc. Alpine defaults to musl.
if grep -qiE 'alpine|termux' /etc/os-release 2>/dev/null || [[ -n "${TERMUX_VERSION:-}" ]]; then
  die "This package is glibc-linked. Alpine/musl and native Termux/Bionic need a separate build. Use a glibc distro inside proot/chroot."
fi

if [[ "${1:-}" == "--check-only" ]]; then
  [[ -x "$CHECK" ]] || die "Missing dependency checker: $CHECK"
  exec "$CHECK"
fi

[[ "$EUID" -eq 0 ]] || die "Run inside the target distro as root (for example: proot-distro login ... or sudo bash required.sh)."

install_apt() {
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  local candidates=(
    adb libqt5core5t64 libqt5core5 libqt5gui5t64 libqt5gui5
    libqt5widgets5t64 libqt5widgets5 libqt5network5t64 libqt5network5
    libqt5dbus5t64 libqt5dbus5 libqt5opengl5t64 libqt5opengl5
    libqt5multimedia5 libqt5x11extras5 libqt5xcbqpa5
    libpulse0 libasound2t64 libasound2 libgl1 libglx0 libegl1
    libx11-6 libx11-xcb1 libxext6 libxrender1 libxcb1
    libxcb-icccm4 libxcb-image0 libxcb-keysyms1 libxcb-randr0
    libxcb-render-util0 libxcb-shape0 libxcb-sync1 libxcb-xfixes0
    libxcb-xinerama0 libxcb-xkb1 libxcb-xinput0 libxcb-util1
    libxkbcommon-x11-0 libsm6 libice6 libfontconfig1 libfreetype6
    libusb-1.0-0 libudev1 libavformat60 libavcodec60 libavutil58 libswscale7
  )
  local selected=() p
  for p in "${candidates[@]}"; do
    if apt-cache show "$p" >/dev/null 2>&1; then selected+=("$p"); fi
  done
  (("${#selected[@]}" > 0)) || die "APT found no matching runtime packages."
  apt-get install -y --no-install-recommends "${selected[@]}"
}

install_dnf() {
  dnf install -y qt5-qtbase qt5-qtmultimedia qt5-qtx11extras \
    pulseaudio-libs alsa-lib mesa-libGL libglvnd-glx \
    libX11 libXext libXrender libxcb libxkbcommon-x11 \
    fontconfig freetype libusb1 systemd-libs
  # FFmpeg SONAME 60 is provided only by repositories/builds carrying FFmpeg 6.
  dnf install -y ffmpeg-libs || warn "Could not install FFmpeg runtime via dnf; verify FFmpeg 6 SONAMEs."
}
install_pacman() {
  pacman -Sy --needed --noconfirm qt5-base qt5-multimedia qt5-x11extras \
    libpulse alsa-lib mesa libglvnd libx11 libxext libxrender libxcb \
    xcb-util xcb-util-image xcb-util-keysyms xcb-util-renderutil \
    xcb-util-wm libxkbcommon fontconfig freetype2 libusb systemd
  pacman -S --needed --noconfirm ffmpeg || warn "Could not install FFmpeg; verify FFmpeg 6 SONAMEs."
}
install_zypper() {
  zypper --non-interactive refresh
  zypper --non-interactive install libQt5Core5 libQt5Gui5 libQt5Widgets5 \
    libQt5Network5 libQt5DBus5 libQt5OpenGL5 libQt5Multimedia5 \
    libQt5X11Extras5 libpulse0 alsa-lib Mesa-libGL1 libX11-6 libXext6 \
    libXrender1 libxcb1 libxkbcommon-x11-0 fontconfig freetype2 libusb-1_0-0
  zypper --non-interactive install ffmpeg-6 || warn "FFmpeg 6 package unavailable from enabled repositories."
}
install_xbps() {
  xbps-install -S
  xbps-install -y qt5-core qt5-gui qt5-widgets qt5-multimedia qt5-x11extras \
    pulseaudio alsa-lib mesa-dri libX11 libXext libXrender libxcb \
    libxkbcommon fontconfig freetype libusb
  xbps-install -y ffmpeg || warn "FFmpeg package unavailable; verify FFmpeg 6 SONAMEs."
}
install_emerge() {
  emerge --sync
  emerge --ask=n dev-qt/qtcore:5 dev-qt/qtgui:5 dev-qt/qtwidgets:5 \
    dev-qt/qtmultimedia:5 dev-qt/qtx11extras:5 media-libs/alsa-lib \
    media-libs/libpulse media-libs/mesa x11-libs/libX11 x11-libs/libxcb \
    x11-libs/libXext x11-libs/libXrender media-libs/fontconfig \
    media-libs/freetype dev-libs/libusb
  emerge --ask=n media-video/ffmpeg
}

if command -v apt-get >/dev/null 2>&1; then
  install_apt
elif command -v dnf >/dev/null 2>&1; then
  install_dnf
elif command -v pacman >/dev/null 2>&1; then
  install_pacman
elif command -v zypper >/dev/null 2>&1; then
  install_zypper
elif command -v xbps-install >/dev/null 2>&1; then
  install_xbps
elif command -v emerge >/dev/null 2>&1; then
  install_emerge
else
  die "Unsupported package manager. Supported: APT, DNF, Pacman, Zypper, XBPS and Portage."
fi

printf '\n'
note "Checking the actual ELF runtime dependencies..."
[[ -x "$CHECK" ]] || die "Missing checker: $CHECK"
if "$CHECK"; then
  printf '\n[OK] Runtime dependency check passed.\n'
  note "Launch with: $ROOT/QtScrcpy"
else
  status=$?
  warn "Some libraries are still unavailable. The installer cannot safely replace ABI versions."
  warn "In particular, this executable requires FFmpeg 6: libavformat.so.60, libavcodec.so.60, libavutil.so.58 and libswscale.so.7."
  warn "If your distro ships another FFmpeg SONAME, use a compatible FFmpeg 6 package/build or rebuild Roainxztar against that distro."
  exit "$status"
fi
