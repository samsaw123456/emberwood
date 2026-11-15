# Recognizable regular monsters

The player could not distinguish the first slime, beetle and bat drawings. This
revision prioritizes silhouette, contrast and species-defining features at actual
game size. The existing code-native artwork is redrawn directly in Godot.

- Moss slime: broad jelly dome, shiny highlights, hanging drips, large eyes and
  gentle body wobble during its existing hop.
- Bramble beetle: domed copper wing cases, a shell seam, antennae, a separate head,
  and three pairs of jointed walking legs.
- Cave bat: broad scalloped wings with visible fingers, coordinated flapping,
  tall ears with colored interiors, bright eyes and small fangs.

## Working checklist

- Core loop/physics/navigation: existing spawn positions, body hitboxes, movement,
  stomp/weapon rules, rewards and progression are unchanged. Wings, antennae and
  feet are decorative extensions around the central body, as with the opossum.
- Interaction/state: native weapon fights, pause/resume and retry; use the existing
  monster regression suite. Every drawing uses level time so pause freezes it.
- Feel/accessibility: clearer silhouettes and contrast at 1152×648 and 800×600;
  Gentle motion disables decorative wobble, stepping and flapping while keeping
  collision-relevant movement. Retain the game's palette and licensed opossum art.
- Polish/robustness: inspect each creature against real scenery, validate imports,
  lint/format, exported game, offline package and download refresh.
- Out of scope: new monsters, boss changes, additional rewards or routes. No new
  dependencies, network requirement or bitmap-generation service is introduced.

## Verification

`python3 tools/run_game_tests.py monsters` passed **438 checks** covering every
weapon, stomps, contact/armor, pause, retries, placement and the corrected title.
Native keyboard fights passed for all three species at **1152×648 and 800×600**:
shoot, pause/resume, defeat, R retry, restored enemy, and a second victory. Bat
shots were timed from the fox's visible jump position after fixed-time input proved
unreliable in the slow Xvfb software renderer. No combat rules were changed.

Each creature was visually inspected against the forest at both sizes. A rendered
frame comparison confirmed decorative animation changes the normal frames and
produces identical frames with Gentle motion enabled. The comparison isolates art
from mechanical movement by using stationary preview fixtures. The normal native
fixtures retain hopping and hovering.

Godot import/export, `gdformat --check scripts tests`, `gdlint scripts tests`, Ruff
checks/format checks, and `git diff --check` passed. A source comparison confirms
that enemy positions, sizes, speeds and hitbox functions are unchanged. The full
20-level route was not repeated for this artwork-only revision; its previous pass
is recorded in [the monster release](MONSTERS.md). Hardware GPU performance was
not benchmarked; native tests used software rendering.

The **1.2.1 Linux x86-64 package** passed Lintian, dependency simulation, upgrade
from 1.2.0, reinstall, and removal in an isolated filesystem. The registered
launcher opened offline with the development checkout and engine hidden. Its
window title and icon were checked, and a packaged-resource probe confirmed the
new species-specific artwork alongside all four ordinary enemy types, fifteen
extra patrols and six bosses. Installed-app controls were exercised.

Screenshots at 800×600: [slime](screenshots/monster-art-slime-800.png),
[beetle](screenshots/monster-art-beetle-800.png), [bat](screenshots/monster-art-bat-800.png).
The combat fixtures place enemies near the first camp; the preview below shows
the actual drawing routines at their normal game scale without overlapping signs.

[Monster artwork preview](screenshots/monster-art-preview.png).

The Applications shortcut, executable Zed launcher, GitHub release, installer and
Downloads copies are refreshed together. Ubuntu/Debian x86-64 remains the packaged
platform; other desktop/CPU packages are outside this update.
