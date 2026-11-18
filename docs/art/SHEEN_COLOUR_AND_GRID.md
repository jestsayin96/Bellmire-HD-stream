# THE CREAM-PAINTED BOARD. TWO CAUSES, BOTH FIXED, AND THE FAULT IS NOT CURED.

Run 2026-11-18 00:34-01:0x CT (clock read off the machine), art lane.
Asked for by the team lead's 23:58 ART row: *"THE SIDE-VIEW LEAF THAT GOES
NEAR-WHITE AND READS AS A CREAM-PAINTED BOARD ... the A/B has just told you the
remedy is in the material or the paint, not in the grade. START THERE."*

## WHAT I CHECKED FOR FIRST, BY MEASURING

Before building anything: the view-transform A/B (ticked, `art c5acf79`) had
already killed the grade route and located the fault in the pass-10 vertex
paint. I re-read that table and `_metal_read_greener.json` off the tree rather
than from the row, and **the drift control came first**: the shipped arm of this
run reproduces pass 10 to every decimal (front 0.5287 / side 0.3091 / back
0.5405). Nothing had moved under me, so every number below is comparable with
the ones already in the plan.

**ONE CORRECTION TO THE ROW, AND IT IS SMALL.** The row says the paint costs
*"0.26 of saturation on that view alone"*, taking 0.5652 as the side's unpainted
value. 0.5652 is the **front** flat control. The **side** flat is 0.5312, so the
side-view paint cost was **0.222**, not 0.26. The direction and the conclusion
are unaffected and the row was right to send me here.

## WHAT THE PREVIOUS RUN GOT WRONG, AND IT WAS MINE

The 23:35 run framed this as a **binary** - paint ON (body_sat collapses) against
paint OFF (hilite_desat regresses below the oak control, which is the pass-5
state the whole history was escaping) - and refused to settle it, saying the
choice belonged with the fault's history.

**THE BINARY IS FALSE.** The band is not a switch. Its colour is a parameter, and
the shipped value was the one thing in the ramp nobody had ever measured an
alternative for. There is a setting where **both** numbers are acceptable, and
this run found it by sweeping rather than by arguing.

## CAUSE 1 - THE BAND WAS PAINTED WITH A DIELECTRIC'S HIGHLIGHT

`COPPER_SHEEN` was `(1.000, 0.880, 0.820)`: authored saturation **0.180**, very
nearly a chalk wash, and `SHEEN_MAX` drives 86% of the way from the leaf body's
0.765 toward it. But **copper is a conductor**. A dielectric's highlight carries
the light's colour and runs to white; a metal's carries the light's colour times
its own reflectance and runs to its own tint. The leaves were being painted with
the wrong physics - the same class of error as the metallic dial.

The new value has **no number of mine in it**: it is `_metal_read.CTRL['copper']`,
`(0.955, 0.637, 0.538)` - the measured reflectance of Cu this repo already uses
as its physics control - normalised to a peak of 1.0, giving
`(1.000, 0.6670, 0.5634)`, authored saturation 0.437.

Four arms, `_sheen_ab.py`, three views, against a matte oak and against the
shipped material with the paint taken off. **body_sat, side view:**

| arm | sheen rgb | sheen sat | side body_sat | side cream_share | side hilite_desat |
|---|---|---|---|---|---|
| ship | 1.000 0.880 0.820 | 0.180 | 0.3091 | 0.4206 | 0.3086 |
| pale | 1.000 0.800 0.715 | 0.285 | 0.3478 | 0.3695 | 0.2951 |
| warm | 1.000 0.735 0.640 | 0.360 | 0.3889 | 0.3234 | 0.2862 |
| **cu** | **1.000 0.667 0.563** | **0.437** | **0.4308** | **0.2920** | **0.2783** |
| *matte oak control* | - | - | *0.5000* | *0.0075* | *0.1603* |
| *unpainted control* | - | - | *0.5312* | *0.0028* | *0.2173* |

Monotone the whole way, and **nothing regresses**: at `cu` the highlight
desaturation is still 0.2783, above the oak control **and** above the unpainted
material. The band still does the job it was baked for.

`cream_share` is a new number and it is the only one here that asks the
**viewer's** question: the share of visible copper pixels that are **bright and
colourless at once** - above the median luminance and under 0.25 saturation. A
cream-painted board is exactly that conjunction; neither half alone is the
fault. 0.25 is stated so it can be checked - every surface in this test's
vocabulary sits above it.

## CAUSE 2 - THE PICTURE FOUND IT AND NO NUMBER IN THAT TABLE ASKS ABOUT IT

With the colour fixed I cropped the side view at 4x and looked. **The band was
still a hard-edged vertical stripe.** A sheen with square corners is not a
sheen, it is a drip of paint, and no hue fixes that.

The cause is arithmetic, not taste. Vertex colours are interpolated across
faces, so on `_leaf`'s **4 x 5 grid the entire falloff has to be carried by five
columns**. `_smooth` was being sampled too coarsely to be seen. The ramp's maths
was never the problem.

`_sheen_grid_ab.py`, band colour held at `cu`, tessellation swept:

| arm | verts/leaf | side body_sat | front body_sat | back body_sat |
|---|---|---|---|---|
| 4x5 (shipped) | 60 | 0.4308 | 0.5323 | 0.5405 |
| **8x10** | **198** | **0.4930** | **0.5345** | **0.5378** |
| 14x18 | 570 | 0.4926 | 0.5357 | 0.5378 |

**THE METRIC SATURATES AT 8x10 AND THAT SATURATION IS THE EVIDENCE THE CAUSE WAS
SAMPLING.** 14x18 buys 0.0004 for 2850 vertices against 990. 8x10 ships.

**THE SILHOUETTE DOES NOT MOVE, AND THAT IS ASSERTED AND NOT ASSUMED.** Every
vertex still lies on the same analytic bowed surface, and the body's world
bounds are **identical across all three arms to 1e-6**. An arm that moved the
outline would be a different body wearing the same argument, and the harness
goes red on it.

## WHAT THE REGISTER'S OWN INSTRUMENT SAYS ABOUT THE SHIPPED BYTES

`greener.glb` regenerated, then `_metal_read.py` re-run on it. Two instruments,
built separately, agree to the decimal (side 0.4930 both) - which is the
drift control that makes the table above worth anything.

| view | body_sat before | **after** | hue_retention before | **after** | hilite_desat after | oak | unpainted |
|---|---|---|---|---|---|---|---|
| front | 0.5287 | **0.5345** | 0.6912 | **0.6987** | 0.3780 | 0.2157 | 0.2533 |
| side | 0.3091 | **0.4930** | 0.4040 | **0.6444** | 0.2754 | 0.1568 | 0.2154 |
| back | 0.5405 | **0.5378** | 0.7066 | **0.7030** | 0.3301 | 0.0934 | 0.1073 |

The side view recovers **83% of the paint's saturation cost** (0.3091 -> 0.4930
against an unpainted ceiling of 0.5276) and its hue retention goes 0.404 ->
0.644, which closes most of the gap to the front and back. **The back view gives
back 0.0027 of body_sat and 0.0036 of hue retention.** That is a regression, it
is tiny, and it is written here rather than left out.

## THE VERDICT IS STILL `ok: false` AND IT SHOULD BE

`_metal_read` still returns **PAINTED - NOT EARNED AS REFLECTION** on all three
views, because the span is vertex-painted and a painted stripe satisfies
"the bright end runs whiter than the body" by construction. **Nothing here is a
pass and I am not reporting one.** What moved is the diagnostic the fault was
actually about.

## I LOOKED AT IT, AND THE FAULT IS IMPROVED, NOT CURED

`renders/art/minibosses/_sheen_ab_sheet.png` (4 colour arms x 3 views) and
`_sheen_grid_sheet.png` (3 grid arms x 3 views). 0 blanks, 0 frame clips,
border alpha **0.000 on all 21 tiles**.

**THE HONEST SENTENCE: A VIEWER WOULD STILL CALL THOSE SHEETS TIMBER.** They are
warmer and the stripe is now a gradient instead of a slab, but the surface has
not changed its name. Mr. E's eye is the bar and I am not going to claim it has
been met.

What I can see on the shipped body, said as a list:
1. The leaves read as **pale tan planks** in all three views. Better, not fixed.
2. The band's **lower boundary is still ragged** at 8x10 and at 14x18 alike. It
   is NOT the grid: it is the **overlap edge** where the sheet in front occludes
   the one behind, aliased at this render size. Finer tessellation makes it
   finer teeth, not a clean edge.
3. The leaves' **top edge is castellated** and reads as a comb rather than a
   hanging sheet, from the front especially.
4. The **chest slab** is a flat grey plate with almost no shading variation
   across it - the largest dead area on the body.
5. From the **side** the creature reads as a dark L: the head all but vanishes
   against the body, and the scraper pole crosses it.
6. From the **back** the rack hides the head entirely - a screen on legs.
7. The **ember bed** is the brightest thing in every view and pulls the eye off
   the creature.

Items 3-7 are form, not paint, and none of them is what this run was given.
They are named so the next seat does not have to find them again.

## HARNESS GUARDS THAT WOULD HAVE CAUGHT ME

- **two arms with identical vertex colours are an ERROR.** A sweep whose arms do
  not differ measures one thing N times and reads green. Hashed per arm.
- **the control is proved paint-blind rather than assumed.** `ctrl_flat` is
  measured on the first arm AND on the last and the two must agree; every margin
  in the colour table is taken against it, and the A/B had assumed that without
  testing it. It agreed to every decimal in all three views.
- **`SLOT_RGB` is read AFTER the probe merge**, because `merge_objs` fills it.
  Read before, it returns nothing and every hue_retention would be divided by
  white - a silent 1.0 denominator instead of an error. It is red now.
- the paint is proved to have reached the mesh (`vcol_items_painted` 5 of 5)
  before any number is believed, and the metric functions are **imported** by the
  grid sweep from the colour sweep rather than copied, because two readers in
  this tree each kept a private copy of a statistic and they drifted.
