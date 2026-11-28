# THE TIER-5 SPEAR - WHAT I MADE, WHAT I MEASURED, AND WHAT MY OWN GATE MISSED

Art lane, 27 Nov 2026, 23:3x-23:4x CT (clock read off cruzader with
`TZ=America/Chicago date`; CST is UTC-6).

## THE DEFECT THIS CLOSES

`origin/main:scripts/gear.gd:213`

    "spear": {"family":"blade", "noun":"spear",
              "kit":[KIT+"spear_A.gltf", KIT+"spear_A.gltf",
                     KIT+"halberd.gltf", KIT+"halberd.gltf", KIT+"halberd.gltf"]}

Tiers 3, 4 AND 5 are the same `halberd.gltf` at the same scale. A viewer who
spends months of points on a legendary spear is handed the rare one, pixel for
pixel. It is the sceptre's defect, one row up the same file.

## WHAT I CHECKED FOR BEFORE MAKING ANYTHING, MEASURED NOT REMEMBERED

- `assets/gear/artifact/` walked: EIGHT golden meshes (sword, big sword,
  dagger, small axe, double axe, double hammer, bow, and last hour's sceptre).
  No spear. Confirmed by `git ls-files`, not by memory.
- `C:\hd adventure\_packs` walked in full - **10,172 files** - for
  spear/pike/lance/javelin/glaive/halberd/trident/polearm/naginata. 18 hits, of
  which 13 are floor spikes. **Five are real spears**, in two packs:
  `quaternius_medieval_weapons_2018_CC0` (1,202 tris, 4 materials) and
  `medieval_pack_CC0` (196 tris, 1 material).
- **SO THIS ONE IS SOURCED, NOT AUTHORED - the opposite of the sceptre.** The
  sceptre was authored because 30 pack hits held no sceptre. Charter rule 3
  says use the packs first, and here the packs serve it.

## LICENCE, AND IT IS NOT TAKEN FROM THE FOLDER NAME

`docs/art/ASSET_SOURCES.md` warns in two places that a folder called
`quaternius_medieval_weapons_2018_CC0` is not licensed by its name, and lists
that pack among those with no licence FILE on disk. It is nevertheless cleared
and already in use, and I checked which rather than assuming either way:

- Row 15 of the same file records **Medieval Weapons Pack (Sept 2018),
  Quaternius, CC0 1.0, opengameart.org/content/lowpoly-medieval-weapons**.
- The System 8 entry records that **this same pack's five shields already
  SHIPPED** into `assets/gear/shields/` with
  `LICENSE_Quaternius_MedievalWeapons_CC0.txt` written beside them, precisely
  because the extracted pack carries no licence file of its own.

So this is not the pack's first use and the gate was cleared on 19 Nov. CC0
1.0: commercial use permitted, no attribution required, no share-alike.

## THE SUBSTITUTION IS QUATERNIUS' OWN, AND I MEASURED IT RATHER THAN INVENTING IT

`tools/art/_goldmatprobe.py` read the shipped `sword_golden.glb` and the pack's
own plain `Sword.obj` through one importer:

| material | plain `Sword.obj` | shipped `sword_golden.glb` |
|---|---|---|
| Steel / Golden | 224 tris | 224 tris |
| LightSteel / LightGold | 132 tris | 132 tris |
| DarkSteel | 180 | 180 |
| LightWood | 240 | 240 |
| DarkWood | 96 | 96 |

**Triangle counts identical, material for material.** The golden tier of this
family IS the plain mesh under `Steel -> Golden`, `LightSteel -> LightGold`. So
the tier-5 spear is the pack spear under that same substitution: it joins a
family that already shipped, by construction, rather than standing next to
eight meshes with a gold of my own choosing.

Applied to the spear: `Steel 92 -> Golden 92`, `LightSteel 96 -> LightGold 96`,
wood untouched in count. The generator ASSERTS the counts and refuses any pack
material that does not map into the shipped family.

## AND I FOUND A DEFECT IN MY OWN SHIPPED SCEPTRE WHILE DOING IT

The sceptre's own notes say a gold at metallic 1.0 reads as a flat dark stick
and that `_goldcontrol.py` found the shipped set bright because it is "barely
metallic". The probe says it is not barely - **IT IS ZERO**:

    Golden     base 0.4672 0.3365 0.0589   metallic 0.00  roughness 0.50
    LightGold  base 0.7874 0.6773 0.1896   metallic 0.00  roughness 0.50
    DarkWood   base 0.0637 0.0324 0.0516   metallic 0.00  roughness 0.50
    LightWood  base 0.1574 0.0790 0.0849   metallic 0.00  roughness 0.50

`sceptre_golden.glb` shipped at **metallic 0.30 / roughness 0.35** on a base of
my own choosing (0.95 0.76 0.30). **It is not this family's gold.** Recorded
here rather than buried; it is not re-opened this run because the sceptre was
ticked by eye at 23:1x and a re-tint is a separate one-change pass.

Note also that the golden family DARKENED the wood (DarkWood 0.0637 against the
pack's plain 0.1301) so the gold carries the eye. The substitution takes that too.

## SCALE AND GRIP, DERIVED OFF THE SHIPPED POLEARMS

    pack Spear.obj    +Z, 9.7171 long, z -2.1552 .. +7.5619   butt 22.2% below origin
    SHIPPED spear_A   +Z, 3.1387 long, z -1.0322 .. +2.1066   butt 32.9% below origin
    SHIPPED halberd   +Z, 2.7468 long, z -0.9322 .. +1.8146   butt 33.9% below origin

`hand_scale()` has **no arm for this path** and falls through
`begins_with(ART)` to **0.60**; the KIT polearms take 0.62. To read at least as
long as the common spear the mesh must be `0.62/0.60 x 3.1387 = 3.243` units,
and tier 5 should be the grander one, so the target is **3.50 units -> 2.100 m
in hand** against the common spear's 1.946 m. Origin at **33.0% from the butt**,
`spear_A`'s own proportion.

## TWO FAULTS MY OWN GENERATOR PRINTED BEFORE THEY COULD SHIP

1. **`butt_frac` came back 0.2218 against a target of 0.3300** - the re-origin
   was a silent no-op.
2. **FAR WORSE: the first run's bounds were x -0.0791..0.1119 and
   y +0.3202..+0.4372.** The pack spear's shaft does not run up `x=y=0`; it is
   offset ~0.38 units in y. The engine attaches at the ORIGIN, so this spear
   would have floated **0.23 m to the side of the fist in every carry**.

Both had **one cause**, and it is trap 3's family: the OBJ importer leaves a
90-degree X rotation ON THE OBJECT to convert Y-up to Z-up, so LOCAL y is
WORLD z, and every `v.co.z` edit was moving the mesh along an axis it was not
meant to touch. Fixed by flattening location+rotation+scale into the mesh
before any measurement, and the generator now **asserts** butt_frac to 0.005
and the shaft axis to 1e-4 and dies if either drifts.

## THE FIT PROOF - RENDERED ON A POSED BODY AND LOOKED AT

`tools/art/_spearcarry.py`, KayKit hero 2.45 m, idle pose, handslot.r at
`[-0.491, -0.1069, 0.6406]`, front/side/back, EEVEE.

**THE ENGINE NEEDS NO WIRING AND THAT IS THE POINT.** `gearcarry` walked the
real branches of `origin/main:scripts/gear.gd`: `held_rot` has arms only for
`DUN+staff_`, `ART+bow_golden.glb` and `DUN+crossbow_`, so `spear_A.gltf`,
`halberd.gltf` and `artifact/spear_golden.glb` are **all** carried at
`Vector3.ZERO`; `hand_scale` resolves through `begins 'res://assets/gear/artifact/'`
to **0.60**. Tier 5 is held exactly as the common spear the game already ships.

| | mine, pass 1 | mine + langets | SHIPPED `spear_A` |
|---|---|---|---|
| length in hand | 2.100 m | 2.100 m | 1.946 m |
| clip % of checked verts | 52.1 | **48.7** | **46.2** |
| front moved px | 3,808 | 4,144 | 5,006 |
| side moved px | 800 | **1,122** | 1,064 |
| back moved px | 3,618 | 3,946 | 4,689 |
| bounds x / y | 0.191 / 0.117 | **0.241 / 0.241** | - |
| blanks / border / blind / ground | 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 |

**The 52% clip is not a defect: the house's own shipped spear clips 46.2% at the
same carry**, because a third of any polearm sits behind the fist and inside the
torso. That is what the control was for.

### PASS 2 - THE LANGETS, AND WHY THE PICTURE ASKED FOR THEM

Pass 1 was the substitution alone. I looked at it beside the control and the
**picture overturned the numbers**: every hard gate was green, but the pack
spear's head is NARROWER than the shipped common spear's broad leaf blade, so
the legendary read gold but **slimmer than tier 1**. Gold alone is not a
receipt if the shape goes backwards.

Pass 2 added, as ONE change, four radial gold langets and a LightGold collar at
the socket - the sceptre's radial answer, so no viewing angle can hide the
head's width. Side-on moved pixels went **800 -> 1,122, past the shipped
common's 1,064**, bounds became radially symmetric (0.241 / 0.241), and clip
fell 52.1 -> 48.7.

### WHAT I CAN SEE, HONESTLY, AND IT INCLUDES A GATE OF MINE THAT MISSED

- **FRONT: PASS.** Gold blade and the langet collar read clearly against the
  grey armour and red cape. Legibly richer than the control beside it.
- **BACK: PASS**, and I checked it on purpose because of the Beadle. The head
  is held clear of the cape and the gold is legible against the red.
- **SIDE: THE NUMBER PASSED AND THE PICTURE FAILS.** `moved: 1,122` is green
  and from the side **there is essentially no spear** - the shaft points down
  the camera axis and foreshortens to a point, leaving a small gold lump at the
  waist. The gate counts pixels that moved; it cannot tell 1,122 px spread
  along a spear from 1,122 px in a 30-pixel blob. **This is Pass 11's lesson
  again in a new costume and I am recording it against myself.**
- **BUT IT IS NOT MINE TO FIX.** The SHIPPED `spear_A` scores 1,064 on that
  same view and is **equally invisible side-on** - a dark lump at the same
  waist. The side-on vanish belongs to `held_rot` returning `Vector3.ZERO` for
  every spear in the game, which is `scripts/gear.gd` - the game build's file.
  Reported below, not touched.
- The langets sit close under the blade, so the head reads as one gold mass
  rather than blade-plus-langets. At stream distance that is the point; up
  close it is blunt.
- The shaft is still as thin as the common spear's. Not changed this pass.
- The spear is carried horizontally, straight out to the hero's right, like a
  couched lance rather than shouldered. Same as the shipped spear. Same cause.

## RENDERS

    renders/art/spear/engine_fallback/{front,side,back}.png          pass 1
    renders/art/spear_langets/engine_fallback/{front,side,back}.png  SHIPPED
    renders/art/spear_ctl_common/engine_fallback/{front,side,back}.png  control
    renders/art/spear*/engine_fallback/_no_*.png                     without-model halves
    renders/art/spear*/_carry_report.json

`_spearcarry.py --model assets/gear/halberd.gltf` was REFUSED by my own +Z axis
gate (span x 1.293 against z 2.747) because the halberd's axe blade makes it
wide in x. The gate is correct and the control is simply out of its scope; the
common spear served as the control instead.
