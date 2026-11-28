# The Hall, tiers 1-3 - BUILT. What the pictures said, including where my own design was wrong.

**28 Nov 2026, ~02:3x-03:0x CT. Art lane.** Row: plan `TAKE THIS NEXT`,
ART 02:34 - *"BUILD THE HALL TIER LADDER YOU JUST DESIGNED. The design is
ticked; the ladder is not. Three tiers, RENDERED SIDE BY SIDE, and the
progression must read at a glance."*

Generator `tools/art/hallgen.py`; shared gate helpers `tools/art/townlib.py`;
measurements `tools/art/_hallmeasure.py` -> `renders/art/town/_hall_measure.json`.
Gates `renders/art/town/hall/_report.json`, **verdict GREEN, errors []**.
Sheet `renders/art/town/hall/_tiers_side_by_side.png`.

## What shipped

| | T1 The Moot Hall | T2 The Chief's Hall | T3 The Hall of Bellmire |
|---|---|---|---|
| dims (m) | 5.479 x 6.890 x 5.460 | 8.250 x 10.976 x 11.339 | 13.801 x 19.784 x 22.411 |
| tris | 1,884 | 30,096 | 139,066 |
| .glb | 0.68 MB | 1.41 MB | 2.30 MB |
| roof | **authored thatch**, sagging ridge | pack round tile | pack round tile + tower spire |
| walls | plaster + wood trim, 1 door | uneven brick below, plaster above | as built (stone, timber, tower) |
| dressing | a bench | external stair, chimney, lamp | paved court, iron railing, banners |

Pivot contract **measured, not asserted**: `core_centre_dx_dy` is `[0.0, 0.0]`
and `base_dz_m` is `0.0` on all three, so the game build swaps the mesh at one
unmoved spawn point.

Silhouette through ONE camera at ONE ortho scale, monotonic on both axes:
height **178 -> 343 -> 609 px**, area **23,314 -> 67,876 -> 156,263 px**.

## MY OWN DESIGN WAS WRONG THREE TIMES AND THE PICTURES CAUGHT ALL THREE

**1. `Wall_Plaster_WoodGrid` IS AN OPEN TIMBER LATTICE, NOT A TIMBER-FRAMED
WALL.** The design doc picked it off its NAME and wrote "timber-framed". The
first tier-1 render was a hall **you could see straight through**. Every gate
I had passed it: a lattice is not blank, not clipped, not missing and not
small - it is just not a wall. Its 248 tris against `Wall_Plaster_Straight`'s
86 said the same thing in a number I had already measured and not read.
**Fixed:** `Wall_Plaster_Straight` everywhere, one lattice bay kept on the
north face as a vent, which is what the piece is actually for.

**2. A HOLE IN THE BUILDING THAT THE NEW INSTRUMENT ALSO COULD NOT SEE.** With
the walls solid, the render showed a dark void under the roof at each end: a
two-slope roof over a four-wall box leaves the gable TRIANGLES open. The
see-through test I had just written missed it too, because the hole sits at
the silhouette EDGE and a scanline reads that as background, not as a hole.
That limit is now written into `townlib.solidity` and this is the case that
proved it. **And I then shipped the identical hole on tier 2** - the pack's
`Roof_RoundTiles_6x8` is open at both ends as well - and only the side-by-side
sheet caught it. Fixed on both.

**3. MY FIX FOR THE PIVOT DEFECT REINTRODUCED THE PIVOT DEFECT.** The whole
reason this ladder exists as a new family is that `lm_hall.glb` is 1.92 m
off-centre and would make the hall jump on upgrade. My first full run
re-centred each tier on its WHOLE assembly - so tier 3's paved court, which
only extends south, dragged the hall ~2 m north of the spawn point. Builders
now hand back a `core` (walls and roof, no yard) and the pivot is taken off
that.

## TWO INSTRUMENTS WERE WRONG AND THE PICTURE WAS RIGHT BOTH TIMES

- **`n_images_in_file` reports 0 on all three tiers and the buildings are
  plainly textured.** It counts `bpy.data.images` with `has_data`, which is
  False for images Blender has not evaluated in background mode. **The number
  is wrong; do not read it as "no textures embedded".** It is left in the
  report with this note rather than deleted, because a silently removed bad
  instrument is how the next seat re-invents it.
- **The first size fix changed the file by nothing at all.** I set each image
  datablock's `file_format` to JPEG; the exporter's AUTO mode never reads that
  flag. Tier 2 stayed at 16.61 MB to two decimal places and I nearly called
  the dedupe ineffective. The real fix was `export_image_format='JPEG'` passed
  to the exporter, in a LOCAL export function - `lordgen.export_glb` is used
  by 24 shipped bodies and is not touched. 16.61 MB -> 1.41 MB.

## THE HERO GATE WAS TOO BLUNT FOR A 22 M BUILDING

Against tier 3 the 2.453 m Knight moved only ~650 px and the old absolute
floor of 1500 called the scale reference **ABSENT**. It is not absent - it is
correctly tiny, because the building really is nine times its height. A
reference's job is to be READABLE, which is a height in pixels, not an area,
so the gate now asks for both (`>= 250 px moved` **and** `>= 34 px tall`) and
the per-tier views render at 1280x1160. Tier 3's worst view is 60 px tall.

## WHAT IS STILL WRONG, BY EYE, ON THE SHIPPED SHEET

Stated because an honest list of faults is worth more than a clean sheet.

1. **The tier-3 banners read as flat red rectangles, not banners.** Content's
   line says banners **on the gable**; these hang on the front wall face
   because the gable of `lm_hall` was not measured. Real remaining work.
2. **The paved court barely reads.** The `Floor_Brick` tiles sit at a shallow
   angle against a grey ground plane of similar value, so the railing reads
   and the paving under it does not.
3. **Tier 1's thatch still reads as thick slabs rather than combed thatch.**
   It is warm straw against red tile, which is the tier separation the ladder
   needed, but it is not yet convincing thatch up close.
4. **Tier 2's gable board is a blank panel** - plain, arguably in voice, but
   flatter than the kit's own detailing around it.
5. **Content's "a guard at the steps" is NOT BUILT, deliberately.** A guard is
   a character, not a building asset, and the miniboss roster is capped at 70.

## FOR THE GAME BUILD LANE - WIRING. I DID NOT DO ANY OF THIS.

Three new meshes, all with `.glb.import` siblings generated:
`assets/buildings/town_hall_t1.glb`, `town_hall_t2.glb`, `town_hall_t3.glb`.
They share one pivot, so one spawn point swaps between them by tier.
Content's `town_buildings.landmarks.hall` already carries the names and
`tier_levels` 1/5/9. **`lm_hall.glb` is unchanged and still referenced by
whatever referenced it.**

## STILL OPEN FOR MR. E / THE SUPERVISOR - the one decision, unchanged

Should the town's buildings be scaled ~1.15x so the hero fits through a door?
The kit's doors top at 2.32-2.36 m and the adventurer stands 2.453 m. Nothing
walks through a door today so nothing looks wrong on stream, and this ladder
is built at the kit's native scale so it matches the other twelve buildings.
It is cheap now and expensive once the town layout is placed.
