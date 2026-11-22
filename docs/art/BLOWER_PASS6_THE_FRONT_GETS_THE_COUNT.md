# THE BLOWER, PASS 6 - THE FRONT GETS THE COUNT, AND THE FIRST FIX I TRIED WAS WRONG

21 Nov 2026, art lane. Machine clock read with `TZ=America/Chicago date` at the
start of the run: **Sat Nov 21 15:34:33 CST 2026**. CT, not UTC.

## THE ITEM

The team lead's 14:58 handover gave the art lane one thing: *"the Blower's pass
6, the bag that reads only from behind - the one thing its own note still calls
open."* The Blower's own owed-note said the same and offered **two** candidate
fixes, with the instruction to take exactly **one** and to judge it on a
picture.

## FIRST I BUILT AN INSTRUMENT, BECAUSE "READS ONLY FROM BEHIND" IS NOT A NUMBER

`tools/art/_bagfacing.py`. It reads the shipped render - no Blender scene, no
materials, no depsgraph - and asks the viewer's question: standing in front of
this thing, how much of what you see is the bag, and is the bag where the
figure is or splayed out beside him like scenery?

Pass 5 as shipped:

| view  | litpale_share | litpale_central | outer_share |
|-------|---------------|-----------------|-------------|
| front | 0.0401        | **0.1607**      | 0.4138      |
| side  | 0.1197        | 0.4174          | 0.2805      |
| back  | 0.1808        | **0.5733**      | 0.4161      |

That is the fault in numbers. The front sees a quarter of the pale the back
sees, and 84% of the little it does see lies OUTSIDE the middle half of the
figure - two thin rims standing beside a man. The archway read.

**WHAT THE INSTRUMENT CANNOT SEE, AND I FOUND IT BY DRAWING ITS OWN ANSWER BACK
OVER THE PICTURE IN MAGENTA AND LOOKING AT IT.** `litpale_*` classifies the bag
by BRIGHTNESS, so it is a lighting measurement as much as a material one: the
Blower's whole left wing is in shadow from the front camera and is scored as
body, and the two eyes and the pale nozzle are scored as bag. So the honest use
is the FRONT-TO-BACK COMPARISON, where both views are lit the same way and the
asymmetry is the signal. It is **not** "this much of the creature is bag". That
limitation is written into the file's docstring, not just here. `outer_share`
is pure silhouette and carries no such blindness.

## THE FIRST FIX. I RAN IT, IT WENT THE WRONG WAY, AND IT IS STRUCK

Option (a) was: bring the bag's own flanks round toward the front camera by
making the wedge less flat. Swept at 0.58 / 0.74 / 0.88, everything else
frozen, under `BLOWER_FLAT`:

| flat          | front litpale_share | front width_px |
|---------------|---------------------|----------------|
| 0.58 shipped  | 0.0401              | 196            |
| 0.74          | 0.0329              | 196            |
| 0.88          | 0.0296              | 196            |

**Deeper is worse from the front, monotonically, and the front silhouette does
not move one pixel at any value.** I laid the three front renders side by side
and looked: they are indistinguishable. The reason is structural, not a matter
of finding the right number - the bag is wide in X and banded in Z, so from the
front the viewer sees the band EDGES nearly tangent to the view direction. They
take grazing light whatever their depth, and added depth is added self-shadow.

**Option (a) cannot work and is struck.** The knob stays in the file at its
original default - pass 5's geometry exactly - so the next seat inherits the
failed experiment and not only the conclusion.

## THE FIX THAT SHIPPED - THE TALLY BOARD

Option (b): give the front its own face carrying the same count. Not a dial,
not a needle, nothing with an instrument's manners on it. **A tally board hung
on the two straps already crossing his chest**, pale hide because it is OFF the
bag, with **eight dark rungs - one per band of the bag**. A man who works a
bellows all day and must know how many strokes are left marks them where he can
see them, and that puts them facing whoever is standing in front of him.

Sized off the torso rather than guessed: the torso limb runs r0.340 at z0.72 to
r0.272 at z1.38, so its front surface at the board's height is y -0.327. The
board's back face sits at -0.303, inside that surface, so it is stitched on and
not floating; its front face stands 0.030 proud. The straps pass at x
+-0.18..0.235 over this height, so a board 0.240 wide hangs between them and
touches neither.

| view  | litpale_share      | litpale_central    | outer_share |
|-------|--------------------|--------------------|-------------|
| front | 0.0401 -> **0.0636** | 0.1607 -> **0.4710** | 0.4138 (unchanged) |
| side  | 0.1197 -> 0.1253   | 0.4174 -> 0.3948   | 0.2805 -> 0.2879 |
| back  | 0.1808 -> **0.1808** | 0.5733 -> **0.5733** | 0.4161 (unchanged) |

The back is **byte-for-byte the same number**, which is the check that matters:
nothing pale was added aft, which is the exact fault the back-lamp guard exists
to catch. `outer_share` front is unchanged to four places because the board is
inside the outline - **this pass fixes a READ, not a silhouette**, and the
numbers say so rather than me saying so.

## THE FIRST PLACEMENT WAS WRONG AND NO NUMBER COULD HAVE TOLD ME

At the first attempt the board sat at z1.200 with a dark lug across its **top**.
Every number it produced was an improvement - front share 0.0710, front central
0.5258, both better than what shipped. **The picture was worse.** The lug sat a
tenth of a unit under the two eyes and spanned the same width, so the front view
read as a FACE: two eyes, a wide banded grin beneath them, the board a bib under
the chin. That is the Beadle's lesson wearing a new costume, and `_bagfacing.py`
is blind to it by construction, because a misread is not a quantity.

Fixed in the same pass, as a defect in my own new work: the board drops to
z1.090, loses 0.04 of height so it does not ride onto the hip, and **the top lug
is gone** - only the foot lug remains, which is the one that reads as a board
hung on strapping rather than as a jaw. The A/B of all three states is committed
at `renders/art/minibosses/blower/_p6_gauge_ab.png` (pass 5 / first placement /
shipped) and I looked at it before committing.

## WHAT I CAN STILL SEE WRONG, AND I AM NOT HIDING ANY OF IT

1. **The board's foot and the nozzle mouth are two pale masses close together
   on the lower right of the front view.** At stream distance they may merge
   into one pale blob. This is the most likely next fault and it is the first
   thing the next pass should look at.
2. The foot lug does almost no work - it is dark on dark and barely visible.
3. The rungs read as "a banded pale panel", which is a count, but they are not
   unmistakably a *fill level*; the board says HOW MANY, not HOW FULL.
4. The board is flat and frontal, so it foreshortens away at a 3/4 angle; only
   the front, side and back were rendered and judged.
5. Gap between the hood and the board's top edge is tight - the grin is gone,
   but the board still sits high.

## GATES

- `minibossfit` register `_fit_report.json`: **GREEN**, ok true, errors [],
  blind_views [], unproved_cells [], stale_margin [], red_summary.rows [],
  blank_check 3 files / **0 failures**, min_proving 2, 48 rows.
- `_backlamp_guard`: **GREEN**, audited 46, red [], errors 0.
- `minibossgen`: ok true, blower CORRIDOR-SAFE / UNDER-LID, span 1.88 m.

## WIRING - THE GAME BUILD LANE'S, NOT MINE

`assets/monsters/minibosses/blower.glb` is rebuilt by this pass. It is still
**static**, so `scripts/bestiary.gd` needs a `model` path and **no `anims`
entry**. Nothing else changed shape, scale or footprint: the authored height is
unchanged at 2.48 and the measured span is unchanged at 1.88 m, so **any fit
ratio or draw row already derived for the Blower stays correct** and does not
need re-deriving.

If a LIVE fill is ever wanted on that board - rungs lighting up as the count
runs - it needs a material or mesh the engine can drive, which a static glb
does not carry. The board is emitted in its own named span (`gauge`) so it can
be found. That is a decision for the game build lane; the body does not depend
on it and reads as a count either way.
