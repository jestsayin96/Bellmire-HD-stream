# 66 OPEN-LATTICE BAYS IN SHIPPED TOWN ART, 61 WITH NOTHING BEHIND THEM, AND
# 12 OF THEM ARE IN A MESH I SHIPPED LAST NIGHT UNDER A DOC THAT SAYS THE
# FAULT WAS FIXED. MY FIRST SWEEP OF THIS WAS ITSELF WRONG - SEE FINDING 2b.

**28 Nov 2026, 04:35-05:2x CT. Art lane. Second bridge-down run in a row.**

The Blender/Godot/git bridge refused every call again this run (two attempts,
`Cannot connect to Blender at localhost:9876`), as it did at 03:34 and for the
team lead at 02:58 and the game build at 04:10. So: nothing rendered, nothing
imported, nothing committed, nothing pushed. **The commit debt from 01:0x-04:0x
CT is still unpaid** - see `_ART_COMMIT_OWED_nov28_0334.md`, still accurate.

What a Python-only run *can* do is read the `.glb` files directly. That is what
this is.

## The new instrument: `tools/art/_glbprobe.py`

A pure-Python GLB/glTF reader. No Blender, no numpy, no bridge. It parses the
container, walks the scene graph, applies node matrices, and reports world
bounds, pivot centre, triangle counts, a module census, and **texture identity
by SHA-1 of the embedded image bytes**.

**IT WAS VALIDATED AGAINST A KNOWN ANSWER BEFORE ANY CLAIM WAS MADE ON IT.**
`TOWN_HALL_LADDER.md` carries Blender-measured dims for the three hall tiers.
The probe reproduces all three independently, to four decimals:

| tier | doc (Blender, Z-up) | probe (pure Python, Y-up) |
|---|---|---|
| T1 | 5.479 x 6.890 x 5.460 | 5.4791 x 6.890 x 5.4595 |
| T2 | 8.250 x 10.976 x 11.339 | 8.2498 x 10.9757 x 11.3391 |
| T3 | 13.801 x 19.784 x 22.411 | 13.8013 x 19.7839 x 22.4109 |

Axis order differs because glTF is Y-up and Blender Z-up; the three numbers are
the same three numbers. The transform maths is therefore corroborated by an
instrument that shares none of its code.

**Triangle counts do NOT fully agree and I am not going to paper over it.**
Doc 1,884 / 30,096 / 139,066; probe 2,688 / 30,120 / 139,090. T2 and T3 are
+24 each - a constant, so probably one 24-tri object counted differently - but
**T1 is +804 and that is not explained.** Until it is, read the probe's dims
and hashes, which are corroborated, and treat its tri counts as indicative.

### *** WHAT THIS INSTRUMENT CANNOT SEE. THE LIMIT IS THE POINT. ***

It never renders. So it is **blind to the three faults that have actually bitten
this lane**: it cannot tell a wall from an open lattice by look, it cannot see a
gable hole, it cannot see colour, and it cannot say whether a progression reads
at a glance. A GREEN verdict from `_glbprobe.py` is **not a fit proof** and must
never be reported as one. `red_on_empty` is built in: zero primitives or zero
POSITION min/max is an ERROR, not a clean pass.

## FINDING 1 - THE HALL LADDER'S TIER 2 -> 3 STEP IS WEAKER THAN MY OWN DOC SAID

`TOWN_HALL_LADDER.md` fault 8 said tiers 2 and 3 "separate almost entirely by
SIZE" and that "the only new material in tier 3 is the tower's stone and the
banners". **By byte hash, it is worse than that: there is no new stone.**

Textures per tier, identity proven by SHA-1 of the embedded bytes:

- **T1:** Plaster, RockTrim, WoodTrim. (3)
- **T2:** those three **byte-identical**, plus Brick, RoundTiles, UnevenBrick. (6)
- **T3:** all six of T2's **byte-identical**, plus MetalOrnaments. (7)

So the ladder's material step is **+3 new textures at T1->T2 and exactly +1 at
T2->T3**, and `T_RockTrim` - "the tower's stone" - is a texture **tier 1 already
wears**. The only genuinely new image a viewer gets for funding hall 5 -> 9 is
the ironwork. T3 does add two materials over T2 (`MI_WoodTrim_Wear`,
`MI_WindowGlass`) but both ride on textures T2 already has.

Mr. E's rule 2: wear is a variable and condition is the receipt for what
viewers paid for. **This is the receipt being thin, measured.** Fault 8 stands
and is now quantified rather than eyeballed.

## FINDING 2 - THE LATTICE FAULT IS NOT FIXED IN TIER 3, AND IT IS ALL OVER TOWN

`Wall_Plaster_WoodGrid` is the module that made the first tier-1 hall a building
you could see straight through. That was established **by rendering it** (doc
fault 1), so the module's see-through character is rendered evidence, not an
inference. Its signature is 248 tris against `Wall_Plaster_Straight`'s 86.

Swept across all 18 building meshes. **66 bays in 11 of 18 meshes, 61 of them
with nothing behind them:**

| mesh | bays | unbacked | band (y, up) |
|---|---|---|---|
| lm_hall | 14 | 12 | 3.12 - 9.37 |
| **town_hall_t3** | **14** | **12** | **3.13 - 9.38** |
| lm_chapel | 7 | 6 | 3.12 - 6.25 |
| lm_barracks | 6 | 6 | 3.12 - 6.25 |
| mk_house_b | 6 | 6 | 3.12 - 9.37 |
| lm_workshop | 5 | 5 | 3.12 - 6.25 |
| mk_house_c | 5 | 5 | 3.12 - 6.25 |
| mk_house_a | 4 | 4 | 3.12 - 6.25 |
| mk_house_d | 3 | 3 | 3.12 - 6.25 |
| lm_watermill | 1 | 1 | 3.12 - 6.25 |
| **town_hall_t1** | **1** | **1** | **0.01 - 3.13 (GROUND LEVEL)** |
| town_hall_t2 | 0 | 0 | - |
| granary, sawmill, windmill, all 3 wells | 0 | 0 | - |

**Tier 2 of the hall ladder carries zero. Tier 1 carries one, at ground level.
Tier 3 carries fourteen.** Tier 3 was derived from `lm_hall`, which has 14 bays
in the band y 3.12-9.37; tier 3 has 14 in y 3.13-9.38. It inherited them
wholesale and the fix never reached it. The fix in `TOWN_HALL_LADDER.md` -
"`Wall_Plaster_Straight` everywhere, one lattice bay kept on the north face as
a vent" - **is accurate for tiers 1 and 2 and FALSE of tier 3.** My own doc is
wrong for tier 3 and this corrects it.

### Asking the viewer's question without a renderer

A lattice with a solid wall behind it is legitimate timber framing over plaster.
A lattice with nothing behind it is a hole. That is decidable geometrically: for
each bay, take its thin horizontal axis as the wall normal, then look for any
other mesh node in the same wall plane (normal centres within 0.80 m - walls are
0.4 m thick, so this is generous) that covers the bay's in-plane area.

| mesh | bays | unbacked (cover < 0.25) |
|---|---|---|
| town_hall_t3 | 14 | **12** |
| lm_hall | 14 | **12** |
| lm_chapel | 7 | **6** |
| mk_house_a | 4 | **4** |

On the full corrected sweep, 61 of 66 bays have no geometry behind them. In every mesh the same two
bays (`.057`, `.065`) come back fully backed by `Wall_UnevenBrick_Window_Thin_Round`
at cover 1.0, which is the test demonstrating it can return a backed result -
it is not a function that says HOLE to everything.

### *** WHAT THIS DOES NOT ESTABLISH. DO NOT OVERSTATE IT. ***

**I did not look at a picture, so I have not proved the town reads as holed.**
The honest statement is: 66 instances of a module proven by render to be
see-through, the large majority with no geometry behind them. Three ways this
could still be fine and none is excluded:
- the openings may be small and high enough to read as a dark vent band;
- an unlit interior behind them reads as shadow, not as sky;
- nine of the eleven meshes are **Medieval Village MegaKit buildings shipped as the
  pack authored them**, and the town has looked like this on stream for days
  without anyone naming it.

That last one cuts both ways: it is equally consistent with a fault nobody has
looked for. **It is one render to settle and that render needs the bridge.**

## FINDING 2b - MY OWN SWEEP WAS WRONG AND THE FIX CHANGED A CONCLUSION

The first run of this sweep reported **65 bays in 10 meshes and ZERO in
town_hall_t1**. Both were wrong. It normalised module names by splitting on
`.` to strip Blender's `.001` suffix - but `hallgen.py` names its placed modules
`Wall_Plaster_WoodGrid_inst`, and `_inst` is not a `.` suffix. Every bay in a
mesh this lane GENERATED was invisible to a sweep built for the pack's naming.

Corrected count: **66 bays, 11 meshes, 61 unbacked.** The matcher now strips
`\.\d+$` and `_inst$` both.

**And the bay it was hiding mattered more than the count.** `town_hall_t1`
carries exactly one bay - which is what the hall doc claimed, so the doc was
right and my sweep libelled it - but it sits at **y 0.01 - 3.13, ground level,
and the backing test returns it UNBACKED.** A "vent" at ground level with
nothing behind it is a doorway-height hole in the wall.

That independently reproduces a fault already found BY EYE on the shipped
sheet. `TOWN_HALL_LADDER.md` second-look fault 6: *"Tier 1 reads as an
open-fronted shed, not an enclosed hall. The west bay is open to the camera and
the bench inside is visible through it."* The bench is visible through it
**because there is a hole**, and the hole is the retained vent bay, placed at
ground level instead of high in the wall where a vent belongs. Two instruments
agree and one of them is a picture, which is the only kind of agreement worth
much.

**So the tier-1 fix is not "remove the bay" - it is MOVE it.** Keep one bay as
the vent the module is actually for, in the band above head height, with wall
below it.

This is the fourth time this lane has red-proved its own instrument in two
days. The habit holds: the sweep said zero, the detail listing said 248 tris of
`Wall_Plaster_WoodGrid_inst`, and the disagreement was the finding.

## FINDING 3 - THE CHAPEL PIVOT, THE PLAN'S OPEN QUESTION, IS ANSWERED

`TOWN_CHAPEL_LADDER_PLAN.md` left `[ ] pivot` blocked on the bridge. It is not
blocked; it is just bookkeeping. `lm_chapel.glb`:

- bounds lo `[-4.976, -0.007, -7.877]`, hi `[4.976, 19.281, 11.714]`
- dims `9.952 x 19.288 x 19.591` m, 110,780 tris, 179 mesh nodes
- **centre `[0.0, 9.637, 1.918]`**

**x is dead centred (0.000). z sits 1.918 m off.** Unlike tier-3 hall, that
offset is NOT a yard - the chapel has no paving, court or fence node at all. It
is a real tower/entry extension at the +z end: the nave roof
(`Roof_RoundTiles_8x14`) spans z -7.877..7.829, centred on z ~= -0.024, while
`Roof_Tower_RoundTiles` and `Door_2_Round` reach z 11.713.

**So the chapel ladder's pivot is taken off the NAVE, not the assembly.** The
nave is already centred; the whole-assembly centre is not. Pivot on the
assembly and tier 3's taller tower drags the chapel along +z as tiers swap -
which is exactly the defect that dragged hall tier 3 two metres north. The
chapel is a new mesh family for the same reason the hall was.

## FINDING 4 - 56% OF THE CHAPEL'S MESH IS CORNER TRIM

| module | count | tris | each | share |
|---|---|---|---|---|
| **Corner_Exterior_Brick** | **20** | **62,040** | **3,102** | **56.0%** |
| Window_Thin_Round1 | 22 | 9,196 | 418 | 8.3% |
| Door_2_Round | 1 | 6,188 | 6,188 | 5.6% |
| Roof_RoundTiles_8x14 | 1 | 5,484 | 5,484 | 5.0% |
| Wall_UnevenBrick_Straight | 27 | 1,512 | 56 | 1.4% |

A corner bevel costs **3,102 tris; a whole wall costs 56.** Twenty of them eat
more than half the building. Not a correctness fault and nothing is visibly
wrong, but the chapel tier ladder must not inherit it: a decimated or boxed
corner would return ~55k tris on a building seen at stream distance.

## THE CHEAP GATE, RUN AGAIN BECAUSE IT HAS BITTEN TWICE

All 222 `.glb` under `assets/`, `renders/`, `tools/` checked for a `.glb.import`
sibling. **All six new tier meshes have one** (hall t1/t2/t3, well t1/t2/t3) -
the 03:34 run's hand-check independently confirmed. Twelve files lack one and
all twelve are render intermediates under `renders/art/d85`, `d95/kits` and
`minibosses/_metal_tmp` - not loadable game assets, so no sibling is owed.

## FIRST WORK FOR THE NEXT FIRING THAT HAS A BRIDGE, IN ORDER

1. **Pay the commit debt.** `_ART_COMMIT_OWED_nov28_0334.md`, 322 files plus
   this run's. Assert `^[0-9a-f]{40}$` on any SHA before it goes near a push.
2. **Render `lm_chapel` and `town_hall_t3` face-on at the lattice band and
   LOOK.** One picture decides finding 2 either way. Azimuth and elevation 0 -
   an angled shot fills a lattice's own gaps.
3. If holed: `Wall_Plaster_Straight`, keeping one or two bays as the vent the
   piece is actually for. Tier 3 of the hall first, since that is mine and
   shipped last night under a doc that says it was fixed.
4. Then hall faults 6 (tier-1 open bay) and 7 (floating eave), then fault 8
   with the texture table above as the spec.
5. Then the chapel measurement run, module choice, and `chapelgen.py`.

## REPORTS WRITTEN

- `renders/art/town/_glbprobe_all_buildings.json` - all 18 meshes
- `renders/art/town/_glbprobe_hall_chapel.json` - the five in detail
- `tools/art/_glbprobe.py` - the instrument, with its blindness at the top

## NOTHING HERE IS A NEW WORK_PLAN ITEM

Findings 1 and 2 are defects in this lane's own shipped work and a correction to
its own doc; finding 3 closes a line the chapel plan left open. The 15 Nov
freeze is not touched and no row was written.

---

# CORRECTION AND EXTENSION, 28 Nov 2026 05:35-06:1x CT (SIXTH bridge-down hour)

**Written by the 05:34 CT art firing. The Blender/Godot/git bridge refused
three more calls this run** (`localhost:9876`, 05:35 / 05:38 / 05:41), making
it the fifth-to-sixth consecutive hour house-wide. **This run also had no git
at all**: only `C:\hd adventure\bellmire-art` was mounted, not the parent
`C:\hd adventure`, so the worktree's `.git` pointer into the main repo was
unreachable and `git status` still has never been run. The commit debt in
`_ART_COMMIT_OWED_nov28_0334.md` is **still unpaid and now larger**.

## The new instrument: `tools/art/_modcover.py`

Finding 2 above decided "is this bay backed" by asking whether some other node
in the wall plane COVERS THE BAY'S AREA, treating a backer as an opaque
rectangle. **That method cannot see a lattice behind a lattice** - it would
score such a bay BACKED. `_modcover.py` replaces it with a software rasteriser:
it projects every triangle within 1.0 m of the bay's plane into the bay's own
in-plane window and takes the UNION of filled cells.
`hole_frac = 1 - cover`.

Union, not sum, is the whole design: summing projected triangle area
double-counts a wall's front and back faces and reads ~2.0 for a solid wall,
which cannot distinguish "solid" from "solid, twice".

### It was validated before any claim was made on it, and it has a negative control

1. **Known-by-PICTURE pair.** The tool refuses to print a table unless
   `Wall_Plaster_WoodGrid` (see-through, established BY RENDER, finding 1 of
   this doc) separates from `Wall_Plaster_Straight` (solid) by >= 0.20.
   Measured: **solid 1.0000, lattice 0.6847, margin 0.3153. GREEN.**
2. **Resolution independence.** Grid 64 / 128 / 256 / 384 give lattice
   0.7070 / 0.6847 / 0.6922 / 0.6917, margin 0.2930 / 0.3153 / 0.3078 /
   0.3062. Stable to ~0.01 beyond grid 128, so the number is not a rasteriser
   artifact. (Solid drops to 0.9979 at grid 384 - a one-cell edge effect,
   recorded rather than hidden.)
3. **Negative control, and this is the one that matters.** Across 18 meshes,
   **310 solid-wall instances** (`Wall_Plaster_Straight` 80,
   `Wall_UnevenBrick_Straight` 230) read `hole_frac` **exactly 0.0000, every
   one.** A noisy instrument would invent holes there. It does not.
4. **Independent corroboration of finding 2.** It reproduces this doc's bay
   counts exactly - `town_hall_t3` 12 of 14, `lm_hall` 12 of 14, `lm_chapel`
   6 of 7, `town_hall_t1` 1 of 1, `town_hall_t2` 0 - and the town-wide
   **66 bays / 61 unbacked**, by maths sharing none of the first method's code.

**`red_on_empty` throughout:** zero triangles, a degenerate in-plane box, zero
filled cells, or zero instances of the target module is an ERROR. `town_hall_t2`
correctly returns `RED ON EMPTY: zero instances ... a sweep over no bays reads
clean and means nothing` rather than a clean pass.

### *** WHAT IT STILL CANNOT SEE - IT NEVER RENDERS ***

Blind to colour and material; blind to whether a progression READS at a glance;
blind to assembly faults such as a gable hole, which belong to no single node;
blind to backface culling (a one-sided quad reads 1.00 and can still vanish);
and blind to anything deeper than 1.0 m, deliberately - a solid far wall 6 m
back does not close a hole, because looking into the building's inside IS the
open-shed look. **A green sheet from this tool is NOT a fit proof.** The chapel
ladder still cannot ship without renders looked at by eye.

## FINDING 3 - COVERAGE ALONE DOES NOT FIND THE FAULT, AND THAT CORRECTS MY OWN FRAMING

The 66-bay framing of finding 2 was too narrow. Ranked by how open each
wall module is in its own plane, **the lattice is not the most open module in
town, and it is not the most numerous open one:**

| module | n | cover_med | note |
|---|---|---|---|
| Wall_UnevenBrick_Door_Round | 17 | 0.5018 | doorway - open ON PURPOSE |
| Wall_Plaster_Door_Flat | 1 | 0.5596 | doorway |
| **Wall_Plaster_WoodGrid** | **66** | **0.6847** | **the lattice** |
| Wall_Plaster_Window_Wide_Round | 79 | 0.7094 | window - open on purpose |
| Wall_UnevenBrick_Window_Wide_Round | 45 | 0.7094 | window |
| Wall_Plaster_Window_Wide_Flat | 46 | 0.7588 | window |
| Wall_UnevenBrick_Window_Thin_Round | 108 | 0.8586 | window |
| Wall_Plaster_Straight | 80 | 1.0000 | solid |
| Wall_UnevenBrick_Straight | 230 | 1.0000 | solid |

A door and a window are SUPPOSED to be mostly air. So a low `cover` is a flag
to look at, never a fault by itself, and any future gate that reports "mostly
air" as a defect will libel 295 legitimate windows and doors. **The fault is
an opening with NOTHING BEHIND IT**, which is `hole_frac`, not `cover`.

## FINDING 4 - 88 UNBACKED OPENINGS TOWN-WIDE, NOT 61. THE DOORWAYS ARE WORSE THAN THE LATTICE PER-INSTANCE.

672 wall-family openings swept across all 18 shipped meshes, `depth` 1.0 m:

| module | n | unbacked | hole_med | hole_max |
|---|---|---|---|---|
| Wall_Plaster_WoodGrid | 66 | **61** | 0.2516 | 0.3104 |
| Wall_UnevenBrick_Door_Round | 17 | **16** | 0.1876 | 0.3636 |
| Wall_Plaster_Window_Wide_Round | 79 | 6 | 0.0000 | 0.2868 |
| Wall_UnevenBrick_Window_Wide_Round | 45 | 4 | 0.0000 | 0.2967 |
| Wall_Plaster_Door_Flat | 1 | **1** | 0.4440 | 0.4440 |
| Wall_Plaster_Window_Wide_Flat | 46 | 0 | 0.0000 | 0.0000 |
| Wall_UnevenBrick_Window_Thin_Round | 108 | 0 | 0.0000 | 0.0000 |
| Wall_Plaster_Straight | 80 | 0 | 0.0000 | 0.0000 |
| Wall_UnevenBrick_Straight | 230 | 0 | 0.0000 | 0.0000 |
| **TOTAL** | **672** | **88** | | |

Three things in that table, in order of how much they change the work:

1. **The windows are almost all fine - 160 of 170 backed.** Glass and shutters
   sit behind them. That is good news and it was not known before; it also
   means the window modules need no fix and must not be swept up in one.
2. **`Wall_Plaster_Door_Flat` is the single worst hole in town at 0.4440** -
   44% of that bay is nothing. One instance, so it is one fix.
3. **16 of 17 round brick doorways are unbacked**, and the audit missed them
   entirely because it only looked at the lattice. Per instance their median
   hole is smaller than the lattice's (0.1876 vs 0.2516) but their MAXIMUM is
   larger (0.3636 vs 0.3104).

**Whether an unbacked doorway is a FAULT is not decided here and I am not
deciding it.** A doorway is an opening by nature; for facade buildings seen at
stream distance it wants a door leaf or a dark interior panel, and 16 of 17
have neither. The lattice is already KNOWN to read as a fault by render. The
doors are a flag of the same rank, to be settled by the same picture.

## WHAT TO RENDER FIRST WHEN THE BRIDGE RETURNS - UNCHANGED TARGET, ONE SHOT ADDED

Still `lm_chapel` and `town_hall_t3` face-on (azimuth 0, elevation 0) at the
y 3.1-9.4 band, plus `town_hall_t1`'s ground-level vent bay. **Add one shot:**
any `lm_*` wall carrying `Wall_UnevenBrick_Door_Round`, face-on, to settle
finding 4's doorways in the same window. One contact sheet answers all of it.

## WHAT THIS DOES NOT CHANGE

Finding 1 (the hall ladder's thin material step: +3 textures T1->T2, +1
T2->T3, `T_RockTrim` already worn at T1) is untouched - it is a texture-identity
result and this run adds nothing to it. The chapel ladder is still at
"measurement run BLOCKED, bridge down", and `chapelgen.py` is still
deliberately NOT written: choosing chapel modules off their names is exactly
how the lattice got in, and finding 3 shows name-based choice would also have
mistaken 295 legitimate windows and doors for defects. `_modcover.py` narrows
that choice but does not replace `_chapelmeasure.py`, which renders.

---

# THE LIST, AND THREE THINGS THE LIST SAYS THAT THE AGGREGATE COULD NOT
# 28 Nov 2026, 06:35-07:1x CT. SEVENTH consecutive bridge-down hour.

**Written by the 06:34 CT art firing**, rowed by the team lead's 05:58 block:
*"Keep to the town building ladder on paper: the chapel/market tier specs and
the 88-opening list."* The bridge refused again at 06:35
(`Cannot connect to Blender at localhost:9876`), and this seat ALSO had only
`C:\hd adventure\bellmire-art` mounted - not the parent - so git was
unreachable for the second, separate reason section 2 of that block describes.
`git status` has still never been run. Nothing was rendered, imported,
committed or pushed, and **no shipped `.glb` was touched**, per the row.

## The list exists now: `docs/art/TOWN_OPENING_LIST.md`

Finding 4 established the COUNT but published only module x file totals, and
**you cannot apply a fix to a total.** `tools/art/_openinglist.py` emits every
unbacked opening with its node index, its node name, its world centre, its
wall normal and the in-plane size a backing panel would have to be. 177 lines,
grouped by mesh, worst hole first.

It is a DRIVER, not a method: every number comes from `_modcover.throughlight`,
already validated three ways. The additive coordinate fields it needed
(`centre`, `lo_xyz`, `hi_xyz`, `normal_axis`, `normal_centre`,
`size_inplane`, `axes_inplane`) were added to that function without touching
any existing field's value.

**IT REPRODUCES FINDING 4 EXACTLY.** 672 openings swept, 88 unbacked, and all
nine per-module pairs identical - 66/61, 17/16, 79/6, 45/4, 1/1, 46/0, 108/0,
80/0, 230/0 - with zero disagreements, from a driver that shares none of the
aggregating code the first sweep used. The reproduction check is built into
the tool and prints DISAGREES rather than smoothing a mismatch over.

`TOWN_OPENING_LIST.md` is GENERATED. Do not hand-edit it; findings go here.

## FINDING 5 - "88" IS NOT AN ARTIFACT OF THE THRESHOLD, AND I BUILT THE GUARD EXPECTING THE OPPOSITE

`unbacked` is a threshold (> 0.18, `hallgen.py` line 762's own solidity gate),
so the tool reports the count at four thresholds on the principle that a
number which moves with its own cutoff is a choice and not a fact.

    0.05 -> 88     0.10 -> 88     0.18 -> 88     0.25 -> 45

**The count is identical at 0.05, 0.10 and 0.18.** The reason is that the
split is clean: the 584 backed openings read `hole_frac` **exactly 0.0000**,
the lowest unbacked one reads **0.1860**, and *nothing in town falls between*.
So the gate could sit anywhere across that whole range and name the same 88
openings. I wrote this guard to catch a fragile count - in particular because
16 of the 17 brick doorways sit at 0.1876, a hair above the cutoff, which
looked like exactly the kind of thing that should not be trusted. It is not
fragile, and the honest report is that the guard cleared the number instead of
breaking it.

One direction IS sensitive and must not be hidden: at 0.25 the count falls to
45. That is not 43 openings becoming backed - **it is severity, not backing.**
Of the 88, 43 sit in the 0.2 band, 43 in the 0.3 band and 2 in the 0.4 band.
If the fix has to be rationed, that is the ranking to ration it by.

## FINDING 6 - CORRECTION I OWE MY OWN DOC: "TIER 2 CARRIES ZERO" IS TRUE OF THE LATTICE AND FALSE OF OPENINGS

Finding 2 above says, in bold: *"Tier 2 of the hall ladder carries zero."*
That sentence is about `Wall_Plaster_WoodGrid` and **for the lattice it is
correct** - `town_hall_t2` has no lattice bay, and `_modcover` properly returns
RED ON EMPTY there rather than a clean pass.

Read as a statement about the tier, it is wrong. Per-mesh, across all nine
wall families:

| mesh | unbacked openings |
|---|---|
| lm_hall | 13 |
| **town_hall_t3** | **13** |
| **town_hall_t2** | **11** |
| lm_barracks | 9 |
| lm_chapel | 7 |
| mk_house_b | 7 |
| lm_workshop | 6 |
| mk_house_c | 6 |
| mk_house_a | 5 |
| mk_house_d | 4 |
| lm_watermill | 2 |
| **town_hall_t1** | **2** |
| granary, sawmill, windmill | 1 each |
| all three wells | 0 |

**`town_hall_t2` carries eleven unbacked openings and the second-worst hole in
town** - node 30, `Wall_UnevenBrick_Door_Round.013`, `hole_frac` 0.3701, at
world centre (0.00, 1.77, 3.89), normal z, 2.00 x 3.12 m. It is a shipped
tier of this lane's own ladder and the lattice-only framing hid it. The three
wells are the only genuinely clean family in town, at zero.

## FINDING 7 - THE WORST HOLE IN TOWN IS NOW LOCATED, IT IS AT GROUND LEVEL, AND IT IS MINE

Finding 4 named `Wall_Plaster_Door_Flat` as the worst hole in town but not
which mesh it was in. It is in **`town_hall_t1`** - this lane's own tier 1,
shipped last night:

- node 10 `Wall_Plaster_Door_Flat` **hole_frac 0.4404**, centre
  (-1.01, **1.57**, 2.89), normal z @ 2.889, in-plane 2.00 x 3.12 m
- node 19 `Wall_Plaster_WoodGrid.019` **hole_frac 0.3153**, centre
  (0.99, **1.57**, -2.89), normal z @ -2.889, in-plane 2.00 x 3.12 m

**Both sit at centre y 1.57 - ground level - in the same small mesh, on
opposite faces.** The second is the retained "vent" bay finding 2b already
identified as misplaced. The first was not known to be in this mesh at all.

`TOWN_HALL_LADDER.md` second-look fault 6 recorded, BY EYE, that *"tier 1
reads as an open-fronted shed, not an enclosed hall... the bench inside is
visible through it."* That fault now has **two named, located, measured causes
at ground level on opposite walls of the building** - a 44%-open doorway and a
32%-open vent bay, two metres wide and three metres tall each. A viewer at
stream distance is looking through the front wall and out the back one.

**And a small correction to my own number:** finding 4 prints the worst hole as
**0.4440**; the measurement is **0.4404**. A transposition in the doc, not in
the data. My reproduction check compared *counts*, not that figure, so it
passed GREEN while the typo sat two sections above it - which is a fair
reminder of what a green gate does not cover.

## WHAT THE LIST DOES AND DOES NOT DECIDE ABOUT THE FIX

Of the 88, **61 are the lattice and 27 are doors and windows that are open by
design.** That is the split the fix turns on, and the list carries an
`open by design` column so it cannot be lost again:

- **The 61 lattice bays are a fault.** The module's see-through character was
  established BY RENDER (finding 1), and these have nothing behind them.
- **The 27 are a judgement call and this doc does not make it.** A doorway is
  an opening by nature. Finding 3's warning stands: any gate that treats
  "mostly air" as a defect libels 295 legitimate windows and doors. What
  decides it is whether a facade building at stream distance wants a door leaf
  or a dark interior panel - and that is a question for a picture.

**None of this is a render, so none of it is a fit proof,** and the fix stays
unapplied. The row forbids touching a shipped `.glb` while the bridge is down,
and this run did not.

## FIRST WORK FOR THE NEXT FIRING THAT HAS A BRIDGE - REVISED, STILL ONE SHEET

1. **Pay the commit debt** (`_ART_COMMIT_OWED.md`, now the single file).
2. **One contact sheet, face-on, azimuth and elevation 0** - an angled shot
   fills a lattice's own gaps. Four subjects, all now at known coordinates:
   `town_hall_t1` at **ground level, both faces** (findings 7 - the worst two
   in town and the one already seen by eye); `town_hall_t3` and `lm_chapel` at
   the y 3.1-9.4 band; and `town_hall_t2`'s node-30 doorway (finding 6).
3. That sheet settles the lattice AND the doorway question together. Then fix
   tier 1 first - it is the worst, it is this lane's own, and it is small.

## FINDING 8 - WHY A DOORWAY WITH A DOOR IN IT IS STILL A HOLE, MEASURED - AND THE TWO WORST ARE MINE BECAUSE THEY HAVE NO DOOR AT ALL

Finding 4 left the doorways as an open judgement call. They are now explained,
and the explanation splits them into two groups that need different answers.

### The mechanism: a single leaf hung in a double opening

The windows are backed because each carries an in-plane companion - 22
`Wall_UnevenBrick_Window_Thin_Round` against 22 `Window_Thin_Round1` panes in
the chapel, 10 wide-rounds against 10 `Window_Wide_Round1`, and so on, 1:1 in
every mesh. The lattice has **no companion of any kind**, which is why 61 of 66
are holes. Pair-counting predicts the lattice and the windows exactly.

**It fails on the doorways, and the failure is the finding.** Ten meshes have a
door leaf present and the doorway still unbacked. The first hypothesis - the
leaf is swung open, out of plane - is WRONG: every leaf's thinnest axis is the
wall normal, so they are all flush in the wall. Measured across all 18 meshes:

| | |
|---|---|
| doorway opening width | **2.000 m** (every instance) |
| door leaf width | **1.115 m** (`Door_2/4_Round`), 1.152 m (`Door_8_Round`) |
| leaf centre offset from opening centre, laterally | **0.513 - 0.515 m**, n=16 |
| opening width left uncovered | **46.8% - 47.9%** |

Sixteen doorways, one number, spread 0.002 m. The MegaKit's
`Wall_UnevenBrick_Door_Round` is a **DOUBLE-WIDTH opening and the pack hangs a
SINGLE leaf in it, hinged to one jamb.** The other half is the hole. That is a
pack-authoring characteristic, not a placement mistake of ours, and it accounts
for all ten "insert present yet still unbacked" cells at once.

(My first sweep of this got the axis wrong - it picked the taller in-plane axis
and reported a 0.367 m *vertical* offset, which is just a short leaf under an
arched head, and it matched one leaf to three doorways in `lm_barracks`. I
caught it by reading the result against a per-node dump I had already printed.
The corrected sweep takes the horizontal in-plane axis and pairs each leaf
once. Same trap as every other one in this doc: the number looked plausible
and was answering a different question.)

### So the 16 pack doorways are a judgement call, and the 2 without leaves are not

**`town_hall_t1` node 10 and `town_hall_t2` node 30 have NO DOOR LEAF AT ALL** -
not an offset one, none. They are the only two openings in town with nothing
paired to them, their uncovered width is **100%**, and they are the **two worst
holes in town** at `hole_frac` 0.4404 and 0.3701.

**Both are meshes this lane GENERATED.** `tools/art/hallgen.py` places a
doorway module and never places a leaf behind it. The pack's own buildings all
carry one; our two generated tiers do not.

That closes finding 7 with a cause. `TOWN_HALL_LADDER.md` fault 6 recorded by
eye that *"tier 1 reads as an open-fronted shed... the bench inside is visible
through it."* **The bench is visible because the doorway has no door in it.**

### THE FIX, SPECIFIED - FOR THE GAME BUILD'S INFORMATION, AND FOR THIS LANE TO APPLY

This is a defect in this lane's own generator, so it is this lane's to fix and
it is NOT a new WORK_PLAN item. **It is deliberately NOT applied this run:** the
row says the doorway fix waits for Godot and that shipped `.glb` meshes are not
to be touched while nothing can be rendered, and an untested edit to the
generator that produces three shipped tiers is the same risk one step back.

In `tools/art/hallgen.py`, wherever a `Wall_UnevenBrick_Door_Round` or
`Wall_Plaster_Door_Flat` module is placed, place a `Door_2_Round` leaf with it:

- leaf centre = opening centre, **laterally offset +0.515 m** along the wall's
  horizontal in-plane axis, matching all 16 pack instances
- leaf centre **y = 1.192** (the pack's floor-aligned leaf height), against the
  opening's own centre y 1.561
- leaf centre on the wall normal = opening's normal centre **+0.108 m**
  (barracks: opening z 5.889, leaf z 5.997), so the leaf sits proud of the wall
- then re-run `_openinglist.py`; tier 1 node 10 and tier 2 node 30 should fall
  from 0.4404 and 0.3701 to roughly the pack's 0.1876

**Even then it is not done.** A doorway half-covered by a single leaf is what
the whole town already looks like, so matching the pack only makes our tiers
consistent with it - it does not establish that the result READS right at
stream distance. That still needs the contact sheet, looked at by eye.
