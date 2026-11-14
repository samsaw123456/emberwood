# Emberwood interface

The title menu uses the opening level itself: the fox, acorns, trees, platforms,
and spikes remain visible. A small, static pixel wordmark is drawn from original
5-by-7 glyphs in `scripts/hud.gd`. It has no entrance animation, hover movement,
letter spacing effect, or oversized headline treatment. The Start button is sized
for its text, and the instructions describe the actual controls and objective.

The user explicitly rejected the previous “FIELD GUIDE / THREE CROSSINGS” design.
Its paper page, route illustration, uppercase eyebrow, Roman chapter numbering,
large serif heading, monospaced prose, and editorial composition have been removed.
They must not return under a different name or palette. The visible play scene and
compact game menus determine the composition here.

## Text and interaction

DejaVu Sans regular is bundled for controls, counters, and instructions. The bold
weight distinguishes menu actions and short state headings. These fonts have clear
small numerals, arrows, and health marks. The title's bitmap lettering is separate
from readable interface text; it is not used for paragraphs or small controls.
Both font files retain their [license](../assets/fonts/LICENSE.txt).

Cream text, muted green controls, and gold focus outlines borrow colors already in
the forest and collectibles. Buttons have straight edges and a clear pressed state.
The outline marks keyboard focus; it is not permanent decoration on every control.
Text uses linear filtering at fractional window sizes while the world sprites keep
their pixel filtering.

The live HUD shows the level, location, acorns, gems, elapsed time, and pause button
without separate statistic cards. Shallow dark backing keeps text readable over
changing scenery. The boss display uses filled and empty health marks plus a
specific action hint. Toasts have a bounded width and can wrap.

Pause, level completion, and victory are small menus over the current scene.
Each has a direct action, and pause includes sound and gentle-motion settings.
Pause also contains two equipment rows with direct toggles, descriptions, and
checkpoint hints for locked rewards. The play HUD reports dash readiness and
bow/armor status in a single line. Bow and leaf armor are drawn on the fox in
the same small pixel scale; unused reward campfires display the corresponding
item. Equipment introduces no separate inventory grid or decorative screen.
The title's controls sit over the ground at the bottom of the screen so they do not
collide with the tutorial signs in the opening level. No decorative page, marketing
panel, route diagram, or slogan is needed to explain the game.

## Verification

The native Godot window was exercised with XTest keyboard input: Start, moving and
jumping, Escape to pause, Tab/Space for both settings, resume, Continue, and Explore
again. Assertions confirmed the resulting game states, level progression, and
sound/motion values. Transition and victory fixtures were opened directly to test
those menu controls; this UI check does not claim a complete campaign playthrough.

Title, live HUD, pause, level completion, boss hints, and victory were rendered and
visually inspected at 1152×648. The title was also inspected in an actual 800×600
window with letterboxing. A control-text overlap with world signs was found and
fixed before rerunning the input flow and both title captures. GDScript formatting,
linting, and Godot parsing passed. Campaign checks are recorded in
[PLAYTEST.md](PLAYTEST.md).
