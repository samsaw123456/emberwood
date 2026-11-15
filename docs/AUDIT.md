# Boss and game-state audit

Old Croak's fight had reproducible hit-detection and retry bugs. The audit also
found related bounce, protection, and saved-state problems. Each finding below
was reproduced before its fix and has regression coverage.

## Findings and fixes

| Fault | Corrected behavior |
| --- | --- |
| Pressing R or falling after victory revived Old Croak and relocked the gate. | Defeat survives checkpoint retries. An unfinished fight still resets, and restarting the whole adventure clears completion. |
| Arrows passed through the bright cap strip and leaf tips because only the lower body was tested. | Projectile contact includes the drawn cap. A gold cap takes damage; a guarded cap blocks the arrow. Terrain still has priority when it is closer. |
| A late stomp touched a gold leaf but had to sink into the body before registering, sometimes after the opening closed. | Descending feet crossing the visible cap from above register immediately. Side and underside contact cannot count as a stomp. |
| Invulnerability skipped offensive critter stomps along with incoming damage. | Protection prevents damage while leaving valid attacks available. Successful stomps do not spend armor. |
| A grounded mushroom bounce restored an extra jump; a dash could cancel the upward launch after playing its feedback. | Mushrooms, critters, and Old Croak share a bounce operation that cancels the dash, discards stale floor contact, and leaves one air jump. |
| Releasing a previously held jump shortened an externally triggered bounce. | Jump release only shortens a player-initiated jump. Mushroom, critter, and boss launches retain their full strength. |
| An older game window could overwrite a newer best time or an unrelated preference. | Saving reads the existing file, keeps the fastest valid time, and writes only the changed preference. Unreadable saves are preserved; the error message stays visible when toggling sound with M. |

The right-hand refuge is reachable and does not block the fight. Approaching
from the far right requires a double jump to reach the cap; a single jump can
fall short. The resting-phase hint now explicitly mentions double jumping.
Old Croak still takes three hits, with one hit allowed per opening. Waves clear
when a hit lands, and the boss cannot take extra damage after defeat.

## Acceptance and game checklist

- **Core loop/progression — passed:** all three chapters, acorn gates, three-hit
  boss victory, final gate, and replay. An unfinished loss resets the encounter;
  a completed encounter survives both manual retry and falling.
- **Physics/interaction — passed:** cap edges, late and fast descents, guarded
  hits, side/underside rejection, nearest projectile obstruction, mushroom
  walking/falling/dashing, protected critter attacks, jump budgets, and jump
  release. Pausing preserves bounce, dash, and retry timing.
- **Navigation/camera — passed:** an input-only campaign reaches every required
  acorn and exit. The right refuge and post-victory backtracking were exercised.
  No new navigation system or camera behavior was introduced.
- **State/consistency — passed:** armor and equipment persist through retries;
  a full restart clears progression. Sequential saves from stale instances
  preserve faster records and unrelated settings. Malformed saves are not
  overwritten. This is not a cross-process file-locking system.
- **Feel/accessibility/polish — passed for changed behavior:** clearer boss hint,
  cap geometry matching the target, reliable bounce feedback, pause/resume,
  and screenshots inspected at 1152×648. Existing sound and motion options stay
  available; no visual redesign was needed.
- **Robustness/performance — checked within scope:** nine automated suites,
  GDScript and Python lint/format checks, resource import, shell syntax, asset
  references, and documentation links. The existing dash test covers 30 and
  120 Hz. Long sessions and other operating systems were not tested here.
- **Playtest evidence — passed:** a full graphical campaign at normal 60 Hz
  beat Old Croak with stomps in **01:33**, with **zero retries and three hearts**.
  A separate graphical fixture started at the arena with its acorns/equipment
  prepared, then used input to win with three arrows, press R, pause/resume the
  retry, walk into a real fall, respawn, and finish through the still-open gate.
  Native XTest input exercised a dash into a mushroom and a protected critter
  stomp. Fixture setup is separate from the input-only full campaign.

See [playtest notes](PLAYTEST.md) for commands, suite counts, and screenshots.
Two already-open user game windows were preserved; they retain their old code
until reopened. Test runs used isolated save directories and were cleaned up.
