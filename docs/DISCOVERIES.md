# Forest discoveries

One optional chest on each of the twenty trails gives a leaf shield when dashed
through with Shift. Walking through it is harmless. The shield blocks one spike,
monster or boss hit before spending armor. Falls still cause a retry. Chests stay
open on retry, so their shield cannot be farmed; a new trail has a fresh chest.

Finding any existing hidden firefly recruits a companion for the rest of the run.
It collects visible gems within 115 pixels of the fox, never through solid terrain.
It does not fetch acorns or secrets. It survives retries and follows into later
levels; Explore again starts a fresh adventure. Existing gem totals remain exact.

## Working game checklist

- Core loop: optional dash treasure and useful exploration reward; existing acorn
  requirements, boss gates and twenty-level route remain intact.
- Physics/interaction: non-solid chest, real dash contact, clear prompt; verify
  ordinary overlap, both directions, repeat touches, safe placement and gem walls.
- Navigation: all chests rest on safe existing ground; no new required detours.
- State: freeze on pause, one shield per chest, no duplicate rewards on retry,
  companion persists between levels, new adventure resets it.
- Feel/accessibility: use existing sounds and palette, leaf crest and visible
  firefly wings, restrained HUD status; Gentle motion stops decorative bob/flapping.
- Polish/performance: inspect 1152×648 and 800×600, validate pickups and counts,
  lint/format/import/export and offline installed launcher.
- Playtests: native keyboard success/failure/retry loops at both window sizes,
  discovery regression coverage and the complete campaign; evidence below.

## Verification

`python3 tools/run_game_tests.py finds` passed **184 checks**. Coverage includes
real dash input in both directions, ordinary walking, duplicate rewards, pause,
spike and boss protection, armor precedence, falls, retry, gem range, solid walls
and ground, acorn/secret exclusions, Continue, replay and placement on all twenty
trails. A wall fixture was corrected to wait for Godot's physics registration
before resuming pickup checks.

Related suites passed: **438 monster checks**, **84 equipment checks** and
**359 game checks**. These cover the unchanged combat, settings and core state
transitions alongside the new reward logic.

Native X11 keyboard play at **1152×648 and 800×600** exercised Start, walking to
the actual first chest, Shift to open it, one protected spike contact followed
by failure, camp retry, companion rescue and automatic gem collection, pause
and resume, Gentle motion, R retry and Continue. The companion fixture moves a
hidden firefly and two gems near camp; the transition fixture supplies acorns
and places the fox at the gate. These fixtures test interactions independently
of the complete route. Screenshots were visually inspected at both sizes.
A disappearing startup window initially interrupted the test driver; ignoring
that transient X11 window fixed the driver, and both complete runs passed.

The new status text sits in the footer so it cannot overlap boss hints. The
rescue message was shortened after inspecting a wrapped toast. No game resources
or dependencies are fetched at runtime. Native tests used software rendering;
hardware GPU performance and multi-hour sessions were not benchmarked.

Screenshots: [chest](screenshots/discoveries-chest-800.png),
[shield](screenshots/discoveries-shield-800.png),
[firefly friend](screenshots/discoveries-friend-800.png).

The input-driven campaign completed **all twenty levels and all six bosses** in
**07:47 game time, zero retries**, earning all thirteen gear rewards and finding
every hidden firefly. This also exercises the companion across the complete run.

`gdformat --check scripts tests`, `gdlint scripts tests`, Ruff checks/format checks,
Godot import/export and `git diff --check` passed. The **1.3.0 Linux x86-64** package
passed Lintian, APT dependency simulation, upgrade from 1.2.1, reinstall and removal
in an isolated filesystem. The registered desktop launcher was played offline
with the development checkout and engine hidden; its title, icon, controls and
rendered scene were checked. An exported-resource probe confirmed discovery
rewards and twenty chests alongside the existing monsters and six bosses.

The Applications shortcut, Zed's executable `emberwood`, public GitHub release,
installer, source ZIP and extracted Downloads copy are refreshed together.
Ubuntu/Debian x86-64 is the packaged platform; other desktop packages are outside
this update.
