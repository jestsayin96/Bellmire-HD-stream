# The legendary dagger's last red: it was FACING, not SIZE - and my own search threw the fix away before printing it

ART lane, 27 Nov 2026, 18:35 - 18:5x CT (machine clock, `TZ=America/Chicago date`).
Branch `art`. Nothing outside `tools/art/`, `docs/art/` and `renders/art/` was touched.

## The row I was given

The 17:58 team lead row ticked the ART item and refused to call the register green,
on exactly one residual:

```
blind_views: ["dagger: only 1 of 3 views show the weapon"]
```

with the instruction: *"APPLY YOUR OWN PRESCRIBED `hand_scale` 0.5 -> ~0.75 FOR THE
DAGGER IN YOUR OWN HARNESS, RE-PROVE, AND GET `blind_views` TO 0"*, and
**DO NOT EDIT `gear.gd`**.

I did re-prove it, and **my own prescription of 0.75 was wrong.** The register is now
`verdict: "GREEN"`, `blind_views: []`, by a different and smaller change.

## First: `hand_scale` is not mine to set, and I did not set it

`_t5_rxproof.py` takes `hand_scale` from `GC.carry()`, which READS the real branches of
`gear.gd::hand_scale` - the golden dagger's arm is `gear.gd:305-306`,
`if path.begins_with(ART + "dagger_"): return 0.5`. That file is the GAME BUILD's.
What I changed is the **prescription** my harness proves, which is what this tool has
always existed to prove (it already prescribes `held_rot` triples the engine does not
ship either). The engine half is routed below and I did not touch it.

## What I measured, in order, including the two answers I got wrong

**1. `_t5_dagread` - scale sweep plus a grid search.** The scale arm works on the
numbers: `hand_scale` 0.70 is the smallest that clears `WF.VIS_MIN` on two views
(front 1011 px against a 900 px floor), 0.75 gives front 1159. It also reported
"1 distinct geometry on the 90-degree grid", from which **I concluded a front-facing
carry was not reachable. That conclusion was wrong.**

**2. I looked at the 0.75 render, and the picture refused the number.**
`renders/art/gear_t5/_rx/_dagread/cells/dagger_pres_hs075_front.png`: the blade is
**still a gold hairline**, now a 1.04 m one. `WF.VIS_MIN`'s own comment says 900 px
means *"about 30x30"* - it assumes a **compact** shape. 1,159 pixels smeared down an
18-px-wide line passes a gate that was never meant to pass it. **My `vis` gate can be
cleared by a lath, and my `show` gate cannot catch it, because `show` is
scale-invariant: `best_minor` and `mid_px` grow together.** Applying 0.75 would have
quieted the gate without fixing the picture - and it would have cost the object, since
`gear.gd:304` records the .blend at 1.39 m and chose 0.5 to put it *"at a long knife"*.
1.04 m is a short sword.

**3. `_t5_dagyaw` - 36 candidates, 0 clean.** This also corrected my framing: in the
`(-90, y, z)` family **the z term is the STAND-UP term, not a facing term** - at z=0 the
blade lies flat at hang 89.9 deg, a lance. The four grid triples `_t5_dagread` found are
one placement, not four, because once x is -90 the y and z terms both act about the
vertical and all four sum to yaw 90.

**4. `_t5_dagcensus` - no filtering at all, and this is where my own fault is.**
All 64 grid triples, nothing discarded: **24 stand the blade upright and EIGHT put the
broad 0.2972 m axis along world X**, the face the front and back cameras see. The best,
**`(0, 0, 90)`**, misses the clip ceiling by **1.4 points - `clip_frac` 0.384 against
0.370**. `_t5_dagread` stage 1 filtered on that ceiling *before printing anything*, so it
reported "does not exist" when the truth was "I did not look at it". **A search that
discards a candidate silently cannot tell you the difference between absence and your
own filter.** That is the worst thing in this run and it is mine.

**5. `_t5_dagface` - the combination neither earlier tool tried.** `clip_frac` FALLS as
the weapon grows (0.352 at 0.50, 0.289 at 0.75). So: face-front **and** a modest bump.

## The prescription, and what it costs

**`held_rot (0, 0, 90)` at `hand_scale 0.60`** - and `(0,0,90)` is the triple `gear.gd`
already ships for the bow, the one cell the team lead confirmed correct by eye.

Measured on the posed knight, same shipped gates as `artifactfit`:

| | shipped 0.5, `(-90,0,90)` | scale arm 0.75 | **prescribed `(0,0,90)` @ 0.60** |
|---|---|---|---|
| `vis` front / side / back | 403 / 957 / 190 | 1159 / 2657 / 565 | **1598 / 567 / 1219** |
| proving views (need 2) | 1 | 2 | **2** |
| front `minor` | 13 px (edge-on) | 18 px | **38 px (the face)** |
| `clip_frac` (ceiling 0.37) | 0.352 | 0.289 | **0.346** |
| hang / ground / border | 0.1 / 0 / 0.000 | 0.1 / 0 / 0.000 | **0.1 / 0 / 0.000** |
| `show` (floor 0.70) | 1.077 | 1.032 | **1.066** |
| blade length | 0.695 m | **1.042 m** | **0.834 m** |
| reads as a dagger? | no - a hairline | **no - a long hairline** | **yes** |

**THE COST, SAID OUT LOUD: 0.834 m against 0.695 m shipped**, which is longer than the
pack daggers at their own shipped scale. I looked at the render and it still reads as a
knife - leaf blade, pommel below the fist, tip below the chin - which 0.75 does not.
**`(0,0,90)` @ 0.55 also passes at 0.764 m**, but leaves the back view 929 px against a
900 px floor - 3% of margin on a gate that is re-run every hour. I took 0.60 for the
margin. **Both renders are on disk and Mr. E can overrule the length by looking:**
`renders/art/gear_t5/_rx/_dagface/cells/dagger_f+000+000+090_hs055_front.png` and
`..._hs060_front.png`.

The side view now sees the edge and does not prove. Two of three is what
`WF.MIN_PROVING` asks, and the two that prove are the two a viewer sees most.

## A SECOND FAULT, FOUND BY LOOKING AT THE SHEET: the contact sheet's ROWS WERE REVERSED

With the register green I looked at `_sheets/rx_front.png` and the top row had 3 figures
and the bottom row 5 - the reverse of the `order=axe,bow,crossbow,...` the tool prints
beside it. **The 13th cell was sitting where the 1st was named.**

`WF.read_png` reshapes `im.pixels` with **no flip**, and Blender's buffer is BOTTOM-UP,
so cell arrays are bottom-up; the sheet buffer goes straight back into `im.pixels`, also
bottom-up, so the CELLS came out upright while `divmod`'s row index counted from the top.
My 17:52 note in that file explained the earlier upside-down fix with the sentence
*"WF.render_to already returns a TOP-DOWN array"* - **that sentence is false**, and
believing it is why I never looked for the row order. The earlier fix got upright cells
for the right reason by accident.

**No gate number moved and no verdict was ever wrong** - every metric is computed on the
cell arrays, not the sheet. But the sheet is the one artefact a human LOOKS at, and a
picture that maps the wrong weapon to the wrong name is worse than a wrong number,
because it is the thing that is supposed to overrule the numbers. Fixed by inverting the
row index where the bug is; the false explanation is kept in the file, struck, because it
is the reason the bug lived. `_t5_resheet.py` already had the honest idiom.

## Register state

`renders/art/gear_t5/_rx/_t5_rxproof.json`: `verdict: "GREEN"`, `ok: true`, 13 cells,
`blind_views []`, `blanks []`, `frame_clips []`, `laths []`, `floor_breaks []`,
`lances []`, `errors []`.

**A GREEN VERDICT HERE IS A PROOF OF THE PRESCRIPTION, NOT OF WHAT THE GAME SHIPS.**
The register now carries `engine_hand_scale` and `engine_held_rot_deg` per cell and a
top-level **`engine_delta`** listing every line `gear.gd` must change, emitted green or
red, so no seat can read this as "the engine carries it this way today". It does not.

## WIRING OWED BY THE GAME BUILD LANE - `scripts/gear.gd`, I did not touch it

The full list is in `_t5_rxproof.json.engine_delta`. The dagger is the only one that
changed this run; the other 11 `held_rot` rows are the tier-5 engine half already routed.

1. `gear.gd` `held_rot` - add an arm for `ART + "dagger_"` returning
   `Vector3(0, 0, 90)`. It ships `Vector3.ZERO` today (the default arm).
2. `gear.gd:305-306` `hand_scale` - `if path.begins_with(ART + "dagger_"): return 0.5`
   becomes **`return 0.60`**.

Both are needed together: the rotation without the scale leaves the blade small, and the
scale without the rotation is the hairline this run rejected.

## Also owed, small, unchanged

`assets/monsters/minibosses/snarer_chibi.glb` is still committed with no `.glb.import`
sibling. **My answer: it is not wanted.** The game build loads the base `snarer.glb` and
is not blocked either way; nothing references the chibi. It can be left or dropped - I
have not deleted it.
