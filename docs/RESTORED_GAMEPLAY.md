# Restored gameplay

Version 1.3.1 removes all three additions from 1.3.0 at the player's request:
treasure chests, their bonus leaf shields, and the gem-fetching firefly companion.
The original hidden fireflies remain optional collectibles. Existing leaf armor,
dash, equipment, twenty levels, six bosses and detailed monster artwork remain.

## Working checklist

- Core loop and state: restore the pre-discovery game exactly; check title, pickup,
  damage, retry, pause/resume and chapter progression with the existing suites.
- Physics/navigation: unchanged from 1.2.1; verify runtime scripts match that commit.
- Interaction: walking/dashing through former chest locations must give no reward;
  hidden fireflies must not create a companion or change gem collection range.
- Visuals/accessibility: remove chest art, extra leaf crest, companion and footer
  status; inspect the real game at both normal and small window sizes.
- Robustness: lint/format, import/export, offline package upgrade from 1.3.0,
  launcher and Downloads refresh; remove obsolete source files in Downloads.
- Playtest evidence: checks below. No new gameplay or dependencies.

## Verification

Every runtime script matches commit `6af72c7` (version 1.2.1) byte for byte.
The discovery script, tests, artwork screenshots and integration code are removed.
The existing `monsters`, `equipment` and `game` suites passed **881 checks**
(438 + 84 + 359). No new tests duplicate the reverted implementation.

Native keyboard play at **1152×648 and 800×600** passed Start, movement/dash
through the former chest location, unprotected spike damage, failure/retry,
pause/resume, hidden-firefly collection without a companion or gem magnet,
direct gem pickup, R retry and Continue. The native fixture moves a firefly and
one gem near camp, and supplies acorns/places the fox at the gate for the
Continue check. Its gem was lowered into walking pickup range after the first
fixture run missed it. No product changes were needed.

The rendered result was inspected at both sizes: no chest, leaf-shield crest,
companion or additional footer status. [Small-window screenshot](screenshots/restored-gameplay-800.png).
The complete twenty-level campaign was not repeated for this exact code restore;
its earlier verification is recorded in [monster artwork](MONSTER_ART.md).

GDScript lint/format, Ruff checks/format checks, Godot import/export and
`git diff --check` passed. The Applications shortcut and Zed launcher point to
this restored checkout. Version 1.3.1 permits a normal package upgrade from
1.3.0 while restoring earlier gameplay. The current source ZIP/extracted copy
and installer in Downloads are refreshed, including removal of obsolete tracked
source files. Older versioned installers and Git history remain as archives.

The Linux package passed Lintian and APT dependency simulation. Isolated install,
upgrade from 1.3.0, reinstall and removal passed. Its registered desktop launcher
ran offline with the checkout and development engine hidden; title/icon lookup,
movement, jump/dash, failure/retry and pause/resume were exercised. An exported
resource probe confirmed the removed feature script is absent and the previous
monster artwork, twenty levels and six bosses remain. Hardware GPU performance
and multi-hour sessions were not benchmarked.
