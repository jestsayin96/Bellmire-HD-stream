# THE HALL: THE T2 GABLE AND THE T3 COURT. BOTH DEFECTS ARE IN MY OWN
# SHIPPED WORK, AND FOUR OF MY OWN INSTRUMENTS WERE WRONG ON THE WAY.

**28 Nov 2026, 14:34-16:0x CT. Art lane.** Rowed by the plan's TAKE THIS NEXT
block, ART (:34): *"TWO HALL DEFECTS, AND ONE OF THEM IS ON STREAM RIGHT NOW."*
Both block `HALL_T3_FITS`, which is one constant in the game build's hands.

Everything below is measured off the files. No Godot run and no lock claim:
the three `.glb` names are unchanged, so their `.import` siblings still serve.

---

## 1. T2's GABLE - THE CAUSE IS NOT WHAT THE ROW SAYS, AND T1 HAS IT TOO

The row says the gable "renders as flat untextured white", that every other
panel on the wall is plastered and framed, and that **"T1's gable is textured,
so it is t2-specific."** The first two are exactly right. The third is wrong,
and I would rather say so than quietly fix one tier.

Measured, `renders/art/town/_probe_uv.json`:

| tier | gable material | has UV layer | gable area |
|---|---|---|---|
| t1 | `gable_board` | **false** | 13.38 m2 |
| t2 | `gable_board` | **false** | 46.10 m2 |

**Both tiers wear the same flat untextured board and neither has a UV layer at
all.** T1's is simply 3.4x smaller, sits under a deep thatch overhang, and is
close in tone to the thatch beside it, so nobody had ever called it. The defect
is shared; only its VISIBILITY is t2-specific. One fix serves both.

### Why it reads as white when the source says brown

`gable_board` is `(0.44, 0.36, 0.26)` and that is a plausible brown - but
`mat_solid` writes straight into the Principled **Base Color** socket, which is
**LINEAR**. A value picked as an sRGB swatch therefore renders about two stops
light: 0.44, 0.36, 0.26 linear reaches the screen as **sRGB 177, 161, 140**,
the pale beige the game build saw. Read back off the shipped
`town_hall_t2.glb` to be sure (`_probe_gable.json`), so this is the file's own
number and not an inference.

**THIS IS A HAZARD WIDER THAN THIS FILE AND I HAVE NOT SWEPT IT.** Every
authored colour in `hallgen.py` is in the same socket. `THATCH` and `BENCH`
were tuned BY EYE against a render, so they are correct as they stand and I
left them alone; flipping five constants blind in a run about two other
defects would be the opposite of changing one thing at a time. Only `BANNER`
and `BANNER_TRIM`, which nobody had ever looked at close up, are restated.
**Any other lane carrying hand-picked colours into a linear socket should
check its own.**

### The fix

1. The gable triangle now wears the kit's own `MI_Plaster` - the datablock the
   wall modules already imported, so no new image is embedded.
2. **It is given UVs, and that is the half that is easy to miss.** A material
   swap alone would have sampled a single texel and left the triangle exactly
   as flat as the colour it replaced. Density is measured, not chosen:
   **0.48031 uv/m** = `uv_area / world_area` off `Wall_Plaster_Straight`, one
   tile per 2.082 m, which is the kit's own 2 m grid.
3. Plain timber framing, procedural and therefore original: a tie beam, a king
   post, and on t2 the two barge boards and a pair of struts. **Wear is the
   variable** - t1 gets the tie and post only, because a moot hall is make-do.
   The pack's own gable on `lm_hall` is framed this way; I matched it by eye.

**The barge boards shipped rotated the wrong way on my first pass** - `ry` was
`-side*theta` where rotation about Y sends (1,0,0) to (cos a, 0, -sin a), so
the board needs `+side*theta`. The render showed four timbers crossing the
slope and stabbing a metre out past the tile. **Every number in the report was
green.** The picture caught it.

## 2. T3's COURT - 4.078 m OVER THE PLOT, AND THE RAILING WAS ON THE ROAD

`TOWN_TIER_FIT_SPEC.md` section 2 predicted this from the numbers; the game
build then saw it on stream. Shipped tier 3 measured **19.784 m** deep against
a plot that allows **15.70**.

**It cannot be fixed by making the court shallower.** The hall body is
13.801 x 15.706 and plot b001 (`data/town/bellmire.json`, `half [6.9, 7.85]`)
allows 13.80 x 15.70, so there is **no ground at all** in front of the south
door. Anything laid there overhangs by construction. Widening the plot is
forbidden by the spec: that pushes an art defect into content's authored town.

So the court goes where there IS free ground inside the plot, and the free
ground is measured. `free_ground_rect` rasterises every triangle of the body
between z 0.02 and 1.60 and returns the largest empty rectangle: on `lm_hall`
that is **4.00 x 10.00 m**, the open strip east of the nave and north of the
tower. Ten `Floor_Brick` tiles and five fence panels, railing along the court's
outer edge, all inside the plot.

Result: **13.8013 x 15.7059** - the body's own footprint to the millimetre.
Over plot by 1.3 mm and 5.9 mm, which is what `lm_hall` itself measures and
what the spec calls exact. **Dressing overhang: 4.078 m -> 0.000 m.**

## 3. FOUR INSTRUMENTS OF MINE WERE WRONG, AND THE PICTURE CAUGHT THREE

This is the part worth keeping.

1. **The occupancy probe sampled VERTICES.** A flat wall panel has vertices
   only at its corners, so it reported wide empty bands straight through solid
   walls. Rewritten to rasterise triangle bounding boxes, which over-marks
   rather than under-marks - the safe direction for "where may I build".
2. **The first court was paved INSIDE THE HALL.** The largest free rectangle
   on `lm_hall` is the nave interior, 6.0 x 12.0 m, bigger than any yard
   outside. Eighteen tiles went down indoors and **both my overhang gate and
   my tile-count gate called it GREEN** - the subject absent, the gate passing.
   Fixed by flood-filling the free cells from the border: only ground reachable
   from outside is ground.
3. **The banners were hung off `min y`, which is the EAVE and not the wall.**
   The barge board overhangs the gable wall by ~0.8 m. That added a fresh
   0.121 m overhang - introduced by the very run that was removing a 4.078 m
   one - and **the new fit gate caught it**, which is the first time a gate of
   mine has caught me rather than the other way round.
4. **Three heuristics in a row put the gable in the wrong place.** Binning x
   over a tall band mixed a full-width storey with the narrowing triangle and
   gave centre x +1.60; binning over the banner band picked the TOWER, the
   widest thing at that height, and gave +3.87; and measuring the wall plane at
   the eave band rather than at the banners pinned them 0.04 m BEHIND the gable
   face, so they vanished inside it and the render came back with a clean
   plaster triangle and no banners - **and not one number in the report said a
   word about it.** `lm_hall.glb` carries `Roof_Front_Brick8`, the gable infill,
   named, the whole time: x -4.256..4.256 so the centre is exactly 0.0, z
   9.237..14.683. **When a part has a name, measure the part.**

## 4. THE NEW GATE

`build()` now fails loudly if a tier's footprint exceeds the plot read from
`data/town/bellmire.json` - content's own data, not a constant in this file.
**And it goes red on empty.** Ask what a PASS looks like with the subject
absent: drop the court and the railing altogether and the overhang test passes
perfectly, so the court tiles are counted too and zero is a failure. That
second clause is the only reason fault 2 above was findable.

## 5. WHAT I CAN SEE IN THE FINAL RENDERS, INCLUDING WHAT IS STILL WRONG

Looked at: `hall_t2/front.png`, `hall_t2/three_quarter.png`,
`hall_t3/front.png`, `hall_t3/three_quarter.png`, `_tiers_side_by_side.png`.
Gates: 3/3 GREEN, `errors: []`, 0 blank, **border alpha 0 on all 12 views**.

- t2's gable now carries plaster grain and a timber frame and reads as part of
  the same building as the storey below. The original defect is gone.
- The three tiers read as a progression at a glance: make-do thatch, framed
  tiled hall, stone hall with tower.
- t3's banners hang on the gable, deep red, flanking the centre line.
- **STILL WRONG / UNPROVEN:** the court paving does not read against the grey
  studio ground plane - `Floor_Brick`'s base colour is close to it. The tiles
  are there (10 of them, x 2.849..6.849, z 0.007..0.027, `_probe_court.json`)
  but **I cannot claim it reads, and it needs looking at on the real terrain.**
- The railing is **2.86 m tall** - taller than the hero's 2.453 m. That is the
  pack prop at native scale and it is tall for a court railing.
- The two barge boards do not meet cleanly at the apex; there is a small notch
  under the ridge on both tiers.
- From the front the railing reads as a single pale post, not a railing.
- The court is BESIDE the hall, not at the steps. See section 6.

## 6. ONE THING FOR THE SUPERVISOR, AND IT IS A REAL DECISION

Content's tier-3 line is *"a PAVED COURT and a guard at the steps."* **A court
at the steps cannot be built**: the hall body fills its authored plot to within
6 mm, so there is no ground in front of the south door. The court is now beside
the hall, on the only free ground inside the plot. Either that is accepted, or
plot b001 grows - which is content's data and not this lane's to change.
(The guard remains deliberately unbuilt: a guard is a character, the miniboss
roster is capped at 70, and a town NPC is not a building asset.)

LICENCE: unchanged. Medieval Village MegaKit [Standard], Quaternius, CC0 1.0,
recorded in `docs/art/ASSET_SOURCES.md`. Modules placed unmodified on the kit's
2 m grid; the thatch, bench, lamp, banners and all gable framing are
procedurally generated here and are therefore original.
