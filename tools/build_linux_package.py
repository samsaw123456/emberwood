"""Build a self-contained amd64 Debian package using Godot's release runtime."""

import argparse
import gzip
import hashlib
import shutil
import subprocess
import tempfile
from pathlib import Path

from install_app import desktop_entry

VERSION = "1.2.1"
ROOT = Path(__file__).resolve().parents[1]


def write(path: Path, content: str, mode: int = 0o644) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")
    path.chmod(mode)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--runtime", required=True, type=Path)
    args = parser.parse_args()
    runtime = args.runtime.resolve()
    version = subprocess.check_output([runtime, "--headless", "--version"], text=True)
    if not version.startswith("4.5.1.stable"):
        parser.error("Use the Godot 4.5.1 stable Linux x86_64 release template.")
    output = ROOT / "dist"
    output.mkdir(exist_ok=True)
    package = output / f"emberwood_{VERSION}_amd64.deb"
    with tempfile.TemporaryDirectory(prefix="emberwood-package-") as temporary:
        stage = Path(temporary)
        game = stage / "usr/lib/emberwood"
        game.mkdir(parents=True)
        binary = game / "emberwood.bin"
        shutil.copyfile(runtime, binary)
        binary.chmod(0o755)
        subprocess.run(
            [
                ROOT / "emberwood",
                "--headless",
                "--export-pack",
                "Linux",
                game / "emberwood.pck",
            ],
            cwd=ROOT,
            check=True,
        )
        write(
            stage / "usr/games/emberwood",
            "#!/bin/sh\nexec /usr/lib/emberwood/emberwood.bin "
            '--main-pack /usr/lib/emberwood/emberwood.pck "$@"\n',
            0o755,
        )
        desktop = stage / "usr/share/applications/org.emberwood.Emberwood.desktop"
        write(desktop, desktop_entry(Path("/usr/games/emberwood")))
        subprocess.run(["desktop-file-validate", desktop], check=True)
        for size in [16, 24, 32, 48, 64, 128, 256, 512]:
            name = "emberwood.png" if size == 512 else f"emberwood-{size}.png"
            icon = stage / f"usr/share/icons/hicolor/{size}x{size}/apps/emberwood.png"
            icon.parent.mkdir(parents=True)
            shutil.copyfile(ROOT / "assets/app" / name, icon)
        documentation = stage / "usr/share/doc/emberwood"
        documentation.mkdir(parents=True)
        write(
            documentation / "copyright",
            "Emberwood and Phippy Gaming Workshop\n"
            "Copyright (C) 2026 Samuel Callahan Sierra and Phippy Gaming Workshop contributors\n"
            "Source: https://github.com/samsaw123456/emberwood\n"
            "Code license: Apache-2.0. Full text: /usr/share/common-licenses/Apache-2.0\n\n"
            "Imported assets retain their original licenses and copyright notices:\n"
            "assets/CREDITS.md, assets/licenses/, and assets/fonts/LICENSE.txt.\n"
            "Godot Engine and embedded libraries: packaging/licenses/GODOT-LICENSE.txt\n"
            "and packaging/licenses/GODOT-COPYRIGHT.txt.\n",
        )
        for source in [
            ROOT / "assets/licenses",
            ROOT / "packaging/licenses",
        ]:
            destination = documentation / source.relative_to(ROOT)
            shutil.copytree(source, destination)
        shutil.copyfile(ROOT / "assets/CREDITS.md", documentation / "assets/CREDITS.md")
        shutil.copyfile(ROOT / "assets/README.md", documentation / "assets/README.md")
        write(
            documentation / "assets/fonts/LICENSE.txt",
            (ROOT / "assets/fonts/LICENSE.txt").read_text(),
        )
        write(
            documentation / "README",
            "Open Emberwood from your Applications menu. No internet is needed to play.\n"
            "A/D: move; Space: jump twice; Shift: dash; J: weapon; Esc: gear/pause; R: retry.\n"
            "Collect three acorns per level. Earn equipment at campfires.\n"
            "Source and full illustrated guides: https://github.com/samsaw123456/emberwood\n"
            "Code license: copyright. Art: assets/CREDITS.md and assets/licenses/.\n"
            "Fonts: assets/fonts/LICENSE.txt. Engine: packaging/licenses/.\n",
        )
        (documentation / "changelog.gz").write_bytes(
            gzip.compress(
                f"Emberwood {VERSION}: clearer slime, beetle and bat artwork.\n".encode(),
                mtime=0,
            )
        )
        manual = stage / "usr/share/man/man6/emberwood.6.gz"
        manual.parent.mkdir(parents=True)
        manual.write_bytes(
            gzip.compress(
                b".TH EMBERWOOD 6\n.SH NAME\nemberwood \\- forest platform adventure\n"
                b".SH SYNOPSIS\n.B emberwood\n.SH DESCRIPTION\n"
                b"Explore twenty levels and collect three acorns per gate. Plays offline.\n"
                b".SH CONTROLS\nA/D move, Space jumps twice, Shift dashes, J uses a weapon.\n"
                b"Esc pauses and selects gear; R retries from camp.\n"
                b".SH AUTHORS\nSamuel Callahan Sierra and Phippy Gaming Workshop contributors.\n",
                mtime=0,
            )
        )
        write(
            stage / "usr/share/lintian/overrides/emberwood",
            "# Official Godot 4.5.1 release template; preserve upstream engine and licenses.\n"
            "emberwood: embedded-library freetype [usr/lib/emberwood/emberwood.bin]\n"
            "emberwood: embedded-library libjpeg [usr/lib/emberwood/emberwood.bin]\n"
            "emberwood: embedded-library libjsoncpp [usr/lib/emberwood/emberwood.bin]\n"
            "# The upstream official release template is not PIE.\n"
            "emberwood: hardening-no-pie [usr/lib/emberwood/emberwood.bin]\n"
            "# Upstream game changelog, not a Debian archive source package.\n"
            "emberwood: syntax-error-in-debian-changelog *\n",
        )
        installed_size = (
            sum(p.stat().st_size for p in stage.rglob("*") if p.is_file()) // 1024
        )
        write(
            stage / "DEBIAN/control",
            f"Package: emberwood\nVersion: {VERSION}\nArchitecture: amd64\n"
            "Maintainer: Samuel Callahan Sierra <samuel@callahansierra.com>\n"
            "Section: games\nPriority: optional\n"
            f"Installed-Size: {installed_size}\n"
            "Depends: hicolor-icon-theme, libc6 (>= 2.31), libgl1, libx11-6, libxcursor1, libxinerama1, "
            "libxi6, libxrandr2, libxrender1, libasound2 | libasound2t64\n"
            "Homepage: https://github.com/samsaw123456/emberwood\n"
            "Description: Forest platform adventure with twenty levels\n"
            " Guide the fox through twenty trails, earn weapons and armor, and face\n"
            " six animal guardians. Includes the game engine and plays offline.\n",
        )
        for entry in stage.rglob("*"):
            entry.chmod(
                0o755
                if entry.is_dir() or entry in [binary, stage / "usr/games/emberwood"]
                else 0o644
            )
        subprocess.run(
            [
                "dpkg-deb",
                "--root-owner-group",
                "-Zxz",
                "-z3",
                "--build",
                stage,
                package,
            ],
            check=True,
        )
    with package.open("rb") as artifact:
        digest = hashlib.file_digest(artifact, "sha256").hexdigest()
    (output / "SHA256SUMS").write_text(f"{digest}  {package.name}\n")
    print(package)


if __name__ == "__main__":
    main()
