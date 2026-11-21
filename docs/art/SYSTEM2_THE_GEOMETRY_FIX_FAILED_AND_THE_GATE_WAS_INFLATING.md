# SYSTEM 2 - I TRIED THE GEOMETRY FIX I WAS GIVEN, IT FAILED, AND ON THE WAY I
# FOUND MY OWN GATE HANDING OUT A 33% UNEARNED PASS
21 Nov 2026, 17:35-18:1x CT, art lane.

## THE ITEM

The 16:58 plan row, to ART: "FIX THE CROSSBOW PROD, THE DEFECT YOU JUST PROVED
... the geometry fix is your next pass and the acceptance test is a PICTURE,
not the register."

## WHAT I CHECKED FIRST, MEASURED, NOT REMEMBERED

1. **That the defect is still real and still mine.** `_fit_register.json` on
   disk: verdict FAIL, `laths` 3, crossbow common/uncommon/rare at show
   0.39/0.37/0.40 against SHOW_MIN 0.70. Not stale - written 21 Nov 17:0x.
2. **I looked at the shipped pictures again before touching anything.**
   `crossbow_common_side.png` and `_front.png`, both stamped 21 Nov 14:47 CT.
   A featureless flat tray forward of the fist, from both. I agree with the
   complaint without reservation.
3. **I measured the mesh instead of assuming its shape.**
   `crossbow_common.glb`: ONE mesh, 395 verts, 316 polys, materials WoodDark +
   Stone. Dim (0.691, 0.638, 0.194). **There is no bowstring and no stirrup in
   the asset at all** - the two parts that would make a crossbow nameable
   edge-on simply are not modelled. Banding the verts on |x| shows the prod is
   a flat limb pair in the mesh XY plane, 0.047-0.083 m thick, tips swept back
   from y -0.533 to y -0.24.

## THE GEOMETRY FIX I CHOSE, AND WHY I CHOSE IT OVER THE OBVIOUS ONE

The obvious art-side shortcut is to **bake the 35 deg carry roll into the glb**.
It would make the shipped carry read with no engine change at all. **I REFUSED
IT AND THE REASON IS NOT STYLE.** The previous pass handed the game build a
~35 deg roll with evidence. If that lands in `gear.gd` against a pre-rolled
mesh the result is 70 deg and nobody would be able to see where the second 35
came from. A fix that silently double-applies is worse than the defect.

So I tried **camber**: bend the prod limbs up out of the stock's plane, ramped
on |x| so the stock never moves, rotating about the prod's own centreline. This
is a change to the weapon's SHAPE, it composes with any carry, it cannot double
up, and a cambered prod is what real crossbows have. `tools/art/_s2_camber.py`,
same body, same three cameras built once before any weapon exists.

## IT FAILED. THE NUMBER SAYS SO AND SO DOES THE PICTURE, AND THEY AGREE

Honest `show` (fixed denominator - see the next section for why that word is
doing work), crossbow_common, one body, one camera set, 9 cells:

           roll 0    roll 20   roll 35
  camber 0   0.390    0.536     0.757      <- roll alone CLEARS
  camber 30  0.574    0.696     0.742
  camber 40  0.643    0.734     0.757      <- camber alone does NOT clear

**Camber alone tops out at 0.643 and does not discharge the fault.** And the
pictures say the same thing, which is the part that settles it. On
`_ab_grid_side.png`, which I looked at:

  - **(0,0) shipped** - a flat tray. Unreadable. Confirms the complaint.
  - **(0,35) roll alone** - the prod stands up as a clear C beyond the fist,
    the stock runs forward out of the hand. **This is the one a viewer would
    call a crossbow.** Best read of the four.
  - **(40,0) camber alone** - a thickened wedge with a rolled lip. Still reads
    as a plank. From the front it is worse than that: at 40 and above the two
    limbs read as a pair of HORNS or tusks at the hip, not a bow.
  - **(40,20)** - better than camber alone, but the limbs read as a claw.

**So my own hypothesis for this run is refuted, and the fix already handed to
the game build is the right one.** It survives the denominator correction
below (0.757, not the 0.833 the old gate would have printed).

Camber is not worthless and I will not overstate that either: it cuts the
body clip hard - 40 verts into the torso at (0,0), **20 at (40,20) and 15 at
(40,35)** - and (40,20) clears the gate at 0.734, so camber buys the engine a
GENTLER roll if it wants one. **But I am not shipping it this run.** It does
not close the item on its own, it is a one-way edit to a pack mesh, and the
gate that would police it was inflating until twenty minutes ago.

## THE REAL FINDING: MY OWN `show` DENOMINATOR MOVED, AND IT MOVED THE WRONG WAY

The note I wrote above `SHOW_MIN` said the world AABB "overstates the middle
extent for a canted weapon, so `show` is understated ... the conservative
direction is toward RED, which is where an instrument's error belongs."
**I MEASURED IT THIS RUN AND IT IS THE OPPOSITE. I was wrong.**

`show` divided the best view's minor extent by the px the weapon's **world**
AABB middle extent subtends. Rotating or bending a weapon changes that AABB.
So the denominator was a property of the CARRY, not of the weapon, and every
change that raises the numerator shrinks it at the same moment:

      camber  roll   best_minor   world mid_px   show(world)   show(fixed)
         0      0        51           130.7         0.390         0.390
         0     35        99           118.8         0.833         0.757
        40      0        84           112.5         0.747         0.643
        40     35        99            98.0        *1.010*        0.757

**The bottom row scores 1.01 on a weapon whose honest number is 0.757 - a 33%
unearned pass, in exactly the direction a lane trying to fix a lath would
push.** A gate that rewards shrinking the weapon is not a gate. Had I shipped
camber 40 and let the game build land its 35, the register would have printed
a comfortable 1.01 and the three LATH lines would have vanished on a weapon
that had earned 0.757.

**FIXED.** `weaponfit.py` now takes the denominator in the **mesh's own local
frame** (times the engine's `hand_scale`), which no carry rotation can touch.

RE-RUN ON ALL 24 CELLS, AND NOTHING WAS LOOSENED:

    WEAPONFIT verdict=FAIL cells=24 blanks=0 frameclips=0 blind=0 laths=3 errors=0
      LATH crossbow_common   show 0.40 (51 px of a possible 128)
      LATH crossbow_uncommon show 0.37 (56 px of a possible 152)
      LATH crossbow_rare     show 0.41 (60 px of a possible 148)

Same three cells, same verdict. The 21 green cells are all still green and
21 of 24 denominators moved by less than 1.5%, because at the shipped roll of
zero the two frames nearly agree - **which is precisely why this defect could
sit in a shipped gate unnoticed: it is invisible until someone fixes the
thing it is measuring.** The two that moved: `dagger_common` 1.03 -> 1.20
(+17% denominator shrink, still green, and it WIDENS the bimodal gap) and
`crossbow_common` 0.39 -> 0.40. The gap SHOW_MIN sits in is still empty:
0.41 to 1.00.

## WHAT I CAN STILL SEE WRONG, INCLUDING IN MY OWN FIX

1. **The denominator fix is not complete and I am not claiming it is.** A
   change that genuinely DEFORMS the mesh still shrinks the local extent, so
   camber can still buy some of its own pass. **I first wrote 4% here from
   reasoning and then measured it: it is 14%** - at 40 deg the local mid falls
   0.6535 -> 0.5623 m, because bending the tips up pulls the prod span in and
   the span, not the stock, becomes the middle extent. Against the 33% just
   closed that is a real improvement and NOT a closure, and I am not going to
   round my own residual down. A real OBB, or the max silhouette minor over
   all orientations, would close it. This is also the second reason I did not
   ship camber this run: the gate cannot yet police it honestly.
   Written into the source note, not just here.
2. **No bowstring, no stirrup, on any of the three crossbows.** This is the
   deeper art answer and it is NOT what the plan asked for this run, so I did
   not do it. A stirrup hangs perpendicular to the prod and would read from
   exactly the angles the prod does not. Open, and mine.
3. **The back view still shows no crossbow at any angle** - carried forward
   from the previous pass unchanged. Carry position, not rotation. Do not
   chase it.
4. **The crossbows still clip 40 verts into the torso at the shipped carry.**
   Roll cuts it to 35, camber+roll to 15-20. Open.
5. **I swept `common` only.** uncommon and rare are the same family at larger
   size; I expect the same angles to serve - **expect, not measured.**
6. The staff still goes through the floor. Untouched, still the game build's.

## FOR THE GAME BUILD LANE - I DID NOT EDIT gear.gd AND I SHIPPED NO ASSET

1. **The 35 deg roll handed over at 17:1x CT STANDS.** It is re-confirmed on a
   corrected instrument: `show` 0.757 against SHOW_MIN 0.70, and it is the
   best-reading of the four pictures. `scripts/gear.gd`, `held_rot()`, the
   `DUN + "crossbow_"` branch, extra ~35 deg of roll about the hand slot's
   forward axis on top of `Vector3(-90, 0, 90)`. Scale stays x1.0.
2. **If 35 crowds the front view, 20 deg becomes available the moment art
   ships camber** - (40,20) measures 0.734 with clip 20. Say so and I will
   ship it; I am not shipping an asset change on a guess about your euler.
3. `tools/_s20_hand.gd` will go red on any of these and its INTENT needs
   changing to "prod canted, stock forward". Unchanged from the last pass.

## ARTEFACTS, ALL COMMITTED

    tools/art/_s2_camber.py                           the camber x roll sweep
    tools/art/weaponfit.py                            the denominator fix
    renders/art/system2/_camber/_camber_grid.json     9 cells, both show numbers
    renders/art/system2/_camber/_camber_common.json   the 5-angle camber sweep
    renders/art/system2/_camber/_sheet_grid.png       9 cells x 3 views
    renders/art/system2/_camber/_ab_grid_side.png     the four candidates - LOOKED AT
    renders/art/system2/_camber/_ab_grid_front.png    the four candidates - LOOKED AT
    renders/art/system2/_camber/_tight_front.png      camber 0..55 close - LOOKED AT
    renders/art/system2/_fit_register.json            FAIL, laths 3, honest denominator
