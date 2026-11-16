# D75 - THE EIGHT LORDS

Mr. E's principle, 15 Nov: *"people want to see what they pay for, not just a stat."*
The audit's hardest finding was that **the bosses were wearing hero bodies** -
`bestiary.gd` builds a lord as `ADVC + body + ".glb"` from the ADVENTURER set, so
the Hollow King, the Grubmother, the Rattling Host, Nightwing, the Gravewyrm, the
Ossuary Lord, the Pale Duchess and Mourncoil were all reskinned adventurers, and
all 270 uniques inherited that. The biggest moment in a delve was a hero model
with a different name over its head.

These eight are now bespoke. None of them is a humanoid body with a tint on it.

## What shipped

| Lord | h | Silhouette - what makes it itself at stream distance | Faces |
|---|---|---|---|
| The Hollow King | 4.2 | an **open ribcage** you can see through, a crown of nine spikes, cold fire off the shoulders, ringed staff | 1 421 |
| The Grubmother | 4.5 | **a wall** - wider than tall, segmented, brood sacs breaking the outline, abdomen tapering back | 6 343 |
| The Rattling Host | 4.4 | **seven skulls stacked** above one harness, six arms thrown wide, a hanging fringe of ribs | 4 198 |
| Nightwing | 3.2 | **almost entirely wing** - scalloped membranes, asymmetric sweep, the body an afterthought | 727 |
| The Gravewyrm | 9.0 | a **narrow tower of coil**, dorsal plates spiking the spine the whole way up, horned head at the apex | 2 004 |
| The Ossuary Lord | 7.0 | **pauldrons of stacked skulls**, a nine-rib halo, greatsword planted, spiked shield | 4 881 |
| The Pale Duchess | 4.6 | a **collar fan** and **arms far too long**, ending in four blades each | 1 338 |
| Mourncoil | 10.0 | a **broad barrel coil** hung with icicles and two sheets of frost, flat crowned head reared forward | 2 066 |

Canon came from `scripts/bestiary.gd` BOSS_DEFS (title, height, tint, aura, and
the note that prints when it rises) and `data/bosses.json` (the shape notes and
the 270 uniques). Heights are authored to the canon `h` in metres; `LORD_SCALE`
is still applied by the game on top, as before.

## Where things are

    assets/monsters/lords/<key>.glb        the eight models
    renders/art/lords/<key>/{front,three_quarter,side}.png
    renders/art/lords/_contact_sheet.png   all eight, lit
    renders/art/lords/_silhouettes.png     all eight in pure outline
    renders/art/lords/_report.json         per-lord stats + the blank check
    tools/art/{lordlib,lords,lordgen}.py   the generator

Regenerate any time:

    blender -b -noaudio -P tools/art/lordgen.py -- --repo <repo> [--only hollow_king]

## Two traps this generator exists to avoid

1. **Scale.** The animal models are authored near 700 units while gear sits near
   2. A camera left at the default `clip_end` of 100 renders them as **empty
   transparent images and reports success**. Every camera here takes its
   distance and its `clip_start`/`clip_end` from the *evaluated* world-space
   bounds of the actual geometry. Nothing is assumed.
2. **Blank renders.** Every written PNG is re-opened and its opaque pixel count
   asserted above zero; the run fails loudly and names the files. This caught a
   real failure on the first pass of this very item - the camera was aimed 180
   degrees away from the subject and all 24 renders came back empty while
   Blender reported success on every one.

## Performance

Every lord is **at most four meshes** (one per material: body, recess, bone,
glow), merged before export. Built part-by-part they ran to 107 objects, which
would be 107 draw calls for a single boss, and D23 is already fighting for frame
rate. Face counts are 727-6 343. No textures: four flat materials per lord, the
glow one an emission shader carrying the lord's canon `aura` colour.

## For the owner of bestiary.gd - NOT done here

The art worker does not touch game code. To put these on screen, `BOSS_DEFS`
needs a model path per lord instead of `ADVC + body`:

    "hollow_king": {... "model": "res://assets/monsters/lords/hollow_king.glb" ...}

and the lord build path in `bestiary.gd` should prefer `model` when present and
fall back to the existing `body` lookup when it is absent, so nothing breaks
while the two halves land separately. These meshes are **static** - they carry no
armature and no animations, so the existing `anims` entries will not apply to
them. Idle motion, if it is wanted, is a rig job and belongs with D74's bone work
rather than here.

### Three things Mr. E may want to rule on

1. **The Grubmother is 8.3 m wide** at her canon 4.5 m height, because "a wall"
   is what `bosses.json` says she is. That is wider than some corridors. Either
   she stays a wall and only appears in rooms, or her width is clamped.
2. **Mourncoil at 10 m and the Gravewyrm at 9 m** are canon heights and they are
   large on screen at normal camera height. They read well, but whether the
   camera should pull back for a greater lord is a game decision, not an art one.
3. **The Hollow King's cold fire** is geometry, not a shader - pale blue blades
   rather than moving flame. It reads as *wreathed*, which is the canon note, but
   if Mr. E wants it to actually flicker that is a VFX pass in-engine.

## Licence

Everything here is **original geometry generated by `tools/art/`** from raw
vertex maths. No third-party asset is read, copied or derived from. The project's
CC0-only constraint (Quaternius, KayKit, Kenney, with a LICENSE note) is not
engaged by these files, and the forbidden Quaternius Bestiary / QAL pack is not
used anywhere in this generator - which is exactly why the lords are generated
rather than hunted.
