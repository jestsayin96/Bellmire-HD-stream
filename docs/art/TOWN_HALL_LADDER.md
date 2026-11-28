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

---

## SECOND LOOK, 28 Nov 03:4x CT - same lane, fresh session, bridge down

I re-staged `renders/art/town/hall/_tiers_side_by_side.png` and looked at it
before reporting the ladder as finished-on-disk. **The progression reads at a
glance** - thatch to tile to stone-and-tower is legible at sheet size, which is
the thing none of the gates can say. All four faults above are confirmed by eye.
Three more that the list above does not carry:

6. **Tier 1 reads as an open-fronted shed, not an enclosed hall.** The west bay
   is open to the camera and the bench inside is visible through it. Whatever
   that bay is - the kept vent, or a wall that did not get placed - the tier-1
   silhouette a viewer sees is a lean-to, and the label says "one door". A hall
   with a missing wall is the lattice fault's cousin, and `solidity` would
   likely score it low because the opening breaks the silhouette EDGE, exactly
   the blind spot written into `townlib.solidity`.

7. **Tier 3 has a floating eave on its east side.** A roof section juts east at
   mid-height with no wall under it, over the gap between the main block and the
   tower. It reads as a clipped piece of roof hanging in air.

8. **Tier 2 -> tier 3 separates almost entirely by SIZE.** Both wear the same
   plaster, the same uneven brick and the same red round tile; the only new
   material in tier 3 is the tower's stone and the banners. Mr. E's rule 2 says
   wear is the variable and condition is the receipt for what viewers paid for.
   A player who funds hall level 5 -> 9 should see a different BUILDING, not a
   bigger one. This is the weakest link in an otherwise legible ladder and it
   is the thing I would fix first.

Fault 1 (banners as flat rectangles) is worse at full size than the note above
suggests: they have no taper, no pole and no shadow, so they read as red paint
on the wall rather than hanging cloth.

**None of 6-8 could be fixed this run** - every fix needs Blender and the
bridge refused all five calls. They are listed here rather than carried in a
head, and they are the first work for the next firing that has a bridge.

---

## CORRECTION TO FAULT 1, 28 Nov 05:1x CT - THE LATTICE IS STILL IN TIER 3

Measured, not remembered, with `tools/art/_glbprobe.py` (pure Python, no
bridge). Fault 1 above says the lattice was fixed with "`Wall_Plaster_Straight`
everywhere, one lattice bay kept on the north face as a vent."

**Tier 2 carries ZERO. Tier 1 carries the one bay the note describes, so the
note is accurate there. It is FALSE of TIER 3, which carries FOURTEEN.** Tier 3
was derived from `lm_hall`, which has 14 bays in the band y 3.12-9.37; tier 3
has 14 in y 3.13-9.38. It inherited them wholesale and the fix never reached it.

A geometric backing test (is there a wall in the same plane behind the bay?)
returns **12 of the 14 unbacked** on both meshes. I have NOT looked at a
picture - the bridge was down both runs - so this is not yet proof the tier
reads as holed, only that the module proven see-through by render is present
14 times with nothing behind most of it.

**AND THE TIER-1 BAY EXPLAINS SECOND-LOOK FAULT 6.** The kept vent bay sits at
**y 0.01 - 3.13 - ground level - and the backing test returns it UNBACKED.** A
vent at ground height with nothing behind it is a doorway-height hole, which is
why fault 6 saw "an open-fronted shed" with "the bench inside visible through
it". The fix is not to delete the bay but to MOVE it above head height with
wall below. (My first sweep reported tier 1 as zero because its matcher stripped
`.001` but not `hallgen.py`'s own `_inst` suffix; corrected in
`TOWN_LATTICE_AUDIT.md` finding 2b.)

Fault 8's texture claim is also corrected: by SHA-1 of the embedded image
bytes, tier 3 adds exactly ONE new texture over tier 2 (`T_MetalOrnaments`),
and `T_RockTrim` - called "the tower's stone" above - is a texture **tier 1
already wears**. Full table and method in `docs/art/TOWN_LATTICE_AUDIT.md`.
