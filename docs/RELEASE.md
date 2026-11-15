# Weapons and downloadable app

Scope: five weapons, eight armor sets, twenty levels, and an offline Linux package
that other players can install into their Applications launcher.

## Checklist

- Core loop/progression: Thorn fan at Willow Narrows' second camp; Sunwood lance
  at Rootbound Ruins' second camp. Thirteen gear rewards in total. Existing gates,
  boss rules, levels and restart remain unchanged.
- Physics/combat: fan fires three short-range shots at different angles; lance
  travels farther but fires more slowly and pierces four critters. Both use the
  existing swept collision rules. Terrain blocks them; boss vulnerability and
  recovery apply to every projectile, including simultaneous fan contacts.
- Interaction/state: one volley per press, shared cooldown, pause freezes every
  projectile, finite lifetimes, checkpoint equip, retry/level persistence, and
  restart cleanup. Both weapon and armor lists scroll to keyboard focus and show
  their selected item when reopened.
- Feel/visuals: distinct thorn shots and golden lance details on the fox, camp
  previews, readable gear names, and separate sound cues. Existing art direction
  and accessibility settings are retained.
- Distribution: install/reinstall/uninstall, menu entry, icon, dependency check,
  engine/licenses bundled, offline launch without development files, release
  download, and updated local Downloads copies.
- Evidence: verification below. No new levels or armor
  sets are required for this update. Windows/macOS/ARM installers remain outside
  this Linux x86-64 release.

## Results

Fourteen focused/regression/campaign suites passed: weapon collision **80**,
new weapon reward/input **26**, loadout **118**, gear menu/retry **62**, game
integration **359**, equipment **84**, earlier expansion **60**, later armor
**169**, and interactions **30**, plus fox, platform, boss, arrow, and full campaign.
The complete twenty-level input run finished in **06:36**, with zero retries,
all acorns/fireflies, and **13 earned rewards**. Separate route/trail suites were
not repeated because geometry and movement are unchanged and the campaign
traverses every level.

Native keyboard fixtures reached each new camp, fired J (three fan shots or one
lance), selected all available weapons with Tab/Space, and paused/resumed at
1152×648 and 800×600. Weapon artwork, projectiles, and the scrolling menu were
inspected. Fixtures start near the reward camp; the campaign test establishes
reachability from the beginning. Formatting, lint, and Godot import passed.

The final Debian package passed a fresh install, reinstall, desktop launch,
and removal in an isolated filesystem. Only a loopback network interface was
available; the development checkout and installed development Godot were hidden.
The bundled game reached its title, ran/jumped/dashed, hit spikes, returned to
camp, paused, and resumed with native keyboard input. A packaged-resource probe
confirmed all 13 rewards and both new weapons. APT's dependency simulation and
Lintian passed; documented overrides retain the official Godot runtime's bundled
libraries and upstream executable format. No host package installation occurred.

Screenshots: [Thorn fan](screenshots/thorn-fan.png),
[Sunwood lance](screenshots/sunwood-lance.png),
[five-weapon menu at 800×600](screenshots/five-weapons-menu-800.png),
[packaged offline retry](screenshots/package-offline-retry.png),
[packaged pause](screenshots/package-offline-pause.png).
