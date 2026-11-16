QtScrcpy ARM64 Linux package for Android chroot environments

Target: aarch64 Linux userspace with glibc (Ubuntu/Parrot/Debian chroot).
This is NOT an Android APK and does not run directly in Android's native
application environment.

Install runtime dependencies inside the chroot:
  sudo apt update
  sudo apt install adb qtbase5-dev libqt5multimedia5 libqt5x11extras5 \
    libqt5opengl5 libx11-xcb1 libxcb-xinerama0 libgl1 libasound2

Launch from a graphical chroot session with X11/XWayland configured:
  ./QtScrcpy

For USB access, expose the Android USB device to the chroot and configure
udev/device permissions. Wireless ADB can be used where USB passthrough is
unavailable. Qt platform plugin xcb requires a working X11/XWayland
display and its runtime libraries.
