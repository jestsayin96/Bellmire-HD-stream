# SYSTEM 2, ART'S HALF - THE 24 KAYKIT DUNGEON WEAPONS IN A HAND

Written 2026-11-17 by the art lane. The team lead's 11:58 row offered a choice
between art's half of System 2 and a twentieth miniboss. I TOOK SYSTEM 2, and the
reason is the one the row itself gave: the game build is wiring that pack right
now - its own next item is dagger, staff and crossbow - and its half draws from
mine. A twentieth creature would have been new work nobody was waiting on; this
was work one lane was already blocked behind.

## WHAT I CHECKED FOR FIRST, MEASURED, NOT REMEMBERED

Before copying a single file I listed what was already in the tree and what was
already in the pack:

  - `git ls-tree origin/main assets/gear/` - NINE of the 24 were already in the
    repo and already wired: sword, axe and hammer at common/uncommon/rare, put
    there by the game build at S16 and S17. I DID NOT RE-ADD THEM and I did not
    touch them.
  - `_packs/kaykit_dungeon_pack_CC0/Models/gltf/` - the pack ships TEN families
    with a common/uncommon/rare ladder. Two of the ten are furniture (chest,
    chestTop). The other eight are the 24 weapon models.
  - So the work was FIFTEEN files, not 24: dagger, staff, crossbow, axeDouble and
    shield, three tiers each.

The pack's own `License.txt` was read on the machine - CC0, commercial use
explicit. Recorded in docs/art/ASSET_SOURCES.md with the date and the URL.

## THE FIT PROOF, AND THE INSTRUMENT HAD TO BE FIXED BEFORE IT COULD BE BELIEVED

`tools/art/weaponfit.py` puts all 24 on the real KayKit Knight body in the idle
pose - MF.import_hero, hero 2.45 m, handslot.r at (-0.491, -0.107, 0.641) - and
shoots front, side and back at one fixed frame.

PASS 1 WAS A LIE AND I CAUGHT IT BY LOOKING. It carried each weapon to the fist
UPRIGHT, which is showcasegen's hand_delta convention and is right for a
procedural blade authored world-up. The register came back GREEN - 24 cells, zero
blanks, zero frame clips - and the picture showed the sword BURIED IN THE TORSO.
That is the same family of fault this lane found at pass 11 of the Hurdleman: a
number that cannot see what a viewer sees. The picture is the evidence and the
number is the suspect.

THE FIX WAS CALIBRATED, NOT GUESSED. `tools/art/_s2_cal.py` renders one axe under
four candidate axis corrections against the engine's own s17 close-up, where the
axe hangs from the fist with the haft along the hand. IDENTITY is the correction:
`rig.matrix_world @ pose_bone("handslot.r").matrix`, which is what Godot's
BoneAttachment3D does. The other three lay the haft through the legs or out the
back. Pass 2 then cropped three swords and two daggers off the cell - the border
check caught that, which is what it is for - and the frame was widened twice.

FINAL: verdict GREEN, 24 of 24 cells, 0 blanks, 0 frame clips, errors [].
The clip column is weapon vertices measured INSIDE the body, excluding the fist
sphere (0.16 m - the grip is inside the fist by design). It is reported, not
gated, because a weapon carried at the hip touches a hero.

| model | reach | drop | span | inside the body | below floor |
|---|---|---|---|---|---|
| sword_common       |  0.16 |  0.16 |  1.01 |   23 /  148 (15.5%) | 0 |
| sword_uncommon     |  0.16 |  0.16 |  1.20 |   50 /  187 (26.7%) | 0 |
| sword_rare         |  0.30 |  0.30 |  1.50 |   76 /  494 (15.4%) | 0 |
| axe_common         |  0.22 |  0.09 |  0.71 |  101 /  283 (35.7%) | 0 |
| axe_uncommon       |  0.32 |  0.07 |  0.76 |   38 /  335 (11.3%) | 0 |
| axe_rare           |  0.32 |  0.11 |  0.75 |   24 /  653 ( 3.7%) | 0 |
| hammer_common      |  0.21 |  0.21 |  0.69 |  101 /  371 (27.2%) | 0 |
| hammer_uncommon    |  0.32 |  0.32 |  0.69 |   64 /  454 (14.1%) | 0 |
| hammer_rare        |  0.34 |  0.34 |  0.73 |  110 / 1636 ( 6.7%) | 0 |
| dagger_common      |  0.06 |  0.06 |  0.71 |    3 /   21 (14.3%) | 0 |
| dagger_uncommon    |  0.15 |  0.15 |  0.82 |    8 /   64 (12.5%) | 0 |
| dagger_rare        |  0.15 |  0.15 |  0.92 |   19 /  152 (12.5%) | 0 |
| staff_common       |  0.08 |  0.09 |  0.72 |   51 /  294 (17.3%) | 0 |
| staff_uncommon     |  0.10 |  0.11 |  0.89 |   38 /  310 (12.3%) | 0 |
| staff_rare         |  0.09 |  0.09 |  0.92 |  207 /  827 (25.0%) | 0 |
| crossbow_common    |  0.28 |  0.28 |  0.12 |   98 /  202 (48.5%) | 0 |
| crossbow_uncommon  |  0.41 |  0.41 |  0.15 |  127 /  338 (37.6%) | 0 |
| crossbow_rare      |  0.42 |  0.42 |  0.15 |  194 /  500 (38.8%) | 0 |
| axeDouble_common   |  0.22 |  0.22 |  0.71 |   60 /  276 (21.7%) | 0 |
| axeDouble_uncommon |  0.32 |  0.32 |  0.76 |   25 /  436 ( 5.7%) | 0 |
| axeDouble_rare     |  0.32 |  0.32 |  0.75 |    0 /  821 ( 0.0%) | 0 |
| shield_common      |  0.28 |  0.28 |  0.54 |  355 /  630 (56.3%) | 0 |
| shield_uncommon    |  0.30 |  0.30 |  0.66 |  343 /  626 (54.8%) | 0 |
| shield_rare        |  0.28 |  0.28 |  0.70 |  140 /  291 (48.1%) | 0 |

The instrument can move and does: axeDouble_rare went 318 -> 0 between pass 1 and
pass 4, sword_common 63 -> 23. It also goes RED ON EMPTY - a cell whose model
fails to import, or whose clip test would be computed over zero vertices, is an
error and not a silent pass.

## THE FOUR FAULTS I CAN SEE. ALL OF THEM, NOT THE FLATTERING THREE.

1. **THE STAFF IS BURIED, AND MY OWN CLIP NUMBER DID NOT CATCH IT.** The dungeon
   staff is authored about the MIDDLE of its shaft (local z -0.43 .. +0.47), so a
   plain attach lays it sideways and half the shaft goes back through the hero -
   only the finial shows. Clip read 51/294, which is LOW. The shaft sits behind
   the cape, where a six-ray inside test finds a way out. Said plainly because it
   is the second time a number of mine has missed what the eye sees.
2. **THE CROSSBOW IS WORSE AND HERE THE NUMBER AGREES.** It is authored FLAT
   (0.69 x 0.64 x 0.19) and has no blade axis at all; in the fist it lies along
   the hip, inside the body. 40-50% of its own vertices read inside. On the sheet
   you can see a sliver at the belt and nothing else.
3. **THE SHIELD IS HELD THROUGH THE HIP.** Authored about its own centre, so the
   face reads from the front but 50-56% of it is inside the body, and it is on
   the weapon hand rather than off the forearm. gear.gd already has an offhand
   bone (handslot.l) for this.
4. **THE SIDE VIEW PROVES NOTHING FOR A BLADE OR AN UPRIGHT STAFF.** The carry
   points the blade straight out along the camera axis at azimuth 90, and an
   upright staff stands directly behind the body from that angle. Both are real
   occlusion, not modelling faults, but the side cell is evidence about the BODY
   and not about the weapon. Judge blades on front and back.

Smaller, and not worth an item: sword_common's blade grazes the cape edge; every
family's grip disappears into the fist, which is correct.

## THE NUMBERS THAT FIX 1, 2 AND 3 - MEASURED, AND PROVED WITH A PICTURE

`tools/art/_s2_carry.py` computes the LOCAL rotation that has to sit between the
BoneAttachment3D and the model, and re-renders with it applied so the fix is
judged as a picture rather than as a quaternion.

  staff     local euler (-85.13, -90.06, 85.26) deg / quat (0.70708,0.00071,-0.70714,0.0)
            AND hand_scale 1.30, not 0.8. At 0.8 the staff stands 0.73 m on a
            2.45 m hero and reads as a rod. At 1.30 the butt sits at z 0.05-0.08,
            just clear of the floor, the head tops out at 1.26-1.57 - chin height
            - and the clip count falls 168 -> 34. 1.30 is the LARGEST scale this
            body can carry upright without the staff dragging; it is measured off
            the model's own below-grip length (0.43), not chosen.
            Picture: renders/art/system2/_sheet_s130_staff.png
  crossbow  local euler (0, 0, 90.06) deg - levels the stock forward.
            Picture: renders/art/system2/_sheet_fixed_crossbow.png
  shield    same rotation, and it belongs on handslot.l.
            Picture: renders/art/system2/_sheet_fixed_shield.png

**I DID NOT BAKE THESE ROTATIONS INTO THE MESHES AND I WILL NOT.** Baking a pose
correction inside an asset hides it, and it goes silently wrong the moment the
idle pose or the attach bone changes. It belongs in gear.gd's equip(), which is
the game build's file. The number and the proof are handed over; the edit is not
mine to make.

## WHAT THE GAME BUILD MUST WIRE (I DO NOT TOUCH scripts/gear.gd)

  a. `scripts/gear.gd` KINDS - the three families your own row names, exactly the
     shape sword/axe/mace already have:
       "dagger"   kit[0..2] -> DUN + "dagger_common/uncommon/rare.glb"
       "staff"    kit[0..2] -> DUN + "staff_common/uncommon/rare.glb"
       "crossbow" kit[0..2] -> DUN + "crossbow_common/uncommon/rare.glb"
     No new licence row is owed - same pack, already recorded.
  b. `scripts/gear.gd` - a GREATAXE path. The pack's `axeDouble_*` is in the repo
     now and nothing reads it. This is the item you could not settle off
     s17_front.png: give "Bearded Greataxe" its own double-headed silhouette and
     the question stops being "hidden or absent".
  c. `scripts/gear.gd` equip() / hand_scale() - the three carry corrections above.
     equip() currently applies position and scale but no rotation, which is why
     the staff and the crossbow cannot read however good the model is.
  d. `scripts/gear.gd` - shields to handslot.l, and the dungeon shield ladder at
     tiers 1-3.
None of a-d is art's to do and none of it is blocking art.

## WHAT I CHANGED IN MY OWN FILES
  - assets/gear/dungeon/ - fifteen new .glb (the pack's own geometry, renamed)
  - tools/art/gearmodels.py - DAGGER, STAFF, CROSSBOW and SHIELDS now take the
    dungeon ladder at tiers 1-3 (kit models keep 4-5, the same split gear.gd uses),
    and a new GREATAXE table so a greataxe is not a hatchet.
  - tools/art/weaponfit.py, _s2_cal.py, _s2_carry.py, _s2_sheet.py, _s2_probe.py
  - renders/art/system2/ - 24 cells x 3 views, eight contact sheets, the fixed
    sheets, _fit_register.json and _carry_fix.json
