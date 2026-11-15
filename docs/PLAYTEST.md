# Emberwood playtest notes

The adventure has five chapters—Emberwood, Flooded Mill, High Canopy, Moss
Caverns, and Sunlit Ridge—with 15 required acorns, 108 optional gems, five hidden
fireflies, and Old Croak. The latest [expansion evidence](EXPANSION.md) includes
new weapons, armor, levels, and the Zed launcher. Older runs below are retained
as evidence for the versions they tested.
Verification uses Godot 4.5.1 on Linux, normally at 60 Hz. Tests use isolated
saved data through [the runner](../tools/run_game_tests.py).

## Game checklist

- **Core loop and rules:** title, forest, chapter result/Continue, mill, canopy,
  boss, caves, ridge, summit gate, results, and replay. Each gate requires three
  acorns; the canopy gate also requires defeating Old Croak. Retries are unlimited.
- **Physics:** acceleration/stopping, variable-height double jump, jump limits,
  coyote time, buffered landing, moving-platform carry/turnaround, crumble and
  recovery. Dash respects walls, cooldown, one airborne use, held-input rules,
  jump interruption, pause, and reset. Dash traveled 99.2 pixels at both 30 and
  120 Hz. Slopes and vertical camera scrolling are outside this level design.
- **Interaction and rewards:** Shift dashes from the start. The second Emberwood
  campfire awards a bow; the third awards armor. Rewards equip immediately and
  can be removed independently in pause. J fires once per press with a cooldown.
  Later camps add the spear, bark armor, seed bombs, and ironwood armor. Only one
  weapon and one armor can be equipped at a time. Spears pierce two critters;
  seed bombs arc and burst nearby, with terrain blocking their blast.
  Arrows use swept collision, hit the first obstruction, and cannot cross thin
  walls beside the fox. Left/right shots, moving/collapsed platforms, misses,
  range cleanup, and simultaneous turn/shoot were checked. Shooting during a
  dash follows its locked facing direction.
- **Defense and combat:** leaf/bark/ironwood armor block one/two/three hits and give
  recovery time; falls still cause retries. A new camp or retry recharges armor;
  returning to an old camp or reequipping does not. Old Croak takes one arrow
  or falling stomp per resting phase. Three hits defeat him. Guarded phases
  reject arrows, including shots through the visible cap. Stomps cross the cap
  from above, and protection does not disable critter attacks. External bounces
  interrupt dashes, leave one air jump, and ignore release of an earlier jump.
  Switching armor preserves damage already taken; it cannot refill protection.
- **Navigation:** all required acorns and gates are reachable through movement
  input. Campfires mark safe retry positions. The boss arena closes only when
  its acorns are collected, and reopens on defeat. Camera bounds follow the
  chapter. Later checkpoints grant any earlier equipment rewards that were missed.
- **State:** title, playing, paused, retrying, chapter complete, and won. Pause
  and focus loss freeze physics, dash/shot cooldowns, arrows, and boss attacks.
  Returning focus requires explicit resume. Retries preserve equipment choices
  and restore armor. A defeated boss and its open gate survive retries and
  falls; an unfinished fight resets. Chapters preserve choices and remove old
  projectiles.
  Replay resets rewards, counters, level entities, and temporary combat state.
- **Feel and accessibility:** visible keyboard focus, native buttons/toggles,
  readable controls, sound/gentle-motion settings, forgiving collision margins,
  and clear boss hints. Armor has ready/spent text as well as a color change.
  Bow and armor appear on the fox in either facing direction. The HUD, menus,
  and title were inspected at 1152×648 and 800×600 with letterboxing.
- **Polish and discovery:** licensed SunnyLand art, distinct forest/mill/canopy
  scenery, small static pixel title, bundled DejaVu Sans, correct item counts,
  campfire reward previews, and three hidden fireflies. Design constraints are
  recorded in [DESIGN.md](DESIGN.md) and the project instructions.
- **Robustness and performance:** native Intel OpenGL and X11 software rendering
  were exercised. Tests cover repeated input, pause, retries, chapter cleanup,
  replay, and settings reload. Multi-hour sessions, Windows, macOS, gamepads,
  touch, and remappable controls remain untested or unsupported.

## Reproducing checks

Run from the project root (`~/git/aie` on this computer). The launcher resolves
its own directory and has no dependency on the previous project location.
Local lint tools are in `~/.local/share/phippy-tools/venv/bin/`.

```sh
./emberwood --headless --editor --import --quit
gdformat --check scripts tests
gdlint scripts tests
ruff check tools/run_game_tests.py
ruff format --check tools/run_game_tests.py
sh -n emberwood start-game.sh
python3 -m json.tool .zed/tasks.json
python3 tools/check_assets.py
python3 tools/run_game_tests.py
git diff --check
```

The runner includes `fox`, `platform`, `boss`, `arrow`, `game`, `equipment`,
`loadout`, `weapons`, `expansion`, `interactions`, `route`, and `campaign`. Pass
suite names to run a subset. All twelve suites passed across focused runs.
Game integration passed **223 checks**; equipment **84**; loadout **45**; weapons
**52**; expansion integration **60**; full-scene interactions **30**. Controller,
platform, boss, original-route, and full-campaign tests also passed. Physics
assertions wait on physics ticks instead of delayed rendering frames.
Formatting, lint, shell syntax, resource import, and documentation links passed.

## Earlier boss audit verification (three chapters)

The [combat and progression audit](AUDIT.md) records the reproduced faults and
their fixes. After those changes, a new graphical campaign at normal 60 Hz
completed all three chapters and beat Old Croak with stomps: **01:33, zero
retries, three hearts, 42/72 gems, all nine acorns, and all three fireflies**.
This run used only movement, jump, and menu inputs from the title to the ending.

A separate graphical fixture prepared the final arena and earned equipment.
Normal controls then defeated Old Croak with **three arrows**, retried with R,
paused and resumed during that retry, walked left into the gap for a real fall,
and reached the final gate after the second retry. Both retries retained boss
defeat, acorns, equipment, and the open exit. This fixture's 00:13 result is not
a complete-campaign time and was saved only in a temporary directory.

Native XTest fixtures exercised Shift into the real mushroom and a protected
critter stomp while releasing a held jump after the bounce. The mushroom
produced upward movement with one air jump; the critter was defeated without
spending armor or triggering a retry. Both screenshots were visually inspected.
The graphical runs logged only expected software-display input-method/VSync
warnings. Test processes and saves were cleaned up, preserving the user's two
existing game windows.

- [Stomp campaign ending](screenshots/audit-stomp-victory.png)
- [Arrow victory before retry](screenshots/audit-boss-defeated.png)
- [Checkpoint after a post-victory fall](screenshots/audit-post-victory-checkpoint.png)
- [Mushroom launching during a dash](screenshots/audit-mushroom.png)

## Earlier graphical and native input evidence (three chapters)

A complete graphical campaign at normal 60 Hz used movement, jump, dash,
shooting, and menu input from the title through the ending. No teleport or
progress changes were used. It naturally earned both rewards, shot a critter,
toggled both equipment options with Tab/Space, and defeated Old Croak with
**three arrow hits and no stomps**. Result: **01:31, zero retries, 41/72 gems,
all nine acorns, all three fireflies, two hearts, and spent armor**. Enter replay
cleared the equipment progression. The existing stomp-based campaign also
passed with the added equipment, completing in 01:33 without retries.

Native XTest input separately exercised Enter, Shift dash, movement into a
reward campfire, J shooting, Escape pause/resume, Tab/Space equipment toggles,
and R retry. Assertions checked the actual game state, arrow count, equipment,
and checkpoint. A fixture positioned the fox just before the bow checkpoint;
reward contact and subsequent actions used normal keyboard input. After the
facing correction, native simultaneous left-and-J input fired left successfully.

A separate native fixture started with earned equipment beside spikes. Moving
into the spikes spent armor without a retry. Remaining on them caused a real
failure after protection expired; automatic retry restored the fox at camp with
both items equipped and armor charged. Headless coverage additionally checks
boss/critter damage, falls, paused projectiles/cooldowns, and repeated actions.

Screenshots below were inspected. A tutorial/title overlap and a HUD/pause-button
overlap were fixed during review. A temporary display interruption required one
native rerun; the completed native runs passed. Graphical runs logged only the
software display's input-method/VSync warnings. Test saves and display/game
processes were cleaned up; the playable native game is left open.

- [Title](screenshots/title.png)
- [Title at 800×600](screenshots/title-800.png)
- [Dash](screenshots/dash.png)
- [Bow reward](screenshots/bow.png)
- [Arrow in flight](screenshots/arrow.png)
- [Armor reward](screenshots/armor.png)
- [Equipment menu](screenshots/pause.png)
- [Equipment at 800×600](screenshots/equipment-800.png)
- [Armor blocking spikes](screenshots/armor-block.png)
- [Automatic retry with equipment](screenshots/armor-retry.png)
- [Flooded Mill](screenshots/mill.png)
- [High Canopy](screenshots/canopy.png)
- [Old Croak](screenshots/boss.png)
- [Campaign victory](screenshots/victory.png)
