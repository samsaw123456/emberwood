"""Build a macOS app bundle zip using Godot's official macOS export template."""

import argparse
import hashlib
import shutil
import subprocess
import tempfile
from pathlib import Path

VERSION = "1.5.0"
ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--godot",
        type=Path,
        default=Path(
            "~/.local/share/phippy-tools/Godot_v4.5.1-stable_linux.x86_64"
        ).expanduser(),
        help="Godot 4.5.1 editor executable used to run the export.",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=ROOT / "dist" / f"emberwood_{VERSION}_macos.zip",
        help="Output zip path.",
    )
    args = parser.parse_args()
    godot = args.godot.resolve()
    if not godot.is_file():
        parser.error(
            f"Godot editor not found: {godot}. Pass --godot or install Godot 4.5.1."
        )
    output = args.output.resolve()
    output.parent.mkdir(parents=True, exist_ok=True)

    subprocess.run([str(godot), "--headless", "--editor", "--import", "--quit"], cwd=ROOT, check=True)
    with tempfile.TemporaryDirectory(prefix="emberwood-macos-") as temporary:
        export_path = Path(temporary) / f"emberwood_{VERSION}_macos.zip"
        subprocess.run(
            [str(godot), "--headless", "--export-release", "macOS", str(export_path)],
            cwd=ROOT,
            check=True,
        )
        if not export_path.is_file():
            parser.error(
                "Godot did not produce a macOS zip. Install macOS export templates "
                "for Godot 4.5.1.stable (Editor > Manage Export Templates)."
            )
        shutil.move(str(export_path), str(output))

    with output.open("rb") as artifact:
        digest = hashlib.file_digest(artifact, "sha256").hexdigest()
    sums = output.parent / "SHA256SUMS"
    lines = []
    if sums.exists():
        lines = [
            line
            for line in sums.read_text(encoding="utf-8").splitlines()
            if line.strip() and not line.endswith(f"  {output.name}")
        ]
    lines.append(f"{digest}  {output.name}")
    sums.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(output)
    print(
        "Note: macOS builds are unsigned/not notarized. On first launch, macOS may "
        "require Open Anyway in Privacy & Security."
    )


if __name__ == "__main__":
    main()
