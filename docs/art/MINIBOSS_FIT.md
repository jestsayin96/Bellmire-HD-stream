# THE FOURTEEN MINIBOSSES DO NOT FIT THE CHARACTERS. HERE IS THE PICTURE.

**16 Nov 2026, art lane.** Mr. E's acceptance test is FIT - *"these need to fit
the characters in our game."* For gear that means rendering it on a body. For a
creature there is one equivalent question, and **nobody had ever asked it: how
big does it read standing next to a hero?**

Answered now, by a picture, not an argument:
`renders/art/minibosses/_hero_scale.png` - all fourteen, each beside a real
KayKit adventurer at scale 1.0, **one ortho scale and one ground line in every
cell**, with the top of the hero carried across every cell as a dashed rule.
Rig: `tools/art/minibossfit.py`. Blank check **14 files, 0 failures**.

## WHAT HAD TO BE MEASURED BEFORE ANY OF IT MEANT ANYTHING

Two numbers decide this and both were wrong in my head:

1. **A hero is 2.45 m tall, not 1.30 m.** `gear.gd`'s measured "body top y
   1.30" is the TORSO MESH. These are **chibi** bodies - `Knight_Head` alone
   runs 1.20 to 2.30 and the helmet to 2.45. The head is **55% of the whole
   height**. Legs are 21%.
2. **Heroes are never normalised.** `townsfolk.gd` ~253 scales `_mdl` only when
   `size_k != 1.0`, and that is for children. So a viewer's hero is exactly the
   raw glb: 2.45 m. Monsters ARE normalised - `bestiary.gd`'s `h` in metres -
   which is why the two can be compared at all.

Two traps inside the measurement itself, both caught and both now commented in
the rig: the character glb carries **the whole wardrobe** (six weapons and
shields parked on the rig, plus a hidden 1.9 m Icosphere) and measures 3.45 m
raw; and the **rest pose is not the posed body** - on Blender 4.4+ slotted
actions, setting `animation_data.action` without also setting `action_slot`
leaves the rig in rest and reports success.

## FAULT 1 - SCALE. TEN OF THE FOURTEEN ARE SHORTER THAN THE PARTY.

| | |
|---|---|
| hero | **2.45 m** |
| miniboss authored heights | 2.00 - 2.70 m |
| ratio to the hero | **0.82x to 1.10x** |

A set piece gated to floor 4 and deeper that the heroes **look down on** is not
a set piece. The Scrapwright is 0.82x a hero. Only the Bellman and the Snuffer
are taller, by 6-10%, which reads as a tall man and not as an event.

**This costs no geometry.** The mesh is authored at a proportion, not a size;
the in-game size is whatever `h` the game build lane types into `bestiary.gd`.
The recommendation is **authored + 1.30 m**, which keeps the order and the
spacing of the fourteen exactly as designed, puts the smallest at 1.35x a hero
and the largest at 1.63x, and stays clear below the smallest lord (4.2 m):

| key | authored | now | **recommend `h`** | vs hero |
|---|---|---|---|---|
| scrapwright | 2.00 | 0.82x | **3.30** | 1.35x |
| cook | 2.05 | 0.84x | **3.35** | 1.37x |
| boiler | 2.10 | 0.86x | **3.40** | 1.39x |
| tallyman | 2.15 | 0.88x | **3.45** | 1.41x |
| drillmaster | 2.20 | 0.90x | **3.50** | 1.43x |
| sower | 2.25 | 0.92x | **3.55** | 1.45x |
| porter | 2.30 | 0.94x | **3.60** | 1.47x |
| snarer | 2.30 | 0.94x | **3.60** | 1.47x |
| gaoler | 2.35 | 0.96x | **3.65** | 1.49x |
| stoker | 2.40 | 0.98x | **3.70** | 1.51x |
| sexton | 2.45 | 1.00x | **3.75** | 1.53x |
| sluicekeeper | 2.50 | 1.02x | **3.80** | 1.55x |
| snuffer | 2.60 | 1.06x | **3.90** | 1.59x |
| bellman | 2.70 | 1.10x | **4.00** | 1.63x |

A miniboss at these heights still **fits a three-cell corridor**: the corridor
test is the FOOTPRINT span, which is unchanged by `h` only if `h` is applied as
a uniform normalise - it is (`Monster` scales the body to `h` from its measured
bounds), so the widest, the Gaoler's 3.72 m chain coil, becomes 3.72 x 3.65 /
2.35 = **5.78 m, still inside the 11.0 m clear span**. None of the fourteen is
room-locked at the recommended heights either. The game build lane should
re-run its own clearance test rather than take my word.

## FAULT 2 - PROPORTION. THIS ONE IS THE ART LANE'S, AND IT IS NOT FREE.

The men inside these creatures are seven-head realistic figures with 0.10 m
limbs. The game's characters are chibi: head 55% of height, legs 21%, mitts for
hands. Side by side **they read as two different games** - the minibosses look
like pipe-cleaner men next to a toy knight.

`renders/art/minibosses/_proportion.png` is the worked example on one creature,
four cells, one change per cell: the Drillmaster as he is; rebuilt chibi at the
same 2.20 m; original at the recommended 3.60 m; and both changes together.
`minibosses.drillmaster_chibi` is the builder, keyed out of `ORDER` so it
changes none of the shipped fourteen.

**Both changes together is the one that works.** Proportion alone fixes the
register but leaves him small; height alone makes a thin scarecrow bigger.

### The honest fault list on the chibi Drillmaster - every one of these is visible

Two were found by looking and fixed in a second pass, and are named here rather
than hidden: the **eyes were inside the skull** (the head is 0.44 deep and they
sat at 0.40, so the face was blank from every angle), and the **helm read as a
mushroom** - a 1.24 m brim at mid-head height covering dome and face both.

What is still wrong, after the fix, in the picture as it stands:

1. The helm dome is a **sharp cone**, so it still reads as a pointed farmer's
   hat rather than a kettle helm. It wants a rounded cap.
2. The eyes are **flat pale discs with no pupil**. The knight has a dark pupil
   in a light eye; these read as blank goggles.
3. **No neck and no value break** between head and torso - both are `bone`, so
   the head's bottom edge is lost and the shoulder spheres read as two side
   blobs rather than shoulders.
4. The **baton reads as a lollipop** - a pale ball on a thin stick, hanging off
   a mitt that does not visibly hold it.
5. The **gong crowds the right shoulder** at this bulk and its struck rings
   barely read from the front; it is close to leaving the cell.
6. The **belt has vanished** into the body colour at wear 0.15.
7. **Boots read as hooves** - the legs are so short that the dark blocks are
   most of what is there.

**Do not convert the other thirteen until 1, 2 and 3 are solved on this one.**
They are register problems shared by every figure in the file, and solving them
thirteen more times is the expensive way to find that out.

## WHAT THE GAME BUILD LANE SHOULD DO - the art lane does not touch these files

1. **`scripts/bestiary.gd`** - the fourteen entries are still completely
   unwired (there is no reference to `minibosses` in that file at all). When
   they are added, use the **recommended `h` column above**, not the authored
   height, and no `anims` entry - these are static meshes with no armature.
2. **`scripts/dungeon_hd.gd` ~655** - the theme -> miniboss map, and split the
   shared `shrine`/`crypt` weight row (Snuffer = shrine, Sexton = crypt).
3. Re-run the spawn clearance test with the new heights before shipping.

## FOR MR. E - one decision, and the picture is `_proportion.png`

The fourteen read as a different art style from your own characters. The fix is
not cosmetic and it is not cheap: it is a rebuild of the figure inside each of
the fourteen, and the worked example says roughly a pass per creature. Worth
doing, worth doing later, or leave them realistic and let the dungeon be a
different register from the town? The height fix is free either way and should
happen regardless.

---

## REGISTER CONVERSION 2 OF 14 - THE STOKER, PASS 3

`renders/art/minibosses/_stoker_register.png` - original left, chibi right, a
real 2.45 m KayKit Knight standing beside each. Front, side and back per cell.
Ratio 0.98, pair 4.74 m, fits the fixed frame, blank check 2 files 0 failures,
`BLENDER_EEVEE`. Four faults closed, and the fourth was not where it looked.

**8 - THE T-POSE.** Both arms were TWO-POINT polylines leaving the shoulder
level or rising, so each read as a ball on a stick held straight out. Both are
three-point now with a real elbow: upper arm out and down, forearm forward and
in. A chibi arm is short enough that the elbow IS the read; without one there is
no arm, only a spoke.

**9 - THE LEFT MITT IN THE FLUE.** The mitt sat at x -0.64 and the flue stands
at -0.74 with a 0.115 radius, so the hand was inside the chimney's column in the
front silhouette and the two merged. The forearm now comes to the hip, mitt at
-0.44, clear of the flue's near edge and reading against the body.

**THE EYES.** A single dark oval on a pale skull is a HOLE, not an eye - the
Drillmaster's fault 2 arriving from the opposite direction. The hero's face has
three values and so does this one now: dark socket, pale eye sunk in it, dark
pupil, each standing slightly proud of the last. No glow - this creature's one
light is the grate, which is the thing the party has to starve.

**4 - THE VALUE BREAK, AND IT WAS THE LIMBS, NOT THE HEAD.** `limb()` defaults
to the `bone` slot. Every arm and leg was therefore PALER than the torso: a bone
stick-figure in a brown box, with the lightest things on the creature at its
ankles. Limbs now take the mid tone, boots and mitts the dark, the skull keeps
the bone. The single pale thing above the ground is the face.

### What is still wrong - looked at, front, side and back

1. ~~The heat cap reads as a bowl-cut of hair.~~ **FIXED IN THE SAME PASS, and
   deliberately so: this is the register fault the other twelve would have
   inherited**, and converting them over a cap that reads as hair is the
   expensive way to find that out. A dark dome on a pale skull has no edge
   between them. It now has a brim 0.08 proud of the skull sitting 0.11 above
   the eyes - the Drillmaster's mushroom is what that clearance is for - and a
   bone band in the seam for the cap to end at. Two things to watch in the
   picture as it stands: the brim's front edge runs **close to the eye line**
   and the eyes now sit in its shade (a gain in grimness, a hair from being
   fault 2 of the Drillmaster all over again), and the **bone band is the
   brightest ring on the head**, competing with the face it was meant to serve.
2. **The back is bare** - a flat slab with nothing on it but the flue passing.
   The knight has a cape there; this has nothing that says furnace from behind.
3. The pupils are **small and wide-set with no brow**, so the face reads doll-ish
   rather than grim. The value structure is right; the expression is not.
4. **The belt is invisible from the front** - dark on brown, and both forearms
   now cross it.
5. **Boots are dark blocks nearly as wide as the leg is long** - the Drillmaster's
   fault 7, shared by every chibi conversion so far.
6. From the side the **torso is a shallow slab**, 0.48 deep against a chibi
   knight who is round. Depth, not height, is what is missing.
7. The **fuel basket reads as a flat plank from the FRONT only** - from side and
   back it is plainly a bucket. It is a front-view presentation fault, not the
   geometry fault pass 2 recorded.
8. The **rake haft is `bone`** and is the brightest long line on the figure after
   the grate; it competes slightly with the face.
9. The **shoulder spheres overhang the upper arms** and float a little at the
   joint.

Twelve creatures still to convert. The Scrapwright and the Bellman are a machine
and a shroud with no man-proportions, and should be skipped.
