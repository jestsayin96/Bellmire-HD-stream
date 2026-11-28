# THE TOWN TIER LADDER - THE FIT SPEC. The chapel and the market, and a
# 4.08 m DEFECT IN THE TIER-3 HALL I SHIPPED LAST NIGHT.

**28 Nov 2026, 06:34-07:1x CT. Art lane. SEVENTH consecutive bridge-down hour**
(`Cannot connect to Blender at localhost:9876`, refused at 06:35 and 06:5x),
and this seat had only `C:\hd adventure\bellmire-art` mounted, so git was
unreachable for the second reason the team lead's 05:58 block section 2
describes. Nothing rendered, imported, committed or pushed. No shipped `.glb`
touched, per the row.

Rowed by that block: *"Keep to the town building ladder on paper: the
chapel/market tier specs and the 88-opening list."* The list is
`docs/art/TOWN_OPENING_LIST.md`; this is the specs.

**EVERYTHING HERE IS MEASURED OFF THE FILES, NOT REMEMBERED.** Sources:
`renders/art/town/_glbprobe_all_buildings.json` (dims, census),
`renders/art/town/_modcover_all_buildings.json` (per-module solidity),
`renders/art/town/_openinglist.json` (every unbacked opening),
`data/town/bellmire.json` (the authored plots).

---

## 1. THE HARD CONSTRAINT, AND IT IS MR. E'S OWN RULING - NOT AN AESTHETIC

`data/town/README.md`, recording his ruling of 15 Nov 16:57:

> Bellmire is HAND-BUILT... Twelve levels for now; **each level is a superset of
> the one before (nothing ever moves when the town levels up - things only
> appear).**

A tier ladder swaps one mesh for another on the same plot. So **a tier swap must
not move the building**, and that is a correctness requirement with his name on
it, not a preference. Two things follow, and both are measurable:

**(a) The format carries ONE footprint per building, not one per tier.** A
`buildings` entry has a single `pos`, `off` (footprint centre in the model's
frame) and `half` (footprint half-extents). There is no per-tier variant. So
either all three tier meshes of a building share one origin and one footprint
centre, or the loader needs a per-tier `off`/`half` - **and that is the GAME
BUILD's format decision, not this lane's.** It is named in section 5.

**(b) The plots were authored to the pack buildings' EXACT footprints.** This is
not a guess; the numbers agree to 6 mm:

| landmark | mesh footprint (x by z, m) | plot `half` x2 | agreement |
|---|---|---|---|
| lm_hall | 13.801 x 15.706 | 13.80 x 15.70 | exact |
| lm_chapel | 9.952 x 19.591 | 9.96 x 19.60 | exact |

So the plot IS the footprint budget, and a tier that exceeds it has nowhere to
stand.

## 2. *** THE TIER-3 HALL EXCEEDS ITS PLOT BY 4.08 m. IT IS MINE AND IT SHIPPED. ***

| mesh | x | height | z | plot allows x,z | verdict |
|---|---|---|---|---|---|
| town_hall_t1 | 5.479 | 5.460 | 6.890 | 13.80 x 15.70 | fits |
| town_hall_t2 | 8.250 | 11.339 | 10.976 | 13.80 x 15.70 | fits |
| **town_hall_t3** | **13.801** | **22.411** | **19.784** | 13.80 x 15.70 | **EXCEEDS z BY 4.08 m** |

Tier 3 matches `lm_hall` exactly in x and height - it was derived from it - but
is **4.078 m deeper**. That depth is the yard/court node already identified as
the thing that pulled tier 3's assembly centre 2 m off the nave's. The plot
b001 is authored at `pos [118.93, -18.06]`, `yaw -30.01`, `half [6.9, 7.85]`.

**Consequences, stated as consequences and not as a render:**
- At yaw -30 degrees a 4 m overhang projects into whatever sits behind the plot.
  `tools/_d93_validate.gd` checks OVERLAP, ON_ROAD, ON_SQUARE, DOOR and
  UNREACHED; a footprint 26% deeper than its plot is the shape of thing those
  checks exist to catch. **I have not run the validator - it needs Godot** - so
  this is a predicted failure, not an observed one, and it must be run.
- It also breaks (a): with one `off` per building, a deeper tier 3 either
  overhangs or shifts the building, and shifting it violates "nothing ever
  moves".

**THE FIX IS THIS LANE'S AND IT IS NOT A NEW PLAN ITEM** - it is a defect in
this lane's own shipped work. **Drop or shrink the yard so tier 3's footprint
is <= 13.80 x 15.70**, which also re-centres the pivot onto the nave and fixes
the 2 m drag with the same cut. Do NOT instead widen the plot: that pushes an
art defect into content's authored town and into the validator.
**Not applied this run** - it is a mesh edit and nothing can be rendered.

## 3. THE CHAPEL LADDER - THE SPEC, WITH THE MODULE CHOICE MADE OFF MEASUREMENTS

`TOWN_CHAPEL_LADDER_PLAN.md` left `[ ] Module choice made off the table`. Here
it is. **Choosing modules off their NAMES is exactly how the lattice got in**, so
every row below is a measured number.

**Footprint budget: 9.96 x 19.60 m, and tier 3 must not exceed it.** Tier 3 is
the one that breaks the budget when the hall's did; hold it to the plot.

**Pivot: take it off the NAVE, not the assembly.** Measured: the nave roof
(`Roof_RoundTiles_8x14`) spans z -7.877..7.829, centre z ~= -0.024, while
`Roof_Tower_RoundTiles` and `Door_2_Round` reach z 11.713, putting the whole
assembly's centre at z 1.918. The authored plot already carries
`off [0.0, 1.92]` for exactly this - which confirms the measurement from the
data side - but since `off` is per BUILDING and not per TIER, every chapel tier
must present the SAME footprint centre or the chapel walks as it levels.

### The module palette, by measurement

| role | module | cover | tris | why |
|---|---|---|---|---|
| **wall, tiers 1-3** | `Wall_UnevenBrick_Straight` | **1.0000** | 56 | 230 instances, `hole_frac` **exactly 0.0000** every one |
| **wall, plaster faces** | `Wall_Plaster_Straight` | **1.0000** | 86 | 80 instances, `hole_frac` exactly 0.0000 |
| **corner, tiers 1-2** | `Corner_Exterior_Wood` | **1.0000** | **12** | see below - 258x cheaper AND more solid |
| corner, tier 3 only | `Corner_Exterior_Brick` | 0.8421 | 3,102 | the showpiece tier can afford it |
| thin window | `Wall_UnevenBrick_Window_Thin_Round` | 0.8586 | 158 | **only with its pane** |
| wide window | `Wall_Plaster_Window_Wide_Round` | 0.7094 | 124 | **only with its pane** |
| window pane | `Window_Thin_Round1` / `Window_Wide_Round1` | 0.9013 / 0.9142 | 418 / 354 | this is what backs a window |
| doorway | `Wall_UnevenBrick_Door_Round` | 0.5018 | 136 | **only with a leaf, placed per finding 8** |
| **FORBIDDEN** | `Wall_Plaster_WoodGrid` | 0.6847 | 248 | the lattice: 61 of 66 are holes town-wide |

**THE COMPANION RULE, and it is the one rule that prevents the whole 88.** An
opening module is never placed alone. Every window in town is backed because it
carries a 1:1 in-plane companion pane; the lattice is a hole because it has no
companion of any kind; and the two worst holes in town are the two doorways
this lane's own generator placed with no leaf (finding 8). So:
**place every opening WITH its companion insert, in the same call, or do not
place the opening.**

### The 56% corner, and the cheapest real win on the board

`lm_chapel` is 110,780 tris across 179 mesh nodes, and **20
`Corner_Exterior_Brick` instances eat 62,040 of them - 56.0% of the whole
building** at 3,102 tris each. `Corner_Exterior_Wood` is **12 tris** and
measures **cover 1.0000** against the brick corner's 0.8421.

Swapping the corners on tiers 1 and 2 costs **240 tris instead of 62,040** - a
258x saving on the single largest line in the budget - and the wood corner is
*measurably more solid* than the brick bevel it replaces. It is also the right
answer for Mr. E's rule 2: **timber corners on a patched tier-1 chapel and cut
stone on tier 3 is wear driven by tier**, which is the progression the viewer is
paying for. The expensive module lands only on the tier that is meant to look
expensive.

Budget, derived from the above (counts from the chapel census):
- tier 1: wood corners, brick straight walls, thin windows + panes, one doorway
  + leaf, no lattice -> on the order of 15-25k tris
- tier 2: + wide windows + panes, plaster faces, more roof -> on the order of
  40-60k
- tier 3: + brick corners, the tower, metal ornament -> near `lm_chapel`'s 110k

**These are budgets, not measurements - no chapel tier mesh exists yet.**

## 4. THE MARKET IS NOT A TIER LADDER, AND THAT CHANGES THE WORK

Measured in `data/town/bellmire.json`: the market is **not** a building with
tiers. It is a `special` that takes over an authored plot at a level:

    id b014, special "market_hall", special_level 5

Five specials work this way: `market_hall` (level 5), `stables` (7),
`guild` (9), `bathhouse` (9), `mage_tower` (11). Under "things only appear",
each is **ONE mesh that appears at its level** - there is no tier-1 market to
make patched and make-do, because at level 4 there is no market at all.

**So the market is a single-mesh item, and it is cheaper than a ladder.** Its
spec is the palette and the companion rule from section 3, its footprint budget
is plot b014's `half` x2, and its wear is fixed at "new when it appears" - a
market hall that appears because the town got rich should read fresh-timbered,
not patched. The three progression tiers Mr. E's priority order names are for
the buildings that EXIST from level 1 and grow: the hall (done, with the defect
in section 2), the well (done), and the chapel (specified here).

## 5. WIRING THE GAME BUILD LANE MUST DO - I DO NOT TOUCH THESE

These are theirs; none of them is in `tools/art/` or `docs/art/`.

1. **`data/town/` format decision: one footprint per building vs one per tier.**
   A `buildings` entry has a single `off` and `half`. The hall's three tiers
   measure 5.479 / 8.250 / 13.801 wide and 6.890 / 10.976 / 19.784 deep - they
   do NOT share a footprint. Either the tier meshes are authored to one shared
   footprint (this lane can do that, and section 2 says tier 3 must be cut to
   the plot anyway), or `buildings` needs per-tier `off`/`half`. **The team
   lead's 05:58 block says the layout format is the game build's to define, so
   this is a flag, not a request, and the art lane is not waiting on it.**
2. **Run `tools/_d93_validate.gd` against a town standing tier-3 hall** once
   Godot starts, and report OVERLAP / ON_ROAD for plot b001. Section 2 predicts
   a failure from the 4.08 m overhang; it is predicted, not observed.
3. Note `data/town/README.md` on branch `art` documents format
   `bellmire-town/1`; the 05:58 block refers content to `bellmire-town/2`. If
   /2 changed `off`/`half`, point 1 may already be answered - I could not check,
   having no git this run.

## 6. WHAT THIS SPEC DOES NOT ESTABLISH

**Nothing here was rendered, so none of it is a fit proof.** Every number is
geometry read off `.glb` bytes. That is blind to colour and material, blind to
whether the three tiers READ as a progression at a glance, blind to assembly
faults such as a gable hole that belong to no single node, and blind to
backface culling.

A chapel tier is not done until the three tiers are rendered side by side, on
the ground, at the stream camera, and **looked at**. The 4.08 m hall defect is
not closed until the validator has run. The companion rule is not proven until
a doorway with a leaf has been seen face-on.
