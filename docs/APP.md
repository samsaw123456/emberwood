# Offline desktop app

The Linux Applications entry is named Emberwood and uses a centered SunnyLand
fox against the game's forest artwork. Pixel edges remain crisp at desktop icon
sizes. The Godot window uses the same icon. The installer points to the canonical
checkout rather than the disposable Downloads copy, so future game edits appear
when the app is reopened.

## Checklist and evidence

- Core loop/physics/state: unchanged. The installed entry launched the actual
  game; native Enter, movement, jump, dash, Escape pause and resume worked.
- Interaction/navigation: Gio loaded the installed Applications entry; GTK
  resolved its 64-pixel icon. The entry uses no terminal and requires no editor.
- Feel/polish: inspected the fox-and-forest icon and rendered gameplay/pause.
  Existing sprite attribution is preserved; no new font or menu style.
- Robustness/offline: a process-local seccomp filter rejected both IPv4 and IPv6
  sockets before `gio launch` started the installed app. It inherited that filter
  and the input sequence above passed. Unix display sockets remained available.
  No computer-wide networking settings were changed.
- Verification: Ruff checks/formatting, shell syntax, desktop-file validation,
  Godot resource import and the real desktop launch passed. Only expected Xvfb
  input-method/VSync warnings appeared. Isolated display, game and test saves
  were cleaned up; existing player windows were preserved.
- Scope: no game-rule changes, new progression, network service, or bundled
  runtime. The already installed Godot executable and project assets are local.
  Current-run progress still resets on closing the game, as documented in GAME.md.

`tools/install_app.py` writes the user desktop entry and icon sizes under
`$XDG_DATA_HOME` (normally `~/.local/share`). Run it again after moving the project.
The source remains in `~/git/aie`; the menu shortcut uses that absolute location.

Inspected evidence: [app icon](../assets/app/emberwood.png),
[offline play](screenshots/app-offline-playing.png), and
[offline pause](screenshots/app-offline-pause.png).
