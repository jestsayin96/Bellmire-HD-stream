# D76 - THE TWELVE THAT WERE ANOTHER CREATURE WITH A LABEL

*"People want to see what they pay for, not just a stat."*

Twelve creature types in `scripts/bestiary.gd` were a second name on a body that
already belonged to another type. They now each have a body of their own,
generated the way the eight lords were in D75.

| Model they shared | Type that keeps it | Type that now has its own body |
|---|---|---|
| `Skeleton_Warrior.glb` | skeleton warrior | **bone sentinel**, **marrow hewer** |
| `Spider.glb` | cave spider | **silk mother**, **spiderling** |
| `Skeleton_Minion.glb` | skeleton minion | **bone bowman** |
| `Skeleton_Rogue.glb` | skeleton rogue | **pale cutthroat** |
| `Skeleton_Mage.glb` | skeleton mage | **gravecaller** |
| `Slime.glb` | slime | **slimeling** |
| `Bat.glb` | cave bat | **gloom bat** |
| `Rat.glb` | giant rat | **scar rat** |
| `Frog.glb` | bog frog | **fen lurker** |
| `Dragon.glb` | grave-whelp | **pit wyrm** |

## Scope - read `D76_SCOPE.md` first

WORK_PLAN's census said "~109 monster families share 10 models". Counted from
`bestiary.gd` on 15 Nov that does not reproduce: there are **30 creature types
on 18 distinct models, of which 12 share**. The measurement is in
`docs/art/D76_SCOPE.md`. This item is built to the measured number - twelve
bodies, the same order of work as the eight lords - **not** a parametric system
to carry 109. The census line in WORK_PLAN.md still needs correcting.

## The rule every one of them answers to

L27a had already given these twelve a different HEIGHT, a TINT and a GLOW, and
in several cases their own weapon. What none of them had was a different
**SHAPE**. So the acceptance test here is not the colour render, it is
`renders/art/creatures/_silhouettes.png`: with the colour thrown away, each of
the twelve must read as ITSELF, and must not read as the creature whose mesh it
is replacing. All twelve pass. Three did not on the first pass and were rebuilt
(see "What was rebuilt" below).

| Key | Name | h | What makes it itself in outline |
|---|---|---|---|
| `sentinel` | Bone Sentinel | 1.90 | a door, not a swordsman - the tower shield IS the silhouette, body hidden behind it; `ways {guard}` |
| `hewer` | Marrow Hewer | 1.85 | top-heavy and lopsided - one boulder shoulder, a broad axe bit raised clear of the skull |
| `bowman` | Bone Bowman | 1.60 | a wide low cross - braced in a shooting crouch, 1.6 m of crossbow span across the body; `ranged 8.5` |
| `cutthroat` | Pale Cutthroat | 1.60 | an arrow, already leaning - blades swept low and back, two rag plumes above them |
| `gravecaller` | Gravecaller | 1.85 | a pillar - no legs at all, arms thrown wide, seven raised grave-stones ringing the hem; `raise 2` |
| `silkmother` | Silk Mother | 1.30 | a dome on tall stilts - brood sac carried high, eleven young breaking her outline; `summon spiderling` |
| `spiderling` | Spiderling | 0.35 | a flat star on the floor - body almost nothing, legs splayed nearly level |
| `slimeling` | Slimeling | 0.50 | a splat - broader than tall, seven tongues of ooze running out along the floor |
| `gloombat` | Gloom Bat | 1.20 | a cowl - four fingers per wing, swept forward and scalloped, closing around the body |
| `scarrat` | Scar Rat | 0.80 | a humped comma - arched scarred spine, ribs showing, naked tail held up and curled |
| `lurker` | Fen Lurker | 1.50 | a mouth with a frog behind it - the gape is most of the outline, eyes on top |
| `pitwyrm` | Pit Wyrm | 4.00 | an S with NO WINGS - neck doubled back, plated spine, four digging limbs |

Heights are `bestiary.gd`'s own `h`; each mesh is authored at that height with
its feet on z=0, so `Monster`'s normaliser has nothing to undo.

## What shipped

- `assets/monsters/creatures/<key>.glb` - twelve meshes, **548-2833 faces**,
  **at most four meshes each** (merged by material: body / dark / bone / glow).
  Built part-by-part they run to 60-200 objects, which would be that many draw
  calls per creature, and a floor can hold a dozen at once.
- `renders/art/creatures/<key>/{front,three_quarter,side}.png` - 36 renders,
  560x780, transparent film.
- `renders/art/creatures/_contact_sheet.png` and `_silhouettes.png`.
- `renders/art/creatures/_report.json` - per-creature faces, size, camera and
  the blank check.
- `tools/art/creatures.py` (the twelve builders) and `tools/art/creaturegen.py`
  (the driver). Both reuse `lordlib.py` and D75's render rig.

## What was rebuilt after looking at it

Three of the twelve failed their own silhouette test on the first pass and were
redone. Writing this down because the failures are all the same mistake:

- **gloom bat** - the wing was one smooth grid and read as a flat box. Rebuilt
  as four finger bones per wing with the membrane strung between them and
  scalloped between each pair. A wing is read as its fingers, not as a sheet.
- **marrow hewer** - the axe took three passes: a constant-thickness quad read
  as a flag, a stack of bands read as a curled sheet, and a free crescent read
  as a disc. It is now a flat plate hung off one side of the haft, built in the
  haft's own frame, with a thick spine, a thin edge and a horn at each end. The
  skull was also being swallowed by the shoulder mass and was lifted clear.
- **pale cutthroat** - the rag tails and the blades occupied the same band of
  the silhouette and the blades vanished. Four rags became two, and the blades
  moved below the rag line and gained crossguards.

## New in the toolkit

`creatures.py` adds `surf()` - thickens an open quad GRID along per-vertex
normals, where `lordlib.membrane` only does a flat planar loop. Half of these
twelve need a curved panel (a bowed tower shield, a cupped wing, a jaw), so it
will be wanted again. Also `limb()`, `arc()`, `eyes()` and `spikes()`.

## For the bestiary.gd owner (desktop build)

These are **static meshes with no armature**, exactly like the lords, so the
existing `anims` entries do not apply to them. Idle motion is a rig job (D74).

Wiring is the same shape as the lords': prefer a `model` key when present, so
the art and the game-side change can land separately.

```gdscript
"sentinel": {... "model": "res://assets/monsters/creatures/sentinel.glb", ...}
```

Keys match `bestiary.gd` exactly: `sentinel`, `hewer`, `bowman`, `cutthroat`,
`gravecaller`, `silkmother`, `spiderling`, `slimeling`, `gloombat`, `scarrat`,
`lurker`, `pitwyrm`.

**Footprints worth checking against corridor width before these go in** (x by y,
at authored height): silk mother **2.26 x 1.52**, bowman **1.83 x 1.63**
(crossbow span), pit wyrm **1.68 x 4.77**, slimeling **1.32 x 1.55** (the splat
runs out along the floor). The slimeling's and the bowman's footprints are wider
than their height - if collision is a capsule off `h`, these three or four want
a look. Same question as the Grubmother's 8.3 m width in D75.

## Licence

Original generated geometry. No third-party asset is read by `creatures.py`,
`creaturegen.py` or `lordlib.py`. Quaternius Bestiary / QAL is forbidden on this
project, which is why these are generated rather than bought.

## Rebuilding

```
blender -b -noaudio -P tools/art/creaturegen.py -- --repo <repo>
blender -b -noaudio -P tools/art/creaturegen.py -- --repo <repo> --only gloombat
blender -b -noaudio -P tools/art/creaturegen.py -- --repo <repo> --sheet
```

Engine is `BLENDER_EEVEE` on Blender 5.2. The camera's ortho scale and clip
range are derived from the evaluated world-space bounds every time - these
twelve span 0.35 m to 4.0 m in one batch, and a wrong `clip_end` renders an
empty transparent frame and reports SUCCESS. Every PNG is re-opened and its
opaque pixel count asserted; 36/36 passed.
