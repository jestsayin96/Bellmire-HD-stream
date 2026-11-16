# THE MINIBOSSES - four set pieces the art lane invented outright

Built 16 Nov under Mr. E's standing permission of 15 Nov 17:43: *"you can always
add mini bosses as well. that dont have to be lore mentioned"*. No canon entry,
no bestiary row written here, no `lore_lines`, no content-lane dependency. A
line in the feed when one appears is enough, and if one turns out to be a
favourite its lore can be written later - earned, not assigned.

**The bar, and the only bar: ONE IDEA THAT CHANGES THE FIGHT.** Not a normal
monster with more hit points. Each of these four is named for what it does.

| key | title | h | theme | THE IDEA | wear |
|---|---|---|---|---|---|
| `drillmaster` | The Drillmaster | 2.20 | barracks | **IT SUMMONS** - beats the muster gong and the garrison forms up | 0.15 |
| `scrapwright` | The Scrapwright | 2.00 | workshop | **IT ARMOURS ITSELF** - every plate knocked off is replaced from the floor | 0.30 |
| `gaoler` | The Gaoler | 2.35 | prison | **IT DRAGS** - the hook takes one hero out of the line and reels them in | 0.80 |
| `snuffer` | The Snuffer | 2.60 | shrine | **IT TAKES THE LIGHT** - it puts out the lamps one at a time | 0.90 |

`assets/monsters/minibosses/<key>.glb` - **975-1816 faces, four meshes each**
(merged by material: built part-by-part they run to 60-200 objects, i.e. that
many draw calls for one set piece). Static meshes, **no armature**. Authored
with feet on z=0 at the height in the table.

Generators: `tools/art/minibosses.py` (geometry) and `tools/art/minibossgen.py`
(headless driver). The driver reuses D75's render rig whole - the same measured
clip range and the same blank-pixel assertion.

## Why these four, and why the silhouette decides it

`dungeon_hd.gd` already has the slot: the set-piece roll includes `"miniboss"`
at weight 15 on a normal floor, **35 on barracks and workshop**, 10 on shrine
and crypt, and it is gated to floor 4 and deeper. The slot was built and
under-used; it wanted better things to put in it. Two of these four are built
for the barracks/workshop weight because that is where the roll actually lands.

The acceptance test is `renders/art/minibosses/_silhouettes.png`, not the colour
render: colour thrown away, each must read as itself and none may read as a
hero. **Three of the four failed that test on the first pass and were rebuilt
after looking at the sheet** - which is the whole argument for looking:

- **Drillmaster.** Pass 1 hung the gong flat across his spine and the disc ATE
  HIM - a balloon on two legs with a crumb on top. You could not tell there was
  a man there, or that the disc was a gong rather than a shield. The gong moved
  off to his right and down, he stepped forward and turned a quarter, and the
  mallet became a long clear diagonal with a heavy head. Reads now as MAN, DISC
  BEHIND HIM, HAMMER UP.
- **Scrapwright.** Took two more passes. Pass 1 stacked nine flat plates in
  horizontal courses and produced a symmetrical pagoda - no mass, no lean, no
  read. Pass 2 gave it one dominant lopsided lump but sank the plates inside it
  and it came back a smooth boulder, so **the idea was invisible before the
  fight started**. Pass 3 lays each plate ON the lump, tangent to its surface
  along its own outward normal, over a dark core - which is also how a thing
  that patched itself would actually do it.
- **Gaoler.** The chain coil on the floor read beautifully from the first pass -
  a horizontal ring nothing else in the dungeon has. The HOOK, which is the
  entire mechanic, came out a hairline and vanished. The arm is now heavier and
  half a metre longer, swung clear of the body, and the hook is a C of iron
  0.70 m across you can read at pane distance.
- **Snuffer** passed first time and was not touched.

## Wear is a variable, not a style

These are not viewer gear, so the receipt argument does not apply - but they
must not all be equally rotten, and the `wear` column above is justified by what
each thing IS, not scattered for variety. `wear` drives materials only (rougher,
less metallic, colour pulled toward the dark as it rises); it never changes
geometry.

- **0.15 Drillmaster** - a working man keeps his instrument. The gong is the
  brightest object in this file; his coat and boots are dun.
- **0.30 Scrapwright** - freshly torn plate, still bright, bolted onto an
  ancient dark core. The contrast IS the creature.
- **0.80 Gaoler** - old greased iron and leather, used daily for a long time.
- **0.90 Snuffer** - it has been down there longest. Soot and dead wax.

## Corridors: measured, not hoped

A creature that cannot fit a corridor must be **room-locked by construction**,
never by hoping it fails to fit. `floorgen.gd` uses `G = 4.0` m per cell and
`WALL_IN = 0.5` m (a wall reaches that far into its cell), and D91 widens
corridors to three cells. So the clear span of a three-cell corridor is
**11.0 m**, and the driver compares every measured footprint against it:

| key | w x d x h (m) | footprint span | verdict |
|---|---|---|---|
| `drillmaster` | 1.39 x 0.71 x 2.20 | 1.39 | CORRIDOR-SAFE |
| `scrapwright` | 2.76 x 2.03 x 2.00 | 2.76 | CORRIDOR-SAFE |
| `gaoler` | 3.72 x 2.37 x 2.35 | 3.72 | CORRIDOR-SAFE |
| `snuffer` | 1.51 x 1.20 x 2.60 | 1.51 | CORRIDOR-SAFE |

**None of the four is room-locked.** The Gaoler's 3.72 m is the chain coil lying
on the floor, not his body - worth knowing if the spawn clearance test uses the
mesh bounds rather than a body radius, because the coil is scenery he stands
beside and nothing should be pushed out of the way for it.

## Verification

`renders/art/minibosses/_report.json`. Blank check **12 files, 0 failures** -
every PNG re-opened and its opaque pixel count asserted, because a wrong clip
range renders an empty transparent frame and reports success. Engine
`BLENDER_EEVEE` (there is no `BLENDER_EEVEE_NEXT` on 5.2). Contact sheet and
silhouette sheet both viewed before committing; the three rebuilds above are
what viewing them bought.

## For the game build worker - what the art lane cannot do

The art lane never runs Godot, so the in-game half is open and is not claimed
here. What is needed:

1. **A `model` path, same pattern as the lords and the twelve.** These are
   static meshes with no armature, so existing `anims` entries do not apply.
   Idle motion is a rig job and belongs with D74.
2. **The set-piece roll should prefer the theme-matched one.** The def that
   `dungeon_hd.gd` writes at build time is `Bestiary.pick(floor_no, theme)`; a
   miniboss set piece on a barracks floor should be able to pick the
   Drillmaster, on a workshop floor the Scrapwright, prison the Gaoler, shrine
   or crypt the Snuffer, rather than an elite ordinary creature.
3. **Each idea is a behaviour, and the behaviour is the point.** Shipping these
   as reskins with 2x hp and +20% atk (today's miniboss scaling) wastes them -
   the mesh is the promise that something different is about to happen. The
   summon, the re-plating, the hook-drag and the snuff are four small pieces of
   delve-side logic, and each is a better stream beat than a bigger health bar.
4. **The feed line** for each is in `minibosses.CANON` and in
   `renders/art/minibosses/_report.json` (`feed_line`) - one plain sentence, no
   lore attached: *"Someone is beating the muster." / "It is wearing the
   workshop." / "A chain is paying out in the dark." / "The nearest lamp has
   gone out."*

## Licence

Original geometry, generated from raw vertex maths in `tools/art/`. No
third-party asset is read by any of it. Quaternius Bestiary / QAL is forbidden
on this project, which is why these are generated and not bought.

---

# SECOND SET - 16 Nov 2026: crypt, keep, treasury, mess

The first four were built for the two themes where `dungeon_hd.gd` rolls the
miniboss set piece at **35** (barracks, workshop). The four below cover the
themes where it rolls at **15** (keep, treasury, mess) and **10** (crypt) and
had nothing theme-matched to put in the slot, so it fell back to
`Bestiary.pick()` returning an ordinary creature with doubled hit points -
exactly the thing Mr. E's bar forbids.

| key | title | h | theme | THE IDEA | wear | span |
|---|---|---|---|---|---|---|
| `sexton`   | The Sexton   | 2.45 | crypt    | **IT WILL NOT STAY DOWN** - it carries its own graves; four lit niches are four risings | 0.85 | 2.14 |
| `porter`   | The Porter   | 2.30 | keep     | **IT BARS THE WAY** - a leaf across the chamber mouth: no retreat, no reinforcement | 0.45 | 3.52 |
| `tallyman` | The Tallyman | 2.15 | treasury | **IT TAKES AND LEAVES** - it lifts gear off the party, wears it, and withdraws | 0.20 | 1.89 |
| `cook`     | The Cook     | 2.05 | mess     | **IT KEEPS THE PACK ALIVE** - the pot heals the room; spill the pot | 0.60 | 2.39 |

All four: four meshes merged by material, 1094-1722 faces, static, feet on z=0,
and **CORRIDOR-SAFE** against the 11.0 m clear span of a D91 three-cell corridor
(`floorgen.gd` G = 4.0, WALL_IN = 0.5). **None of the eight is room-locked.**

## Two of these are countable from the doorway, on purpose

The Sexton's four **lit** niches are his remaining risings and the viewer can
count them without being told; the Tallyman wears what it has already taken,
where the viewer who paid for that helm can see it. Mr. E's receipt rule cuts
both ways - a mechanic the stream can read off the model is worth more than the
same mechanic in a number.

## WEAR across the whole eight, lowest to highest

`tallyman 0.20` (the treasury is kept and this is the only bright thing in the
file) → `drillmaster 0.15` gong aside, `scrapwright 0.30` → `porter 0.45` (the
keep is maintained; sound oak, greased iron) → `cook 0.60` (greasy, long-used,
but the pot rim is scoured bright because a cook keeps his pot) → `gaoler 0.80`
→ `sexton 0.85` → `snuffer 0.90`. Nothing in the set shares a value.

## What the pictures overruled - again, three times

The blank check passed on every bad version. Only looking caught these:

1. **Sexton, twice.** Twelve flush cells fused into one banded slab - the thing
   you are meant to COUNT was invisible, and at pane distance he was the Porter.
   Rebuilt at nine bigger cells with air between them; that came back *worse*,
   a bigger solid slab, because each empty niche had a dark back plate closing
   it. An empty grave has to be **a hole you see through**. Back plates deleted,
   lit plugs pushed 0.16 proud, spade haft thickened.
2. **Porter.** A 1.02 m leaf directly behind him ate the far half of the
   drawbar from three-quarters, so "the widest horizontal in the dungeon" came
   out a stub and what remained read as the Sexton. Leaf narrowed and raised,
   bar lengthened to 2.84 m, pushed forward of the leaf and raked so both iron
   shoes clear the body from any angle.
3. **Tallyman.** The stolen kit hung on short cords inside the body's own
   width and fused with the torso - the receipt was not in the outline at all.
   A 1.86 m spreader bar now carries all five pieces wide of the body on long
   cords with air around each.
4. **Cook** (colour sheet, not silhouette). The pot was built from the body
   material and came back **a wooden tub**; and three thin glow tapers meant as
   steam read as pale spikes. The cauldron is black iron now with a scoured
   bright rim, the heat is a lit surface inside the rim, and the modelled steam
   is gone - geometry cannot do steam at this silhouette weight, so the delve's
   own particles can carry it.

## Handed to the GAME BUILD worker

Same four points as the first set, extended:

- `assets/monsters/minibosses/{sexton,porter,tallyman,cook}.glb`, static, no
  armature.
- The set-piece roll can now cover **crypt, keep, treasury, mess** with a
  theme-matched piece instead of an elite ordinary creature. Note `dungeon_hd.gd`
  currently lumps **shrine and crypt** into one weight row - the Snuffer was
  built for shrine and the Sexton for crypt, and the two should split.
- Feed lines: *"A spade is working somewhere in the dark." / "A bar has dropped
  behind you." / "Something is counting what you carry." / "The pot is on."*
- **The Porter's idea needs a door to exist.** It is the one of the eight whose
  behaviour touches the floor rather than the party: it wants the chamber mouth
  sealed for the duration. If that is expensive, the cheap honest version is
  "no fleeing this set piece and no wandering spawns join it" - the mesh already
  promises that much and no more.
