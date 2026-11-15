# Linux installer

Download `emberwood_1.4.0_amd64.deb` from
[GitHub Releases](https://github.com/samsaw123456/emberwood/releases/latest).
Open the file with the system's package installer and choose Install. Emberwood
then appears in the Applications launcher with its fox icon. Downloading a file
alone does not install or register an app.

This package targets x86-64 Ubuntu/Debian Linux desktops. It includes the Godot
4.5.1 release runtime, all game resources, icons, and license notices. Players
do not need a development checkout, Python, Zed, or a separate Godot installation.
Normal desktop libraries are package dependencies. Solo play works offline;
LAN co-op uses the local network. Remove it through the same package manager;
saved preferences are
kept in the user's own data directory. Windows and macOS need separate packages.

## Build

Install `dpkg-deb` and `desktop-file-validate`. Import the project with Godot 4.5.1,
then provide `linux_release.x86_64` from the official
[4.5.1 export templates](https://github.com/godotengine/godot-builds/releases/tag/4.5.1-stable):

```sh
./emberwood --headless --editor --import --quit
python3 tools/build_linux_package.py --runtime /path/to/linux_release.x86_64
```

Output is `dist/emberwood_1.4.0_amd64.deb` with `dist/SHA256SUMS`. The source
checkout's launcher remains available in Zed. The package uses its own engine
and exported resource pack under `/usr/lib/emberwood`, with a launcher under
`/usr/games` and a system Applications entry. No download scripts run at install
time. The engine license and third-party notices are retained under `licenses/`.

## Verification checklist

- Core loop, physics, progression: exercise the exported game's real title,
  movement, jump/dash, failure/retry, pause/resume and LAN co-op.
- Installation/navigation: fresh package install, valid desktop entry and icon
  lookup, launcher registration, update/reinstall, and removal.
- Robustness: lint/format, package inspection, dependency resolution, checksums,
  clean saved data, no development paths, and a launch with networking disabled.
- Visuals/accessibility: preserve the existing fox icon, controls, and menu;
  inspect the packaged game's rendered output.
- Platforms: Linux x86-64 only in this release; Windows, macOS, ARM and other
  package formats are outside this installer.

The earlier installer passed fresh install, reinstall, offline desktop launch and
removal in an isolated filesystem. The development checkout and existing Godot installation were hidden;
only loopback networking was available. APT dependency simulation, desktop-file
validation and Lintian passed. Lintian exceptions document the official Godot
binary's bundled libraries, upstream executable format, and upstream changelog.
For 1.4.0, the actual release runtime and exported resource pack passed the
four-instance LAN and native control audits. Package checksums, desktop-file
validation, APT dependency simulation and Lintian passed again. The existing
source-based Applications entry was refreshed and launched. This release was
extracted and exercised without replacing the system package database. See
[LAN verification](../docs/LAN.md) and [control evidence](../docs/CONTROLS.md).
