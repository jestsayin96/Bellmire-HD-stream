# THE TOWN SQUARE WELL, TIERS 1-3 - AND THE FOUR THINGS I GOT WRONG GETTING HERE

28 Nov 2026, 00:34-01:2x CT. Art lane. Generator `tools/art/townbuild.py`,
harness `tools/art/townbuildgen.py`, probe `tools/art/_townwell_probe.py`,
body measurement `tools/art/_townhero_measure.py`.
Report `renders/art/town/_report.json`. Picture
`renders/art/town/_tiers_side_by_side.png`.

## THE ROW
Plan `TAKE THIS NEXT`, ART (:34), unchanged for three hours: **town building
assets for the progression tiers** - the tier-1/2/3 variants of ONE building,
the town square's well -> fountain of Systems 15-17, proven to fit the way gear
is proven. Priority order town-first is sup-nov27-2304, Mr. E direct: *"The town
is what viewers SEE on stream 24/7."*

## WHAT I CHECKED FOR FIRST - MEASURED, NOT REMEMBERED
1. **`assets/` holds no well and no fountain.** Walked the tree: three icon
   PNGs carry the word `wellhead` (`banner_wellhead`, `wellkeep_coif`,
   `wellhead_ring`) and that is the whole of it. `assets/buildings` held 12
   files before this run - eight `lm_*` and four `mk_house_*`.
2. **A well exists in two packs and BOTH ARE IMPORT-GATED.**
   `low-poly_RPG_item_collection_3\well.obj` is in ASSET_SOURCES with **NO
   LICENCE FILE FOUND** and terms "not established".
   `modular_village_collection` holds five - `Prop_Well_{1,Cobblestone,Dirt,
   Grass,Inside}.obj` - and it is in the 20 Nov gated list. **I did not take the
   gate's word for it: I walked that folder myself this run. 147 files, ZERO
   text files of any kind** - no LICENSE, no README, nothing that could carry
   terms. ASSET_SOURCES already warns that the filename test errs in BOTH
   directions, so a pack with no `LICENSE` can still be licensed; here there is
   no file at all, so there is nothing to read and it stays gated.
3. **The one cleared town-square candidate was measured and LOOKED AT, then
   rejected on READ.** See below.

## THE KENNEY FOUNTAIN IS CLEARED AND IT IS STILL THE WRONG OBJECT
Kenney Fantasy Town Kit 2.0, CC0 1.0, licence read off disk 24 Nov
(ASSET_SOURCES line 803). It has ten `fountain-*` pieces and no well. Measured
off the evaluated depsgraph (`_townwell_probe.py`, verdict GREEN, 0 blanks,
border 0, subject proven seen at 32,866 px moved):

| piece | dims (m) | height vs a 1.80 bar |
|---|---|---|
| `fountain-round` | 2.00 x 2.00 x **0.28** | 16% |
| `fountain-round-detail` | 2.00 x 2.00 x **0.48** | 27% |
| `fountain-square` | 2.00 x 2.00 x 0.46 | 25% |
| `fountain-center` | 1.00 x 1.00 x 0.14 | 8% |
| `fountain-edge` | 1.00 x 1.00 x 0.28 | 16% |

**They are FLOOR TILES for a 2 m grid, not a town-square fountain** - ankle to
knee on the bar in that sheet. A fountain the stream cannot see cannot carry
"the town levelled up", which is the whole point of the item. **REJECTED ON
READ, NOT ON LICENCE** - the pack is cleared and stays available for the roads,
walls and stalls it is actually for.

So tier 3 could have been pack-derived and is not; tiers 1 and 2 could not be,
because **no cleared pack on this machine holds a well at all.**

## FOUR FAULTS OF MY OWN, REPORTED BEFORE THE DELIVERABLE

**(1) I SIZED THE WELL FOR A MAN AND THE BODY IS NOT A MAN.** The first draft
used a 0.76 coping off a remembered "1.8 m hero". Measuring `Knight.glb`:
hips 0.3916, chest 0.9586, head bone 1.2274 - agreeing with `scripts/gear.gd`
to two decimals. On that body 0.76 is above the torso top and the well would
have read as a water tank. Caught before a single render.

**(2) THEN I READ MY OWN MEASUREMENT WRONG AND SAID THE FIGURE IS 1.30 TALL.**
It is not. gear.gd's "body top 1.30" is the TORSO - mesh `Knight_Body` measures
z 0.363-1.279. Above it sit `Knight_Head` (z 1.202-2.301) and `Knight_Helmet`
(z 1.101-**2.453**). **The adventurer stands 2.45 with the helmet**; the 2.45 in
`_d96fix_sheet.py` was right all along and my reading of it was the suspect.
The mesh names corrected me, not a gate. The well did not change again, and the
reason is worth writing down: **interaction heights come off BONES** (hips 0.39
sets a coping a man leans on; hands at 0.73 must reach it) and the head does not
touch those, while **silhouette comes off the whole 2.45 figure**, which is why
the tier-2 ridge sits at 2.08.

**(3) MY HERO-REFERENCE GATE PASSED ON THE WRONG OBJECT.** `Knight.glb` holds
16 meshes and they are not one body: eight `Knight_*` parts plus `1H_Sword`,
`1H_Sword_Offhand`, `2H_Sword`, four shields and an `Icosphere` spanning
z -1.0..+1.0 - loose equipment variants stacked in one file. (That stack is also
why the file's AABB reads 3.45 tall when the figure is 2.45.) My substring
filter kept them. A sword and a shield hung in the air at the right of the first
sheet, the camera had to frame them, and **the three wells came out at 15% of
the frame width - the acceptance test is "the progression reads at a glance" and
the sheet failed it while every gate was GREEN.** `hero_moved_px` read
20,000-37,000 across all twelve views and it was measuring floating equipment.
*** A with/without difference proves SOMETHING moved. It never proves it was the
thing you named. *** Fixed by whitelisting the eight parts by exact name. The
same pass fixed a second bug it hid: the meshes are parented to the armature and
I was translating both, displacing every child twice. After the fix the sheet's
subject pixels went **16,016 -> 164,125**.

**(4) A GREEN SHEET SHOWED A WELL THAT WAS NO LONGER A WELL.** Tier 1's wear
term was `jitter=0.16`. The height arm of that term (`jitter * 1.8`) swings a
0.42 course between 0.13 and 0.71, and the ring came out **a heap of rubble** -
with two poles and a bucket hanging over it the whole thing read as a gibbet.
Every gate was GREEN over it, because **no gate I have asks "is this still a
well"**. Only looking asks that. 0.065 keeps the course visibly hand-laid and
the mouth legible, which is the difference between make-do and derelict.

## WHAT SHIPPED
Three meshes, one family, authored procedurally (and therefore original work):

| key | title | dims (m) | base_dz | verts | glb |
|---|---|---|---|---|---|
| `well_t1` | The Well | 1.54 x 1.89 x 1.72 | **-0.26** | 428 | `assets/buildings/town_well_t1.glb` |
| `well_t2` | The Well Kept | 2.09 x 2.09 x 2.42 | **-0.30** | 864 | `assets/buildings/town_well_t2.glb` |
| `well_t3` | The Fountain | 2.52 x 2.52 x 1.64 | 0.00 | 899 | `assets/buildings/town_well_t3.glb` |

**WEAR IS THE SPEC, NOT A STYLE** (Mr. E, art rule 2). Every difference between
the three is a CONDITION difference driven by `tier` off one shared footprint:
- **t1** dry-laid, **two stones gone from the course**, poles crooked and
  barked, a branch for a crossbeam **lashed with rope because there is no
  iron**, a bucket with one hoop slipped, two warped lid planks that do not
  meet, and the fallen stones left where they fell. Nothing here was bought.
- **t2** coursed and capped with dressed stone, posts squared and plumb and
  **iron-strapped**, a windlass with a cranked handle instead of hand over hand,
  a shingled gable, a sound two-hoop bucket, a cobbled apron.
- **t3** dressed ashlar at **zero jitter** - a fountain that wobbles reads as a
  wall somebody stacked - two kerb steps, a basin cap at 0.43 just over the hip
  bone so the town can SIT on it, a carved column, four bronze spouts, water.

**THE PIVOT CONTRACT, AND THE ONE NUMBER THE GAME BUILD MUST NOT MISREAD.**
All three put the well ring concentric with the pivot at (0,0), ground at z=0,
so the mesh can be swapped at a single unmoved spawn point. **`base_dz_m` is
-0.26 and -0.30 on t1 and t2 and that is DELIBERATE, not a sinker fault** - it
is the shaft lining, which belongs below ground. Per WORLDFIT the sign is half
the instruction: do NOT apply a base offset to these two, or the lining comes up
out of the pavement. `centre_dx_dy` on t1 reads (-0.098, -0.028); that is the
AABB centre pulled off by the scattered spoil stones, which are deliberately
one-sided. The RING is on the pivot in all three.

## THE FIT PROOF - I LOOKED, AND HERE IS EVERY FAULT I CAN SEE
Twelve views (front / three-quarter / side / back per tier) on a ground plane
with the measured Knight beside them, plus the three tiers side by side through
ONE camera at ONE ortho scale. Verdict **GREEN**: 0 blanks, **border alpha 0 on
all 13 frames**, subject proven seen in every frame by ablation (7,926-21,353 px
moved), hero proven seen separately (10,849-38,233), labels all inked.

**The progression reads at a glance** - low grey make-do, then roofed timber,
then a pale tiered fountain with jets - and the scale against the 2.45 figure is
right. Silhouettes 25,557 / 52,728 / 47,745 px. **Note t3 is SMALLER than t2 in
pixels and the progression still reads**, because t3 grows in WIDTH (367 px vs
304) and brightness rather than height. A monotone pixel count was never the
test.

Faults, worst first, none of them hidden:
1. **t3's basin water cannot be seen from any view.** The disc sits at 0.385
   under a cap at 0.43 and the camera never gets under it. *** The one element
   that says "fountain" has real pixels the viewer never sees - this is the
   `head_glow_px: 156` fault in a new costume, found in my own new work.***
2. **t3's four water arcs read as pale struts, not water** - too thick, too
   straight, fully opaque. They look like a tent frame.
3. **t2's barge boards project past the shingles** as two spars either side of
   the roof. Plain modelling error: 1.46 long against a 1.18 roof.
4. **t1's mouth is still not clearly legible** at 3/4 - a 0.42 coping against a
   2.45 figure is low, and the lid planks flatten what is left.
5. **t1's poles, beam and hanging bucket still read slightly gallows-like.**
6. **t2's windlass is hidden behind the roof**; only the crank stub shows.
7. **t2's cobble apron reads as scattered loose tiles**, not paving - 20 stones
   of 0.24 on a 5.78 circumference leaves visible gaps.
8. **t3's bronze finial reads as a party hat.**
9. **Colour is doing almost no work in the tier read; shape carries all of it.**
   Stone 0.33 at t1 against 0.68 at t3 does not separate under this light as
   much as intended. If wear is the receipt, the receipt should be legible in
   VALUE too.

## WHAT THE GAME BUILD LANE MUST DO - I DO NOT DO IT MYSELF
Nothing is wired. The three `.glb` are in `assets/buildings/` and nothing
references them. The wiring is **one spawn point and a tier index**, and it is
the game build's to write because every candidate file is theirs.
- The three meshes are drop-in swaps at ONE transform. Do **not** apply a base
  offset to `town_well_t1.glb` or `town_well_t2.glb`; their negative `base_dz_m`
  is the shaft lining and is intended to sit below the ground plane.
- They are **static**: a `model` path and no `anims` entry.
- The layout format does not exist yet and the plan row says explicitly not to
  wait for it. A building authored against no layout is still a building.
