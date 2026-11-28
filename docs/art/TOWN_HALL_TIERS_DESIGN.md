# The Hall, tiers 1-3 - the measured design, before any of it is built

> **STATUS, 28 Nov 2026 ~03:0x CT: BUILT.** The ladder shipped as
> `assets/buildings/town_hall_t1/t2/t3.glb` via `tools/art/hallgen.py`,
> verdict GREEN. **Three numbers in the design below were wrong and the build
> corrected them - see `docs/art/TOWN_HALL_LADDER.md` for what the pictures
> said.** The biggest: `Wall_Plaster_WoodGrid` was chosen off its NAME and is
> an OPEN TIMBER LATTICE, so the first tier-1 render was a hall you could see
> straight through.

**28 Nov 2026, ~01:5x CT. Art lane.** This is the design handoff for the
plan's ART row ("the next town progression building, chosen off content's
`town_buildings` landmark list"). **Nothing here is built yet.** Every number
below was measured this run, not remembered, so the next firing can start
building instead of re-probing.

## Why the hall, and what content already says

`data/lore_lines.json -> town_buildings.landmarks` carries seven landmarks:
`hall, chapel, barracks, windmill, workshop, market_hall, inn`. **`hall` is
taken** - it is the civic centre, it sits in the `keep` district, and its
three-tier text is the clearest ladder in the list. Content's `see` lines are
the spec:

| tier | name | content's `see` |
|---|---|---|
| 1 | The Moot Hall | "A timber hall with a **thatch** roof, one door, a bench outside." |
| 2 | The Chief's Hall | "**Stone footings**, a **tiled** roof, a **stair** to an upper room, a lamp at the door." |
| 3 | The Hall of Bellmire | "A **stone hall with a tower**, **banners** on the gable, a **paved court** and a guard at the steps." |

`tier_levels` = {1: level 1, 2: level 5, 3: level 9}.

## TIER 3 LARGELY EXISTS ALREADY - DO NOT REBUILD IT

`assets/buildings/lm_hall.glb` is **already a stone hall with a tower**: a
gabled three-storey range, a square stone corner tower with a conical tiled
spire and a metal finial, stone footings, timber framing above, shuttered
windows. Looked at, not assumed: `renders/art/town/_probe/lm_hall_tex/`.
Measured **13.80 x 15.71 x 22.41 m**, 119,062 tris, 225 meshes.

Against content's tier-3 line it is missing only **banners on the gable**, the
**paved court** and the **guard at the steps**. That is dressing on an existing
building, not a new building.

### The pivot defect, which must be fixed before any swap

`lm_hall.glb`'s bounds centre is **x = +1.9246, y = +0.0242** - it is **1.92 m
off-centre in X**. The well ladder's contract is that all tiers share ONE pivot
(footprint centre, ground level, z = 0) so the game build swaps the mesh at a
single unmoved spawn point. If tier 3 keeps this pivot the hall will **jump
1.92 m sideways** on upgrade.

**Recommended:** leave `lm_hall.glb` untouched (whatever already references it
keeps working) and ship the ladder as a new family -
`town_hall_t1/t2/t3.glb` - with t3 a re-centred copy. That costs one export
and breaks nothing.

## The kit, measured - the grid every tier must be built on

Source: **Medieval Village MegaKit [Standard]**, Quaternius, **CC0 1.0**,
cleared (`ASSET_SOURCES.md` ~line 703). 176 glTF modules. It is a **modular
kit - walls, doors, roofs, corners - not whole buildings**, which is exactly
what a tier ladder needs. `lm_hall` and the other eleven buildings are already
assemblies of it, so a hall ladder built from it will match the town by
construction.

| module | dims (m) | origin |
|---|---|---|
| `Wall_*` (all 20) | **2.0 x 0.4065 x 3.1227** | centred in X, base z = 0 |
| `Floor_*` | 2.0 x 2.0 x 0.02 | centred |
| `Corner_Exterior_Wood` | 0.21 x 0.24 x 3.00 | centred |
| `Corner_Exterior_Brick` | 0.53 x 0.58 x 3.02 | centred |
| `Stairs_Exterior_Straight` | 2.0 x 2.08 x 1.20 | centred |
| `Roof_RoundTiles_4x4` | 5.51 x 5.56 x 4.25 | covers a 4x4 box, ~0.75 overhang |
| `Roof_RoundTiles_4x6` | 5.51 x 7.57 x 4.23 | covers 4x6 |
| `Roof_RoundTiles_6x8` | 8.25 x 9.68 x 5.67 | covers 6x8 |
| `Roof_Tower_RoundTiles` | 5.65 x 5.43 x **7.36** | the tower spire |
| `Roof_Wooden_2x1_Center` / `_Center_Mirror` | 2.0 x 1.499 x 1.21 | one slope each, 2 m of ridge |
| `Prop_Chimney` | 0.95 x 1.0 x 3.18 | base z = 0 |
| `Prop_MetalFence_Ornament` | 1.95 x 0.16 x 2.85 | the tier-3 court railing |

**So the grid is 2 m, a storey is 3.1227 m, and walls sit base-at-zero.**

### The scale fact that decides everything, and it is a problem

The KayKit adventurer stands **2.453 m** with the helmet (measured
`_townhero_measure.py`, confirmed again this run). The kit's doors
(`Door_1_Round`, `Door_2_Round`, `Door_4_Round`) top out at **2.32-2.36 m**.

**The hero does not clear the kit's doors by about 10 cm.** Nothing currently
walks through one, so nothing is visibly broken today - but any tier whose
door a viewer watches a hero enter needs the building scaled by **>= 1.107**
(2.6 / 2.35). At 1.15 a storey becomes 3.59 m and a door tops at 2.70 m, which
clears. **This is a decision, not a fact** - see the bottom of this file.

### THERE IS NO THATCH IN ANY PACK ON DISK - CHECKED, ALL 49

Content's tier-1 line asks for a **thatch roof**. All 49 extracted pack
directories under `_packs\` were walked this run for `thatch|straw|reed|hay`:
the ONLY hits are `hay-bale.glb` and `hay-bale-bundled.glb` in
`kenney_graveyard-kit_5.0`. **No thatch roof exists to derive from.** The
MegaKit's nine materials carry no thatch either.

So tier 1's roof must be **procedurally generated** (bmesh, the way
`townbuild.py::_shingles` already makes the well's shingle courses), giving a
hybrid: pack wall box + authored thatch cap. That is the one piece of this
ladder that cannot come from a pack, and it is also where the wear lives.

## The ladder, as specified

| | T1 - The Moot Hall | T2 - The Chief's Hall | T3 - The Hall of Bellmire |
|---|---|---|---|
| footprint | 4 x 6 m (2x3 modules) | 6 x 8 m (3x4) | 13.8 x 15.7 (existing) |
| storeys | 1 (3.12 m) | 2 (6.25 m) | 3 + tower |
| walls | `Wall_Plaster_WoodGrid` (timber-framed), 1x `Wall_Plaster_Door_Flat` | `Wall_UnevenBrick_*` below, `Wall_Plaster_*` above | as built |
| corners | `Corner_Exterior_Wood` | `Corner_ExteriorWide_Brick` | as built |
| roof | **procedural thatch** (no pack source) | `Roof_RoundTiles_6x8` | as built + banners |
| extras | a bench, no paving | `Stairs_Exterior_Straight`, a lamp | `Floor_Brick` court, `Prop_MetalFence_Ornament`, banners |
| wear | patched, no paving, sagging ridge | kept, coursed, paved step | prosperous, dressed, railed |

**WEAR IS THE SPEC, AND THE TEXTURE RUN EXPOSED THE BLOCKER.** Having relinked
all twelve buildings this run I can state the problem precisely: **the kit
ships ONE roof - `MI_RoundTiles`, the same red tile - and every building in
the town now wears it.** A tier-1 and a tier-12 Bellmire currently cannot look
different, because the only roof in use is the prosperous one. Tier separation
therefore has to come from, in order of how much it buys:

1. **roof** - procedural thatch (T1) vs round tile (T2/T3). The single biggest
   read at stream distance.
2. **footprint and height** - 4x6x1 storey vs 6x8x2 vs 13.8x15.7x3+tower.
3. **wall material** - plaster/timber vs uneven brick vs dressed stone, all of
   which the kit already has.
4. **dressing** - paving, railings, banners, a lamp.

## Gate for the build, unchanged from the well

Three tiers rendered **SIDE BY SIDE through ONE camera at ONE ortho scale**,
with the measured Knight for scale, and the progression must read **at a
glance**. Blank, border, subject-moved (RED ON EMPTY below 1500 px), hero-seen
and label gates as in `tools/art/townbuildgen.py`. **And the sheet gets
looked at** - no number in that harness can say "tier 3 reads as richer than
tier 1".

New gate this ladder needs, learnt from the texture run: **a committed file
size sanity check.** Every gate went green over a 28.1 MB `lm_hall`.

## FOR MR. E / THE SUPERVISOR - one decision, and only one

**Should the town's buildings be scaled up ~1.15x so the hero fits through a
door?** Today the kit's doors are 2.32-2.36 m and the adventurer is 2.453 m.
Nothing walks through a door yet, so nothing looks wrong on stream right now,
and leaving it alone costs nothing today. But if viewers will ever see a hero
enter a building, every building in `assets/buildings/` wants the same scale
factor applied at once - which is cheap now and expensive after the town
layout is placed against the current sizes.
