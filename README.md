# QtScrcpy for Android Termux + Linux Chroot

QtScrcpy ARM64 desktop application packaged for use from an **ARM64 Linux userspace running on an Android device**. The intended environments are Termux with a Debian/Ubuntu userspace (for example, through `proot-distro`) and a conventional rooted Linux chroot.

**Short compatibility note:** Designed for Android devices running ARM64 Debian/Ubuntu through Termux (`proot-distro`) or a rooted Linux chroot. It does not run directly in native Termux.

## Demo

The project demo is a 43-second portrait MP4. The video has not yet been uploaded as a GitHub Release asset, so an inline player cannot be embedded here yet. Once the MP4 is attached to the `QtScrcpy-for-Android-chroot` release, its GitHub-hosted video URL can be added here for playback in the GitHub README.

> **Important:** This is a Linux ARM64 application, not an Android APK. The QtScrcpy executable is built for a glibc-based Linux userspace. It is not expected to run directly in Termux's native Android/Bionic environment.

## What this project provides

- An ARM64 QtScrcpy application launcher.
- A bundled ADB client and scrcpy server (when the complete runtime payload is present).
- Default configuration and keymap directories.
- An optional sndcpy helper and APK.
- `required.sh`, an APT-based installer for the Linux runtime libraries.

The launcher sets the paths QtScrcpy uses for ADB, the scrcpy server, configuration and keymaps, then starts the application binary.

## Compatibility overview

| Environment | Compatibility | Notes |
|---|---|---|
| Termux native shell | **Not directly supported** | Native Termux uses Android/Bionic; this Linux executable expects glibc. |
| Termux + Debian/Ubuntu via `proot-distro` | **Intended use** | Run the application inside the distro, with an X11 display server available from Android. |
| Rooted Debian/Ubuntu chroot | **Intended use** | Requires ARM64 userspace, glibc, GUI display access and ADB/device access. |
| Ordinary ARM64 Debian/Ubuntu desktop | **Potentially compatible** | Requires the listed runtime libraries and a working graphical session. |
| x86/x86_64 Linux | **Not supported by this ARM64 build** | Use an executable built for the target architecture. |

Compatibility depends on the Linux distribution and its library versions. The included dependency script uses package names found in newer Debian/Ubuntu repositories (including the `t64` library package names); older releases may need package-name adjustments.

## Requirements

- Android device with a 64-bit ARM CPU and an ARM64 Linux userspace.
- Termux installed from a supported distribution source, if using the Termux route.
- Debian or Ubuntu ARM64 installed inside Termux, or a conventional ARM64 chroot.
- A graphical X11/XWayland server reachable from the Linux userspace.
- Qt 5, XCB, OpenGL, FFmpeg, audio, USB and ADB runtime libraries.
- ADB access to the Android device being controlled.

QtScrcpy is a GUI program. Having the Linux distro installed is not enough: the display server and its socket/environment must also be available inside the distro.

## Option A — Termux with Debian/Ubuntu (proot-distro)

### 1. Install the Android-side components

Install Termux and the Termux:X11 Android application from their official project/distribution sources. In Termux, install the Termux:X11 companion package and proot-distro:

```bash
pkg update && pkg upgrade
pkg install x11-repo
pkg install termux-x11-nightly proot-distro
```

Install a Debian or Ubuntu ARM64 distro:

```bash
proot-distro install debian
proot-distro login debian
```

You can use another supported ARM64 distro, but the dependency installer in this repository is written for APT-based Debian/Ubuntu systems.

### 2. Start the X11 display

In the Termux session (outside the proot distro), start Termux:X11:

```bash
termux-x11 :1 &
```

Open the Termux:X11 Android app. Then enter the Linux distro in another Termux session:

```bash
proot-distro login debian
export DISPLAY=:1
```

If your display server uses a different display number, set `DISPLAY` to match it. The X11 socket must be accessible from the distro. Some setups may require additional shared-directory or socket configuration; proot does not automatically guarantee access to every Android-side socket or device.

### 3. Install dependencies inside Debian/Ubuntu

Copy or clone this project into the Linux distro, then run the installer **inside the distro**, not in the native Termux shell:

```bash
cd QtScrcpy-for-Android-chroot
chmod +x required.sh QtScrcpy
./required.sh
```

The installer requires root inside the distro. If your distro login is not root, use its supported `sudo`/root login method.

If APT reports that a package cannot be found, your distribution release may use different Qt 5 or `t64` package names. Update the package list for your distro rather than trying to install Linux packages with Termux's `pkg` command.

### 4. Launch

From the project directory, inside the Linux distro:

```bash
export DISPLAY=:1
./QtScrcpy
```

The launcher resolves its own directory, configures the bundled runtime paths, and starts `bin/QtScrcpy`.

## Option B — Rooted Linux chroot

For a conventional chroot, make sure the root filesystem is ARM64 and provides glibc. Bind or expose the resources the GUI and ADB need before entering the chroot.

Typical host-side preparation may include access to:
- The X11 socket directory used by your Android X server (commonly `/tmp/.X11-unix`).
- Relevant device nodes if you intend to use USB ADB.
- Audio sockets/devices if you need audio features.
- GPU/render devices only if your chroot and Android graphics stack support them.

The exact bind mounts depend on the Android ROM, chroot manager, X server and device permissions. Do not blindly mount every host device into the chroot.

Inside the chroot:

```bash
dpkg --print-architecture
# Expected: arm64

cd /path/to/QtScrcpy-for-Android-chroot
chmod +x required.sh QtScrcpy
./required.sh
export DISPLAY=:1
./QtScrcpy
```

Set `DISPLAY` to the display number provided by your X server. For example, `:1` is common in some Android X11 setups, but it is not universal.

## ADB connection notes

QtScrcpy needs ADB to see the Android device.

### Wireless ADB

Wireless debugging can avoid USB passthrough problems. Enable Wireless debugging in Android Developer options, pair/connect using the ADB pairing details shown by Android, and verify:

```bash
./bin/adb devices
```

The pairing and connection ports are shown by Android and may change; do not assume a fixed port.

### USB ADB

USB ADB from a chroot/proot environment is more complicated. The USB device node, permissions and required interfaces must be visible to the Linux userspace. A proot environment generally cannot grant itself host-level device access. Configure USB passthrough from the Android host/chroot manager where supported.

If ADB already works in the Termux host but not inside the distro, you may need to use a shared ADB server or configure ADB connectivity explicitly. Check which ADB server the client is using and avoid starting conflicting ADB servers on the same port.

Always verify ADB independently before troubleshooting QtScrcpy:

```bash
./bin/adb version
./bin/adb devices
```

## Runtime layout

The expected extracted layout is:

```text
QtScrcpy-for-Android-chroot/
├── QtScrcpy                 # launcher script
├── required.sh              # APT runtime dependency installer
├── README.md
├── bin/
│   ├── QtScrcpy             # ARM64 Linux executable
│   ├── adb                  # ADB client
│   └── sndcpy.sh            # optional sndcpy helper
└── share/
    ├── scrcpy-server
    ├── sndcpy.apk
    ├── config/
    │   └── config.ini
    └── keymap/
        └── *.json
```

Keep the `bin/` and `share/` directories beside the top-level `QtScrcpy` launcher. The launcher uses paths relative to its own location; moving individual files or directories will break those paths.

## Troubleshooting

### `Exec format error` or executable will not start

Check the architecture and executable type:

```bash
uname -m
file bin/QtScrcpy
dpkg --print-architecture
```

This build is for ARM64/aarch64 Linux. It also expects a glibc-based environment; the native Termux/Bionic shell is not the target.

### `error while loading shared libraries`

Check unresolved dependencies:

```bash
ldd bin/QtScrcpy | grep 'not found'
```

Install the missing libraries using APT inside the distro. Do not run `ldd` on the top-level `QtScrcpy` launcher: it is a shell script, not the ELF application.

### Qt says the `xcb` platform plugin cannot be loaded

Confirm that the X server is running and that `DISPLAY` is correct:

```bash
echo "$DISPLAY"
ls -la /tmp/.X11-unix 2>/dev/null
```

Install the Qt XCB platform plugin and its X11/XCB dependencies in the Linux distro. A message saying that the plugin was found does not necessarily mean all of its dependent libraries are present.

### The window does not appear

- Open the Termux:X11 Android app.
- Confirm that the Linux distro can access the X11 socket.
- Check `DISPLAY` and any X authorization requirements.
- Run QtScrcpy from a terminal and inspect the full error output.

### ADB shows no devices

```bash
./bin/adb kill-server
./bin/adb start-server
./bin/adb devices -l
```

Check Wireless debugging pairing/connection or USB passthrough and permissions. ADB working in the Android host does not automatically mean it is available inside a chroot.

### Audio or screen capture problems

Audio capture and display rendering depend on the Android-side permissions, Linux audio/display sockets and device support. First confirm that the QtScrcpy window works, then test ADB and the scrcpy connection separately.

## Security and limitations

- Only install APKs and use ADB commands for devices you own or are authorized to administer.
- Do not expose an ADB server to untrusted networks.
- The dependency installer installs system packages inside the Linux distro; review it before running.
- This project does not make a proot distro equivalent to a fully privileged chroot. Hardware access, USB, GPU acceleration and audio may be restricted by Android and the container environment.
- This repository targets ARM64 Linux on Android-hosted userspaces. It does not promise compatibility with every Android version, ROM, distro release or display server.

## Project status

This repository documents and packages the ARM64 QtScrcpy runtime for Android-hosted Linux environments. Check the repository contents and releases to confirm that all runtime payload files (`bin/QtScrcpy`, `bin/adb`, `share/scrcpy-server`, configuration/keymap data and optional sndcpy assets) are present before launching.

## License and upstream components

QtScrcpy, scrcpy, ADB, sndcpy and their bundled components may have separate upstream licenses. Consult the corresponding upstream project and license notices before redistribution.
