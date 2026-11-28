# The Chapel, tiers 1-3 - THE MEASUREMENT PASS ONLY. NO MESH BUILT, AND THAT IS DELIBERATE.

**28 Nov 2026, 03:34-04:0x CT. Art lane.** Written during a bridge outage: the
Blender/Godot/git bridge refused every call this run, so nothing could be
rendered, imported, committed or pushed. What a Python-only run can honestly
produce is the pass that has to come FIRST anyway.

## Why the chapel, and why nothing was built

The well ladder shipped ~01:0x CT and the Hall ladder ~02:50 CT, both GREEN.
Standing order 1 (sup-nov27-2304, Mr. E direct) puts town buildings at the head
of the art queue and the deadline order forbids waiting for a row, so the next
item is the next landmark. Taken off content's own
`data/town/bellmire.json`, MEASURED not remembered: 66 placed buildings, five
named landmarks - `lm_hall` (done), `lm_chapel`, `lm_barracks`, `lm_windmill`,
`lm_workshop`. The temple district carries `b019` at `special_level` 11, the
second-highest special level in the town, and a spire is the tallest thing a
viewer sees after the hall tower. **The chapel is next.**

Nothing was built because **the build is not the first step and the Hall just
proved it.** The Hall's design doc chose `Wall_Plaster_WoodGrid` off its NAME
("timber-framed"); the module is an open timber lattice and tier 1 rendered as
a building you could see straight through. Every gate in the house passed it.
Writing `chapelgen.py` right now would mean choosing chapel modules off their
names again, with the bridge down and no way to render the result - the same
mistake with the instrument that catches it unplugged.

## What was written instead: `tools/art/_chapelmeasure.py`

Ready to run the moment the bridge is back:

    blender -b -noaudio -P tools/art/_chapelmeasure.py -- \
        --out renders/art/town/_chapel_measure.json \
        --shots renders/art/town/_probe/chapel

It differs from `_hallmeasure.py` in the two ways that matter:

1. **It enumerates the packs by pattern instead of measuring a hardcoded list
   of 16 names.** The hardcoded list is where the lattice got in.
2. **It renders every wall-like candidate FACE-ON and runs
   `townlib.solidity` on it**, then sorts the table so siblings sit together.
   A wall whose `hole_frac` sits far above its siblings' is a lattice, an
   arcade or a railing whatever its name claims. Azimuth and elevation are
   both 0 on purpose: an angled shot fills a lattice's own gaps.

Camera distance and clip planes come from the measured bounds (trap 1), bounds
come off the evaluated depsgraph (trap 3), and `red_on_empty` is inherited - a
module that renders under 1000 px is logged as an ERROR, not as a clean wall.

## What the measurement CANNOT settle, so do not let it

- **Material, not just geometry.** `hole_frac` says nothing about colour. This
  is live: the Hall's tier 2 -> 3 step is already weak because both tiers wear
  the same plaster and the same red tile, so that step reads almost entirely as
  SIZE. Mr. E's rule 2 says wear is the variable. The chapel's three tiers must
  separate by MATERIAL AND CONDITION, not by scale - plan for daub and a
  shingled lean-to at T1, dressed stone and leaded glass at T3.
- **Gable holes.** A two-slope roof over a four-wall box leaves the gable
  triangles open, `solidity` is blind to it (the opening sits at the silhouette
  edge and reads as background), and the Hall shipped that hole on two tiers
  before the side-by-side sheet caught it. **Assume the chapel has it and close
  it in the builder.**
- **The pivot.** `lm_hall.glb` is 1.92 m off-centre, which is why the Hall
  became a new mesh family rather than a retexture. `lm_chapel.glb` has NOT
  been checked for this. The measure pass reports its centre; if it is off,
  the chapel ladder is a new family too and the pivot is taken off the CORE
  (walls and roof), never off the whole assembly with its yard - re-centring on
  the whole assembly is the defect that dragged Hall tier 3 two metres north.

## Pack licence

Medieval Village MegaKit and the Castle pack are the two roots. Both must be
confirmed against `docs/art/ASSET_SOURCES.md` before anything derived from them
ships; the Hall sheet already carries "MEGAKIT. CC0." on its face and the
pack-catalogue worker is the authority. Any sourced piece records the pack and
a reproducible derivation, to the tier-5 spear's standard.

## Status

- [x] Next item chosen off content's data, measured
- [x] `tools/art/_chapelmeasure.py` written, syntax-checked
- [ ] Measurement run - **BLOCKED, bridge down**
- [x] **Module choice made off the table - 28 Nov 06:4x CT, in
      `docs/art/TOWN_TIER_FIT_SPEC.md` section 3.** Every module chosen by a
      MEASURED number (solidity from `_modcover`, tris from `_glbprobe`), not
      by its name - names are how the lattice got in. Includes the companion
      rule, the forbidden lattice, and the 258x corner saving.
      NOT a render, so NOT a fit proof.
- [ ] Pivot confirmed on a built tier - spec'd off the nave (finding 3 +
      the plot's own `off [0.0, 1.92]`), unbuilt
- [ ] `chapelgen.py`, three tiers, side-by-side sheet, looked at
