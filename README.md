# Roainxztar

**Roainxztar** is an ARM64 Linux desktop application project for displaying and controlling Android devices from an Android-hosted Linux userspace.

The application is intended for **AArch64/glibc** environments such as Debian, Ubuntu, Parrot and Kali running through Termux `proot-distro` or a rooted Android chroot. It is not an Android APK and is not designed to run directly in Termux's native Android/Bionic shell.

> [!IMPORTANT]
> This repository is in a source-port/build transition. The current branch contains packaging scripts and documentation, but it does **not yet contain the complete application executable, ADB payload, scrcpy server payload, or upstream C++ source tree**. Do not treat the current branch as a complete runnable release.

## Project identity

- Product/application name: **Roainxztar**
- Target architecture: **ARM64 / AArch64**
- Runtime target: **Linux with glibc**
- Android-hosted environments: **Termux + Debian/Ubuntu proot-distro** and rooted Linux chroots
- Desktop display: **X11 / XWayland**
- Upstream application technology: QtScrcpy
- Upstream source: [barry-ran/QtScrcpy](https://github.com/barry-ran/QtScrcpy)
- Core library: [barry-ran/QtScrcpyCore](https://github.com/barry-ran/QtScrcpyCore)

QtScrcpy is the upstream codebase used as the starting point. Roainxztar is the product identity for this ARM64 Android-hosted Linux adaptation; this repository does not claim ownership of the upstream project.

## Build direction

The project is moving away from relying on a prebuilt executable tied to one distribution's shared-library ABI. The intended build pipeline is:

1. Fetch the upstream source and its required submodules.
2. Build natively for AArch64 using a controlled ARM64 Linux build environment.
3. Resolve and validate Qt, FFmpeg and other runtime dependencies against the target ABI.
4. Package the application, ADB, scrcpy server, configuration, keymaps and required Qt runtime components.
5. Run dependency and launch checks in a distro test matrix.
6. Publish a versioned ARM64 package only after the runtime tests pass.

The initial compatibility target is **glibc-based ARM64 distributions**. Debian, Ubuntu, Parrot and Kali are candidates for validation; compatibility is not guaranteed until each is tested. Alpine/musl requires a separate build and is not covered by the glibc package.

## Current repository status

| Component | Status |
|---|---|
| Roainxztar product identity and documentation | In progress |
| ARM64 packaging/dependency scripts | Present; require review against the new build |
| Complete upstream C++ source tree | Not yet imported |
| ARM64 executable | Not present in the current branch |
| Bundled ADB and scrcpy server | Not present in the current branch |
| Portable Qt/FFmpeg runtime packaging | Not implemented |
| ARM64 CI build and distro tests | Not implemented |
| Release package | Not ready |

## Android-side requirements

- An Android device with an ARM64 CPU.
- Termux for the proot-distro route, or a rooted chroot manager.
- A Debian/Ubuntu-based ARM64 userspace for the initial setup.
- An X11 server such as Termux:X11, with its socket and display environment accessible inside the distro.
- Android Developer options and ADB debugging enabled on the device being controlled.

## Environment setup

### Termux + Debian/Ubuntu (proot-distro)

In Termux:

```bash
pkg update && pkg upgrade
pkg install x11-repo termux-x11-nightly proot-distro
proot-distro install debian
```

Start the X server from Termux:

```bash
termux-x11 :1 &
```

Open the Termux:X11 Android app, then enter the distro in another Termux session:

```bash
proot-distro login debian
export DISPLAY=:1
uname -m
dpkg --print-architecture
```

Expected architecture: `aarch64` / `arm64`.

### Rooted Linux chroot

The chroot must provide an ARM64 glibc userspace. The host must expose the required X11 socket and any device/audio resources that the application needs. Only bind-mount resources that are actually required; a chroot does not automatically grant safe access to every Android device node.

## Dependency diagnostics

Run the checker from the repository root:

```bash
bash check-deps.sh
```

The checker reports unresolved shared libraries for the packaged application and ADB when those files are present. A missing executable is a packaging issue, not a library dependency that the installer can fix.

**Do not create fake SONAME symlinks.** For example, FFmpeg 7 libraries (`.so.61/.59/.8`) are not ABI-compatible drop-in replacements for FFmpeg 6 libraries (`.so.60/.58/.7`). The final build must either use the correct runtime ABI or be rebuilt against a supported dependency baseline.

## ADB access

Wireless debugging is the preferred initial connection method in proot environments because USB passthrough may be unavailable. Pair and connect using the IP address and ports shown by Android's Wireless debugging screen, then verify:

```bash
adb devices -l
```

USB ADB requires the USB device nodes and permissions to be exposed by the Android host/chroot manager. A proot process cannot grant itself host-level USB access. Do not expose an ADB server to untrusted networks.

## Runtime permissions

The installer may set executable/read permissions on files inside the project directory. It cannot grant Android host permissions, bypass Android security policy, or automatically authorize access to arbitrary host device nodes. Any required Android permission or privileged bind mount must be approved and configured by the device owner.

## Upstream and licensing

The upstream QtScrcpy project and QtScrcpyCore are published separately. Review their license files and preserve upstream copyright and license notices when source is imported or redistributed. Roainxztar-specific scripts and packaging changes must retain their own clear attribution.

- [QtScrcpy upstream repository](https://github.com/barry-ran/QtScrcpy)
- [QtScrcpyCore upstream repository](https://github.com/barry-ran/QtScrcpyCore)
- [scrcpy upstream project](https://github.com/Genymobile/scrcpy)

## Important limitations

- Native Termux uses Android/Bionic and is not the target for a glibc-linked Linux executable.
- proot does not provide the same hardware access as a privileged chroot.
- GPU acceleration, audio, USB and X11 socket access depend on the Android ROM, host app and container setup.
- A successful compile does not establish distro compatibility; the packaged binary must be tested in each supported environment.

---

*Roainxztar is an independent ARM64 packaging/build effort based on the upstream QtScrcpy codebase. It is not an official QtScrcpy release.*


## Cross-distribution dependency installer

The reference ARM64 executable is dynamically linked. Its Qt 5 runtime needs the Qt 5 multimedia/X11 stack, and its video path is linked specifically to the **FFmpeg 6 ABI**:

- `libavformat.so.60`
- `libavcodec.so.60`
- `libavutil.so.58`
- `libswscale.so.7`

The updated `required.sh` detects common Linux package managers and installs the matching Qt/X11/audio/USB runtime packages where available:

| Package manager | Distribution families (examples) |
|---|---|
| APT | Debian, Ubuntu, Parrot, Kali |
| DNF | Fedora and compatible RPM distributions |
| Pacman | Arch Linux and derivatives |
| Zypper | openSUSE |
| XBPS | Void Linux (glibc variant) |
| Portage | Gentoo |

Run it inside the target ARM64 glibc distro:

```bash
bash required.sh
```

Then inspect unresolved dependencies:

```bash
bash check-deps.sh
```

**Important compatibility boundary:** package-manager detection is not a guarantee that every distribution repository carries the required FFmpeg 6 ABI. Some current distributions ship FFmpeg 7 or 8 instead. The installer reports unresolved libraries rather than creating unsafe SONAME symlinks. If the exact FFmpeg 6 libraries are unavailable, this prebuilt binary still needs a compatible FFmpeg 6 runtime or a rebuild against the target distribution.

Native Termux (Android/Bionic) and Alpine (musl) are not supported by this glibc binary. Use a Debian/Ubuntu/other glibc userspace inside proot/chroot, or create a separate native/musl build. A package installer cannot overcome libc or binary ABI incompatibility.

The uploaded Ubuntu-oriented reference archive is a prebuilt ARM64 package, not source code. Broad distro support for the application itself still requires testing the actual binary and all of its transitive dependencies on each target distro; this installer only automates dependency setup where compatible packages exist.
