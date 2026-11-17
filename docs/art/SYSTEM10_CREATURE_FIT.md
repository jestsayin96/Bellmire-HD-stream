# SYSTEM 10 - THE TWELVE SHARED-MESH CREATURES. NOT REBUILT: MEASURED, PROVEN, AND HANDED OVER.

Register: `renders/art/creatures/_fit_creatures_register.json` (verdict GREEN).
Sheet:    `renders/art/creatures/_fit_hero_scale.png` (12 cells, one ortho scale 7.59 m, one ground line).
Harness:  `tools/art/creaturefit.py`.

## WHAT I CHECKED FOR FIRST - MEASURED OFF THE TREE, NOT REMEMBERED

SYSTEM 10 says "the 12 creatures in assets/monsters/creatures that share a mesh
each get their own body". **ALL TWELVE BODIES ALREADY EXIST.** I did not build
one mesh this run.

Measured, by parsing `scripts/bestiary.gd` rather than trusting any summary:
29 creature keys across 17 distinct meshes, and **exactly 12 keys are the
second-or-third occupant of a shared mesh**:

| key | shares | bestiary h | committed body |
|---|---|---|---|
| sentinel | Skeleton_Warrior.glb | 1.90 | `creatures/sentinel.glb` |
| hewer | Skeleton_Warrior.glb | 1.85 | `creatures/hewer.glb` |
| bowman | Skeleton_Minion.glb | 1.60 | `creatures/bowman.glb` |
| cutthroat | Skeleton_Rogue.glb | 1.60 | `creatures/cutthroat.glb` |
| gravecaller | Skeleton_Mage.glb | 1.85 | `creatures/gravecaller.glb` |
| silkmother | Spider.glb | 1.30 | `creatures/silkmother.glb` |
| spiderling | Spider.glb | 0.35 | `creatures/spiderling.glb` |
| scarrat | Rat.glb | 0.80 | `creatures/scarrat.glb` |
| lurker | Frog.glb | 1.50 | `creatures/lurker.glb` |
| pitwyrm | Dragon.glb | 4.00 | `creatures/pitwyrm.glb` |
| gloombat | Bat.glb | 1.20 | `creatures/gloombat.glb` |
| slimeling | Slime.glb | 0.50 | `creatures/slimeling.glb` |

The list of twelve the plan asked for and the list of twelve files on disk are
the SAME TWELVE. SYSTEM 10's art was delivered by D76. What was missing is
everything below.

## WHAT WAS ACTUALLY MISSING, AND IS NOW MADE

`assets/monsters/creatures/` is referenced by **NOTHING** in `scripts/`,
`web/` or `data/` - grepped, zero hits. And D76's own sheet cannot carry the
argument for wiring it, because D76 shot each creature **ALONE at its OWN
camera radius and ortho scale** (`renders/art/creatures/_report.json` records a
different `cam.ortho` per creature). No two of those pictures can be compared,
and none of them answers Mr. E's question - how big does it read beside a hero.

So this run built the proof the minibosses already had: all twelve rendered
**on a body**, front/side/back, at ONE ortho scale and ONE ground line, beside
the real posed KayKit `Knight.glb` at scale 1.0, measured 2.45 m.

**THE FRAME IS MEASURED, NOT GUESSED.** A no-render pre-pass imports all twelve
with the hero and returns the widest and tallest pair; the frame comes out
7.59 m. Carrying over the minibosses' 5.60 m would have cropped the 4.00 m
pit wyrm and still reported GREEN.

**THE NORMALISATION IS THE GAME'S OWN.** `monster.gd:43` is
`_body.scale = Vector3.ONE * (h / hb.size.y)`, so the harness scales by
`h / raw_z` and then applies `lift`. The result is the one number the game
build needs and it is a good one:

> **ALL TWELVE COME BACK AT SCALE FACTOR EXACTLY 1.000.** D76 authored every
> body at its bestiary `h` already - raw file height equals canon height to the
> centimetre on all twelve. Wiring these in will NOT resize anything. That is a
> fact worth having before the swap, not after.

Ratios against a 2.45 m hero: pit wyrm **1.63x** (the only one taller), sentinel
0.78, hewer 0.76, gravecaller 0.76, bowman 0.65, cutthroat 0.65, lurker 0.61,
silkmother 0.53, gloom bat 0.49 (floating at lift 1.8, so its head clears the
hero's by +0.55), scar rat 0.33, slimeling 0.20, spiderling 0.14.
Widest footprint span: pit wyrm 6.65 m, silk mother 4.12 m - both inside the
11.0 m three-cell clear span, so **none of the twelve is room-locked**.

Blank check: **36 PNGs, 0 blanks, 0 failures, errors []**. Parts 3-4 each,
992-4994 faces.

## *** THE ONE THING THAT MATTERS MOST, AND IT IS BAD NEWS ***

**ALL TWELVE BODIES ARE STATIC. NO RIG, NO SKIN, NO ANIMATIONS.**
Read out of the glTF JSON chunk of each file: `animations: []`, `skins: 0`,
3-4 nodes, meshes named `<key>_body / _bone / _dark / _glow`.

Every one of these twelve keys carries an `anims` dict in bestiary.gd
(`A_SKL`, `A_SPIDER`, `A_RAT`, `A_FROG`, `A_DRAGON`, `A_BAT`, `A_SLIME`), and
the mesh each currently shares IS animated. **So swapping `path` to the D76
body trades motion for uniqueness: the creature would stand frozen - no idle,
no walk, no attack, no death.** A viewer would see a statue slide across the
floor.

This is not a reason to throw the twelve away and it is not a re-open of D76.
It is a decision that belongs to Mr. E and the game build, and the sheet is
there so he can make it by looking. The honest options, shortest first:

1. **Wire them where motion is cheapest to lose** - the three that barely
   animate anyway. Not my call to pick.
2. **Keep the shared animated mesh and keep the existing `tint`/`glow`/`h`**,
   which is what the game does today, and use the D76 bodies for the Chronicle
   / hub portrait instead of the floor.
3. **This lane re-authors the twelve onto the shared rig** - the same
   silhouette changes applied as skinned attachments to the animated source
   body, so they move. That is real work and I will take it if told to; it is
   NOT in the plan today and I am not starting it unasked.

## THE FIT PROOF - EVERY FAULT I CAN SEE, AND THERE ARE NINE

I looked at `_fit_hero_scale.png` and at the side views of the worst two.

- **SENTINEL IS THE WORST CELL IN THE SHEET.** From the FRONT it is a flat
  rectangular slab with a round boss - the tower shield stands dead in front of
  the body and hides the entire skeleton. You cannot tell there is a creature
  there. The side view shows the skeleton is real and standing right behind it.
  Front-on, a bone sentinel reads as a door.
- **SENTINEL's shield is a flat plank** - no curve, no edge thickness, and its
  bottom edge sits on the ground line rather than being carried.
- **GRAVECALLER carries four loose grave-marker blocks standing on the ground
  around its feet.** They are part of the body, so they will travel with it -
  a walking creature dragging four headstones. It also reads as a smooth cone
  with no arms: a tent with a skull on top, not a caller.
- **BOWMAN is in a dead T-POSE** with both arms horizontal and the bow held
  flat across them. Nothing is posed, because nothing is rigged - this is the
  static-mesh fault showing up as a silhouette fault.
- **SCAR RAT is nearly invisible head-on.** Seen from the front it is a pale
  vertical sliver; all of its readable shape is in profile.
- **PIT WYRM stands vertically on its tail** and reads as a rocket or a fish
  stood on end rather than a wyrm. It is also the only body that fills its cell
  top to bottom, which is correct at 4.00 m but makes the nose-up pose loud.
- **HEWER's arms are much thinner than its shield and axe**, so the gear reads
  and the creature does not.
- **CUTTHROAT is too narrow to read at 1.60 m** - at the sheet's scale it is a
  pale stick with two thin blades.
- **GLOOM BAT floats with no shadow and no ground contact cue**, so at
  lift 1.8 it reads as pasted onto the frame rather than flying over it.

Honest list, nine faults, none of them hidden by cropping. Six of the nine
(T-pose, nose-up wyrm, thin arms, narrow cutthroat, head-on rat, no ground cue)
are consequences of the bodies being static and unposed - they would largely
fix themselves under option 3 above.

## WIRING THE GAME BUILD LANE MUST DO - I DID NOT DO IT AND WILL NOT

**FILE: `scripts/bestiary.gd`.** For each of the twelve rows listed in the
table above, the `"path"` value changes from the shared mesh to the key's own
body, e.g.

    "sentinel": {... "path": SKL + "Skeleton_Warrior.glb" ...}
            ->  "path": MON + "creatures/sentinel.glb"

`MON` is already `res://assets/monsters/`, so no new const is needed.
**Do not change `h`** - the bodies are authored at it and the scale factor is
1.000 on all twelve.
**`anims` must be dropped or guarded for any row that is switched**, because
these bodies carry no animations at all (see above) - leaving an `anims` dict
pointing at names that do not exist in the file is how a load comes back silent.
**This swap should not be made at all until Mr. E has chosen between the three
options above.** The measurement is ready either way.

**ALSO: NONE OF THE TWELVE HAS A `.glb.import` SIBLING.** Same fault as
`minibosses/snarer_chibi.glb`. Until a Godot editor run generates them, none of
these bodies can load - the wiring is blocked on an import pass before it is
blocked on anything else.

**ON THE SNARER, WHICH THE PLAN ASKED ME TO ANSWER:**
`assets/monsters/minibosses/snarer_chibi.glb` is wanted but is NOT urgent. The
game build loads the base `snarer.glb` and is not blocked. The chibi is the
register conversion's own body and should load once an import pass exists -
and that same pass covers all twelve creatures here, so it is one job, not two.
