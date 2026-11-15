# Emberwood — Forest Adventure

Guide the fox through twenty levels, collect the acorns that open each trail,
get past six animal guardians, and return to the Heart of Emberwood beyond the riverlands
and snowy mountains.

| Chapter | Route |
| --- | --- |
| **1. Emberwood** | The original forest: spikes, critters, moving platforms, crumbling bridges, and a bouncing mushroom. |
| **2. Flooded Mill** | Cross the millpond using timber beams and the rising sluice lift. |
| **3. High Canopy** | Follow the branches above the forest, then face Old Croak in his clearing. |
| **4. Moss Caverns** | Explore rooted stone passages, cross shifting platforms, and find seed bombs. |
| **5. Sunlit Ridge** | Climb the rocky pine trail, earn ironwood armor, and reach the summit. |
| **6. Reedbank Trail** | Earn Reed mail, then face Reed Rumbler. |
| **7. Willow Narrows** | Follow the route between the willows. |
| **8. Broken Aqueduct** | Cross the old riverworks. |
| **9. Heron Marsh** | Cross the marsh and face Marsh Tusk. |
| **10. Riverwatch Falls** | Finish the riverlands crossing. |
| **11. Frostpine Pass** | Enter the snowy mountains and earn Frost armor. |
| **12. Snowmelt Gorge** | Traverse the gorge and face Frost Fang. |
| **13. Slate Heights** | Reach the high stone trail and earn Stoneplate. |
| **14. Whitewater Steps** | Follow the stepping route through the mountains. |
| **15. Cloudline Crossing** | Cross the high pass and face Cloudwing. |
| **16. Copperbark Woods** | Enter the ancient forest and earn Copperbark armor. |
| **17. Rootbound Ruins** | Explore the overgrown stone route. |
| **18. Lantern Hollow** | Follow the old hollow to Lantern Owl. |
| **19. Sunleaf Crown** | Earn the final Sunleaf armor. |
| **20. Heart of Emberwood** | Collect the final acorns and complete the adventure. |

Each level has **3 required acorns** and a hidden firefly. There are **60 acorns,
378 optional gems, and 20 hidden fireflies** across the complete adventure.

## Regular monsters

Fight **opossums, moss slimes, bramble beetles, and cave bats** throughout the
adventure. Slimes hop, beetles patrol quickly, and bats fly low. Jump and shoot to
reach a bat, or land on it from above. All four fall to one stomp or weapon hit;
side contact hurts unless armor or temporary protection absorbs it. Monsters return
when you retry. There are 15 additional patrols across levels 6–20.

## Play

For other Linux players, the [downloadable installer](https://github.com/samsaw123456/emberwood/releases/latest)
includes the game engine and adds Emberwood to the Applications launcher after
installation. It supports x86-64 Ubuntu/Debian desktops. See
[installer instructions](packaging/README.md).

On this computer, open **Applications** and search for **Emberwood**. Its icon
shows the fox in a forest. This shortcut launches the game in `~/git/aie` and
works offline, using the installed Godot runtime and local artwork. Keep that
project folder and runtime installed. Zed and a browser do not need to be open.

To install the same Linux menu shortcut from another checkout, run
`python3 tools/install_app.py` after setting up Godot as described below.
The installer uses the current checkout and installs only for the current user.

Open [project.godot](project.godot) in **Godot 4.5.1**, wait for the artwork to
import, then press **Play** at the top right or **F5**. Choose **Start adventure**.
The executable [emberwood](emberwood) launches the current game. In Zed, open
this project, open the command palette, choose **task: spawn**, then **Play
Emberwood**. The [project task](.zed/tasks.json) runs that same launcher, following
[Zed's task format](https://zed.dev/docs/tasks). It stays connected to the current
project whenever the game is updated.

| Action | Keys |
| --- | --- |
| Move | **A / D** or **Left / Right** |
| Jump | **Space**, **W**, or **Up** |
| Double jump | Release jump, then press it again in the air |
| Jump higher | Hold jump a little longer |
| Dash | **Shift**, in the direction you face |
| Use the selected weapon | **J** |
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

Press **J** to use your selected weapon in the direction the fox faces. Each
press uses it once; ammunition is unlimited, with a short delay between uses.

| Reward | Where to earn it | What it does |
| --- | --- | --- |
| **Bow** | Emberwood, second campfire | Fires quick, straight arrows. |
| **Leaf armor** | Emberwood, third campfire | Blocks one hit. |
| **Throwing spear** | Flooded Mill, second campfire | Pierces two critters in a line. |
| **Bark armor** | High Canopy, second campfire | Blocks two hits. |
| **Seed bombs** | Moss Caverns, second campfire | Lobs a seed that bursts on impact or after a short fuse, hitting nearby enemies. |
| **Ironwood armor** | Sunlit Ridge, second campfire | Blocks three hits. |
| **Reed mail** | Reedbank Trail, second campfire | Blocks four hits. |
| **Thorn fan** | Willow Narrows, second campfire | Fires three spreading thorns with a shorter reach. |
| **Frost armor** | Frostpine Pass, second campfire | Blocks five hits. |
| **Stoneplate** | Slate Heights, second campfire | Blocks six hits. |
| **Copperbark armor** | Copperbark Woods, second campfire | Blocks seven hits. |
| **Sunwood lance** | Rootbound Ruins, second campfire | A slower, longer-reaching throw that pierces four critters. |
| **Sunleaf armor** | Sunleaf Crown, second campfire | Blocks eight hits. |

Weapons stop at solid terrain; seed bursts cannot hit through walls. Armor blocks
spikes, critters, or guardians, but cannot save you from a fall. A newly reached
campfire or a retry repairs it. Revisiting an old camp or swapping armor does not
erase damage already absorbed. The HUD shows the remaining blocks.

Rewards equip automatically. Open **Esc** to choose **one weapon and one armor**;
you can turn either off. Scroll the armor list to see all eight sets; keyboard
focus brings each choice into view. The weapon list scrolls too, with five choices.
Gear and choices carry across retries and levels.
A later checkpoint also awards earlier rewards you missed. Restarting the whole
adventure clears equipment along with level progress.

A boss appears every third level: **3, 6, 9, 12, 15, and 18**. See the
[guardian roster](docs/BOSSES.md): frog, opossum, boar, wolf, eagle, and owl.
Each marks where it will land before leaping. Avoid the landing spot and
jump over the ripples. When he rests and his cap turns gold, double-jump onto it.
You can also **shoot him while he rests**. **Three hits**, one per opening, let
you pass. The fox has **three hearts** during this encounter. Losing them before
victory returns you to the nearby campfire and resets the fight, including the
guardian's health. Once defeated, he stays defeated through retries and falls, and
the gate stays open. Continue through it to the next level. Your collected
acorns and gems remain collected.

Choose **Restart all chapters** in the pause menu to begin again from the forest.
**Gentle motion** in the title or pause menu reduces decorative movement and
particles. The game pauses when its window loses focus and waits for you to resume.

The complete campaign's best time and the sound/motion settings are saved locally.
The current chapter, campfire, and collected items reset when you close the game.
The twenty-level campaign uses its own best-time record; earlier shorter
campaign records are preserved separately.

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
- [scripts/arrow.gd](scripts/arrow.gd): arrows, piercing spears, arcing seed bombs,
  swept hit detection, and wall-aware bursts.
- [scripts/level.gd](scripts/level.gd): terrain, hazards, pickups, and world labels.
- [scripts/chapters.gd](scripts/chapters.gd): new chapter layouts and test routes.
- [scripts/trails.gd](scripts/trails.gd): the fifteen later routes, assembled from
  curated traversal sections with shared placement data.
- [scripts/platform.gd](scripts/platform.gd): solid, moving, and crumbling terrain.
- [scripts/boss.gd](scripts/boss.gd): the guardians' attack tells, leaps, ripples,
  vulnerable phase, and defeat.
- [scripts/hud.gd](scripts/hud.gd): game menus, controls, and boss health display.
- [scripts/forest_backdrop.gd](scripts/forest_backdrop.gd): region scenery and landmarks.

The launcher uses `GODOT_BIN` when set, then `godot4` or `godot` on `PATH`, then
the local workshop runtime in `~/.local/share/phippy-tools/`. It forwards extra
arguments to Godot. Run these commands from the project directory:

```sh
# Import artwork and verify project loading, including after a fresh clone.
./emberwood --headless --editor --import --quit

# Formatting and linting; supplied by gdtoolkit.
gdformat --check scripts tests
gdlint scripts tests
ruff check tools/run_game_tests.py
ruff format --check tools/run_game_tests.py

# Fox, platform, boss, arrows, game state, equipment, interactions, and routes.
# Each suite uses temporary saved data and cleans it up afterward.
python3 tools/run_game_tests.py

# Launch the playable game.
./emberwood
```

On this computer, `gdformat`, `gdlint`, and `ruff` are available in
`~/.local/share/phippy-tools/venv/bin/`. Run the checks after changing movement,
collisions, chapter flow, or the boss, then play the affected sections. The
campaign best-time key is `game/forest_monsters_best_time` in `user://emberwood.cfg`.

See [playtest notes](docs/PLAYTEST.md) for verification and screenshots, and
[visual direction](docs/DESIGN.md) for the pixel title and readable game interface.
The [combat and progression audit](docs/AUDIT.md) records the boss fixes and
related interaction checks.
The [twenty-level expansion notes](docs/TWENTY_LEVELS.md) track the latest areas,
armor, and verification. The [earlier five-level notes](docs/EXPANSION.md) remain
available for the previous release.

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
The app icon combines the SunnyLand fox and trees with a forest clearing;
its original sprite credits remain above. `tools/build_app_icon.py` regenerates
the bundled icon sizes using Pillow; playing or installing the game does not
require Pillow.
