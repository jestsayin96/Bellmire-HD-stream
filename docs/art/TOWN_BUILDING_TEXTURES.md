# The town's buildings were shipped untextured, and this is how they were fixed

**28 Nov 2026, 02:0x-03:0x CT. Art lane. Branch `art`.**

## The defect

Every one of the **twelve** pack-derived buildings in `assets/buildings/`
carried **zero images and zero base-colour links**. All their materials sat at
Blender's default grey `(0.8, 0.8, 0.8)`. On stream the entire town - the
thing sup-nov27-2304 says viewers see 24/7 - rendered as flat grey massing.

Audited file by file off the actual meshes, not sampled and not remembered:

| file | materials | base-colour links | images |
|---|---|---|---|
| lm_barracks | 51 | 0 | 0 |
| lm_chapel | 50 | 0 | 0 |
| lm_granary | 29 | 0 | 0 |
| lm_hall | 49 | 0 | 0 |
| lm_sawmill | 28 | 0 | 0 |
| lm_watermill | 41 | 0 | 0 |
| lm_windmill | 21 | 0 | 0 |
| lm_workshop | 45 | 0 | 0 |
| mk_house_a | 39 | 0 | 0 |
| mk_house_b | 42 | 0 | 0 |
| mk_house_c | 44 | 0 | 0 |
| mk_house_d | 44 | 0 | 0 |

They were exported on 15 Nov from the Medieval Village MegaKit with the
textures stripped. Nobody had rendered one since, which is why it stood for
thirteen days.

### The three wells are NOT part of this, and my first audit libelled them

`town_well_t1/t2/t3` also report **zero images**, and my first pass flagged
them. **That flag was wrong.** The wells are solid-colour meshes built by
`lordlib.mat_solid`; their colour lives in the Base Color *default_value*, not
in a texture, and they render correctly. The honest test is not "has images"
but "is the base colour still the default grey **and** unlinked", and that is
the test `towntex.py` applies. A gate that cannot tell a painted material from
an unpainted one is not a gate. The wells were not touched.

## Why this is a relink and not a repaint

Nothing was invented. The stripped export kept the two things that make the
original recoverable, and both were **measured before any fix was attempted**:

1. **The UVs are intact.** 225/225 meshes in `lm_hall` carry a `UVMap` inside
   0..1. This mattered: relinking textures over missing UVs produces garbage,
   and garbage is not something a thumbnail would have shown me.
2. **The material names survived**, suffixed by Blender's import de-duplicator
   (`MI_Plaster.011`, `MI_Brick.004`). Strip the `.NNN` and every one is a real
   material in the pack. The *object* names survived too
   (`Corner_Exterior_Brick.050`), which is independent corroboration that these
   buildings are MegaKit assemblies and not something else.

So `tools/art/towntex.py` harvests the **nine real material datablocks** from
the pack's own glTF files - whole node graphs authored by Quaternius, not
reconstructed by me - and reassigns them by name. Source modules, chosen so all
nine are covered with no guessing:

| module | materials taken |
|---|---|
| `Wall_Plaster_Door_Round` | MI_Plaster, MI_RockTrim, MI_WoodTrim |
| `Wall_UnevenBrick_Straight` | MI_UnevenBrick |
| `Wall_Plaster_Window_Wide_Round` | MI_Brick |
| `Roof_Tower_RoundTiles` | MI_RoundTiles, MI_MetalOrnaments |
| `Roof_Wooden_2x1` | MI_WoodTrim_Wear |
| `Door_1_Round` | MI_WindowGlass |

`MI_WoodTrim_Wear` and `MI_WindowGlass` were each **checked against the module
that uses them** rather than assumed: the wear material resolves to the
`T_WoodTrim_*` set (the pack ships no `T_WoodTrim_Wear` map) and the glass
material carries no texture at all. That is why the gate accepts
`n_mat - 1` linked base colours and names the one that is legitimately plain.

## The size trade, and the first answer that was wrong

The pack's maps are 2048 and total 51.58 MB. My first cut - drop normals,
downscale to 1024 - still shipped 14 images and took `lm_hall` from 1.0 MB to
**28.1 MB**. **Every gate was GREEN over that**, because no gate I had asks "is
this file sane to commit"; twelve of those is 336 MB of repo for one visual
fix. The file size caught it, not an instrument. Second cut:

- **Base colour only.** Normal and roughness/ORM maps are dropped.
- Roughness and metallic are **not guessed** when their map goes: the map's own
  channel mean is measured and written in as a constant, so the surface keeps
  roughly the finish Quaternius gave it. ORM packs O/R/M into R/G/B, so the
  mean is taken over **that socket's own channel** - a whole-image mean would
  hand the roughness slot the occlusion map's average.
- Base colour exports as **JPEG q90 at 1024**. All seven textured materials
  here are opaque; the one pack map that needs alpha (`T_VineLeaf`) is not used
  by these buildings.

Result: **lm_hall 28.1 MB -> 2.24 MB.** Whole set 11.0 MB -> 23.5 MB, i.e.
**+12.5 MB** for the entire town. Reverse it with `--px 2048` and by restoring
the normal branch if these ever have to carry a close-up.

## Result

| file | tris before | tris after | images | mats | linked | MB |
|---|---|---|---|---|---|---|
| lm_barracks | 132238 | 132238 | 7 | 9 | 8 | 2.40 |
| lm_chapel | 110780 | 110780 | 7 | 9 | 8 | 2.33 |
| lm_granary | 30590 | 30590 | 7 | 9 | 8 | 1.87 |
| lm_hall | 119062 | 119062 | 7 | 9 | 8 | 2.14 |
| lm_sawmill | 33048 | 33048 | 6 | 8 | 7 | 1.73 |
| lm_watermill | 29936 | 29936 | 7 | 9 | 8 | 1.79 |
| lm_windmill | 50284 | 50284 | 6 | 8 | 7 | 1.51 |
| lm_workshop | 41252 | 41252 | 7 | 9 | 8 | 2.10 |
| mk_house_a | 33368 | 33368 | 7 | 9 | 8 | 1.92 |
| mk_house_b | 29644 | 29644 | 7 | 9 | 8 | 1.74 |
| mk_house_c | 35508 | 35508 | 7 | 9 | 8 | 1.96 |
| mk_house_d | 36418 | 36418 | 7 | 9 | 8 | 1.97 |

**Triangle count is identical on every file** and every mesh kept its UV layer
- both gated, because a relink that silently drops geometry is a worse bug than
the grey it fixed. Material slots collapsed from **21-51 down to 8-9**, which is
a draw-call win that came free with the remap.

## What the gates cannot see, and what looking showed

The relink gate proves a texture is **present and linked**. It cannot prove the
texture landed on the **right surface or the right way up** - a plaster map on a
roof passes every number in it. `towntexsheet.py` adds a chroma gate
(saturation mean over the building's own pixels; flat grey measures ~0.00, all
twelve now measure 0.22-0.33) and that still cannot see a mis-mapped surface.

So the sheet was **looked at**: `renders/art/town/_texfix_sheet.png`. Plaster on
walls, round tile on roofs, dressed stone on towers and footings, wood on
shutters and framing - the relink landed correctly on all twelve.

### Faults visible in that sheet, reported because they are real

1. **Every roof is the identical red round tile.** Twelve buildings, one roof
   colour. This is the blocker for the tier work: a level-1 Bellmire and a
   level-12 Bellmire currently cannot look different, because the only roof in
   use is the prosperous one.
2. **`lm_windmill` has no sails.** It is a bare stone tower with a conical tile
   roof - geometrically `Roof_Tower_RoundTiles` on a tower shaft. A windmill
   without sails does not read as a windmill at any distance.
3. **`lm_sawmill`, `lm_watermill` and `lm_granary` do not read as their
   function.** No saw, no water wheel, no granary doors; all three are houses.
4. **`mk_house_a`, `_c` and `_d` are near-duplicates** at a glance.
5. `lm_barracks` reads as a house with a small tower - no yard, no racks - and
   `lm_chapel` as a house with a tower, with no bell, cross or markers.

None of these are regressions from this run; they are what the grey was hiding.

## Wiring the game build lane must do

**Nothing in code.** No path, name, pivot, scale or triangle changed - this is
a content-only change to twelve existing `.glb` files, all of which already
have their `.glb.import` siblings and keep them.

The one operational note: because the `.glb` **contents** changed, Godot will
re-import all twelve on the next editor run. If the game build keeps a
`.godot/` import cache in its own worktree, it should let one import pass
complete before judging how the town looks.

## Licence

Medieval Village MegaKit [Standard], Quaternius, **CC0 1.0 Universal**, licence
read off disk and already recorded in `docs/art/ASSET_SOURCES.md` (~line 703).
The buildings were already derived from this pack on 15 Nov; this run restores
that pack's own textures to them and introduces **no new source**.
