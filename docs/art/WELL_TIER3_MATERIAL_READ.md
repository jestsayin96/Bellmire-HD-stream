# THE FOUNTAIN IS THE FLATTEST THING IN ITS OWN LADDER

**28 Nov 2026, 08:34-09:2x CT. Blender bridge DOWN for an eighth consecutive
run - no render and no git were possible. Everything below was measured on the
ALREADY-SHIPPED bytes with tools that need no Blender, and then LOOKED AT.**

## THE FINDING

The town-square well ladder (`assets/buildings/town_well_t1/t2/t3.glb`,
generated 06:50 CT) carries its tier progression in SHAPE but not in
MATERIAL. Measured off the shipped side-by-side sheet
`renders/art/town/_tiers_side_by_side.png`, per-tier:

| tier | title | chroma mean | chroma p90 | saturation | warm px % | value |
|------|-------|------------:|-----------:|-----------:|----------:|------:|
| t1 | The Well        |  5.3 | 12.0 | 0.044 |  4.6% | 124.4 |
| t2 | The Well Kept   | 23.2 | 45.0 | 0.174 | 52.3% | 129.9 |
| **t3** | **The Fountain** | **5.4** | **8.0** | **0.040** | **1.6%** | **152.8** |
| -- | HERO knight (ref) | 17.9 | 48.0 | 0.172 | 18.2% | 110.2 |

**The tier-3 Fountain is as colourless as the broken tier-1 well** - chroma
5.4 against 5.3, saturation 0.040 against 0.044 - and at 1.6% warm pixels it
is the LEAST warm object in the sheet, less warm than the grey steel knight
standing beside it. The ladder's material richness runs 5.3 -> 23.2 -> 5.4:
it rises at tier 2, where the timber roof and winch arrive, and collapses at
tier 3 back below tier 1.

The sheet's own caption claims of t3: `DRESSED ASHLAR. BRONZE SPOUTS. RUNNING
WATER.` **There is no bronze read on the spouts.** At 1.6% warm the only warm
pixels in the whole tier are the small finial at the apex. The four spouts
render as thin pale blue-grey arcs of uniform thickness; at stream distance
they read as wire legs rather than water.

## WHY THIS MATTERS MORE THAN A LOOKS NOTE

Mr. E's rule 2 is binding and this is now the spec of the priority-1 item:
*"a level 12 Bellmire is PROSPEROUS - fresh timber, cut stone, bright
banners... A viewer who spent months of points on a legendary piece must not
get something second-hand. Condition is the RECEIPT for what viewers paid
for."*

The Fountain is the TOP of the town square ladder - the thing viewers spend
months of points to reach - and it measures as the palest, flattest object in
its own contact sheet. The receipt is not legible.

## THE STRUCTURAL CAUSE, MEASURED FROM THE SHIPPED BYTES

`tools/art/_glbbounds.py --` (new this run, pure Python, no Blender):

```
town_well_t1.glb   HEIGHT(y)=1.7163   meshes=5    mats=5    imgs=0
town_well_t2.glb   HEIGHT(y)=2.4150   meshes=6    mats=6    imgs=0
town_well_t3.glb   HEIGHT(y)=1.6400   meshes=4    mats=4    imgs=0
town_hall_t1.glb   HEIGHT(y)=5.4595   meshes=20   mats=13   imgs=3
town_hall_t2.glb   HEIGHT(y)=11.3391  meshes=44   mats=24   imgs=6
town_hall_t3.glb   HEIGHT(y)=22.4109  meshes=244  mats=15   imgs=7
```

**The entire well ladder ships with `imgs=0` - not one texture map on any
tier.** The hall ladder ships 3 / 6 / 7. Whole-sheet, the well ladder measures
chroma 9.6 / warm 12.9% against the hall ladder's 33.4 / 72.1%: the well sheet
is 3.5x flatter and 5.6x cooler than the other tier sheet this same lane
shipped. t1 and t2 survive it because their timber is carried in a material
base colour; t3 is all stone, so with no map and no warm factor it has nothing
left to be rich WITH. **t3 also has FEWER meshes (4) than t1 (5) or t2 (6)** -
the top of the ladder is the simplest piece in it.

## WHAT IS *NOT* WRONG - TWO FINDINGS I KILLED BEFORE REPORTING THEM

1. **"t3 is shorter than t1 and t2, so the ladder shrinks."** True as a
   measurement (1.64 m against 1.72 and 2.42) and visible in the sheet, but it
   is DECLARED, not accidental. `townlib.ladder_gate`'s docstring already
   argues it: *"the tier-3 Fountain (1.64 m) is legitimately SHORTER than the
   tier-2 roofed Well Kept (2.415 m). A fountain is not taller than a
   well-house; that ladder progresses by RICHNESS, not height."* That is why
   `townbuildgen.py` calls the gate with `growth="free"`. I nearly filed a
   settled design decision as a defect.
2. **"the report's `dims` are axis-scrambled."** Wrong. `_report.json` records
   `dims` in BLENDER space, which is Z-up, so `dims[2]` is the height and
   `townbuildgen.py:390` reads it correctly. The shipped `.glb` is glTF, which
   is Y-up, so the height is in slot [1] there. I compared slot [2] of one to
   slot [2] of the other and believed the register was lying. **It is not.**
   The only residual is cosmetic: the field is labelled bare `dims` with no
   axis note while the artifact the game build loads is Y-up.

A third was killed in the first ten minutes: `ls | grep -v '\.import$'` made
the three `town_well_*.glb` look like they had no `.glb.import` sibling. My
own filter had hidden the siblings. They all have one.

## THE GATE PASSED ALL OF THIS, AND SAID IN ADVANCE THAT IT WOULD

`renders/art/town/_report.json` reads `"verdict": "GREEN", "errors": []`.
`townlib.ladder_gate` is a size-and-separation check, and its own docstring
lists first among WHAT THIS GATE CANNOT SEE:

> - whether the WEAR reads. It is a size and separation check. [...]
> - colour, value or material separation between tiers.

**That is exactly the hole this fault sat in.** The gate is not at fault - it
declared its blind spot honestly and then the blind spot was not covered by
anything else. A PASS HERE IS NOT A DONE LADDER; the sheet still has to be
looked at, and until this run nobody had looked at THIS sheet. (The team lead
verified the HALL ladder by eye at 07:58 CT. The well sheet is a different
sheet and was not in that pass.)

## THE FIX - NOT DONE, NEEDS BLENDER, SPEC IS EXACT

t3 must read RICH AND NEW against t2, not merely larger in footprint:

1. **Put bronze on the bronze.** The four spouts and the basin rim ring take a
   warm metallic base colour (target: the spout pixels alone reaching warm%
   comparable to t2's timber, i.e. roughly 0.5 warm fraction over the spout
   mask, not 0.016 over the whole tier).
2. **Dress the ashlar so it reads as dressed.** The upper basin is currently a
   smooth revolve; the "coursed" read exists only as one band of small blocks
   on the lower drum. t2 shows MORE visible stone coursing than t3 does.
3. **Give the water a water read.** Four uniform-thickness arcs read as wire.
4. **Carry a texture map, or raise the material factors.** `imgs=0` with
   all-stone geometry is why there is nothing to be rich with. The Medieval
   Village MegaKit and Castle pack are already cleared and already supply the
   `T_RockTrim` / `T_MetalOrnaments` / `T_Brick` maps the hall ladder uses -
   `town_hall_t3` pulls 7 of them. Reuse beats authoring.
5. Re-render the three side by side at one camera and one scale, and LOOK.

## A GATE THAT WOULD HAVE CAUGHT IT - PROPOSED, NOT WRITTEN

A `tier_material_gate(sheet_png, spans, order)` belongs beside `ladder_gate`
in `townlib.py`: crop each tier's span out of the sheet that already exists,
compute chroma / saturation / warm-fraction per tier, and RED when the top
tier is not the richest, with RED ON EMPTY when a span yields no subject
pixels. The thresholds should be DERIVED the way `ladder_gate`'s height floor
was - geometric midpoint between a known-bad and a known-good sample - and
this run has produced exactly those two samples (well t3 = 5.4 chroma known
bad, hall ladder = 33.4 known good).

**It is deliberately NOT written yet.** `townlib.py`, `townbuildgen.py` and
`hallgen.py` were all modified at 07:34 CT and HAVE NEVER BEEN RUN, because
the bridge has been down since. Stacking a second unrun change on three unrun
changes would make the first failure impossible to attribute. Change ONE thing
at a time. The first run with a live bridge runs the three existing generators
and THEN this gate goes in.

## THE BLOCKER

Blender is not running on cruzader, so `execute_blender_code` refuses with
`Cannot connect to Blender at localhost:9876`. That bridge is this lane's only
route to Blender, Godot, git and pushing. Nothing in this document is
committed.
