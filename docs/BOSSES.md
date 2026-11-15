> Previous release: v1.1.0. See [regular monsters](MONSTERS.md) for v1.2.0.

# Six forest guardians

A guardian blocks the gate every third level. All take three hits, one per gold-cap
opening, from a falling stomp or any equipped weapon. They share clear landing
marks and ripple attacks, with different animals, leap heights, timing and cap details.

| Level | Trail | Guardian | Animal |
| --- | --- | --- | --- |
| 3 | High Canopy | Old Croak | Frog |
| 6 | Reedbank Trail | Reed Rumbler | Opossum |
| 9 | Heron Marsh | Marsh Tusk | Boar |
| 12 | Snowmelt Gorge | Frost Fang | Wolf |
| 15 | Cloudline Crossing | Cloudwing | Eagle |
| 18 | Lantern Hollow | Lantern Owl | Owl |

The five later trails extend into flat clearings after their original obstacles
and rewards. Each has an arena campfire. Collect all three acorns before the fight
starts; until then the return route stays open. Losing all three hearts resets the
fight at camp. A defeated guardian stays defeated after retry. Level 20 remains
the journey's final gate. Best times use a new campaign key because this route
contains five additional fights; older preferences and saved records are retained.

## Working checklist

- Core loop: six encounters, guarded gates, three hits, next-level transition.
- Physics/navigation: continuous arena floor, hazards outside the clearing,
  reachable camps and gates, landing markers within bounds, full route play.
- Interaction: all weapons retain the shared guard/recovery rules; real input
  battle and actual projectile contacts, no extra hits from a fan volley.
- State: missing-acorn backtracking, pause/resume, health-loss retry, completed
  fight retry, chapter cleanup, restart, new best-time key.
- Feel/accessibility: familiar gold-cap target, readable names and hints,
  distinct animal silhouettes and cap tips, existing mute/reduced-motion settings.
- Polish/performance: inspect rendered fights at normal and smaller sizes;
  retain fixed physics; reuse SunnyLand frog/opossum/eagle art and add original
  pixel silhouettes for the boar, wolf and owl; no new dependencies.
- Distribution: update Zed launcher, package version, installer, GitHub and Downloads.
- Verification: results below. Controller/remapping and new armor/weapons
  are outside this boss-only change.

## Verification

The six-guardian integration suite passes **191 checks**: the exact level schedule,
six distinct species with only one frog, correct names/art, reachable weak points,
missing-acorn backtracking, real bow hits after actual attack phases, pause/resume,
health-loss retries, persistent victories, gate progression, and restart cleanup.

Native keyboard play beat all five new animals after a retry, using movement,
jumping and bow shots, with pause/resume and unlocked-gate checks. The opossum was
retested after lowering its cap and body hitbox to match its silhouette. The owl
was played at 800×600; the others at 1152×648. Each rendered animal was inspected.
Fixtures begin near the arena with acorns; the full campaign independently checks
reachability from the title with movement, jumps and menu input only.

Screenshots: [opossum](screenshots/boss-opossum.png),
[boar](screenshots/boss-boar.png), [wolf](screenshots/boss-wolf.png),
[eagle](screenshots/boss-eagle.png), [owl at 800×600](screenshots/boss-owl.png).

The final full campaign passed in **07:45**, with **zero retries**, every acorn
and hidden firefly, and all **13 gear rewards**. It defeats all six animals by
movement and jump inputs, including the opossum's adjusted cap. Other passing
suites: original boss, arrows, weapons (80), game integration (359), equipment
(84), loadout (118), armor menu (62), later armor (169), interactions (30), and
later weapons (26). The separate trail runner also passed Reedbank Trail with
its new fight and fifth camp; the campaign traverses all remaining trails.

Commands used include `python3 tools/run_game_tests.py guardians boss arrow weapons`,
`python3 tools/run_game_tests.py campaign`, and the listed integration suites.
`gdformat --check scripts tests`, `gdlint scripts tests`, Ruff checks/format checks
for packaging/test Python, Godot import/export, shell syntax and desktop-entry
validation passed. Local documentation links and installer SHA-256 were validated.

The **1.1.0 Linux x86-64 package** passed Lintian and dependency simulation, plus
an isolated installation of 1.0.0 followed by upgrade to 1.1.0, reinstall, and
removal. The registered Applications entry and icon loaded with the source checkout
and development engine hidden and only loopback networking. Its bundled runtime
launched the game offline and accepted movement/jump/dash and pause controls. A
packaged-resource probe confirmed all six distinct species, twenty levels and
thirteen rewards. Source keyboard tests above establish actual fight/retry outcomes.
Only Ubuntu/Debian x86-64 is packaged; no Windows/macOS/ARM verification is claimed.

The local Applications shortcut and Zed task both use the updated project launcher.
Version 1.1.0's GitHub release carries the installer and checksum; the downloaded
source archive and extracted game are refreshed from the published commit.
