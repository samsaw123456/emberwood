# Emberwood playtest notes

The expanded campaign has three chapters: Emberwood, Flooded Mill, and High
Canopy, ending with Old Croak. It contains nine required acorns, 72 optional gems,
and three hidden fireflies. Verification uses Godot 4.5.1 on Linux with a fixed
60 Hz simulation. Test saves are isolated from player settings by
[the test runner](../tools/run_game_tests.py).

## Game checklist

- **Core loop:** title, original forest, chapter result/Continue, mill, canopy,
  boss, final gate, campaign results, and replay. Each gate requires that
  chapter's three acorns; the final gate also requires Old Croak's defeat.
- **Physics:** ground and edges, acceleration/stopping, variable-height double
  jump, jump limits, coyote time, buffered landing, both-axis platform carry,
  turnaround, crumble/fall/regeneration, and reset use real Godot physics tests.
  Both new routes were traversed through input. Slopes and vertical camera
  scrolling are outside this level design.
- **Interaction:** keyboard movement/jumps, mouse menus/settings, contact pickups,
  spikes, critters, mushroom bounce, and repeated pickups/retries. Boss checks
  cover landing tells, leaps, ripples, valid falling stomps, vulnerable windows,
  three fox hearts, invulnerability after hits, defeat, and encounter reset.
  Inventory and combat weapons are not part of the game.
- **Navigation:** all required acorns and gaps are reachable through movement
  input. Campfires mark safe retry points; the canopy critter cannot patrol into
  its nearby camp. Boss entry closes the arena boundary, which clears on victory
  and resets on retry. Camera bounds follow the current chapter's width.
- **State:** title, playing, paused, retrying, chapter complete, and won. Chapter
  transitions remove old level entities and preserve campaign totals. Pausing or
  losing focus freezes play, retry countdowns, platforms, and boss attacks.
  Focus return waits for explicit resume. Restart clears the entire campaign.
- **Feel and accessibility:** visible keyboard focus, native buttons/toggles,
  readable controls, persistent sound/gentle-motion settings, forgiving collision
  margins, and visible boss hints. Boss health uses filled/empty marks as well as
  color. Pixel art stays crisp while UI fonts use linear sampling when resized.
- **Polish and discovery:** licensed SunnyLand artwork, distinct forest/mill/canopy
  scenery, a small pixel title, bundled DejaVu Sans text, correct per-chapter
  and campaign counts, checkpoints, and three optional secrets. The rejected
  field-guide/paper treatment, serif headline, monospaced prose, and decorative
  uppercase/slash labels have been removed from the interface.
  See [visual direction](DESIGN.md) for the typography and layout choices.
- **Robustness and performance:** native rendering and an isolated X11 software
  renderer were exercised. The new interface was inspected at 1152×648 and at
  800×600 with letterboxing. Physics-driven route input is independent of rendering
  cadence. Multi-hour sessions, macOS, Windows, gamepads, and touch are untested.

## Reproducing checks

Run from the project root. Local lint tools are in
`~/.local/share/phippy-tools/venv/bin/`:

```sh
./start-game.sh --headless --editor --import --quit
gdformat --check scripts tests
gdlint scripts tests
ruff check tools/run_game_tests.py
ruff format --check tools/run_game_tests.py
sh -n start-game.sh
python3 tools/check_assets.py
python3 tools/run_game_tests.py
git diff --check
```

The runner includes `fox`, `platform`, `boss`, `game`, `route`, and `campaign`.
An optional suite argument runs a subset, for example:

```sh
python3 tools/run_game_tests.py boss game campaign
```

The expanded game integration suite passed **163 checks**, covering physical key
mappings, menu flow, chapter progression and cleanup, pickups and totals,
spikes/falls/retries, checkpoint recovery, boss health and arena boundaries,
pause/focus handling, final-gate conditions, replay, and settings persistence.
The campaign's saved best time is separate from the earlier single-level record.

The controller and platform suites passed. The boss suite passed attack tells,
leaps, shockwaves, pause, valid stomps, defeat, retry, and an input-driven battle.
Both new chapter routes passed input-only traversal with all required acorns and
no spike or fall failures. These route checks use real collision bodies and
trigger crumbling platforms through foot contact.

A complete **headless input-driven campaign** reached the ending in **01:33,
with zero retries, all nine acorns, and two fox hearts remaining**. The route
uses movement, jump, and menu input without teleporting the fox or changing
collected progress. Separate tests deliberately exercise failure and recovery.

## Graphical evidence

The original forest was played using native X11 input: start, movement, double
jumps, gems, raised platforms, the first gap, spike and critter failures,
automatic retry, preserved treasure, pause, and settings. These remain part of
the expanded campaign's regression coverage.

The new mill and canopy were rendered and visually inspected. A standalone
Old Croak encounter was played graphically through attack patterns, three valid
stomps, and defeat. The title, pause, chapter transition, boss display, and
results were rendered and inspected; Enter activation exercised
Start and Continue. Bundled fonts and local license paths were verified.

The consolidated run passed all six suites. A final HUD correction made the heart
counter update immediately on damage, including zero hearts during retry; the
expanded 163-check integration suite and graphical recovery fixture passed again. A complete **graphical campaign**
at normal speed and 60 Hz reached the final gate in **01:33**, with **43/72 gems,
all nine acorns, all three fireflies, zero retries, and two hearts remaining**.
Screenshots were inspected at the title, both chapter transitions, both new
levels, boss phases, and the ending. The route used input events only.

A separate graphical arena fixture exercised an actual loss from ripple contact,
pausing during an attack and during the retry countdown, checkpoint recovery,
winning the restored encounter, and Enter-driven campaign replay. It passed.
The fixture starts at the arena with its acorns collected; encounter actions
and replay use normal game input. The first fixture attempt was interrupted by
the temporary X server shutting down; rerunning with a dedicated display passed.
Successful graphical runs logged only Xvfb input-method/VSync warnings.

The interface was also reviewed at 800×600. Temporary game/display processes
and isolated test saves were cleaned up; the playable native game is left open.
Typography, GDScript/Python lint and format, shell syntax, documentation links,
resource import, and artwork inventory checks passed.

## Interface correction and project move

The complete project now lives at `~/git/aie/`, with the starter's Git history
preserved. The launcher resolves the new directory correctly, and source and
documentation contain no absolute references to the previous project location.
Global and project instructions explicitly record the rejected title treatment.

After replacing that treatment, all six automated suites passed again, including
the 163 integration checks. A fresh graphical campaign completed all three levels
and Old Croak through movement, jump, and menu input in **01:33**, with **zero
retries, 43/72 gems, all nine acorns, all three fireflies, and two hearts**.
The graphical recovery fixture also passed attack/retry pausing, an actual loss,
campfire recovery, the restored battle, victory, and Enter-driven replay.

Native X11 input separately exercised Start, movement/jumps, pause/resume,
Tab/Space settings controls, Continue, and Explore again. The revised title was
inspected at 1152×648 and 800×600; controls were moved below the play scene to fix
an overlap with world signs. Title, level results, live HUD, boss hints, pause,
failure, and victory screenshots below show the replacement interface.

- [Title](screenshots/title.png)
- [Title at 800×600](screenshots/title-800.png)
- [Flooded Mill](screenshots/mill.png)
- [High Canopy](screenshots/canopy.png)
- [Old Croak](screenshots/boss.png)
- [Pause](screenshots/pause.png)
- [Boss retry](screenshots/boss-retry.png)
- [Campaign victory](screenshots/victory.png)
