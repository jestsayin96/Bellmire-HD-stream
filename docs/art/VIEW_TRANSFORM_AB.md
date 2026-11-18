# THE VIEW-TRANSFORM A/B. ONE BODY, THREE TRANSFORMS, AND IT KILLS THE CANDIDATE.

Run 2026-11-17 23:35-23:42 CT (clock off the machine), art lane.
Asked for by the team lead's 22:58 ART row and by FOR THE SUPERVISOR item 1.

## WHAT WAS ASKED, AND WHAT I CHANGED (NOTHING)

A bounded A/B on ONE body - the Greener - front, side and back, under Standard
and under Khronos PBR Neutral, measuring shipped `body_sat` against the
matte-oak control exactly as pass 10 measured it. **No default was changed.**
`lordgen.set_engine` is untouched; the register still renders under Blender's
default AgX. The transform is an argument of `tools/art/_metal_read.py` and of
nothing else, it is **proved by readback before a pixel is read**, and a
transform that will not apply is an ERROR, never a silent fall back with the
label kept.

## THE DRIFT CONTROL CAME FIRST AND IT IS CLEAN

Before comparing anything I re-ran the shipped AgX read. It reproduces pass 10
to every decimal place - body_sat 0.5287356 / 0.3090909 / 0.5405405, controls
0.5517241 / 0.5000000 / 0.4657534. The rig has not drifted, so every number
below is comparable with the ones already in the plan.

## THE FAULT IN THE FIRST TABLE, FOUND BY ME, AND WHY THERE ARE FOUR COLUMNS

The first sweep compared **a vertex-painted surface against two unpainted
controls**. Both controls are built with `mat_solid`, which carries no vertex
colour; the shipped leaf has carried pass 10's baked sheen band since 18 Nov.
That band is near-white, so it DRAGS `body_sat` DOWN - on a metric about
saturation that is not a detail, it is the measurement.

So a third control was added: **`ctrl_flat`, the shipped material with the paint
taken off** - `(1.000, 0.520, 0.235)` rough 0.44 metal 0.06 spec 0.92, read off
`OVERRIDE['greener']['bone']` minus its fifth element. It is not a physics
control. It isolates what the TRANSFORM does from what the PAINT does.

## THE TABLE. body_sat, THE GREENER'S COPPER LEAVES.

| transform | view | shipped | flat (unpainted) | matte oak | copper | ship-oak | **flat-oak** |
|---|---|---|---|---|---|---|---|
| AgX (shipped) | front | 0.5287 | 0.5652 | 0.5517 | 0.2931 | -0.0230 | **+0.0135** |
| AgX | side | 0.3091 | 0.5312 | 0.5000 | 0.2857 | -0.1909 | **+0.0312** |
| AgX | back | 0.5405 | 0.5285 | 0.4658 | 0.2982 | +0.0748 | **+0.0627** |
| Standard | front | 0.4725 | 0.4844 | 0.4595 | 0.2581 | +0.0131 | **+0.0249** |
| Standard | side | 0.2623 | 0.4844 | 0.4314 | 0.2581 | -0.1691 | **+0.0530** |
| Standard | back | 0.4878 | 0.4839 | 0.4103 | 0.2581 | +0.0775 | **+0.0736** |
| Khronos PBR Neutral | front | 0.8730 | 0.9091 | 0.9643 | 0.6667 | -0.0913 | **-0.0552** |
| Khronos PBR Neutral | side | 0.7692 | 0.8644 | 0.9286 | 0.6667 | -0.1593 | **-0.0642** |
| Khronos PBR Neutral | back | 0.7238 | 0.6957 | 0.7727 | 0.6667 | -0.0489 | **-0.0771** |

The column that answers the decision is the last one: **is the copper more
saturated than a matte oak board, on the fair unpainted comparison.**

## THE VERDICT

**KHRONOS PBR NEUTRAL IS DEAD. It makes the fault WORSE in all three views.**
It does raise absolute saturation hard - the copper goes 0.5652 -> 0.9091 front
- but it raises **the oak control more** (0.5517 -> 0.9643, +0.413 against the
copper's +0.344). The copper goes from marginally ABOVE oak under AgX to BELOW
oak in every view. A transform that lifts the thing you are comparing against
faster than the thing you are measuring is not a fix. Do not approve it.

**STANDARD IS REAL BUT IT IS NOT WORTH THE RE-GRADE.** It moves the margin in
the right direction in all three views and roughly doubles it - +0.0135 ->
+0.0249 front, +0.0312 -> +0.0530 side, +0.0627 -> +0.0736 back. But the margin
is tiny under BOTH transforms. The purchase is **+0.011 of separation on the
front view**, on a diagnostic metric, against a cost of re-grading 25 miniboss
bodies, 8 lords, 12 creature bodies, every colour number the register has
measured and the D95 showcase - including numbers under already-ticked work in
three lanes. That trade does not pay.

**THE PREMISE WAS TRUE AND THE CONCLUSION DID NOT FOLLOW.** The plan's reasoning
- "AgX desaturates bright warm colour hard, so switching returns roughly half
the lost saturation" - is correct about ABSOLUTE saturation and was measured on
a flat patch. It does not survive a CONTROL, because the control rises with it.
Separation is a comparison, and the flat-patch measurement had nothing to
compare against. **That is the whole finding.**

`body_sat` is a diagnostic and not the pass axis - the axis is `hilite_desat`,
which is unchanged in character by any of this. Nothing here is a pass.

## THE PICTURE, AND I LOOKED AT IT

`renders/art/minibosses/_vt_look_sheet.png` - 9 tiles, rows AgX / Standard /
Khronos PBR Neutral, columns front / side / back. 0 blanks, 0 frame clips,
border alpha 0.000 on all nine. `tools/art/_vt_look.py`.

What the picture says, and it agrees with the table:
1. **The leaves are pale tan BOARDS in all nine tiles.** No transform changes
   the name a viewer gives that surface. The back view is a stack of planks
   under every one of the three.
2. **The biggest visible change in the whole sheet is not on the copper at all -
   it is on the EMBER.** Under Standard the charcoal bed goes from a muted
   salmon to a vivid orange. The transform's most visible effect lands on the
   emissive, which is the one thing nobody asked it to fix.
3. **PBR Neutral darkens the whole body** - leaves, verdigris and floor plates
   all duller and browner. It looks worse by eye, independently of the numbers.
4. The baked sheen band is visible as a **vertical stripe sitting in the same
   place on each sheet in every view**. That is the giveaway that it is painted
   and not reflected, which is what pass 10's harness said in words.

## THE SIDE-VIEW "CREAM-PAINTED BOARD" IS NOT A FORM FAULT. IT IS THE PASS-10 PAINT.

The 22:58 row handed me the near-white side-view leaf as a FORM fault. It is
not, and the flat control is the proof: under AgX the side view measures 0.3091
painted against **0.5312 unpainted**. The pass-10 vertex paint costs **0.222 of
saturation in the side view** - seven times its cost on the front (0.037) and it
reverses the sign against the oak control (+0.031 unpainted becomes -0.191
painted). The geometry is not what goes cream. The band is.

**I AM NOT WITHDRAWING THE PAINT THIS RUN, AND THE REASON IS A TRADE I SHOULD
NOT SETTLE ALONE.** Taking it off returns `body_sat` above the oak control in
all three views, and returns `hilite_desat` to 0.159 / 0.203 / 0.035 - BELOW the
matte-oak control at 0.214 / 0.160 / 0.095, which is where this fault was at
pass 5 and is the "painted timber said as a number" the whole pass history was
trying to escape. One number improves and the other regresses to a state already
rejected. Both numbers are on the table above and in `_metal_read_greener.json`;
the choice between them belongs with the fault's history, not with the end of
one run.

## INSTRUMENT FAULTS I FOUND IN MY OWN READER AND FIXED

1. **EVIDENCE COLLISION.** The tmp PNG names carried no transform, so the second
   and third runs silently overwrote the first run's pictures and only the
   numbers survived. On a lane whose rule is "the picture is the evidence and
   the number is the suspect", a reader that keeps the number and destroys the
   picture is the wrong way round. The transform is now in the evidence path.
2. **THE UNPAINTED CONTROL**, above - without it the A/B compares a painted
   surface against unpainted ones and every margin in it is wrong by an
   unquantified amount.
