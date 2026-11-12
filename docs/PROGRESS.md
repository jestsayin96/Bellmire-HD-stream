# PROGRESS

Updated at the end of every build cycle. Newest entry at the top.

## D-cycle D1 - D18a PROP/BUILDING SANITY (desktop, Nov 12)
- tools/_d18a_test.gd: a sanity sweep over Town.tscn. Check A (grounding): 1034 ground props, base vs height_at at
  the prop's own origin; props on a steep slope (crag/mine/mountain/bank), surface/mounted/water dressing, dock
  props over the river, and planter-box flowers are classified out by rule, not by eye. Check B (interpenetration):
  the 83 building instances (mk_house_*, lm_*) tested as ORIENTED footprints (the engine's own _solid_of math) -
  axis-aligned AABBs falsely overlapped rotated neighbours, oriented ones do not. Result: D18A_TEST OK, 0 floaters,
  0 building overlaps.
- Investigated every flag the raw probe raised; all were intended: wall lanterns (2.3 m), tower crossbowmen on the
  watchtowers (~11.7 m), shop/smithy table + rack dressing, flowers planted in raised planter boxes (_planter builds
  a 0.45 m box + soil), bucket/barrel on the raised dock over the riverbed, water lilies/boats, the scar-mouth rock
  crag deliberately set on the mine slope (height_at - 0.8 + lift), and the two outlying farm cottages nestled into a
  foothill at the _low seat. No game script needed changing - the town was already clean.
- Shot sheet renders/cycles/20261112_d18a (1366x768): west_gate, bridge, market_square, street, scar_mouth, docks,
  town_aerial, farmstead_slope, hamlet_north. Looked at: wall ring + towers + gates + roads all connect, the timber
  bridge spans the river level on its pier, houses sit on the ground (hillside cottages read as nestled, not clipped),
  props grounded with connected shadows - nothing floats.
- Standard checks clean: parse 0, _offfloor 0/1615 (0 INPROP), _twitch_parse OK, _townwalk in_solid 0/7801 stuck 0,
  _delve_test 0 SCRIPT ERROR. (Note: real-mode renders need `--headless --import` once first to settle the UID cache.)


## NEXT UP
1. **Fix MegaKit assembly** (`village_assets/tools/megakit.py`). Current output
   is "legos in the wrong spot":
   - Windows are bare openings. The wall modules have holes; the `Window_*`
     and `WindowShutters_*` parts were never inserted into them.
   - Doors likewise — `Door_*` never placed into `DoorFrame_*`.
   - Roof is wrong. `Roof_RoundTile_2x1` is 3.297 wide and spans the INNER
     width of a 2-module house. It does not fit 3-module houses. Pick roof
     parts by building width; `Roof_Front_Brick4/6/8` cap 4/6/8 m.
   - Gable ends currently render as bare timber trusses sticking into the air.
   Measure each part's bounding box before placing it. Render and look.
2. Port the lore text and chronicle lines from the old `NOTES.md` into data
   files in this project.
3. Town generation on hex coordinates with continuous ground.

## NEEDS MR. E
- Nothing blocking right now.

## DONE
### Cycle 13 - 2026-11-08 07:20  (grass + real water)
- assets/shaders/ground.gdshader: trodden dirt inside the town fading to grass
  outside it, blend driven by WORLD position (no UVs needed), edge broken up
  with value noise so the footprint is ragged rather than a clean circle.
- GRASS TEXTURE: every grass set in the Poly Haven library is dry and
  yellow-brown (sampled: leafy_grass 0.59/0.52/0.35, sparse_grass
  0.31/0.24/0.08 ...). Used leafy_grass as T_Meadow_* and tinted it in the
  shader (grass_tint 0.62/0.95/0.42). There is no green grass texture to pick.
- assets/shaders/water.gdshader: two scrolling noise normals + fresnel alpha.
- Water is now ONE continuous strip mesh built along river_pts instead of a
  transparent PlaneMesh per segment. The per-segment quads overlapped and the
  doubled-up alpha caused the banding. Gone now.
  Renders: town_river.png, town_aerial.png

## STILL WRONG
- Dirt footprint is a circle (town_r 100) but the town is wide, so its east
  and west ends sit on grass. Make the mask elliptical or derive it from
  distance to the nearest road/plot.
- Grass still reads slightly yellow from the god camera; push grass_tint.
- Water colour a little pale/turquoise.
- No bridge, gate, wall or people.

### Cycle 12 - 2026-11-08 07:05  (river)
- A RIVER runs through the valley south of the town. World-space polyline
  (double-sine meander, 41 points, x -300..300 around z 125), NOT hex cells -
  it has to bend freely and cut a gorge where it leaves through the hills.
- river_dist(x, z) = distance to the centreline. height_at() carves the bed
  with a smoothstep over RIVER_W + RIVER_BANK, so the bank slopes in rather
  than dropping as a cliff at the waterline. Water surface is flat at y -0.9.
- Plots and trees test river_dist before they place. MEASURED: plots stayed at
  201, so the river runs clear of every house as designed; nature 211 -> 206
  (five trees moved off the water).
- New probe shot "river" in tools/_town.gd.
  Renders: town_aerial.png, town_river.png - the riverside shot is the first
  one that reads as a PLACE: town on the near bank, river bending away into a
  gorge through the rim.

## SCHEDULING
Mr. E: blocks were finishing well before the next one fired. Schedule the next
block ~10 minutes after each one finishes, not 30.

## STILL WRONG
- Water is a flat milky ribbon with faint banding where segments overlap.
  Wants a single continuous mesh and a simple shader (scrolling normal map,
  fresnel) instead of one transparent quad per segment.
- Banks and valley floor are bare dirt everywhere; grass on the floor outside
  the town and on the banks would help most.
- No bridge - nothing crosses the river yet. A road south to a bridge would
  give the river a reason to be there in play.
- No gate, no wall, no people.

### Cycle 11 - 2026-11-08 06:52  (terrain)
- THE GROUND HAS HEIGHT. height_at(x, z) is the single source of truth:
  a FLAT valley floor out to VALLEY_R (150 m) with a few cm of simplex
  ripple, then hills rising to HILL_RISE (26 m) beyond it.
  Flat-in-the-middle is deliberate, not lazy - it means streets stay walkable
  and no house straddles a slope, WITHOUT needing a separate pass to flatten
  road and square cells afterwards. Bellmire is a valley town, so the town
  belongs on the valley floor anyway.
- Ground is a generated ArrayMesh, 160x160 quads over the map extent, with
  normals and tangents from SurfaceTool rather than hand-computed.
- EVERYTHING now samples height_at() when it is placed: houses, props, trees,
  road ribbons and square paving. A prop that ignores it floats or sinks the
  moment the rim starts rising.

## BUG: the ground rendered BLACK and invisible from above
Triangle winding. I emitted [a, c, b, b, c, d]; Godot culls back faces, so
from above every triangle was facing away and you saw straight through to the
clear colour. [a, b, c, b, d, c] is correct. If a generated mesh is invisible
from the side you expect to see it, suspect winding before lighting.

## STILL WRONG
- The valley reads subtly because the town fills most of the flat floor; only
  the far rim shows. Either shrink VALLEY_R toward the built area or raise
  HILL_RISE so the bowl is legible from the god camera.
- No river yet. Bellmire is canonically a valley MARKET town on a river; the
  old game has river cells and a water shader (trial-and-error/town.gd
  _watery(), READ ONLY) worth studying.
- No gate, no wall, no people.

### Cycle 10 - 2026-11-08 06:50  (props, market stalls, trees)
Bellmire is dressed. 201 houses, 90 props, 211 trees and bushes.
- Imported from kits Mr. E already owns, nothing downloaded:
  assets/props/   Quaternius Fantasy Props - Barrel, Barrel_Apples, Bench,
                  Crate_Wooden, FarmCrate x3, Stall_Empty, Stall_Cart_Empty,
                  Anvil_Log, Workbench, Banner_1      (30.6 MB)
  assets/nature/  Quaternius Nature - CommonTree 1-5, Pine 1-3, two bushes
                                                       (11.4 MB)
- TRIMMED THE TEXTURES. First copy took every PNG in each source folder:
  77.6 MB. Parsed the .gltf files for their image URIs and deleted the
  unreferenced ones - nature fell 39.9 -> 11.4 MB. Always copy the models,
  then keep only the textures the models actually name.
- _dress_square(): 2-5 props scattered per square cell, stalls and produce
  crates among them.
- _dress_streets(): props sit against the FACADE, derived from the plot's own
  yaw (fwd = the direction the house faces), never dropped in the
  carriageway - the same mistake the Blender props() made before it learned
  about setback.
- _scatter_nature(): trees and bushes only on cells with no road, no square
  and no plot, so nothing grows through a house or a street. They ring the
  built area, which reads as the valley around the town.
  Renders: village_assets\renders\town_aerial.png, town_street.png

## STILL WRONG
- No gate and no town wall; the ring road still ends at open ground.
- Flat plane, no terrain height anywhere. This is now the biggest single gap -
  a valley town on a billiard table.
- No people. The old game has roster.gd / villager.gd and KayKit characters
  ready to port.
- No river, despite Bellmire being a valley market town in the lore.

### Cycle 9 - 2026-11-08 06:42  (four house shapes, market square)
- EXPORTED THREE MORE HOUSES from house2 by varying wx/wy/floors:
    b  2x3, 3 floors  tall and narrow   0.57 MB
    c  4x3, 2 floors  wide, low front   0.80 MB
    d  3x5, 2 floors  deep              0.80 MB
  All four together are 2.9 MB. This is what the shared-material decision
  bought - the same four shapes would have been ~200 MB a cycle ago.
- town.gd HOUSES table carries a per-shape DEPTH (footprint + roof overhang),
  and the plot setback is derived from the chosen shape's depth. A single
  shared HOUSE_DEPTH would have put the deep model's front wall in the
  carriageway - the same class of bug as the original canyon.
- DISTRICT_SHAPES biases shapes by district: trades get wide fronts, keep and
  garrison tall narrow blocks, homes the plainer two. Measured spread over 201
  plots: a 86, b 50, c 35, d 30.
- MARKET SQUARE: the market district's centre hex and its six neighbours are
  cleared of plots and paved. 7 cells. A town needs somewhere that is neither
  a street nor a house.
  Renders: village_assets\renders\town_aerial.png, town_street.png

## STILL WRONG
- No gate, no town wall; the ring road still ends at open ground.
- Nothing on the square - no stalls, no well, no cross. It is just paving.
- No trees, props or people anywhere in the Godot town. megakit.py has props()
  for Blender but there is no equivalent here, and the kit's Prop_* parts have
  not been exported.
- Houses sit flat on a plane; no terrain height at all.

### Cycle 8 - 2026-11-08 06:34  (ground, back rank, variety)
- GROUND IS TEXTURED. MI_Grass.tres (brown_mud_02 as T_Dirt_*) - trodden earth
  rather than lawn, which is what a medieval town between buildings actually
  is. Triplanar, uv1_scale 0.14, albedo tinted to 0.72/0.66/0.52.
- BACK RANK. 45% of frontages now get a second house set back behind the first
  and facing the other way, so the blocks the ring encloses fill in instead of
  leaving a hollow middle. Plots 158 -> 193.
- VARIETY from one model: per-instance non-uniform scale (x 0.93-1.10,
  y 0.95-1.18, z 0.93-1.10). Deliberately NOT a 180 yaw flip - that turns the
  door away from the street, which is the entire point of deriving plots from
  roads.
- Cobble retuned to uv1_scale 0.28.

## THE BUG THAT COST THIS CYCLE - .tres FILES CANNOT CONTAIN # COMMENTS
I wrote explanatory `#` comments inside the [resource] block of MI_Grass.tres
and MI_Cobble.tres. Godot does not parse them: the resource loaded with
DEFAULT values, so the ground rendered pure white and the cobble was never
using its uv1_scale at all.
It looked exactly like a texture-cache problem, and I wasted a step renaming
T_Grass_* to T_Dirt_* chasing that theory before measuring. The texture was
always fine - sampled it at 0.30/0.27/0.22 brown, 2048x2048, file present.
RULE: keep commentary in the .gd files. A .tres gets properties only.
(The rename is harmless and stays, but it was not the fix.)

## STILL WRONG
- No market square, no gate, no town wall; the ring just ends at open ground.
- Still one house model. New shapes now cost <1 MB each, so export a second
  and third from Blender (vary wx/wy/floors in house2).
- No trees, no props, no people. props() exists in megakit.py for Blender but
  nothing equivalent in the Godot town yet.

### Cycle 7 - 2026-11-08 06:29  (ring road, cross streets, cobbles)
- _lay_roads() now lays a SPINE, a RING of eight waypoints around the core,
  THREE CROSS STREETS tying ring to spine, then a branch to each district
  centre. Blocks only exist where roads enclose something; a spine alone can
  never make a town.
  Added _cell_near(world) - nearest hex to a world position, a linear scan of
  437 cells. Cheap, and avoids hand-converting world coords back to offset
  coords, which is where this sort of thing usually goes wrong.
  MEASURED: road cells 46 -> 108, plots 113 -> 158, every district 6-26.
- ROAD IS COBBLED. cobblestone_03 copied in as T_Cobble_* (9.9 MB) with a
  MI_Cobble.tres. PlaneMesh UVs are 0..1, so a SHARED material cannot tile
  per-segment through UVs - it uses uv1_triplanar with uv1_scale instead,
  which tiles in world space regardless of quad size.
  First pass at uv1_scale 0.22 gave 2 m flagstones. The texture covers ~2 m of
  real cobbles, so it wants ~3x the repeats: 0.7 is right. Verified by eye at
  street level, not assumed.
- Road ribbon lifted 0.02 -> 0.06 above the ground to kill the seam.
  Renders: village_assets\renders\town_aerial.png, town_street.png

## STILL WRONG
- The ground between roads is flat untextured green. It needs grass/dirt, and
  ideally a worn verge where it meets the cobbles.
- Houses cluster on the OUTSIDE of the ring rather than filling the blocks it
  encloses - a plot only needs to touch a road, so interior cells go unused.
  Consider allowing a second rank set back behind the frontage.
- Still one house model. Cheap variety first: 180 deg yaw flip, slight
  non-uniform scale, more livery tints. New shapes now cost <1 MB each, so a
  second and third house export is also affordable.
- No market square, no gate, no wall.

### Cycle 6b - 2026-11-08 06:20  (Mr. E answered: "keep it simple")
SHARED MATERIALS. The size question is closed.
- Copied the kit's 26 textures into res://assets/kit/textures/ (25.2 MB, ONE
  copy, and that number does not grow with the town).
- Wrote 10 StandardMaterial3D .tres in res://assets/kit/materials/ - seven
  textured (Brick, UnevenBrick, Plaster, RockTrim, RoundTiles, WoodTrim,
  WoodTrim_Wear) and three flat (WindowGlass, MetalOrnaments, Vine, which have
  no texture set of their own). Plaster/RockTrim/WoodTrim use ORM maps, so
  roughness_texture_channel = 1 (green).
- Re-exported the house with export_image_format='NONE'.
  49.77 MB -> 0.75 MB. 66x. No visible change in the render.
- Deleted the 40 stale per-glb textures Godot had extracted from the old file.
- town.gd: _load_materials() loads the shared set and builds ONE tinted roof
  material per livery at startup; _dress() swaps by material name at
  instantiation. Replaces _tinted_roofs(), which duplicated a material per
  house.
- Whole assets/ folder is now 26 MB, including every texture the kit has.
VERIFIED: rendered in Godot, textures present, both liveries visible.

GDScript gotcha, twice now: iterating an UNTYPED Array gives untyped elements,
so `var path := KIT_MATS + n + ".tres"` fails to infer. Write the type out.
Same for indexing a PackedStringArray from split().

### Cycle 6 - 2026-11-08 06:14
STREETS. town.gd rewritten so ROADS COME FIRST and plots derive from them.
- _lay_roads(): a spine across the middle, then a branch from the spine to each
  district centre. _walk() steps to whichever neighbour gets closest to the
  target - cheap, always terminates, and the wander reads as organic.
- _plots_from_roads(): a plot must TOUCH a road and it FACES that road.
  Position is derived from the facade (rp - dir * (SETBACK + depth/2)), never
  from the cell centre. Yaw = atan2(dir.x, dir.z); the glb's street side faces
  +Z in local space.
- Each frontage now carries 1-2 houses offset along the street axis
  (perpendicular to the facing dir), so a 14 m hex gets a short terrace instead
  of one lonely house. Plots 60 -> 113.
- Road is drawn as a RIBBON along each road-to-road link at true carriageway
  width (9 m). One quad per hex had paved a 14 m plaza.
- LIVERY IS APPLIED at last: _tinted_roofs() walks the instance, finds surfaces
  whose material resource_name contains "RoundTiles", duplicates it and sets a
  per-instance override. Red is left neutral because the kit's tiles are
  already terracotta. Verified visually - blue-grey, tan and red roofs along
  one frontage.
- Density varies by district (market .95, craft .92 ... mill .40).
MEASURED: 437 hexes, 46 road cells, 113 plots, per-district 5-20.
  Renders: village_assets\renders\town_aerial.png, town_street.png

## STILL WRONG
- Only 46 road cells, so the town is one frontage deep along a thin spine. It
  needs a loop/ring road and cross streets to get real block structure.
- Road material is flat grey. It should use the MegaKit/Poly Haven cobble.
- Visible seams where the road ribbon overlaps the ground plane; lift the road
  slightly more or use a single merged surface.
- Still one house model, so every street is the same house repeated.

### Cycle 5 - 2026-11-08 05:39
The Godot project is now a game project, not an empty folder.
- scripts/lore.gd  AUTOLOAD. Reads res://data/*.json once at boot and exposes
  it. Carries standing() and rank_of() so the gold-buys-no-rank rule lives in
  one place.
- scripts/hex.gd   Hex COORDINATES only, no plates. COL_W 14.0 / ROW_H 12.12
  (ratio must stay 0.866 for a regular hex), 23 x 19 cells. pos / axial / dist
  / neighbours / all_cells. Sized so one hex holds a real 8x10 m house plus yard.
- scripts/town.gd  Bellmire generator: picks 8 district centres at least 4 hexes
  apart, assigns every hex to the NEAREST centre (organic borders, not radial
  sectors), colours districts by adjacency, lays plots, builds continuous
  ground + sky + sun, instances houses.
- Town.tscn is the main scene; project.godot wires the autoload.
MEASURED, not assumed: 437 hexes, 244 plots, districts 45-62 hexes each.
Livery check walked all 13 district borders: 0 violations.
  Renders: village_assets\renders\town_aerial.png, town_street.png

## HONEST ASSESSMENT - it is a skeleton, not a town
The aerial shows 244 houses scattered at random yaw on bare green ground. It
reads as sheds in a field. Three reasons, all fixable, in priority order:
1. NO STREETS. Plots come straight off hex centres with a jitter. There is no
   road network, so nothing orients the buildings and there are no frontages.
   Houses must face a street; that is what made the Blender street read.
2. LIVERY IS COMPUTED BUT NEVER APPLIED. livery_of is correct and verified,
   and then every house loads the same glb with the same red roof. Needs
   either per-livery roof material override at instance time, or four roof
   variants. This is tangled with the 49.8 MB question below - do not solve it
   by exporting four more 50 MB glbs.
3. ONE HOUSE MODEL, uniform density. Every district looks the same, so the
   organic borders the generator worked for are invisible.

## NEEDS MR. E (unchanged, still blocking asset layout)
- One house glb is 49.8 MB because glTF embeds every texture it touches.
  244 instances share one resource so runtime is fine, but four liveries x
  several house types at 50 MB each is unshippable. The fix is importing the
  MegaKit textures into the project ONCE and referencing shared materials.

### Cycle 4 - 2026-11-08 05:06
- LORE PORTED. res://data/ now holds seven JSON files, taken from the old
  NOTES.md verbatim where possible, not invented:
    world.json    Bellmire, the eight districts + livery-by-adjacency rule,
                  wild-magic scarring, both readings of Jests, the canon
                  silence about floor count
    classes.json  nine classes, sage vs cleric heal maths, mend/quaff rules
    bosses.json   eight bosses in two bags, shapes not bigger numbers
    strains.json  five strains with hp/atk/spd multipliers + depth gating
    ranks.json    seven guild ranks, standing formula, gold-buys-no-rank rule
    biomes.json   14 worlds + the measured note that grey halls only LOOK dark
    origins.json  eight origins, inverted causality, chronicle word order
  VERIFIED IN GODOT, not just Python: a throwaway --script parsed all seven
  with JSON.parse_string. Result ok=7 bad=0. Probe deleted.
- props() now hugs the facades. It was placing crates at +-3.2..4.4 from the
  centreline, i.e. in the carriageway. Takes `setback` and lands just inside it.
- 12-house street rendered, carriageway clear:
  village_assets\renders\mk_street4.png
  village_assets\buildings\megakit_street_04.blend  (1192 objects)

## MY MISTAKE THIS CYCLE - and the lesson
Editing megakit.py by truncating at a marker ("s[:s.index('def props(')] + new")
DELETED everything after that marker: house2, _slot, INSERTS, ROOF_W/ROOF_D,
GROUND_SLOTS, UPPER_SLOTS. It kept working for one more call only because
importlib.reload() executes new source into the EXISTING module namespace - it
does not remove names you deleted from the file. So a stale in-memory house2
met a freshly redefined roof_for and raised ValueError.
Two rules from this:
  1. Never write a file as head + new_tail unless you intend to drop the tail.
     Use an exact string replace, and assert the result still contains the
     symbols you expect.
  2. To test a module you have restructured, delete it from sys.modules and
     import fresh. reload() hides deletions.
The file was rebuilt with ONE implementation (house2 only; house() is gone),
which also ends the two-session collision. A timestamped .bak sits beside it.

### Cycle 3 - 2026-11-08 04:30
- CANYON BUG FIXED, and it was not cosmetic. street_row() positioned houses by
  CENTRE: y = side * (6.0 + jitter). house2 centres the building on its origin,
  so a 10 m deep house put its front wall 1 m from the road centreline - inside
  an 11 m road. The buildings were standing in the street.
  street_row() now takes `setback` = road centreline -> FACADE, and derives
  y = side * (setback + back + D/2). Measured after the fix: closest facade is
  5.48 m from the centreline against a 5.5 m road half-width. Clear.
  Also: gaps 1.8-3.4 m with occasional 5-7 m, and 30% of plots set back with a yard.
- The "floating roof fragment" was the same bug - a house standing in the road,
  seen end-on. Gone now. No separate fix needed.
  Render: village_assets\renders\mk_street3.png
- GODOT PIPELINE CLOSED. house2 -> glTF -> Godot 4.6.1, verified in-engine:
  63 meshes, AABB 8.32 x 11.14 x 9.68 m (correct real-world scale), full PBR
  textures, shadows, SSAO. First --import succeeded first try this time.
  assets/buildings/mk_house_a.glb
  Render: village_assets\renders\mk_house_godot.png
  MegaKit models already carry UVs, so export_gltf.py's hand-built UV pass is
  NOT needed for kit houses - only for the old primitive-built townhouse.

## NEEDS MR. E
- mk_house_a.glb is 49.8 MB because glTF embeds a copy of every texture it
  touches. One house. A town of these is unshippable. The fix is to import the
  MegaKit textures into the Godot project ONCE and have house meshes reference
  shared StandardMaterial3D resources, rather than shipping textures per-glb.
  That is a design decision about asset layout - worth his call before building
  the town importer on top of it.

## STILL WRONG
- Crates land in the middle of the road; props() should hug the walls.
- Upper-storey shutters sometimes sit beside a window rather than on it.
- Street dead-ends into empty ground; needs an end (gate, wall, square).

### Cycle 2 - 2026-11-08 03:56
- GABLE FIXED. Roof_RoundTiles_* is tiles only; the triangle between wall-top
  and ridge was open and you could see sky through the house. Capped both ends
  with Roof_Front_Brick<rw>, sized to the ROOF width (rw from roof_for), not
  the wall width. Verified by rendering the gable end head-on:
  village_assets\renders\mk_gable.png
- street_row() now calls house2() (it still called the broken house()).
  Footprint mix widened to wx 2-4, wy 3-5 now that roofs are picked properly.
- Rendered a 10-house street, two rows: mossy terracotta roofs, jettied
  half-timbered upper storeys, stone ground floors, glazed windows with
  shutters, cobbles, crates. This is the look.
  village_assets\renders\mk_street2.png
  village_assets\buildings\megakit_street_02.blend  (856 objects)

### LIGHTING RULE (third time this bit me - write it down)
With view_transform 'Standard' the SKY TEXTURE is what blows the image out,
not the sun. A physical sky returns radiance many times a flat colour of the
same strength. Working values for an exterior daylight street:
    ShaderNodeTexSky strength 0.055, sun energy 0.85, exposure -0.15
A flat-colour world can sit near 0.30 with sun 1.9. Do not reuse flat-world
light levels with a sky texture.

## STILL WRONG (next cycles)
- Houses sit almost shoulder to shoulder; the street reads as a canyon.
  Widen the gap and vary the setback.
- A small roof fragment floats mid-air near the centre of mk_street2.png -
  probably a roof placed for a house whose walls are shorter. Investigate.
- Upper-storey shutters sometimes sit beside the window rather than on it.

### Cycle 1 - 2026-11-08 03:22
- Measured EVERY Window/Door/Roof/Overhang/Balcony/Stairs part before placing
  anything. Findings now treated as fact:
  - Window_* and WindowShutters_* are ALREADY positioned for a storey
    (Window_Wide_Round1 spans local z 1.016..2.742). They go in at the SAME
    transform as their wall - no offset maths.
  - Door_* are hinged, not centred: Door_1_Round spans x -0.046..1.074.
  - Roof_RoundTiles_<W>x<D> are COMPLETE roofs for a W x D metre building.
    13 of them: 4x4 4x6 4x8 / 6x4..6x14 / 8x8..8x14. Hand-assembling slopes
    and gable trusses was the whole "legos in the wrong spot" bug.
- house2() renders correctly: glazed arched windows, open+closed shutters,
  studded door with ironwork, stone ground floor with quoins, half-timbered
  upper storey, mossy tile roof, chimney. VERIFIED by render, not assumed.
  Saved: village_assets\buildings\megakit_house_01.blend
  Render:  village_assets\renders\mk_house2.png

## COLLISION - TWO SESSIONS ARE EDITING megakit.py
At 03:19:44 another session wrote to village_assets/tools/megakit.py while
this one was mid-edit. The file now holds TWO implementations: house() +
roof_for() (this session) and house2() + _slot() + ROOF_W/ROOF_D + a second
roof_for() (the other). The LATER roof_for wins at import, and it returns a
3-tuple, so calling the earlier house() raises TypeError.
Do not "fix" this by deleting one blindly - confirm with Mr. E which session
owns this file. For now house2() is the working path; prefer it.

### Cycle 0 — 2026-11-08 ~02:50
- New empty Godot 4.6.1 project confirmed at
  `C:\hd adventure\jests-hd-medieval-adventure`.
- Chose the Quaternius Medieval MegaKit as the building set (already owned;
  nothing downloaded). 176 modular glTF parts, 2 m grid, 3.123 m storey.
- Wrote `village_assets/tools/megakit.py`: imports each module once and places
  linked duplicates, so a street costs one import per distinct part.
- Assembled a test house and an 8-house street. Geometry assembles; walls,
  corners, half-timbering, arched doorways and roof trusses all land.
  BUT the placement is wrong — see NEXT UP.
- Read the old `NOTES.md` (2,316 lines) and extracted the lore spine into
  PLAN.md.
- Wrote PLAN.md and this file.

## BUGS FOUND AND FIXED (do not rediscover)
- **AgX tone mapping crushes this kit's albedo to white.** Looks exactly like
  missing textures. Cost an hour of chasing the wrong cause. Render with
  `view_transform = 'Standard'`, and note Standard clips hard above 1.0, so
  keep sun energy near 1.0 rather than 2.5.
- **Blender matrix_world is identity on freshly created objects** until the
  depsgraph updates. Call `bpy.context.view_layer.update()` before reading it,
  or every piece collapses onto the origin.
- **Poly Haven folders all contain `Diffuse.jpg` / `nor_gl.jpg` / `Rough.jpg`.**
  Cache images by folder+filename, never basename, or every material reuses
  whichever set loaded first.
- **MegaKit .gltf texture paths resolve against the open .blend, not the gltf,
  and the PNGs live in `../Textures`.** Call `megakit.fix_textures()`, then
  touch `im.pixels[0]` to force the buffer to load.
- **Godot's first `--import` on a fresh project crashes with 0xC0000005.**
  Run it a second time; that works.


## Cycle 14 - countryside, river, bridge
- ground.gdshader: dirt only inside an elliptical town mask (town_r 172x104, fade 0.22, noisy edge); greener grass outside (tint 0.50/0.92/0.34).
- water.gdshader: darker deep/shallow colours.
- town.gd _build_bridge(): x=0 road runs south from the ring to a timber bridge at z=130 (6.4 m deck, railings, posts every 2.4 m, 4 piers, cobble approaches).
- Lesson: MegaKit trim-sheet materials (MI_WoodTrim) go half white on BoxMesh UVs -> use a duplicate with uv1_triplanar + tint for primitive meshes.
- Verified render town_river.png: deck shows wood planks, no white.
- Next: gate + town wall where the spine leaves the ring; dress the market square; people (port villager roster, keep old character look).


## Cycle 15 - wall, gates, market square
- _build_wall(): ellipse fitted outside every plot (+13 m), 236 stone segments + merlons as two MultiMeshes, world-triplanar MI_UnevenBrick (scaled boxes would stretch object UVs), round towers every ~45 m with cone roofs, river cut = open gap flanked by towers.
- No road reached the wall at first, so no gates. Spine now carried out east/west to the wall -> 2 gatehouses (taller towers + arch lintel) at x=+-167, road continues 90 m into the country.
- _road_strip(): roads outside town are ONE terrain-following strip; separate flat quads stepped and gapped on the hills.
- _clear_gate_lanes(): plots on the gate lane removed (a house stood inside the west gate); nature skips the lanes too.
- Market square laid out: well (stone ring, water, posts, roof) in the centre, 6 stalls/carts on a ring facing it between the streets, goods beside each, benches, banners.
- PROP_SCALE 1.45: Quaternius props were toy-sized next to real-scale MegaKit houses.
- Probe now also shoots town_square.png and town_gate.png (positions come from stats()).
- Next: people - port villager roster from old game (read only), old character look.


## Cycle 16 - people
- Copied KayKit Character Pack Adventures (5 bodies, weapons, textures, 18.9 MB) into addons/ at the SAME res:// path as the old game, and rig.gd verbatim, so later ports of villager/roster code need no path edits. Old game untouched.
- scripts/townsfolk.gd (class Townsfolk): the walking half of villager.gd - same models, same tints, same pace 0.62, Idle/Walking_A, name tag (pixel 0.008, hidden beyond 32 m). home -> work -> home on a loop.
- town.gd: old ROSTER (role, body, tint, headcount) mapped to districts; 30 roster people + 14 plain townsfolk = 44. Merchants stand behind the square's stalls facing the well; 4 guards hold the two gates; the rest walk.
- town.route(): nearest road hex -> BFS over road hexes -> destination, walkers keep 1.8 m right of centreline.
- Verified renders town_square.png / town_people.png / town_gate.png.
- Next: check PLAN.md for the next milestone (dungeon entrance / player / HUD); people currently walk to a point in front of a door, not inside.


## Cycle 17 - shops, watchtowers, placement rules (Mr. E: "a tree should not be in the middle of a road")
- ONE placement test, is_clear(p, r): not within r+0.5 of any carriageway EDGE (_road_segs = every road-hex link, bridge road, gate roads), not on the square, not in a house footprint, not on a registered structure (_objs), not in the river, not on the wall line. Used by trees, bushes, street props, countryside, bridge tower. 90-100 bad spots rejected per build.
- House footprints measured from the meshes (_measure_houses: a 8.2x9.7, b 5.5x7.6, c 10x10.3, d 8.2x11.9). Frontages were spaced 4.6 m for 8-12 m wide houses, so pairs stood inside each other. Now over-propose 3 per frontage + 2 back, then _resolve_overlaps() (oriented-rect SAT) keeps only what fits, frontages first. 122 houses, zero overlaps.
- Shops (_pick_shops / _dress_shops): a street-facing house + a fenced yard beside it (the yard replaces the next plot) + a signpost with the trade name + a keeper. 10 shops: 2 blacksmith (stone forge with live coals + light, chimney, anvil, whetstone, workbench), 2 armourer (weapon stands, training dummies, table with sword/shield/axe), 2 apothecary (glowing green cauldron, bottle shelves, potions on the table), 2 general store, 2 tavern (tables, stools, mugs, kegs). Things on tables sit on the measured table top (_top).
- Watchtowers: 2 in the garrison + 1 guarding the bridge; stone shaft, corbelled crenellated top, arrow slits, door, red pennant, lantern, a guard on top.
- Countryside: 170 trees/bushes on the hills outside the wall, same clearance rule (keeps off gate roads).
- Copied 30 Quaternius props + 5 MegaKit props (assets/mkprops, textures re-pointed to kit/textures).
- Probe rewritten: shot list built from stats() - aerial, low_aerial, street, river, square, one per shop type, tower.
- Next: shops/taverns as gameplay hooks (old roster gear economy buys from the armourer/blacksmith); interiors later.


## Cycle 18 - district landmarks, enterable buildings, saving (Phase A1, partly)
- tools/landmarks.py (village_assets): MegaKit landmarks exported geometry-only - lm_hall (3 storeys + 5-storey tower),
  lm_chapel (nave + bell tower with spire), lm_barracks (two blocks + gate tower), lm_windmill, lm_granary, lm_watermill.
  Tower door bug fixed (the two-step test cancelled itself; no tower had a door).
- Builds run in their own Blender scene (LM_BUILD) - an earlier run cleared the open scene (megakit_street_04.blend,
  unsaved changes only; file on disk untouched).
- SAVING (Mr. E 07:41: save every finished variant that can serve other purposes): every landmark export also writes
  buildings/variants/<name>_<stamp>.glb and buildings/landmarks/<name>_<stamp>.blend; tools/run_probe.py keeps every
  render set under renders/cycles/<stamp>_<label>/ and a packed snapshot of the generated town under
  snapshots/town_<stamp>_<label>.tscn (generator script stripped). (Saving added by a parallel session at 07:40; adopted.)
- town.gd: _plant_landmarks() per lore - landmark planted at each district centre FIRST, facing its road, with a 4.5 m
  forecourt nothing may build on. Hall carries the canon inscription "MEASURE THE GRAIN. COUNT THE FLASKS. KEEP THE DOOR."
  over the door, livery banners, lamps, flagpole. Chapel: bronze bell, lamp, small graveyard. Barracks: drill yard
  (dummies, racks), banners. Windmill: four lattice sails turning (_spinners/_process). Granary: sacks. Watermill on the
  far bank outside the wall on a stone plinth, wheel in the river turning.
- ENTERABLE BUILDINGS: door positions read from each glb (street-most Door_* node) -> plot door / door_in. Townsfolk walk
  the streets to the real door, step in, vanish indoors for 18-45 s, come back out. Roles work inside their landmark
  (chief->hall, healer->chapel, fletcher->barracks, farmer->granary, miller->windmill). Headless 80 s run: 7-12 indoors,
  ~25 walking at any time (tools/_people_test.gd).
- Next (A1 rest): craft workshops row, lumber mill, mine in the hills, archery range; then A2.


## Cycle 19 - the rest of A1 (workplaces) + the valley and its mountains
- New landmark builds (landmarks.py, appended; saved as variants + .blend): lm_workshop (craft quarter hall, yard with
  workbenches + timber stack + banner), lm_sawmill.
- Outworks outside the wall (old roster workplaces): Lumber Mill past the west gate with log stacks, stumps, axe and a
  stand of pines; Mine cut into the eastern hillside (searches for a real slope), timber-framed dark mouth, lamp, rails,
  sleepers, wagon, spoil, dirt track; Archery Range south of the east road - shooting rail, rack, bench, four straw butts
  with painted rings, fenced lane. Roles now work there (lumberjack->sawmill, miner->mine, fletcher->range,
  smith->workshop). route() sends walkers out through the nearest gate for anything outside the wall.
- _road_strip(dirt=true) for tracks, and resampled every 2 m (long segments buried themselves under hills).
- THE VALLEY (lore: "a valley market town"; "a meadow sits under a mountain"): ground mesh 1520 m, foothills rising into a
  ridged mountain ring, and THE mountain north of town (peak ~175 m at z=-470) - the dungeon scar will open at its foot (A3).
  ground.gdshader: slope -> bare rock, altitude -> snow, macro colour variation in the meadow. Distance fog/aerial
  perspective; sky ground colour matched. No more void past the map edge. River extended to +-700 so it runs out of the frame.
- 32 more Quaternius nature pieces copied in (rocks, dead/twisted trees, grasses, flowers, ferns, mushrooms, pebbles,
  rock paths) for A2/A3.
- A1 DONE. Next: A2 street furniture (lanterns, benches, flower boxes, livery banners) + grass/flowers; A3 fields,
  farmsteads, the scar at the mountain's foot.


## Cycle 20 - FISHING (Mr. E 07:51: "a fishing mechanic, sorta how Minecraft does it, junk to rare items")
- data/fishing.json - loot table: 7 fish (Mud Carp .. The Grinning Carp), 7 junk (Old Boot, Tangled Line, Fish Bones,
  Leaky Bucket, Lily Pad, Old Bone, Drowned Skull), 7 treasure (Coin Pouch, Rusted Key, Sealed Bottle with a note,
  Silver Chalice, Gilded Key, Sunken Chest, Scar-Glass Shard). Rarity common/uncommon/rare/epic/legendary, gold value,
  flavour text. Names follow canon (river comes down from the mountain past the scar). Bottle notes are canon-safe lines
  (the inscription; "the dungeon is still being built").
- scripts/fishing.gd (class Fishing, pure rules, no scene): Minecraft model - category roll fish 85 / junk 10 / treasure 5,
  LUCK -2.5 junk / +2.1 treasure per level; bite wait 5-30 s, -5 s per LURE level; 1.1 s bite window; 3% of fish
  SCAR-TOUCHED (rarity +1, value x3, glow). cast_result() resolves a whole cast for chat/offline.
  Verified over 20,000 rolls: luck 0 -> 84.6% fish / 10.5% junk / 5.0% treasure; luck 3 -> 2.4% junk / 11.5% treasure;
  avg wait 17.5 s.
- scripts/angler.gd (class Angler): the visible loop - CAST (bobber arcs out) -> WAIT (bobs) -> BITE (yanked under,
  splash ring) -> REEL (catch flies out of the river) -> SHOW (held overhead, RARITY + name in rarity colour) -> IDLE;
  misses show "It got away...". Rod + line (sagging ImmediateMesh), red/white bobber, catches use real models (fish tinted
  per species, chest, keys, chalice, bottle, skull, lily...), a built boot, glow light on scar-touched/legendary.
- town.gd: two timber docks on the town bank (plank gaps, piles, mooring post, bucket, barrel, rowboat), a fisher on each,
  70 lily pads along the banks. fishing_log records every catch. go_fish(hero, luck, lure, skill) is the entry point for
  chat (!fish) - rolls the cast and, if a dock is waiting, plays that exact catch there. Wire to chatcmd when it is ported.
- Fixed while reviewing renders: held catch was hidden behind the head (now held overhead), catch label overlapped the
  name tag (raised), rod tilted backwards over the shoulder (sign of the X rotation).
- Renders: village_assets/renders/fishing/. Test tools: tools/_fish_rolls.gd (distribution), tools/_fish_shot.gd.


## Cycle 21 - A2 streets + meadow
- _street_furniture(): iron lamp posts with hanging glowing lanterns + warm OmniLight down every street (37), every other
  pair carries a hanging banner in the district's livery colour; planters with flowers beside front doors (16); benches
  round the square. Placement uses _kerb_ok(): off the carriageway, off the square, not inside any house's REAL oriented
  footprint (_in_house), not on any registered structure.
- _meadow(): 25,820 grass tufts, clover, wildflowers, ferns and mushrooms as 8 MultiMeshes (8 draw calls, no shadows,
  hidden beyond 260 m), outside the wall only, never on roads/tracks/river, not on the high slopes. Quaternius tufts are
  modelled ~1.5-3 m tall - first pass was a jungle; scaled to ~0.3 (knee height).
- Probe: meadow shot now sits at height_at()+1.7 (first one was under the hillside); street_low shot added.
- A2 DONE except: the square only fits 1 extra bench (stalls + streets take the ring) - fine.
- Next: A3 fields + farmsteads + the wild-magic scar at the mountain's foot.


## Cycle 22 - A3 countryside + THE SCAR
- THE SCAR (lore: botched casting scars the ground; the dungeon is one enormous scar - a meadow under a mountain).
  _find_scar(): where the valley floor meets the mountain on the line north of town. ground.gdshader: scorched dark-violet
  ground within SCAR_R=30 m, thin glowing veins (violet->cyan, flickering out of step). 34 scar-glass crystals in
  disagreeing colours, tilted, breaking out of the ground; dead + twisted red trees round the rim; 5 lights pulsing out of
  step (_pulses, uneven double-sine); rising motes whose hue wanders (every spell misfires in turn).
  Accident-vs-deliberate is NOT answered anywhere on screen (canon).
- THE MOUTH: cut into the slope beyond the scar, arch of fallen rock, black opening, violet light pulsing deep inside.
- GUILD POST on the Delvers' Road before the scar: two torch posts, red barrier pole, board reading "KEEP THE DOOR."
  (canon inscription), garrison-livery banner; two gate guards stand there.
- Delvers' Road: north gate gap in the wall, cobbles ring->gate, dirt track gate->post->mouth. Houses on that line cleared.
  _gatehouse no longer lays its generic cobble run-out on the scar side (it was running into the scar).
- FIELDS: 8 fenced fields outside the wall on flat-enough ground (wheat MultiMesh rows / vegetable rows on tilled soil
  mesh draped on the terrain, fence with a gap on the town side). Meadow grass stays out of fields and the scar.
- FARMSTEADS: up to 3 - farmhouse (mk_house_d) + barn (lm_granary), haystacks, cart, dirt track to the nearest road.
  Farmers now work at the farms (ROLE_LANDMARK farmer -> farm).
- _spawn_raw accepts .glb (crystals were silently missing). Road strips lift with slope (track broke up on the hill).
- Probe: scar, scar_mouth, guild_post, fields, farm, north shots; camera heights via height_at.
- A3 DONE. Next: A4 animals (Quaternius farm animals: convert .blend/.fbx -> glb in Blender; pens at farms, herds, birds).


## Cycle 23 - A4 ANIMALS
- Converted Quaternius Farm Animals (.blend, no glTF shipped) -> assets/animals/{Cow,Horse,Pig,Sheep,Pug,Llama}.glb with
  all 6 actions each (Idle, Walk, WalkSlow, Run, Jump, Death) as NLA tracks; copies in village_assets/library/animals.
  Built in throwaway scenes (ANIM_*), Mr. E's open scene untouched.
  Bug: they rendered pure white - each material has 3 outputs and the active one is a Diffuse BSDF the glTF exporter
  can't read. Fix: rebuild each material as one Principled node with its own diffuse colour before export.
- GobKit Duck, Corgi, Red (fox) copied (single 'clip' animation).
- Source scales are all over the place (9 m cow, ~400 m duck) -> ANIMALS table gives each a real-size scale + speed.
- scripts/animal.gd (class Animal): wanders inside a rect, idles between moves, finds walk/idle animations by prefix,
  ducks ride the water surface with a bob.
- town.gd _spawn_animals(): a fenced pen with trough at each farmstead (cows / sheep / pigs), a horse + llama paddock
  (kept clear of the river - first try put it IN the river), duck flotillas on the river, pugs and corgis round the
  square, a fox at the sawmill woods, birds wheeling over the valley and crows over the scar (flapping wings). 27 animals.
- Lesson: a NEW class_name script needs `godot --import` before a --script run, or town.gd fails to parse and the probe
  hangs. Long probe runs go in a background thread in Blender and are polled (tool calls time out at 60 s).
- A4 DONE. Next: A5-A7 equipment (port Rig.equip + FAMILIES tiers + glow), clothing per class/role, magic + spell FX.


## Cycle 24 - A5 EQUIPMENT
- scripts/gear.gd (class Gear): ported old roster FAMILIES (blade/axe/arcane/ranged, 4 meshes each), WEAPONS tiers
  (bare hands / plain steel 60g / fine steel 160g / runed 420g smoulders / dragontooth 1100g burns; size + glow, numbers
  unchanged) and ARMOUR tiers (rags..warded plate, 5E AC); Rig.equip -> Gear.equip on KayKit handslot.r/l + chest bones,
  Gear.ignite (old smoulder colours). dress_hero(family, tier, offhand) ready for the roster port.
- ROLE_GEAR: every trade carries its kit - guards sword+square shield; gate guards halberd+badge shield; tower lookouts
  2h crossbow; chief staff+closed book; healer staff+open book; apothecary wand+book; smith hammer+tongs; miner
  pickaxe+lantern; lumberjack axe; farmer shovel; fletcher bow+quiver on the chest; innkeeper two full mugs; trader map;
  merchant ledger; miller saw; peasants mug/lantern/torch or empty-handed. 30 KayKit RPG-tools/weapon-bits copied to
  assets/gear (tools scaled 0.62 to suit the Adventurers' hands).
- Tier racks at the armourer (blades) and blacksmith (axes): the 4 bought tiers on a stand, each labelled name + price in
  rarity colour, runed/dragontooth glowing with their own light.
- Probe: per-role close-ups ('kit_<role>') aimed at the person at shot time (they walk), rack shot.


## Cycle 25 - A6 CLOTHING
- KayKit bodies unchanged (Mr. E's standing call). FOUND: every body file carries its whole prop set as extra meshes
  (Knight: 2H sword, 1H sword, offhand sword, 4 shields; Barbarian: mug + 3 axes + shield; Mage: staff, wand, 2 books;
  Rogue: knives, 2 crossbows, throwable) and they ALL showed at once - in the old game too. Gear.strip_props() hides every
  non-body mesh (body = Leg/Head/Body/Arm/Cape/Helmet/Hat), so only the equipped gear is held. They arrive under
  BoneAttachment3D like ours, so ours are told apart by the "eq_" name, never by node type (first try hid nothing).
- Gear.clothe(): capes in the district's livery colour (by workplace district), role cloaks override - chief deep blue
  with a faint gold sheen, healers white, apothecaries green, guards/gate guards/lookouts garrison blue, fishers slate,
  miners soot. Old per-role body tints kept.
- Gear.rank_trim(): guild rank worn as a sash on the chest bone (Unproven bare -> Novice bronze -> Delver grey ->
  Journeyman blue -> Veteran silver -> Master gold -> Grandmaster glowing violet). Townsfolk have none; heroes set rank.


## Cycle 26 - A7 MAGIC + SPELL FX  (PHASE A COMPLETE)
- scripts/spells.gd (class Spells): BOLT (glowing orb + halo + spark trail + light streaks to the target, bursts with a
  shock ring and sparks), HEAL (green motes rise round the target, swelling ground ring), WARD (shimmering rim-lit shell
  pops up with a bounce, holds, fades, glints), MEND (golden motes arc hand -> target on bezier paths, soft glow).
  Every FX node frees itself. CAST_ANIM maps each to a KayKit cast animation.
- WILD MAGIC, canon rule "inside a scar every spell misfires IN TURN": a cast in a scar comes out as the NEXT spell in
  ORDER (bolt->heal->ward->mend->bolt), tinted toward scar-violet, with a violet crackle. town.in_scar(p).
  Verified: all 8 casts (4 clean, 4 in the scar) fire and map exactly.
- In town: healers heal whoever is nearest, the chief wards, apothecaries mend, every 14-30 s.
- Gallery renders: village_assets/renders/spells/ (tools/_spells.gd stages caster+target in open meadow and on the scar road).
PHASE A (Bellmire pristine) DONE: landmarks, streets, countryside + scar, animals, equipment, clothing, magic, fishing.
NEXT: PHASE B - monsters and bosses (port bestiary.gd + data/bosses.json + data/strains.json; models from old game
addons + Quaternius monster packs in village_assets/monsters), then PHASE C dungeon pieces. More townsfolk after town.


## Cycle 27 - PHASE B: BESTIARY + LORDS
- scripts/bestiary.gd (class Bestiary): old game's TYPES / STRAINS / BOSS_DEFS / DEPTHS / next_boss ported, canon and
  numbers unchanged (strains measured to improve survival - not softened). Widened with 8 owned creatures the old game
  never used: giant rat, cave spider, bog frog, pit viper, scar adder (Quaternius Easy Enemy Pack, converted from .blend
  with the white-material fix), blood wasp, imp, puglin (Quaternius Bestiary). DEPTHS weave them in: vermin up top, venom
  mid, fiends deep. 15 creature types + dragon body; 6 strains; the 8 canon lords (no invented bosses).
- SIZE: every creature/lord has a real height in metres ("h"); Monster scales the body to it from its own measured
  bounds (body-space walk - global transforms weren't resolved yet at _ready). Lords: Hollow King 4.2, Grubmother 4.5,
  Rattling Host 4.4, Nightwing 3.2, Pale Duchess 4.6, Ossuary Lord 7.0, Gravewyrm 9, Mourncoil 10. Strain scale applies.
- Imp + Puglin ship rigged but with NO animations (T-pose). Their rig is the Quaternius Universal rig, so Monster grafts
  the owned Universal Animation Library (UAL1/UAL2, copied to assets/monsters) onto them: idle/walk/jog/sword/spell/death.
- scripts/monster.gd (class Monster): body + anim map + Gear arms (strip KayKit built-in props) + strain tint/glow; states
  IDLE / PATROL (wander an area on ground_fn) / ATTACK (casters throw Spells.bolt, others play their attack). Lords add a
  breathing ground aura, glowing ring, rotating crown of light, rising motes, a light, and title + canon note overhead.
- Gallery: tools/_bestiary.gd (own flat stage; every creature, the 6 strains on a warrior, 8 lords each beside a 1.8 m
  knight for scale). Renders: village_assets/renders/bestiary/. Library: village_assets/library/monsters (all glbs).
- Next: Phase B rest - monster.gd combat polish (hit react, death, damage numbers), boss entrance; then PHASE C dungeon
  pieces (Quaternius Modular Dungeon blends + KayKit Dungeon Remastered: walls, floors, gates, cells, debris, traps, lava).


## Cycle 28 - PHASE B DONE: combat polish + lord entrance
- monster.gd: hurt(amount, crit) -> white hit flash (all body surfaces, 0.12 s, restores strain glow), hit animation,
  floating damage number (white; crits gold, bigger, with '!'), death at 0 hp: death animation, aura off, sinks into the
  floor and frees. hp from def (lords use canon boss_hp). entrance(): the lord rises out of the ground over 2.2 s in a
  ring of its own-colour embers, title + canon note overhead, shock-ring burst when fully up.
- tools/_fight.gd: knight + healer vs a 5-skeleton pack (one emberbound), numbers, two deaths, then the Ossuary Lord
  rises. Verified renders (village_assets/renders/bestiary/fight_*.png, lord_*.png). (Fight camera aims before the stage
  is in the tree - harmless test-tool framing issue.)
PHASE B DONE. Next: PHASE C dungeon pieces.


## Cycle 29 - PHASE C: DUNGEON PIECES
- KayKit Dungeon Remastered copied whole into addons/kaykit_dungeon_remastered (203 pieces: 16 wall types incl. doorway,
  gated, arched window, broken, cracked, scaffold, shelves; dirt/tile/wood/grate/spike floors + foundations; pillars,
  columns, 8 stair types, barriers; beds, tables, chairs, shelves, kegs, barrels, crates, trunks, chests, coins, keys,
  banners in 6 colours x 7 patterns, candles, torches, rubble). Library copy: village_assets/library/dungeon.
- Quaternius Modular Dungeon: 20 pieces the KayKit set lacks converted from .blend (separate scenes, Principled material
  fix) -> assets/dungeon: Arch, Arch_bars, Arch_Door, Cobweb x2, Spikes, Trap_spikes, Trap_empty, Trapdoor (+open),
  Statue_Horse, Woodfire, Pedestal x2, Skull, Sword_WallMount, Column2, Bag_Coins, Vase, Fence.
- scripts/dungeon_parts.gd (class DungeonParts) - what neither kit has, built in code, each self-animating:
  lava_pool (assets/shaders/lava.gdshader: two-layer drifting fbm, cooling crust cracking to bright melt, vertex swell,
  emission + rock rim + embers + orange light), spike_trap (16 spikes punch up/hold/sink loop), pressure_plate (sinks,
  glowing rune), fire_trap (grate roars flame in bursts with light), portcullis (iron grid in a stone frame winds up and
  slams down), cell (barred 3 sides + hinged barred door with lock, straw pallet, bucket, wall chain; open/closed),
  debris (scaled rubble, bricks, column drum, skull), scar_glass (out-of-step glowing crystals for scar floors),
  torch_lit (mounted torch + flickering light + embers), kit(name) loader for both kits.
- tools/_dungeon_cat.gd: torch-lit catalogue hall with every category; 9 views in village_assets/renders/dungeon/.
  Fixed from review: lava was under the floor tiles (now on the floor in a raised rim, pit cut in the catalogue); fire
  jet was a white blob (additive blend + huge particles); KayKit rubble is room-scale (x0.35); wall shot blocked by stairs.
PHASE C first pass DONE. Next: assemble pieces into rooms/floors (port floorgen.gd/dungeon.gd from the old game, READ
ONLY), biomes from data/biomes.json, place monsters by depth band, lords on boss floors; then more townsfolk (Mr. E).


## Cycle 30 - DUNGEON FLOORS ASSEMBLED
- scripts/floorgen.gd: the old game's FloorGen PORTED VERBATIM (49 KB: 8 themes + 14 biomes with floor/wall tint and
  scatter, prop CLUSTERS, 6 shapes via shape_for (all six in every six floors), origins (origin_for), rooms + corridors
  occupancy grid, lava pools that REPLACE tiles, stairs entry/exit, lighting). Works unchanged because the KayKit Dungeon
  Remastered kit and the hex-kit nature decorations are at the same res:// paths (addons/kaykit_dungeon_remastered,
  addons/hexkit - nature decorations only, 140 files).
- scripts/dungeon_hd.gd (class DungeonHD, Dungeon.tscn): FloorGen.build, then Phase C pieces by theme - traps (1 + depth/3:
  spike / pressure / fire), debris piles, prison cells on prison floors, portcullis in crypt/shrine/treasury, SCAR-GLASS
  growing with depth (none above floor 3, up to 5 clusters) on interior cells only; monsters from Bestiary.pick(depth)
  (3 + depth/2, max 9; FloorGen spawns topped up from open interior cells); on every 5th floor Bestiary.next_boss ->
  Monster lord placed in the open interior cell FARTHEST from the entry (first try put it on the exit stairs), rises via
  entrance(). Floor COUNT is never stated (canon) - only the floor number is used.
- tools/_floors.gd: floors 1 (mess hall, cross), 5 (barracks, cavern, lord), 9 (shrine, hall): plan + in-room views
  (camera steps into an occupied cell 2 away and looks back - the first pass sat on the wall tops).
- Boss name labels reduced (0.009) so they read inside a room.
PHASE C DONE (pieces + floors). Next: MORE TOWNSFOLK (Mr. E 07:41: "add more of them as well after you finish the town").


## Cycle 31 - MORE TOWNSFOLK (Mr. E 07:41)
- Population 56 -> 134 (perf: avg frame 7.2 ms, ~140 fps at 1280x720 with everyone walking; ~50 on the move, the rest
  at work/indoors). Roles added: 46 everyday folk with a full DAY (Townsfolk.stops loop: home -> workplace -> market ->
  sometimes tavern, sometimes chapel, each with its own linger), 3 bakers (oven -> market -> home), 4 washerwomen at the
  river bank by the docks, 10 children (0.68 scale, quick, darting between spots round the square), a town crier on the
  square calling canon/town news ("MEASURE THE GRAIN. COUNT THE FLASKS. KEEP THE DOOR.", Guild hiring at the north gate,
  mind the scar...), a priest on the chapel steps, 4 WATCH PAIRS walking a beat gate -> square -> gate (second man
  follows at the leader's shoulder), 3 carters hauling a MegaKit wagon between market, granary and gates.
- Gear.ROLE_GEAR + capes for baker, washer, priest, crier, watch, carter, child (+ rope bundle, metal bucket copied).
- Everyone still routes along the road graph (no walking through houses); market loiter spots avoid stalls/houses.
- Name tags now only within 9 m of the camera (a crowd of 130 turned close shots into a wall of text).
- Probe: tools/_perf.gd (population + frame time), tools/_folk_shots.gd. Renders: village_assets/renders/folk/.
NEXT: gameplay hookup - port roster.gd (viewer heroes, D&D sheets, gear economy at the armourer/blacksmith racks) and
chatcmd/twitch (!join !fish !buy !delve), heroes walk from town through the north gate to the scar and into DungeonHD.


## Cycle 32 - VIEWER HEROES + CHAT (fake feed only; nothing connected to or posted on Twitch)
- scripts/roster.gd + scripts/chatcmd.gd: the old game's Roster (heroes keyed by Twitch user-id, 9 classes, 4d6-drop-
  lowest stats, D&D modifiers/AC/saves, WEAPONS/ARMOUR tiers + prices, potions/oil, reroll/respec, XP/levels, standing +
  guild ranks, permadeath -> memorial, patrons, save/load) and ChatCmd (verbs !enlist !hero !delve !forge !armoury !brew
  !oil !reroll !respec !guild !memorial !deepest !deadliest !richest !patrons !valley, 1.5 s per-viewer cooldown,
  replies to the ON-SCREEN feed) PORTED VERBATIM. Old verbs kept on purpose: they avoid fightoverlay's !join/!buy so both
  games can share the channel. Added !fish.
- scripts/hero_body.gd (class HeroBody extends Townsfolk): the class's KayKit body (Roster.CLASSES model), gear at the
  bought tier (old FAMILIES mesh, size + glow), guild-rank sash (Lore.rank_of), GOLD name + class always shown, a soft
  gold ring at the feet. go(dest, why, then) walks the streets on an errand.
- town.gd guild: chat_line(user_id, name, msg) is the single entry point (fake feed in tests, IRC later). !enlist raises
  a hero on the square; !forge/!armoury walk them to the blacksmith/armourer yard (spaced, facing the rack) and re-dress
  them at the new tier; !fish walks them to a dock and plays a real Angler cast (Fishing rolls the catch, feed line);
  !delve walks the party out the north gate, past the guild post, to wait at the scar mouth (feed line). feed[] holds the
  on-screen lines.
- Townsfolk names now OFF by default (Townsfolk.show_names) - with 134 people the viewers' heroes must be the readable ones.
- Test: tools/_heroes.gd - 6 fake viewers enlist, forge twice (plain -> fine steel), two fish (River Perch, Mud Carp),
  four delve and arrive at the mouth. Renders: village_assets/renders/heroes/.
NEXT: the delve itself - party enters DungeonHD floor 1 from the mouth (fade/transition), party AI fights the floor's
monsters with Spells/Gear (port expedition.gd), descends by the exit stairs, lords on 5s, permadeath -> memorial,
chronicle lines (canon: origin first, biome second; never a floor count).
