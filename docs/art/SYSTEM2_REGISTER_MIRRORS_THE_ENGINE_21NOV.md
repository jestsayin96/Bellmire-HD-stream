# SYSTEM 2 - THE REGISTER WAS MEASURING A CARRY THE ENGINE DOES NOT SHIP
21 Nov 2026, 14:35-14:55 CT, art lane.

## WHAT THE PLAN ASKED, AND WHY THE ANSWER IS NO

The plan's ART row said `renders/art/system2/_fit_register.json` was four-day-old
evidence of a fault fixed 35 minutes after the register was last written, and that
re-running it would clear the red "on its own" now that the game build's
`scripts/gear.gd` fix (ada04de8, S20, crossbow `held_rot` -> `Vector3(-90, 0, 90)`)
had landed.

I re-ran it unchanged at 14:37 CT. **It came back BIT-IDENTICAL:**

    verdict FAIL / cells 24 / blanks 0 / frame_clips 0 / blind 1 / errors 0
    BLIND crossbow_common: front seen 0.395 vis 726, side seen 0.664 vis 2039,
                           back seen 0.097 vis 175

Not one digit moved, because **`tools/art/weaponfit.py` never read `gear.gd`.** It
carried all 24 models with the identity correction off `handslot.r` and a flat
`HAND_SCALE = 0.8`, so no engine-side override could reach it. The red was never
stale. It was measuring a different carry from the one that ships.

## AND THE RED UNDERSTATED THE FAULT

I looked at `crossbow_common_side.png` - the one view the instrument called
*proving*, at `seen 0.664, vis 2039`. **There is no crossbow in it a viewer could
name.** 2039 px on a 760x760 cell is 0.35% of the frame: a dark smudge merged into
the body's own shadow. Same family as the pass-11 fault - a number answering "how
much of it is unoccluded" when the viewer's question is "can I see a crossbow".

## TWO FAMILIES WERE WRONG, AND THE GREEN ONE WAS WORSE

`gear.gd` overrides **crossbow** (rot, x1.0) and **staff** (rot `(0,0,90)`, x1.9).
The six staff cells had been reading **GREEN** at x0.8 and no rotation - a 0.9 m
wand lying across the hip, not the 1.7-2.2 m staff that ships. A green cell
measuring the wrong carry is worse than the red one, because nobody goes to look.

## THE ROTATION IS DERIVED, NOT COPIED ACROSS A CONVENTION BOUNDARY

Godot's `Vector3(-90, 0, 90)` is a YXZ euler in Godot's axes against a glTF mesh in
Godot's axes. This file is Blender, where the importer sends glTF +Z to -Y and
glTF +Y to +Z. Copying three numbers across that boundary is exactly how a wrong
carry reads green, so the frames were **measured** (`tools/art/_s2_axisprobe.py`):

    handslot.r, Blender world:  +X -> (0, 0, -1) DOWN
                                +Y -> (-0.15, -0.99, 0) FORWARD
                                +Z -> (-0.99, 0.15, 0) ACROSS
    crossbow_common.glb:        dim (0.691, 0.638, 0.194), thin axis Z,
                                prod symmetric on X, stock asymmetric on Y

Axis for axis, the Blender slot frame IS the frame `gear.gd`'s S19 comment
describes - which is what lets its stated intent be honoured rather than its
numbers transcribed. Every matrix is asserted a proper rotation (det +1) before use.

## RED ON EMPTY, KEPT

`gear_overrides()` raises if `gear.gd` cannot be found or a family it claims to
mirror cannot be parsed out of it. It fired for real on the first run (my default
path was one `dirname` too deep) and stopped the run instead of silently falling
back to 0.8. **That silence is what hid this for four days.**

## THE FRAME WAS CROPPING THE EVIDENCE

With the staff at its real x1.9, all eight staff cells went `frame_clip`. The cause
is not the staff: the cell's bottom edge sat at `-GROUND_UP` = -0.18 and the staff's
butt reaches **z -0.216 - below the floor**. The old frame was cropping out the one
thing those cells most needed to show. `GROUND_UP` is now 0.35 so the fault stays
IN the picture.

## FINAL: GREEN, 24 CELLS, AND HERE IS WHAT I CAN STILL SEE WRONG

    verdict GREEN / ok true / cells 24 / blanks 0 / frame_clips 0 / blind 0 / errors 0
    6 cells engine-mirrored

                        scale  reach   drop   clip  ground
    crossbow_common      1.0   0.080  0.114    40     0
    crossbow_uncommon    1.0   0.095  0.114    74     0
    crossbow_rare        1.0   0.122  0.114   116     0
    staff_common         1.9   0.902  0.821    52    51
    staff_uncommon       1.9   1.276  0.857    64    38
    staff_rare           1.9   1.355  0.853   202   149

Faults visible in the pictures, not in the verdict:

1. **THE STAFF GOES THROUGH THE FLOOR, AND SO WILL IT IN THE GAME.** 38-149 verts
   below z=0. The staff's origin is mid-shaft (z -0.432..0.475; at x1.9, -0.82..0.90)
   and the fist sits at z 0.64, so the butt lands at about -0.18. The engine uses the
   same scale and the same rotation, so this is not an artefact of my rig - a hero
   standing still has a hand's width of staff under the floor. **FOR THE GAME BUILD
   LANE** (I do not edit `gear.gd`): this wants either a small +Y offset on the staff
   in the hand slot, or the staff carried higher up the shaft. The number to clear is
   `ground` in this register.
2. `staff_rare` clips 202 verts into the body - the haft passes through the hip and
   thigh, worst of the six. Its head (crystal + crown) also sits directly in front of
   the jaw in the side view and crowds the head at stream distance.
3. The crossbows clip 40-116 verts into the torso: the stock runs back into the hip.
   Readable now from all three views, but it is inside the body, not beside it.

None of 1-3 is fixed here. This pass was about making the instrument measure the
carry that ships; the faults it now reports are real and are the next pass.
