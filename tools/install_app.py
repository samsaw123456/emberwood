"""Install this checkout in the current Linux user's Applications menu, offline."""

import os
import shutil
import subprocess
from pathlib import Path


def main() -> None:
    project = Path(__file__).resolve().parents[1]
    launcher = project / "emberwood"
    if not os.access(launcher, os.X_OK):
        raise SystemExit(f"Game launcher is missing or not executable: {launcher}")
    data = Path(os.environ.get("XDG_DATA_HOME") or Path.home() / ".local/share")
    applications = data / "applications"
    applications.mkdir(parents=True, exist_ok=True)
    for size in [16, 24, 32, 48, 64, 128, 256, 512]:
        source = "emberwood.png" if size == 512 else f"emberwood-{size}.png"
        target = data / f"icons/hicolor/{size}x{size}/apps/emberwood.png"
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(project / "assets/app" / source, target)
    # Desktop Exec has its own quoting rules; it is not interpreted by a shell.
    executable = str(launcher).replace("%", "%%")
    for character in ["\\", '"', "`", "$"]:
        executable = executable.replace(character, "\\" + character)
    executable = executable.replace("\\", "\\\\")
    desktop = applications / "org.emberwood.Emberwood.desktop"
    desktop.write_text(
        "[Desktop Entry]\n"
        "Type=Application\n"
        "Name=Emberwood\n"
        "Comment=Explore twenty forest levels. Play offline.\n"
        f'Exec="{executable}"\n'
        "Icon=emberwood\n"
        "Terminal=false\n"
        "StartupWMClass=Emberwood — Forest Adventure\n"
        "Categories=Game;AdventureGame;\n"
        "Keywords=fox;forest;platformer;offline;\n",
        encoding="utf-8",
    )
    if shutil.which("update-desktop-database"):
        subprocess.run(["update-desktop-database", str(applications)], check=True)
    print(f"Installed Emberwood: {desktop}")


if __name__ == "__main__":
    main()
