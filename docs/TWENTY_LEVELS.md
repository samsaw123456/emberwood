# Twenty-level adventure

Scope: retain the first five levels and add fifteen routes across riverlands,
frostpine mountains, and ancient woods. Add five armor rewards, for eight armor
sets total, and keep the `emberwood` executable and Zed task current.

## Acceptance checklist

- **Core loop:** twenty levels in order, three required acorns per gate, one
  hidden firefly per level, the existing Old Croak fight, a final forest ending,
  accurate totals, and a full restart.
- **Physics:** curated jumps, moving platforms, crumble crossings, thorn patches,
  reachable collectibles, safe camps, and actual input-based route verification.
- **Interaction:** eleven gear choices across three weapons and eight armor sets;
  new camp rewards equip correctly. Armor swaps retain the shared damage budget.
- **Navigation/camera:** distinct route combinations and landmarks, readable
  gate signs and level numbers, bounded cameras, no dead ends, and keyboard focus
  that scrolls the armor list into view.
- **State:** correct transitions across all twenty levels, gear preserved across
  retries/chapters, defeated boss retained after retries, clean replay, and a
  separate best-time key preserving the earlier short-campaign records.
- **Feel/accessibility:** readable equipment and hints at 1152×648 and 800×600,
  clear armor silhouettes and remaining blocks, mute/gentle-motion controls,
  pause/resume, and focus-loss behavior.
- **Polish/discovery:** a firefly in every new route, camp reward previews, three
  new scenery families with individual landmarks, correct spelling and counts.
- **Robustness:** lint, format, import, asset/link checks, launcher/task loading,
  full campaign plus focused armor and route checks, and temporary-data cleanup.
- **Playtest evidence:** run every route with movement/jump input, play the entire
  campaign graphically, exercise failure/retry and the expanded armor menu, and
  inspect screenshots. Existing player windows must be preserved.

## Implemented

The first five levels retain their routes and Old Croak encounter. Fifteen
additional courses combine seven traversal challenges in distinct orders, with
three sections and four safe camps each. The placement data also defines their
repeatable input routes. Riverlands, frostpine mountains, and ancient woods have
their own scenery and chapter landmarks. The full adventure contains 60 acorns,
378 gems, and twenty fireflies.

Five new checkpoint rewards expand armor from three to eight sets: Reed mail,
Frost armor, Stoneplate, Copperbark armor, and Sunleaf armor. They block four
through eight hits, respectively. Each has its own worn artwork. The pause menu
scrolls the armor choices, follows keyboard focus, and reveals the current armor
when reopened. Three existing weapons remain available.

The final gate, results, title count, and best-time record now describe the
twenty-level adventure. Earlier three- and five-level records are preserved
under their original keys. The executable `emberwood` remains the Zed entry point;
the test runner also uses it, so regular verification exercises that launcher.

## Verification

All fifteen automated suites passed across focused runs using isolated saved
data. Game integration passed **359 checks**; equipment **84**; loadout **118**;
armor-menu/recovery **56**; weapons **52**; the earlier expansion **60**;
later armor/retry **169**; full-scene interactions **30**. Fox, platform, boss,
arrow, original forest, new trails, and complete campaign checks also passed.

The fifteen new routes were each traversed from their entrances with movement
and jump input, collecting all three acorns, the firefly, and every checkpoint,
with zero retries. The complete headless campaign reached the final ending in
**06:36**, with **zero retries** and **all eleven gear rewards**. It also verified
every required acorn, all twenty fireflies, Continue between levels, and Old Croak.
This accelerated check keeps the simulation step at 1/60 second.

Native Tab/Space selected all eleven gear choices at 1152×648 and 800×600;
keyboard focus scrolled the armor rows into view. Escape resumed with the
selected armor and weapon. Actual spike contacts exhausted each new armor set,
caused a retry on the next hit, and restored the selected armor at its camp.
Changing armor did not refill spent protection. Restart cleared all rewards.

An isolated Zed profile loaded this project's **Play Emberwood** task. It launched
the current twenty-level title; native Enter, movement, dash, pause, and resume
worked. Paused movement/jump/dash left the game frozen. Temporary editor/game
processes, displays, profiles, and saved data were cleaned up.

A second plain-launcher native play check walked into the first spikes with no
armor, observed the hit message and automatic return to the first camp, then
successfully moved/jumped again. Pressing R returned to the camp once more with
its retry message. Collected gems stayed collected. This used keyboard input
without teleporting the fox or writing game state.

Scenery fixtures covered eleven new chapters at 1152×648 and 800×600. All five
new armor previews and the eight worn sets were inspected. Review fixed a ruins
ledge above its checkpoint, hint contrast over foliage, and a reward name hidden
behind an approach ledge. Spike artwork now stops at the correct collision edge
for narrow patches; 70- and 80-pixel patches were inspected with edge markers.
The original forest test landing was moved away from
a wandering critter after a graphical run exposed timing sensitivity; the revised
input route passed without altering the game's movement or enemy rules.

GDScript formatting/lint, Python formatting/lint, Godot editor import, launcher
shell syntax, Zed task JSON, asset integrity, and whitespace checks passed. The
launcher also imported successfully when called from outside the project.
Graphical tests used Linux software rendering; its input-method/VSync warnings
and the isolated Zed profile's dummy-audio fallback were environment limitations.

The complete normal-speed graphical run also passed at 60 Hz: **06:37**, **zero
retries**, **186/378 gems**, **all sixty acorns**, **all twenty fireflies**, and
**all eleven gear rewards**. It used the actual movement/jump/menu input route
from Start through Old Croak to the final ending, without changing level
positions, collectibles, or progression state. The results screen and selected
chapter captures were visually inspected. All temporary test processes and saves
were cleaned up; existing player windows were preserved.

## Inspected screenshots

- [Twenty-level title launched from Zed](screenshots/twenty-title.png)
- [Zed project task](screenshots/twenty-zed-task.png)
- [Eight worn armor sets](screenshots/twenty-armor.png)
- [Equipment menu](screenshots/twenty-gear.png)
- [Equipment menu at a smaller size](screenshots/twenty-gear-800.png)
- [Automatic retry after hitting spikes](screenshots/twenty-retry.png)
- [Reed mail checkpoint preview](screenshots/twenty-reed-reward.png)
- [Broken Aqueduct](screenshots/twenty-aqueduct.png)
- [Frostpine Pass at 800×600](screenshots/twenty-frost-800.png)
- [Rootbound Ruins](screenshots/twenty-rootbound.png)
- [Heart of Emberwood](screenshots/twenty-heartwood.png)

Scenery/gear screenshots use prepared fixtures; they are separate from the
full-route run. Captures from that uninterrupted playthrough:

- [Opening forest](screenshots/twenty-run-level-01.png)
- [Riverlands entry](screenshots/twenty-run-level-06.png)
- [Mountain entry](screenshots/twenty-run-level-11.png)
- [Ancient forest entry](screenshots/twenty-run-level-16.png)
- [Final level with Sunleaf armor](screenshots/twenty-run-level-20.png)
- [Completed adventure](screenshots/twenty-run-victory.png)

Slopes, new weapons/enemies, network features, touch/controller
schemes, and progress saves are outside this expansion. All optional gem routes,
multi-hour sessions, and Windows/macOS remain untested. Closing the game still
resets the current adventure; best times and sound/motion choices persist.
