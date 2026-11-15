# Five-chapter expansion

These notes describe the earlier five-level release. The current expansion is
documented in [Twenty-level adventure](TWENTY_LEVELS.md).

Scope: continue beyond Old Croak into Moss Caverns and Sunlit Ridge. Add two
weapons and two armor upgrades, earned at camps and chosen in the pause menu.
The existing pixel world, compact typography, and direct controls stay coherent.

## Rules and acceptance checklist — verified

- **Core loop:** five playable chapters, three acorns per gate, five hidden
  fireflies, a final summit ending, and a complete restart. Old Croak remains
  in High Canopy; victory leads onward instead of ending the adventure.
- **Physics:** reachable new jumps and safe camps, moving/crumbling platforms,
  swept weapon collisions, arcing seed bombs, and no shots through walls.
- **Interaction:** J uses one selected weapon. Bow fires quickly; spear pierces
  two critters; seed bombs burst nearby. Leaf/bark/ironwood armor block one/two/
  three hits. Selecting armor must not reset damage already absorbed.
- **Navigation:** distinct cave and ridge routes, useful landmarks, clear gates,
  and keyboard-accessible gear selection. Camera bounds follow each level.
- **State:** reward unlocks and selected gear survive chapter changes and retries;
  new camps/retries repair armor; pause freezes projectiles and blast timing;
  restart clears gear. The longer campaign gets a separate best-time record.
- **Feel/accessibility:** visible selected gear and remaining armor blocks,
  different weapon silhouettes/cues, readable menu at 1152×648 and 800×600,
  focus, mute, and gentle-motion behavior.
- **Polish/discovery:** new camp previews, accurate counters and hints, two new
  firefly hiding places, and no generic interface templates.
- **Robustness:** lint/import/tests, weapon cleanup, invalid gear IDs, repeated
  inputs, guarded boss damage, failure/retry, and old-save compatibility.
- **Playtest:** input-driven full campaign plus native weapon/armor/menu probes
  and screenshots. Test saves are isolated; existing player windows are preserved.

The expanded loop passed. All twelve automated suites passed across focused
runs: fox, platform, boss, arrow, game, equipment, loadout, weapons, expansion,
interactions, route, and campaign. Key results: **223 game checks**, **84 existing
equipment checks**, **45 loadout checks**, **52 projectile checks**, **60 expanded
integration checks**, and **30 bounce/contact checks**. Lint, formatting, Godot
import, launcher shell syntax, task JSON, resource inventory, and local links
were checked. Commands are listed in [PLAYTEST.md](PLAYTEST.md).

## Playing the result

A full graphical run at normal 60 Hz went from the title through all five
chapters using movement, jumping, and menu input. It defeated Old Croak with
stomps, earned all six items through campfire contact, and reached the summit
in **02:14 with zero retries, 70/108 gems, all 15 acorns, and all five fireflies**.
No teleporting or progress changes were used in that campaign.

Separate new-level fixtures played each whole route, including an R retry at
its second campfire. These found a cave jump approaching a ledge from underneath;
moving the ledge and its approach fixed it, and both routes passed again.
Screenshots also exposed light ridge sign text and inherited forest zone names;
both were corrected before the final captures.

A prepared weapon fixture used J and Escape in the real scene: a spear defeated
the first two of three critters; a seed bomb followed an arc and burst across
two enemies while a wall protected the third. Pause froze the projectile and
its fuse, blocked weapon input, and resumed correctly. Separate native XTest
input selected all six equipment choices with Tab/Space and resumed with the
chosen gear at both 1152×648 and 800×600. Fixture setup is distinct from the
input-only campaign.

## The emberwood launcher

The executable [emberwood](../emberwood) delegates to the existing portable
Godot launcher. It starts the current project rather than a copied game. Its
feature comments and the project instructions were updated with this release.
The [Zed project task](../.zed/tasks.json) runs that file as **Play Emberwood**.

An isolated Zed 1.28.1 profile loaded the task through Ctrl+Shift+P → task: spawn,
launched Godot, and accepted Enter, movement, and jump input. The temporary
software-rendering environment showed a GPU notice and used dummy audio because
it had no audio device; graphics and keyboard input worked. Existing player
windows were preserved. Temporary test editors, games, displays, and saves
were cleaned up. The previous platform limits in PLAYTEST.md still apply;
multi-hour sessions and other operating systems were not tested.

## Inspected screenshots

- [Moss Caverns](screenshots/moss-caverns.png)
- [Sunlit Ridge](screenshots/sunlit-ridge.png)
- [Equipment selection](screenshots/expanded-gear.png)
- [Equipment at 800×600](screenshots/expanded-gear-800.png)
- [Spear in flight](screenshots/spear-flight.png)
- [Seed burst](screenshots/seed-burst.png)
- [Complete five-chapter ending](screenshots/five-chapter-victory.png)
- [Play Emberwood in Zed](screenshots/zed-launcher.png)
