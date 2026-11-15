# Emberwood interface

The title menu uses the opening level itself: the fox, acorns, trees, platforms,
and spikes remain visible. The static title uses the bundled bold font at 38 pixels,
spelling Emberwood as actual label text. The old handmade letters were ambiguous. It has no entrance animation, hover movement,
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
small numerals, arrows, and health marks. The title uses the same legible family, at a modest heading size.
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
Pause contains two columns: five weapons and eight armor sets. Each list scrolls
inside the existing menu, follows keyboard focus, and reveals the selected set
when reopened. Descriptions explain behavior and locked choices name their
reward checkpoint.
The play HUD reports dash readiness, the selected weapon, and armor blocks left
in a single line. Each weapon and armor set has a distinct small silhouette on
the fox; unused reward campfires display the corresponding item. Equipment
introduces no separate inventory screen.
The title's controls sit over the ground at the bottom of the screen so they do not
collide with the tutorial signs in the opening level. No decorative page, marketing
panel, route diagram, or slogan is needed to explain the game.

Moss Caverns uses layered rock faces, roots, and muted green stone. Sunlit Ridge
opens into warm sky, angular granite, and distant pines. These landmarks support
the new routes. Solid platform silhouettes and hazard contrast stay readable;
the cave does not depend on glowing effects to establish its identity.

The fifteen later levels follow three regions. Riverlands use reeds, willows,
old aqueducts, and waterfalls; mountain routes use snow, slate, pines, and low
cloud banks; ancient woods use copper foliage, rootbound ruins, lantern hollows,
and a broad heartwood tree. Distant scenery has lower contrast than solid
platforms. World hints use a restrained dark outline to remain readable over
foliage. Region identity comes from terrain and landmarks, with the same clear
controls throughout.

Armor uses woven reeds, a lined winter coat, layered slate, riveted copperbark,
and overlapping golden leaves. These small shapes distinguish the five new
rewards on the fox and at campfires without introducing a separate inventory
screen or large ornamental item cards.

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

The expanded armor menu was exercised with native Tab/Space and Escape at
1152×648 and 800×600. Every gear choice was selected and focused armor scrolled
into view. All eight worn sets were visually inspected together. New scenery
and the longer adventure are recorded in [TWENTY_LEVELS.md](TWENTY_LEVELS.md).

## Guardian encounters

Every third chapter ends with a different animal guardian. Only Old Croak remains
a frog. SunnyLand supplies the frog, opossum and eagle; original pixel silhouettes
provide the boar, wolf and owl. Keep the shared gold-cap weak point, but align it
with each body. Leap height, warning time and ripple speed vary by encounter. Five extended banks place fights beyond all obstacles and collectibles,
with a safe arena camp and dynamic names in the HUD. See [boss notes](BOSSES.md).

## Monster recognition

The first ordinary monster drawings were too small and lacked distinctive features.
Give the slime a broad dripping jelly silhouette, the beetle wing cases, six legs
and antennae, and the bat scalloped flapping wings, tall ears and fangs. Use bright
highlights and dark edges against actual scenery. Check all three at 800×600;
labels or a few extra colored pixels cannot substitute for recognizable shapes.
See [monster artwork](MONSTER_ART.md) for current screenshots and playtests.

## Discoveries

Dash chests use small wooden boxes with brass bands and an open lid after use.
A nearby Shift prompt explains their interaction. A leaf crest beside the fox
shows the one-hit shield without covering worn armor. The rescued firefly has
a yellow abdomen, pale wings and a trailing flight path. Two short status texts
share the unused right side of the controls footer, clear of boss hints. Gentle
motion removes companion bob/flapping. See [discovery checks](DISCOVERIES.md).
