# LAN control audit

The inventory was reconciled against `project.godot`, `scripts/game.gd`,
`scripts/fox.gd`, and every displayed HUD control. **226 native scenarios passed**
on the final 1.4.0 release runtime/resource pack: 133 four-instance checks and
90 additional two-instance checks, plus three title-mouse checks. Physical X11 events drove the running game;
rendered frames and contact sheets were inspected. Audio was captured from each
application's output. Network/state assertions supplement those observations.

[LAN_CONTROLS.csv](LAN_CONTROLS.csv) records each scenario's binding, state,
expected effect, observed result, passed status and local evidence path. The table
below inventories each physical gameplay binding separately; CSV entries retain
host/guest, menu-state, item and press/release variations. See [limits](LAN.md#limits-and-recorded-diagnostics)
for the separate-computer and platform gaps; this is not a physical-network test.

## Physical keyboard inventory

| Binding | Command and availability | Observed result | Status / evidence |
| --- | --- | --- | --- |
| A | Move left while playing | Host and guest move screen-left; release stops | Passed, native-037 / 051 |
| Left arrow | Move left; menu focus outside gameplay | Moves screen-left; menus do not move fox | Passed, native-038 / 052 and menu rows |
| D | Move right while playing | Each of P1–P4 independently moves screen-right | Passed, native-035 / 036 / 039 / 053 |
| Right arrow | Move right; menu focus outside gameplay | Moves screen-right; menus do not move fox | Passed, native-040 / 054 and menu rows |
| Space | Jump while playing; activate focused button in menus | Jump, release, second jump, no third; menu activates intended control | Passed, native-041 / 055, edges-004 / 026 |
| W | Jump while playing | Host and guest rise; second press double-jumps; holding does not repeat | Passed, native-042 / 056 |
| Up arrow | Jump while playing; menu focus otherwise | Same jump result; menus navigate without jumping | Passed, native-043 / 057 and menu rows |
| Left Shift | Dash while playing | Visible right dash, once while held; release/recovery; left-facing dash checked | Passed, native-044 / 047 / 058 / 061 |
| Right Shift | Alternate dash binding | Same visible dash and release/recovery | Passed, native-045 / 059 |
| J | Use equipped weapon while playing | One shot per press; hold does not autofire; all five weapon types visible; guest defeats guardian | Passed, native-065 / 066 / 099–103, edges-064–067 |
| R | Retry while playing | Whole party returns to shared camp with pickups/earned gear; disabled during retry/menus | Passed, native-067, edges-034 / 045 |
| Esc | Pause/resume playing or retry | All peers pause/resume; inert on title, connecting, lobby and results | Passed, native-048 / 062, edges-001 / 021 / 024 / 046 and results rows |
| P | Alternate pause/resume | Same team behavior, including retry; inert in other states | Passed, native-049 / 063, edges-002 / 022 / 025 / 047 and results rows |
| M | Local sound on every screen | Audible output becomes silent then returns; menu/retry setting and toast change locally | Passed, native-069 / 071; edges-068–090 M rows |
| Tab | Forward menu focus | Visible focus moves; all gear scrolls into view | Passed, native menu rows / 086–098 |
| Left Shift + Tab | Backward menu focus | Visible focus moves backward, without dash | Passed, native-013 / 033 / 085 / 116 / 130 |
| Down arrow | Menu focus | Navigates visible controls without moving fox | Passed, native-011 / 031 / 083 / 114 / 128 |
| Enter | Activate focus / submit address | Opens LAN, joins host, starts co-op, resumes; empty submit shows usable error | Passed, native-014 / 017 / 018 / 020, edges-005 / 027 |
| Keypad Enter | Alternate menu activation | Starts solo adventure | Passed, edges-003 |
| Digits and period | Host-address text entry | Displayed address matches typed input and joins | Passed, native-018 / 020, edges-010 |
| Backspace | Address edit | Removes previous character | Passed, edges-010 |
| Delete | Address edit | Removes next character | Passed, edges-010 |
| Home | Address edit | Moves caret to start before deletion | Passed, edges-010 |
| End | Address edit | Moves caret to end before insertion | Passed, edges-010 |
| Ctrl+A | Address edit | Selects address; new typing replaces it | Passed, edges-010 |

## Mouse and menu inventory

| Binding / target | Applicable state | Expected and observed effect | Status / evidence |
| --- | --- | --- | --- |
| Left mouse / Start adventure | Title | Starts solo adventure | Passed, title-controls-003 |
| Left mouse / Sound | Title | Visible local sound setting toggles | Passed, title-controls-001 |
| Left mouse / Gentle motion | Title | Visible local motion setting toggles | Passed, title-controls-002 |
| Left mouse / LAN co-op | Title | Opens host/join form | Passed, native LAN flow |
| Left mouse / Back | LAN form | Returns to title | Passed, native-015 |
| Left mouse / Host a game | LAN form | Opens lobby, shows address, Start disabled alone | Passed, native-016 |
| Left mouse / Join game | LAN form | Connects guest and adds player to lobby | Passed, native-019 |
| Left mouse / address field | LAN form | Focuses editable address | Passed, native join flow, edges-010 |
| Left mouse / Cancel | Connecting | Cancels and returns to usable title | Passed, edges-023 |
| Left mouse / Start co-op | Host lobby | Starts all four players | Passed, native-034 |
| Left mouse / Leave lobby | Lobby | Ends lobby connection; port can be reused | Passed, edges final M/lobby flow; Space activation edges-026 |
| Left mouse / pause icon | Playing | Opens pause menu | Passed, edges-005 |
| Left mouse / Keep exploring | Paused | Resumes team | Passed, native and edges gear/focus flows |
| Left mouse / Sound | Paused, each computer | Checkmark toggles local sound; actual same output path measured by M | Passed, native-070 / 072 |
| Left mouse / Gentle motion | Paused, each computer | Checkmark toggles local motion; guest steady protection glow checked separately | Passed, native-070 / 072, network check 25 |
| Left mouse / Bow | Host gear | Toggles team weapon | Passed, edges-049; keyboard native-086 |
| Left mouse / Throwing spear | Host gear | Toggles team weapon | Passed, edges-050; keyboard native-087 |
| Left mouse / Seed bombs | Host gear | Toggles team weapon | Passed, edges-051; keyboard native-088 |
| Left mouse / Thorn fan | Host gear | Toggles team weapon | Passed, edges-052; keyboard native-089 |
| Left mouse / Sunwood lance | Host gear | Toggles team weapon | Passed, edges-053; keyboard native-090 |
| Left mouse / Leaf armor | Host gear | Toggles team armor | Passed, edges-054; keyboard native-091 |
| Left mouse / Bark armor | Host gear | Toggles team armor | Passed, edges-055; keyboard native-092 |
| Left mouse / Ironwood armor | Host gear | Toggles team armor | Passed, edges-056; keyboard native-093 |
| Left mouse / Reed mail | Host gear | Toggles team armor | Passed, edges-057; keyboard native-094 |
| Left mouse / Frost armor | Host gear | Toggles team armor | Passed, edges-058; keyboard native-095 |
| Left mouse / Stoneplate | Host gear | Toggles team armor | Passed, edges-059; keyboard native-096 |
| Left mouse / Copperbark armor | Host gear | Toggles team armor | Passed, edges-060; keyboard native-097 |
| Left mouse / Sunleaf armor | Host gear | Toggles team armor | Passed, edges-061; keyboard native-098 |
| Wheel up | Equipment column | Scrolls choices up | Passed, edges-062 |
| Wheel down | Equipment column | Scrolls choices down | Passed, edges-063 |
| Left mouse / Continue | Host chapter complete | Advances all peers to the same next chapter | Passed, native-117 |
| Left mouse / Explore again | Host won | Resets whole party to first chapter | Passed, native-131 |
| Left mouse / Restart all chapters | Host pause | Resets whole party to first chapter and equipment | Passed, edges-078; gear reset network check 30 |
| Left mouse / Leave LAN game | Guest pause / results | Returns guest to title; others remain | Passed, native-132, edges-085 |
| Left mouse / Close LAN game | Host pause / results | Closes session; guests return to title | Passed, native-133, edges-086 |

Guest gear, restart, Continue and Explore again controls are visibly disabled.
The headless authorization tests also attempted their underlying actions and
confirmed they cannot modify the host's campaign. The one-player lobby cannot
start; a fifth player and late joins receive a rejection with recovery text.

## Combinations, inactive states and recovery

| Binding / situation | Observed result | Status / evidence |
| --- | --- | --- |
| A+D, then release A | Opposing inputs stop; remaining D moves screen-right, host and guest | Passed, native-046 / 060 |
| Left+Right, then release Left | Same opposing-input behavior | Passed, edges-028 / 031 |
| D+Space | Rightward jump, with both inputs released afterward | Passed, edges-029 / 032 |
| D+Left Shift | Rightward dash and recovery | Passed, edges-030 / 033 |
| Turn right then J | Weapon travels toward visible facing and hits guardian | Passed, edges-064–066 |
| D, lose focus, release while unfocused, regain focus | Team pauses; resume has no stuck movement | Passed, native-050 / 064 |
| Hold Space across retry | Fox stays grounded until release/new press | Passed, edges-048 |
| All movement/jump/dash/J/R during retry | No movement, shot, extra death or jump | Passed, edges-035–045 |
| Gameplay keys on title/lobby/pause/results | No unintended gameplay; arrows/Tab retain menu navigation | Passed, native-001–013 / 021–033 / 073–085 / 104–116 / 118–130 |
| Gameplay keys while connecting | No movement, shot, retry, accidental join or pause | Passed, edges-011–022 |
| Repeated physical press vs held OS repeat | One jump/dash/shot per press; no repeated action from key echo | Passed, native press/hold/release checks plus `test_input_repeat.gd` |

No controller, touch, camera-mode, zoom, remapping, chat, or mouse-combat commands
are implemented. Right/middle mouse have no game action (the address field uses
Godot's ordinary text-editing behavior). There is no countdown state. These are
**not applicable**, rather than claimed device tests. Hardware-specific layouts,
accessibility devices and operating-system window-manager shortcuts were not
part of this Linux X11 audit.

## Evidence

The scripts preserve raw screenshots, before/during/after movement frames,
contact sheets, JSON rows and audio in `build/lan-audit/`. Scenario names distinguish
the host and guest. The full four-player run was retained even though two extra
windows stop rendering after their independent movement checks to reduce the
software-rendering load; all four continue exchanging network state.

Selected inspected frames are committed:

- [Four players](screenshots/lan-four-players.png)
- [800×600 pause menu](screenshots/lan-pause-800.png)
- [Guest thorn fan](screenshots/lan-guest-weapon-thorn_fan.png)
- [Guest guardian defeated](screenshots/lan-guest-guardian.png)
- [Guest campaign results](screenshots/lan-guest-victory.png)

Fixtures supply precise starting positions, earned gear, selected chapters and
extended retry/connection time for otherwise short states. Actions themselves
use real window input. Automated full-campaign play is reported separately from
these fixture-assisted control tests. Test harness timing failures were fixed
by waiting for actual state, release frames and rendering, then rerunning the
full audits; no failed rows remain in the recorded 226 scenarios.
