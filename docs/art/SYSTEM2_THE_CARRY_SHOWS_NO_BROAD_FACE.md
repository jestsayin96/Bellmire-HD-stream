# SYSTEM 2 - THE CROSSBOW IS A LATH, AND THE REGISTER COULD NOT SEE IT
21 Nov 2026, 16:35-17:1x CT, art lane.

## THE ITEM

The 15:58 plan row: "THE CROSSBOW CARRY, STILL UNPROVEN TO A VIEWER ... the new
weaponfit register is GREEN on 24 models but it measures CARRY GEOMETRY, and a
viewer looking at crossbow_common_side.png still sees a flat plank forward of
the hand ... the item is open because the picture is, not because the number is."

## WHAT I CHECKED FIRST, MEASURED

1. **Whether the team lead looked at a stale picture.** He did not.
   `crossbow_common_side.png` is stamped 21 Nov 14:47 CT - written by the 14:35
   fix pass itself, not left over from the 17 Nov run. The `fixed_crossbow_*.png`
   set beside it IS stale (17 Nov 12:50 CT) and is not what either of us judged.
2. **I looked at it myself**, front, side and back, plus `crossbow_rare_side.png`.
   I agree without reservation: a small flat tray forward of the fist. The rare
   tier reads a little better and only because it is gold against a grey body -
   the geometry is identical, so colour is doing work the carry is not.
3. **I measured the silhouette before theorising about it.** On the shipped
   `_w_crossbow_common_front.png`, the weapon's own mask is **140 x 35 px**. At
   FRAME_H 3.80 m over 760 px that is 200 px/m, so the 140 IS the full 0.691 m
   prod. **THE SCALE IS NOT THE FAULT and gear.gd's x1.0 is right.** The fault
   is the 35.

## WHY `vis` AND `seen` WERE NEVER GOING TO CATCH IT

The register already carries a moved-pixel test - A body-only, B body+weapon, C
weapon-alone, one camera - which is the right shape of instrument and is the one
that cured the pass-11 fault. It still cannot see this, and here is the proof
rather than the assertion. `tools/art/_s2_roll.py` sweeps **roll about the slot's
own forward axis** - the one rotation that tilts the prod plane without changing
where the weapon points, how long it is, or where it is anchored. Everything else
is frozen; one camera per view is built before any weapon exists and is shared by
every angle and by the body-only plate.

      roll   front vis   front seen   front minor   side minor   side vis
        0      2610         0.935          35            41        2264   <- ships
       20      2574         0.923          57            70        3940
       35      2629         0.937          87            99        4238
       50      2607         0.896          98           121        4218
       65      2625         0.874          72           128        4044
       90      2692         0.859          55           126        3954

**Front `vis` moves 3% across a sweep that takes the picture from an unreadable
tray to a crossbow anyone can name, and front `seen` moves the WRONG WAY.** No
threshold on either number could have separated these. Raising VIS_MIN would only
have failed the dagger.

And the same point off the shipped register with no sweep at all:

      crossbow_common front  vis 2610  seen 0.94
      axe_common      front  vis 2954  seen 0.82

The crossbow scores BETTER on `seen` and within 12% on `vis`, and the axe reads
as an axe.

## THE NUMBER THAT DOES SEE IT, AND IT IS NOT A THRESHOLD I CHOSE

`show` = the best view's silhouette **minor extent** divided by the pixels the
weapon's own **middle world extent** would subtend. It asks the viewer's
question - *does this carry ever turn the weapon's broad face to a camera* -
rather than *how much of it is unoccluded*.

Measured on all 24 shipped cells (`tools/art/_s2_mid.py` for the extents,
the shipped `_w_` masks for the silhouettes):

      crossbow_uncommon  0.37      <-+
      crossbow_common    0.39        | the three cells a viewer complained about
      crossbow_rare      0.40      <-+
      ---------------------------- a 0.60-wide gap with NOTHING in it ----------
      axeDouble_common   1.00
      shield_common      1.01   sword_rare 1.01   axe_uncommon 1.01
      dagger_common      1.03   sword_common 1.03   axe_common 1.03
      hammer_common      1.06   (21 cells, 1.00 to 1.06)

The distribution is bimodal and `SHOW_MIN = 0.70` sits in the empty middle. It
was read off the data after the fact, not tuned until something passed.

**The dagger is the control and it matters.** `dagger_common` is 29 px across in
its widest view - thinner in pixels than any crossbow cell - and scores **1.03**,
because a dagger IS a sliver and this carry shows all the breadth it has. `show`
is not "thin is bad". It is "you are hiding the broad face this weapon has", and
the crossbow is the only weapon in the kit that has one and never turns it.

The cause, in one line: **the crossbow's prod plane is level and all three
cameras are level, so every one of them catches it edge-on.**

## WHAT THE PICTURES SAY, AND WHERE THEY OVERRULE THE NUMBER

`renders/art/system2/_roll/_sheet_roll_tight.png` (seven angles x three views)
and `_ab_35_50.png` (0 / 35 / 50 / 65 close, front and side). I looked at both.

`worst_minor` peaks at **50 deg** (98 px), and the body-penetration count from
the same sweep peaks there too - in 50's favour, not mine:

      roll        0    20    35    50    65    80    90
      worst_minor 35    57    87    98    72    58    55
      clip        40    35    35    22     9     6     5
      ground       0     0     0     0     0     0     0

**SO TWO OF THE THREE NUMBERS SAY 50 AND I AM RECOMMENDING 35. Here is why, said
straight rather than tidied.** At 50 and beyond the front view reads crowded: the
lower prod limb comes down over the cape and across the thigh. That is VISUAL
OVERLAP, not collision - `clip` falls from 40 to 22 over the same range and
`ground` is 0 at every angle, so nothing is penetrating anything more than it
already did, and I should not dress the picture up as a physics fault. The
silhouette metric cannot see the overlap at all, because it measures the weapon
ALONE and the leg is not in that mask; the same family of blindness this pass is
fixing, one level up.

**MY RECOMMENDATION IS 35 DEGREES**, on the pictures and on conservatism:

  - side: unmistakably a crossbow - both prod limbs curve out clear of the body,
    the stock runs forward out of the fist. best_minor 99 px against the same
    130.7 px denominator - `show` 0.76, from 0.39.
  - front: an angled bar across the hip, clear of the thigh and the cape.
  - it is the SMALLEST departure from the shipped carry that gets the read, and
    it leaves "stock forward" exactly as gear.gd's S20 comment intends.
  - 35 already clears SHOW_MIN with room; the extra 11% of worst_minor at 50 buys
    nothing a viewer can use.

**50 IS A DEFENSIBLE SECOND CHOICE AND I WILL NOT PRETEND OTHERWISE** - it wins
on worst_minor and on clip, and a seat that prefers the numbers to my eye has two
of three behind it. What is NOT defensible is 0, 80 or 90.

## I AM NOT PUBLISHING A GODOT EULER, AND THE REASON IS A MODEL OF MINE THAT WAS WRONG

`_s2_roll.py` tries to derive the `held_rot` the game build would need, and
**refuses**. Keep the refusal. The function models the Blender/Godot boundary as a
CONJUGATION, `B @ G @ B^-1`, solved off the one shipped pair and checked against
the staff pair; no basis satisfies both, so it raises.

The honest reading of that failure is that **my model is wrong, not gear.gd**. The
glTF importer changes the MESH basis only, which COMPOSES (`M_blender = C @ P`)
and does not conjugate. Under conjugation, rotation angle is invariant - and
gear.gd's `Vector3(-90, 0, 90)` is a 120 deg rotation while weaponfit's
`SLOT_ROT["crossbow"]` is 180 deg, which *under that model* would have been a
proof that the register mirrors the wrong carry. **IT IS NOT ONE**, because the
model does not hold, and I nearly published it as one. I verified separately that
gear.gd is self-consistent: `Vector3(-90, 0, 90)` in YXZ equals its own stated
comment map (mesh +X -> slot -Z, +Y -> slot -X, +Z -> slot +Y) exactly.

So this pass hands over a **roll in the slot frame** and the pictures behind it,
and leaves the euler to be solved the way S20's own comment says it was solved -
off the matrix, not guessed.

## FOR THE GAME BUILD LANE - I DO NOT EDIT gear.gd

1. `scripts/gear.gd`, `held_rot()`, the `DUN + "crossbow_"` branch: the carry
   wants **an extra ~35 deg of roll about the hand slot's forward axis** on top of
   the shipped `Vector3(-90, 0, 90)`. Solve it into a Vector3 on your side; the
   evidence is `renders/art/system2/_roll/` and `_roll_px.json` / `_roll_seen.json`.
   **Scale stays x1.0** - the prod already subtends its full 0.691 m.
2. **`tools/_s20_hand.gd` WILL GO RED AND SHOULD.** Its gate asserts *prod level +
   stock forward*. Prod level is precisely the thing that makes the crossbow
   unreadable. The gate's INTENT needs changing to "prod canted, stock forward",
   not just the euler - otherwise the fix and the gate fight each other.
3. Nothing else in this pass needs wiring. The register and the sweep are art-side.

## WHAT I CAN STILL SEE WRONG, AND IS NOT FIXED HERE

1. **The back view shows no crossbow at any angle** - vis 831-1202 px, seen
   0.26-0.39, flat across the whole sweep. The carry is in front of the body and
   roll cannot change that. Nobody should chase it; it is the carry position, not
   the rotation. The register's MIN_PROVING of 2 is the right bar for this family.
2. **The crossbows still clip 40-116 verts into the torso** - the stock runs back
   into the hip. Unchanged from 14:55; roll does not help it and may worsen it at
   large angles. Open.
3. **The staff still goes through the floor** (38-149 verts below z=0) and
   `staff_rare` still clips 202 verts into the hip. Both carried from the 14:55
   write-up, both the game build's to clear, both untouched here.
4. **`show` uses the world AABB**, which overstates the middle extent for a canted
   weapon and so understates `show` for exactly the cells most likely to be
   canted. The error leans toward RED, which is where an instrument's error
   belongs, but it is an approximation and a future pass could use a real OBB.
5. I have not swept the uncommon and rare crossbows. Their `show` is 0.37 and 0.40
   against common's 0.39, and their meshes are the same family at a larger size,
   so I expect the same angle to serve - **expect, not measured.**

## THE REGISTER IS RED AGAIN, ON PURPOSE, AND THE 15:58 NOTE IS SUPERSEDED

Re-run at 17:0x CT with the new gate in place:

    WEAPONFIT verdict=FAIL cells=24 blanks=0 frameclips=0 blind=0 laths=3 errors=0
      LATH crossbow_common:   show 0.39 (best view turns  51 px of a possible 131)
      LATH crossbow_uncommon: show 0.37 (best view turns  56 px of a possible 150)
      LATH crossbow_rare:     show 0.40 (best view turns  60 px of a possible 149)

**The 15:58 prompt-correction item 5 - "the register may now be reported green" -
is correct as of 15:58 and is now out of date by my own hand.** No seat should
report this register green off that note. The red is a TIGHTENING: the 21 cells
that were green are still green under the new gate, nothing was loosened, and the
three red cells are the three a human had already called wrong by looking. When
the game build lands the carry change these go green on their own.

Artefacts, all committed:

    tools/art/_s2_roll.py                         the sweep
    tools/art/_s2_mid.py                          the extents behind `show`
    tools/art/weaponfit.py                        the `show` gate
    renders/art/system2/_fit_register.json        verdict FAIL, laths 3
    renders/art/system2/_mid.json                 24 cells of world extents
    renders/art/system2/_roll/_roll_common.json   the sweep, with the refusal in it
    renders/art/system2/_roll/_roll_px.json       silhouettes per angle per view
    renders/art/system2/_roll/_roll_seen.json     vis/seen per angle per view
    renders/art/system2/_roll/_sheet_roll_tight.png   7 angles x 3 views - LOOKED AT
    renders/art/system2/_roll/_ab_35_50.png           0/35/50/65 close - LOOKED AT
