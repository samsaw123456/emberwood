# Emberwood — Forest Adventure

Guide the fox through three chapters, collect the acorns that open each trail,
and get past Old Croak at the hollow tree.

| Chapter | Route |
| --- | --- |
| **1. Emberwood** | The original forest: spikes, critters, moving platforms, crumbling bridges, and a bouncing mushroom. |
| **2. Flooded Mill** | Cross the millpond using timber beams and the rising sluice lift. |
| **3. High Canopy** | Follow the branches above the forest, then face Old Croak in his clearing. |

Each chapter has **3 required acorns** and a hidden firefly. There are **9 acorns,
72 optional gems, and 3 hidden fireflies** across the complete adventure.

## Play

Open [project.godot](project.godot) in **Godot 4.5.1**, wait for the artwork to
import, then press **Play** at the top right or **F5**. Choose **Start adventure**.
On this computer, [start-game.sh](start-game.sh) also launches the game using the
installed Godot runtime.

| Action | Keys |
| --- | --- |
| Move | **A / D** or **Left / Right** |
| Jump | **Space**, **W**, or **Up** |
| Double jump | Release jump, then press it again in the air |
| Jump higher | Hold jump a little longer |
| Dash | **Shift**, in the direction you face |
| Shoot the equipped bow | **J** |
| Retry from your campfire | **R** |
| Pause, choose equipment, or resume | **Esc** or **P** |
| Sound on or off | **M** |

Collect the chapter's three acorns and enter its gate. The chapter result names
your next destination; choose **Continue** to travel there. Campfires remember
your place during the current chapter. Retries are unlimited, and collected
items stay with you after a tumble.

Dash is available from the start. It gives a short horizontal burst, then needs
a brief cooldown. You get one dash in the air before landing again. Jumping can
interrupt a dash; walls and hazards still matter.

At **Emberwood's second campfire** (the first checkpoint after the starting camp),
you earn a **bow**. Press **J** to fire an arrow in the direction the fox faces.
Arrows knock critters aside and stop at platforms and walls. Ammunition is
unlimited, with a short delay between shots; release and press J for each shot.

At **Emberwood's third campfire**, you earn **leaf armor**. It absorbs one hit from
spikes, critters, or Old Croak. A newly reached campfire or a retry repairs it;
returning to an already lit camp or toggling equipment does not. Armor cannot
save you from a fall. The HUD shows whether it is ready or spent.

Rewards equip automatically. Open **Esc → Equipment** to equip or remove the bow
and armor independently; you can use both together. Equipment and choices carry
across retries and levels. A later checkpoint also awards earlier rewards you
missed. Restarting the adventure clears equipment along with the level progress.

Old Croak marks where he will land before he leaps. Avoid the landing spot and
jump over the ripples. When he rests and his cap turns gold, double-jump onto it.
You can also **shoot him while he rests**. **Three hits**, one per opening, let
you pass. The fox has **three hearts** during this encounter. Losing them before
victory returns you to the nearby campfire and resets the fight, including Old
Croak's health. Once defeated, he stays defeated through retries and falls, and
the final gate stays open. Your collected acorns and gems remain collected.

Choose **Restart all chapters** in the pause menu to begin again from the forest.
**Gentle motion** in the title or pause menu reduces decorative movement and
particles. The game pauses when its window loses focus and waits for you to resume.

The complete campaign's best time and the sound/motion settings are saved locally.
The current chapter, campfire, and collected items reset when you close the game.
The expanded campaign uses its own best-time record; an old single-forest time
is not compared with the longer adventure.

## For developers

This is a Godot 4.5.1 project using GDScript and the compatibility renderer.
No plugins or runtime network connection are required. The main scene is
[scenes/main.tscn](scenes/main.tscn).

- [scripts/game.gd](scripts/game.gd): chapter progression, game states, pickups,
  retries, encounter health, and campaign results.
- [scripts/fox.gd](scripts/fox.gd): movement, double jumps, dash, and worn equipment.
- [scripts/equipment.gd](scripts/equipment.gd): reward definitions, unlocks,
  equipment choices, and armor charge. Checkpoint names and menu descriptions
  come from this shared catalog.
- [scripts/arrow.gd](scripts/arrow.gd): arrow flight, range, and swept hit detection.
- [scripts/level.gd](scripts/level.gd): terrain, hazards, pickups, and world labels.
- [scripts/chapters.gd](scripts/chapters.gd): new chapter layouts and test routes.
- [scripts/platform.gd](scripts/platform.gd): solid, moving, and crumbling terrain.
- [scripts/boss.gd](scripts/boss.gd): Old Croak's attack tells, leaps, ripples,
  vulnerable phase, and defeat.
- [scripts/hud.gd](scripts/hud.gd): game menus, controls, and boss health display.
- [scripts/forest_backdrop.gd](scripts/forest_backdrop.gd): forest, mill, and canopy scenery.

The launcher uses `GODOT_BIN` when set, then `godot4` or `godot` on `PATH`, then
the local workshop runtime in `~/.local/share/phippy-tools/`. It forwards extra
arguments to Godot. Run these commands from the project directory:

```sh
# Import artwork and verify project loading, including after a fresh clone.
./start-game.sh --headless --editor --import --quit

# Formatting and linting; supplied by gdtoolkit.
gdformat --check scripts tests
gdlint scripts tests
ruff check tools/run_game_tests.py
ruff format --check tools/run_game_tests.py

# Fox, platform, boss, arrows, game state, equipment, interactions, and routes.
# Each suite uses temporary saved data and cleans it up afterward.
python3 tools/run_game_tests.py

# Launch the playable game.
./start-game.sh
```

On this computer, `gdformat`, `gdlint`, and `ruff` are available in
`~/.local/share/phippy-tools/venv/bin/`. Run the checks after changing movement,
collisions, chapter flow, or the boss, then play the affected sections. The
campaign best-time key is `game/campaign_best_time` in `user://emberwood.cfg`.

See [playtest notes](docs/PLAYTEST.md) for verification and screenshots, and
[visual direction](docs/DESIGN.md) for the pixel title and readable game interface.
The [combat and progression audit](docs/AUDIT.md) records the boss fixes and
related interaction checks.

## Credits

Built with the [Phippy Gaming Workshop](https://github.com/Tingsters/Phippy-Gaming-Workshop)
and [Godot](https://godotengine.org/). Workshop code and documentation use
[Apache 2.0](LICENSE).

The fox, frog, woodland artwork, critters, platforms, spikes, and gems use
**SunnyLand** by **Luis Zuno (Ansimuz)**, supplied under **CC0 1.0**. Original
artwork files are preserved. See [artwork credits](assets/CREDITS.md), the
[CC0 license](assets/licenses/CC0-1.0.txt), and the
[SunnyLand source](https://ansimuz.itch.io/sunny-land-pixel-game-art).

DejaVu Sans regular and bold are bundled under their
[font redistribution license](assets/fonts/LICENSE.txt). Additional scenery,
pixel title, interface elements, acorns, and sound effects are created in code.
