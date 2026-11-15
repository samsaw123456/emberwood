> Previous release: v1.2.0. See [clearer monster artwork](MONSTER_ART.md) for v1.2.1.

# Regular monsters and readable opening title

Scope: fix garbled window-title characters, clarify opening lettering, and add ordinary enemies,
keeping the six boss encounters intact. The title now uses the game's bundled
bold font and actual text, spelling **Emberwood** clearly at both window sizes.
The window title is **Emberwood - Forest Adventure** with a plain ASCII hyphen,
so legacy window-title readers cannot misread a UTF-8 dash. The app shortcut
matches the new window class. Existing preferences and records are read from the
previous data directory when the new settings file is absent; the next normal
save preserves those values in the new directory without deleting the old file.

## Working checklist

- Core loop: opossums plus moss slimes, bramble beetles, and cave bats; all can be
  defeated by one stomp or weapon hit. Fifteen additional patrols on levels 6–20.
- Physics/navigation: slimes hop, beetles patrol faster, bats hover; rendering and
  weapons share the same moving hitboxes. New patrols stay on the middle bank,
  away from camps, spikes, gaps and boss clearings. Jump over the new patrol.
- Interaction/state: correct stomp versus side contact, each weapon, armor blocks,
  pause/resume, enemy restoration after retry, reset and chapter cleanup.
- Accessibility/polish: title uses readable bundled lettering; enemy shapes/colors
  distinguish types; gentle motion reduces decorative frames while preserving
  movement that matters for collisions. No health bars or boss rules on regular enemies.
- Robustness: lint/format/import, full campaign through all bosses, native keyboard
  combat, small-window inspection, offline installer and updated downloads.
- Out of scope: additional bosses, weapons, levels and controller remapping.

## Verification

`python3 tools/run_game_tests.py settings_migration monsters game` passed:
**10** save-compatibility checks, **438** monster/title checks, and **359** game
integration checks. The interactions (30), weapons (80), and arrow suites also
passed. Monsters were checked against every weapon, stomps, side damage, armor,
pause, retry, and safe camp/spike spacing. Legacy saves are retained; a current
save takes precedence over the old file.

The full campaign input run completed all **20 levels and six bosses in 07:47**,
with **zero retries**, every acorn/firefly, and **13 gear rewards**. It traverses
the new patrols by jumping and retains the existing progression and gear rules.

Native keyboard fixtures defeated each new species with the bow, paused/resumed,
retried with R, verified the enemy returned, and won again. The bat required a
jump-and-shoot. Fixtures place one monster near the opening camp; the complete
campaign separately verifies the actual level placements. Their artwork was
visually inspected at 1152×648, with the bat at 800×600.

Both title sizes were rendered and inspected. X11's legacy `WM_NAME` and UTF-8
`_NET_WM_NAME` now agree on ASCII text, and the window class matches the desktop
entry. The development engine adds its normal `(DEBUG)` suffix; the release app
has the plain title. Formatting/lint, Godot import/export, Python Ruff checks,
shell syntax and desktop-file validation passed.

Screenshots: [title](screenshots/title-readable-1152x648.png),
[small title](screenshots/title-readable-800x600.png),
[moss slime](screenshots/monster-slime.png),
[bramble beetle](screenshots/monster-beetle.png),
[cave bat](screenshots/monster-bat.png).

The final **v1.2.0 Linux x86-64 package** passed Lintian, dependency simulation,
installation over 1.1.0, reinstall, and removal in an isolated filesystem. The
registered launcher opened offline with the development checkout/engine hidden.
The package's actual X11 window title is exactly **Emberwood - Forest Adventure**;
both title properties and the desktop window class were verified. A packaged-game
probe loaded all twenty levels and confirmed four ordinary enemy types, fifteen
added patrols, all six bosses, and the readable opening label. Native installed-app
movement, jumping, dash, pause/resume and icon loading were exercised.

The local Applications entry and Zed launcher are refreshed. GitHub v1.2.0 carries
the installer/checksum, and Downloads receives the published source and app.
Packaging remains Ubuntu/Debian x86-64; Windows/macOS/ARM packages are out of scope.
