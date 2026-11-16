# Downloads and installers

Download builds from
[GitHub Releases](https://github.com/samsaw123456/emberwood/releases/latest).
Install the same Emberwood version on every computer that plays together over LAN.

## Linux (Ubuntu/Debian, x86-64)

Download `emberwood_1.5.0_amd64.deb`. Open the file with the system's package
installer and choose Install. Emberwood then appears in the Applications launcher
with its fox icon. Downloading a file alone does not install or register an app.

This package targets x86-64 Ubuntu/Debian Linux desktops. It includes the Godot
4.5.1 release runtime, all game resources, icons, and license notices. Players
do not need a development checkout, Python, Zed, or a separate Godot installation.
Normal desktop libraries are package dependencies. Solo play works offline;
LAN co-op uses the local network. Remove it through the same package manager;
saved preferences are kept in the user's own data directory.

## macOS

Download `emberwood_1.5.0_macos.zip` and extract it. On first launch, if
Emberwood is not already in an Applications folder, it will ask **“Would you
like to put Emberwood in the Applications folder?”** You can accept to copy it
there, choose **Not now**, or move **Emberwood.app** to Applications manually.
The app includes the Godot 4.5.1 runtime and game resources. Solo play works
offline after installation; LAN co-op uses the local network.

This open-source build is unsigned and not Apple-notarized. macOS may block the
first launch; if so, open **System Settings > Privacy & Security** and choose
**Open Anyway** for Emberwood, then launch it again. If Gatekeeper still blocks
it, you can also remove the quarantine attribute in Terminal:

```sh
xattr -dr com.apple.quarantine /Applications/Emberwood.app
```

Windows packaging is planned for a later release.

## Build

### Linux (.deb)

Install `dpkg-deb` and `desktop-file-validate`. Import the project with Godot 4.5.1,
then provide `linux_release.x86_64` from the official
[4.5.1 export templates](https://github.com/godotengine/godot-builds/releases/tag/4.5.1-stable):

```sh
./emberwood --headless --editor --import --quit
python3 tools/build_linux_package.py --runtime /path/to/linux_release.x86_64
```

Output is `dist/emberwood_1.5.0_amd64.deb` with checksums in `dist/SHA256SUMS`.
The source checkout's launcher remains available in Zed. The package uses its own
engine and exported resource pack under `/usr/lib/emberwood`, with a launcher
under `/usr/games` and a system Applications entry. No download scripts run at
install time. The engine license and third-party notices are retained under
`licenses/`.

### macOS (.zip)

Install Godot 4.5.1 and the **macOS export templates** for 4.5.1.stable
(Editor > Manage Export Templates), then run:

```sh
python3 tools/build_macos_package.py --godot /path/to/Godot_v4.5.1-stable_linux.x86_64
```

Output is `dist/emberwood_1.5.0_macos.zip` (containing `Emberwood.app`) with
checksums in `dist/SHA256SUMS`. macOS exports are unsigned/not notarized in this
project's release flow; see the macOS install notes above.

## Verification checklist

- Core loop, physics, progression: exercise the exported game's real title,
  movement, jump/dash, failure/retry, pause/resume and LAN co-op.
- Installation/navigation: fresh install/open, valid desktop/app registration,
  update/reinstall, and removal/uninstall as applicable.
- Robustness: lint/format, package inspection, dependency resolution, checksums,
  clean saved data, no development paths, and a launch with networking disabled.
- Visuals/accessibility: preserve the existing fox icon, controls, and menu;
  inspect the packaged game's rendered output.
- Cross-platform LAN: host and join between Linux and macOS using the same game
  version on the same local network (UDP 24642).

The earlier Linux installer passed fresh install, reinstall, offline desktop launch
and removal in an isolated filesystem. The development checkout and existing Godot
installation were hidden; only loopback networking was available. APT dependency
simulation, desktop-file validation and Lintian passed. Lintian exceptions document
the official Godot binary's bundled libraries, upstream executable format, and
upstream changelog. For 1.4.0, the actual release runtime and exported resource
pack passed the four-instance LAN and native control audits. Package checksums,
desktop-file validation, APT dependency simulation and Lintian passed again.
The existing source-based Applications entry was refreshed and launched.
See [LAN verification](../docs/LAN.md) and [control evidence](../docs/CONTROLS.md).
Windows, ARM, and physical multi-machine cross-platform LAN runs should be
recorded when exercised; they are not claimed complete from Linux-only automated
evidence.
