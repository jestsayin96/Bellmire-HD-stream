"""weaponfit - ART'S HALF OF SYSTEM 2: the 24 KayKit dungeon weapons, in a hand.

  blender -b -noaudio -P tools/art/weaponfit.py -- --repo <repo> [--fams ...] [--control]

System 2 is "named weapons wired live". The GAME BUILD wires gear.gd; the art
half is the models themselves and the only thing that makes them shippable:
PROOF THEY SIT IN A HAND. Nine of the 24 (sword, axe, hammer) are already in
the repo and already wired. Fifteen were still sitting in the pack. This file
puts all 24 on the same body at the same framing and MEASURES each one, so the
three that are wired and the five families that are not are judged by one
instrument.

WHAT IS MEASURED, PER MODEL:
  reach      tip height above the fist, in metres, on a 2.45 m hero
  drop       how far the pommel hangs below the fist
  clip       weapon vertices INSIDE the body surface, excluding the fist
             sphere - the grip is inside the fist BY DESIGN and is not a fault
  ground     vertices below z=0 (the weapon dragging through the floor)
  frame      vertices outside the fixed camera frame (a crop is a fault)
  vis        *** CAN THE VIEWER SEE THE WEAPON IN THIS VIEW AT ALL *** - see below

AND THE INSTRUMENT GOES RED ON EMPTY. A clip count taken over zero vertices,
or a cell whose model failed to import, is a FAIL and not a silent green - the
lane has shipped a metric computed over nothing before and it read green.

THE CARRY IS THE ENGINE'S, AND IT HAD TO BE CALIBRATED BEFORE IT COULD BE
TRUSTED. Pass 1 carried the weapon to the fist UPRIGHT - showcasegen's
hand_delta convention, which is right for a procedural blade authored world-up
and WRONG for these. The register read GREEN and the picture showed the sword
buried in the torso: the same family of fault this lane found at pass 11, a
number that cannot see what a viewer sees. The engine parents to a
BoneAttachment3D, which takes the bone's FULL posed basis, so this driver now
uses `rig.matrix_world @ pose_bone("handslot.r").matrix` - measured against the
four candidate axis corrections in _s2_cal.py and against the game build's own
s17 close-up, where the axe hangs from the fist with the haft along the hand.
Identity is the correction; the other three lay the haft through the legs or
out the back.

=============================================================================
*** FAULT 4, FOUND BY THIS LANE AT 12:50 AND FIXED HERE. THE SIDE CELL PROVED
*** NOTHING, AND THE PROOF OF THAT WAS ALREADY SITTING IN THE REGISTER.
=============================================================================
The 12:50 register read GREEN over 24 cells with 0 blanks and 0 frame clips,
and its `opaque.side` was 81339 FOR TWENTY-ONE OF THE TWENTY-FOUR CELLS -
identical to the pixel. Three cameras, and one of them was photographing the
body and nothing else. Only crossbow_uncommon (81392) and crossbow_rare (81413)
differed at all, by 53 and 74 pixels, because the crossbow is wide enough to
poke out past the far hip. Nobody had to look at a picture to know: equal
numbers across different weapons ARE the finding.

TWO SEPARATE THINGS WERE WRONG, AND THEY ARE FIXED AND MEASURED SEPARATELY.

1. THE CAMERA WAS ON THE WRONG SIDE. handslot.r sits at world x -0.49. The old
   side view was az +90, which stands the camera at +x - the hero's OFFHAND
   side - so the whole body is between the lens and the weapon. The side view
   is now az -90, the CARRY side. This is a one-number change and it is the
   root cause; the visibility instrument below is what proves it rather than
   my say-so.

2. THE HARNESS COULD NOT HAVE CAUGHT IT. `opaque` counts every pixel in the
   cell, and the body is ~81k of them, so a weapon contributing ZERO can only
   be seen by comparing cells to each other, which nothing did. A blank check
   cannot see a hidden weapon for the same reason a border check could not see
   a clipped glow: it is not the question being asked.
   THE TEST THAT WORKS ASKS THE VIEWER'S QUESTION. Through ONE fixed camera:
     A = the body alone          (rendered once per view and cached)
     B = the body with the weapon
     C = the weapon alone        (the denominator: its full silhouette)
   delta = every pixel that MOVED between A and B - which includes the
           weapon's CAST SHADOW on the body, so it can exceed the weapon's area
   alone = opaque pixels in C    - what it could add if nothing covered it
   vis   = moved pixels INSIDE C's silhouette - the weapon itself, seen
   seen  = vis / alone           - the fraction of the weapon a viewer can see,
           bounded 0..1 by construction
   The renderer does the depth; no occlusion maths of mine is involved, which
   is the point - at pass 11 my own geometry test answered 156 for a face that
   was not there.
   AND A SECOND FLOOR, WHICH THE PICTURE DEMANDED AFTER THE FIRST RUN OF THIS
   INSTRUMENT: seen is a RATIO and a ratio cannot see SIZE. The sheet showed
   the staff and the dagger as a smudge at the hip while seen read 0.70-0.80 -
   both true, because a weapon photographed end-on has a small silhouette and
   80% of a small thing is a small thing. So a view must ALSO put VIS_MIN real
   pixels on screen. That is the same mistake as pass 11 wearing a new coat,
   caught the same way: by looking at the picture the number described.
   A VIEW WITH seen < SEEN_MIN OR vis < VIS_MIN PROVES NOTHING AND IS NOT EVIDENCE. A cell needs
   at least MIN_PROVING of them or the cell FAILS. alone == 0 is RED, not green:
   that is the empty case, and an empty denominator is how this lane has been
   fooled before.

--control also shoots the old az +90 camera as `side_offhand`, scored by the
same instrument, so the fix is reported as a before-and-after NUMBER instead of
a claim. It is off by default; one run with it on is the record.
"""
import os
import sys
import json
import math
import argparse

import re

import bpy
import numpy as np
from mathutils import Vector, Matrix, bvhtree

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lordgen as G          # noqa: E402
import minibossfit as MF     # noqa: E402

FAMS = ["sword", "axe", "hammer", "dagger", "staff", "crossbow", "axeDouble", "shield"]
TIERS = ["common", "uncommon", "rare"]
HAND_SCALE = 0.8             # gear.gd:205, measured at S16 for the DUN pack
FIST_R = 0.16                # the mitt: 0.15 across plus a margin. Inside = by design.
CELL_X, CELL_Y = 760, 760   # square: pass 2 cropped three swords and two daggers
                            # off a 520-wide cell once the carry went horizontal
FRAME_H = 3.80               # metres of world height in the cell, fixed for all 24.
                             # 3.30 still cropped sword_rare (1.50 m of blade held out); this does not.
GROUND_UP = 0.35           # the frame's bottom edge sits at -GROUND_UP. 0.18 cropped all
                           # eight staff cells once the staff was carried at the engine's
                           # real x1.9: its butt reaches z -0.216, BELOW THE FLOOR. The old
                           # value hid the one thing those cells most needed to show, so the
                           # bottom is dropped to -0.35 to keep the fault IN the picture
                           # rather than clipped out of it.
# az -90 is the CARRY side (handslot.r is at world x -0.49). See fault 4 above.
VIEWS = [("front", 0.0), ("side", -90.0), ("back", 180.0)]
CONTROL_VIEW = ("side_offhand", 90.0)
ELEV = 6.0
SEEN_MIN = 0.15              # below this the view shows a sliver and proves nothing
VIS_MIN = 900                # ...AND A RATIO IS BLIND TO SIZE. Found by looking: the
                             # picture showed staff and dagger as smudges at the hip
                             # while `seen` read 0.70-0.80, because 80% of a weapon
                             # photographed end-on is still 20 pixels across.
                             # dagger_common's side view is 389 visible pixels on a
                             # 760x760 cell - 0.07% of it. 900 px is about 30x30 and is
                             # the floor at which a shape, not a smudge, is on screen.
                             # A view must clear BOTH or it is not evidence.
MIN_PROVING = 2              # a cell needs two views that actually show the weapon
DIFF_EPS = 0.02

# =============================================================================
# *** FAULT 6, FOUND 21 NOV 16:4x CT. `vis` AND `seen` CANNOT SEE READABILITY,
# *** AND THE SWEEP THAT PROVED IT MOVED NEITHER NUMBER.
# =============================================================================
# The register went GREEN on all 24 cells at 14:55 and the team lead, looking
# at crossbow_common_side.png, still saw "a flat plank forward of the hand and
# nothing a viewer would call a crossbow". Both were right.
#
# THE PROOF IS A SWEEP, NOT AN OPINION (tools/art/_s2_roll.py, seven angles of
# roll about the slot's own forward axis, everything else frozen, one camera
# per view shared by every angle):
#
#       roll   front vis   front seen   front minor   side minor
#         0      2610        0.935          35            41     <- ships
#        35      2629        0.937          87            99
#        90      2692        0.859          55           126
#
# `vis` moves 3% across a sweep that takes the picture from an unreadable tray
# to a crossbow anyone can name, and `seen` moves the WRONG WAY. Raising
# VIS_MIN could never have caught this; it would only have failed the dagger.
#
# WHAT DOES SEPARATE THEM IS WHETHER THE CARRY EVER TURNS THE WEAPON'S BROADEST
# FACE TO A CAMERA. `show` is the best view's silhouette MINOR extent divided
# by the pixels the weapon's own MIDDLE world extent would subtend. A dagger is
# a sliver and scores 1.03 because it shows all the breadth it has; the
# crossbow is 0.69 x 0.64 m and scores 0.39 because its prod plane is level and
# all three cameras are level, so every one of them catches it edge-on.
#
# MEASURED ON ALL 24 SHIPPED CELLS, 21 Nov 16:5x CT:
#   crossbow_uncommon 0.37, crossbow_common 0.39, crossbow_rare 0.40
#   ... and then NOTHING until axeDouble_common 1.00, through to hammer 1.06.
# The distribution is bimodal with a 0.60-wide empty gap. SHOW_MIN is set in
# that gap, not tuned to make anything pass or fail.
#
# *** THE DENOMINATOR USED TO MOVE, AND IT MOVED THE WRONG WAY. FIXED 21 NOV
# *** 17:5x CT, AND THE NOTE THAT STOOD HERE BEFORE WAS WRONG.
# What stood here said the world AABB "overstates the middle extent for a
# canted weapon, so `show` is understated ... the conservative direction is
# toward RED". I MEASURED IT AND IT IS THE OPPOSITE. Rotating a weapon changes
# its world AABB, so the denominator was a property of the CARRY and not of the
# weapon, and every change that improves the numerator shrinks it at the same
# time. From tools/art/_s2_camber.py, crossbow_common, one body, one camera set:
#
#      camber  roll   best_minor   world mid_px   show(world)   show(fixed)
#         0      0        51           130.7         0.390         0.390
#         0     35        99           118.8         0.833         0.757
#        40      0        84           112.5         0.747         0.643
#        40     35        99            98.0         1.010         0.757
#
# The bottom row scores 1.01 on a weapon whose honest number is 0.757 - a 33%
# unearned pass, and it is unearned in exactly the direction a lane fixing a
# lath would push. A gate that rewards shrinking the weapon is not a gate.
# THE DENOMINATOR IS NOW TAKEN IN THE MESH'S OWN LOCAL FRAME (times the
# engine's hand_scale), which no carry rotation can touch. `show` therefore
# answers only "how much of the breadth this weapon HAS does the carry turn to
# a camera", which is the question it was built to ask.
# RESIDUAL, SAID PLAINLY AND MEASURED RATHER THAN GUESSED: a change that
# genuinely DEFORMS the mesh - bending the limbs, not rotating them - still
# shrinks the local extent, so camber can still buy some of its own pass.
# At 40 deg the local mid falls 0.6535 -> 0.5623 m, which is 14% (I wrote 4%
# here from reasoning first, then measured it). Against the 33% above that is
# an improvement and NOT a closure. A real OBB, or the max silhouette minor
# over all orientations, would close it.
SHOW_MIN = 0.70
PX_PER_M = CELL_Y / FRAME_H


# =============================================================================
# *** FAULT 5, FOUND 21 NOV 14:3x CT BY RE-RUNNING THE REGISTER AND LOOKING. ***
# THE REGISTER WAS MEASURING A CARRY THE ENGINE NO LONGER SHIPS.
# =============================================================================
# The plan said the crossbow red would "clear on its own" once the game build's
# gear.gd fix landed (ada04de8, S20, `held_rot` -> Vector3(-90, 0, 90)). I re-ran
# the register at 14:37 CT and it came back BIT-IDENTICAL: FAIL, crossbow_common
# front seen 0.395 vis 726, side 0.664 vis 2039, back 0.097 vis 175. Not one digit
# moved, because THIS FILE NEVER READ gear.gd. It carried all 24 models with the
# identity correction and a flat HAND_SCALE of 0.8, so the engine's per-family
# overrides could not reach it. The red was never stale; it was measuring a
# different carry from the one that ships.
#
# AND THE RED UNDERSTATED IT. The one view the instrument called proving - side,
# seen 0.664, vis 2039 - shows NO crossbow a viewer could name: 2039 px on a
# 760x760 cell is 0.35% of the frame, a dark smudge merged into the body's own
# shadow. I looked at crossbow_common_side.png before writing this. Same family as
# the pass-11 fault: a number that answers "how much of it is unoccluded" when the
# viewer's question is "can I see a crossbow".
#
# TWO FAMILIES ARE AFFECTED, NOT ONE. gear.gd overrides crossbow (rot, x1.0) AND
# staff (rot, x1.9). The six staff cells were reading GREEN at x0.8 and no
# rotation - a 0.9 m wand lying across the hip, not the 1.7 m staff that ships.
# A green cell measuring the wrong carry is worse than the red one, because
# nobody goes and looks at it.
#
# THE ROTATION IS DERIVED, NOT COPIED. Godot's Vector3(-90, 0, 90) is a YXZ euler
# in Godot's axes against a glTF mesh in Godot's axes; this file is Blender, where
# the importer sends glTF +Z to -Y and glTF +Y to +Z. Copying the three numbers
# across that boundary is exactly how a wrong carry reads green. So the slot frame
# and each mesh were MEASURED instead (tools/art/_s2_axisprobe.py, 14:4x CT):
#   handslot.r in Blender world: +X -> (0, 0, -1) DOWN, +Y -> (-0.15, -0.99, 0)
#   FORWARD, +Z -> (-0.99, 0.15, 0) ACROSS. Axis for axis the frame gear.gd's S19
#   comment describes, which is what lets its INTENT be honoured here.
#   crossbow_common.glb in Blender: dim (0.691, 0.638, 0.194), thin axis Z, prod
#   symmetric on X (-0.345..0.345), stock asymmetric on Y (-0.533..0.105).
# gear.gd's intent, in its own words: "mesh +Z -> slot +Y (stock forward), mesh +Y
# -> slot -X (up), mesh +X -> slot -Z (prod across)" - read through the importer's
# mapping, that is Blender mesh -Y -> slot +Y, +Z -> slot -X, +X -> slot -Z.
# Each matrix below is asserted to be a proper rotation (det +1) before it is used.
ENGINE_FAMS = ("crossbow", "staff")
SLOT_ROT = {
    # columns are where the mesh's local +X, +Y, +Z land in the slot frame
    "crossbow": ((0, 0, -1), (0, -1, 0), (-1, 0, 0)),
    "staff":    ((0, 0, 1), (0, 1, 0), (-1, 0, 0)),
}

# *** FAULT 6, 21 NOV 19:4x CT. THE TABLE ABOVE IS A PHOTOGRAPH, NOT A LINK. ***
# Each basis above was hand-derived against ONE gear.gd `held_rot` value. This
# file then went on READING `held_rot` into the register and MEASURING the table
# anyway, so when the game build rolled the crossbow 0 -> 35 deg (S95) the
# register kept scoring a carry the game no longer ships and reported FAIL on
# three laths rows that the shipped roll passes. A number beside the right
# angle is not a measurement of it.
# THE FIX IS A LINK, NOT A NEW CONSTANT: the roll is taken as the DELTA between
# what gear.gd says now and the value each basis was calibrated at, and applied
# about the slot's own forward axis (+Y) exactly as _s2_stirrup_ab.py applied
# its forecast - base @ Rroll @ Rslot @ S. Writing 35 in here would have gone
# stale the same way the next time the engine moves.
# AND IT GOES RED RATHER THAN GUESSING: only the roll component is derivable
# this way. If gear.gd ever moves the OTHER two angles, the basis itself is
# stale and this file cannot infer the new one, so it FAILS LOUDLY instead of
# measuring a configuration nobody calibrated.
SLOT_ROT_CAL = {
    "crossbow": ("-90", "0", "90"),
    "staff":    ("0", "0", "90"),
}


def gear_overrides(gear_path):
    """Read the engine's per-family hand_scale out of gear.gd. RED ON EMPTY:
    a family this file claims to mirror and cannot find in gear.gd is a FAIL,
    not a silent fall back to 0.8 - that silence is what hid this for four days."""
    with open(gear_path, encoding="utf-8", errors="replace") as fh:
        src = fh.read()
    out, missing = {}, []
    for fam in ENGINE_FAMS:
        pat = r'path\.begins_with\(DUN \+ "%s_"\)\s*:\s*\n\s*return\s+([0-9.]+)' % fam
        m = re.findall(pat, src)
        rot = re.search(r'path\.begins_with\(DUN \+ "%s_"\)\s*:\s*\n\s*return Vector3\(([^)]*)\)' % fam, src)
        if not m or not rot:
            missing.append(fam)
            continue
        out[fam] = {"scale": float(m[-1]),
                    "engine_rot_deg": [x.strip() for x in rot.group(1).split(",")]}
    if missing:
        raise SystemExit("WEAPONFIT FAIL - gear.gd carries no override this file could "
                         "parse for: %s. Refusing to measure a carry I cannot verify "
                         "against the engine." % ", ".join(missing))
    return out


def slot_matrix(fam, engine_rot=None):
    """The calibrated basis, plus whatever roll gear.gd has moved since it was
    calibrated. Returns (matrix, roll_applied_deg)."""
    cols = SLOT_ROT[fam]
    M = Matrix(((cols[0][0], cols[1][0], cols[2][0]),
                (cols[0][1], cols[1][1], cols[2][1]),
                (cols[0][2], cols[1][2], cols[2][2])))
    d = M.determinant()
    assert abs(d - 1.0) < 1e-6, "%s slot rotation is not a proper rotation (det %.4f)" % (fam, d)
    M = M.to_4x4()
    roll = 0.0
    if engine_rot is not None:
        cal = SLOT_ROT_CAL.get(fam)
        if cal is None:
            raise SystemExit("WEAPONFIT FAIL - %s has an engine carry but no "
                             "calibration record, so the roll gear.gd ships "
                             "cannot be told apart from the basis. Refusing to "
                             "measure it." % fam)
        try:
            now = [float(x) for x in engine_rot]
            was = [float(x) for x in cal]
        except ValueError:
            raise SystemExit("WEAPONFIT FAIL - %s held_rot is not numeric: %r"
                             % (fam, engine_rot))
        # only the middle component (roll about the slot's forward axis) is
        # derivable from the calibrated basis. RED, not a guess, on the others.
        for idx, name in ((0, "x"), (2, "z")):
            if abs(now[idx] - was[idx]) > 1e-6:
                raise SystemExit(
                    "WEAPONFIT FAIL - gear.gd now carries %s at held_rot %s but "
                    "this file's slot basis was calibrated at %s. The %s angle "
                    "moved, and only the roll can be derived from the basis, so "
                    "the basis itself is now stale. Re-derive SLOT_ROT[%r] "
                    "against the engine before measuring - this file will not "
                    "score a carry nobody calibrated."
                    % (fam, list(engine_rot), list(cal), name, fam))
        roll = now[1] - was[1]
        if abs(roll) > 1e-6:
            M = Matrix.Rotation(math.radians(roll), 4, 'Y') @ M
    return M, roll


def world_verts(objs):
    dg = bpy.context.evaluated_depsgraph_get()
    out = []
    for ob in objs:
        ev = ob.evaluated_get(dg)
        me = ev.to_mesh()
        m = ob.matrix_world
        out.extend([m @ v.co.copy() for v in me.vertices])
        ev.to_mesh_clear()
    return out


def inside(trees, p):
    """Six rays. All six hit something -> the point is inside a closed body."""
    dirs = [Vector(d) for d in ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1))]
    for t in trees:
        if all(t.ray_cast(p, d, 3.0)[0] is not None for d in dirs):
            return True
    return False


def load_model(repo, fam, tier):
    p = os.path.join(repo, "assets", "gear", "dungeon", "%s_%s.glb" % (fam, tier))
    if not os.path.isfile(p):
        return [], p
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=p)
    new = [o for o in bpy.data.objects if o not in before]
    bpy.context.view_layer.update()
    return new, p


def make_cam(az, cz, pts):
    """One camera, built from the FULL point set so that A, B and C share it.

    If the camera moved between the body-only and the body+weapon render, the
    pixel diff would be measuring the camera and not the weapon.
    """
    scene = bpy.context.scene
    cam_d = bpy.data.cameras.new("cam")
    cam_d.type = 'ORTHO'
    cam = bpy.data.objects.new("cam", cam_d)
    bpy.context.collection.objects.link(cam)
    scene.camera = cam
    a, e = math.radians(az), math.radians(ELEV)
    dirv = Vector((math.sin(a) * math.cos(e), -math.cos(a) * math.cos(e), math.sin(e))).normalized()
    centre = Vector((0.0, 0.0, cz))
    cam.location = centre + dirv * 9.0
    cam.rotation_euler = dirv.to_track_quat('Z', 'Y').to_euler()
    bpy.context.view_layer.update()
    fwd = (cam.matrix_world.to_3x3() @ Vector((0, 0, -1))).normalized()
    depth = [(p - cam.location).dot(fwd) for p in pts] or [8.0]
    cam_d.ortho_scale = FRAME_H
    cam_d.clip_start = max(0.01, min(depth) - 1.0)
    cam_d.clip_end = max(depth) + 4.0
    return cam


def frame_outside(cam, pts):
    mwi = cam.matrix_world.inverted()
    half_v = FRAME_H / 2.0
    half_h = FRAME_H * (CELL_X / float(CELL_Y)) / 2.0
    return sum(1 for p in pts if abs((mwi @ p).y) > half_v or abs((mwi @ p).x) > half_h)


def render_to(path):
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    return read_png(path)


def read_png(path):
    im = bpy.data.images.load(path, check_existing=False)
    w, h = im.size
    a = np.array(im.pixels[:], dtype=np.float32).reshape(h, w, 4)
    bpy.data.images.remove(im)
    return a


def show(objs, on):
    for o in objs:
        o.hide_render = not on


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--gear", default="",
                    help="scripts/gear.gd of the main repo. Default: the sibling "
                         "checkout. The engine's per-family carry is READ from it, "
                         "never copied into this file by hand.")
    ap.add_argument("--fams", default=",".join(FAMS))
    ap.add_argument("--control", action="store_true",
                    help="also shoot the old offhand-side camera, scored the same way")
    a = ap.parse_args(argv)
    fams = [f for f in a.fams.split(",") if f]
    views = list(VIEWS) + ([CONTROL_VIEW] if a.control else [])
    outdir = os.path.join(a.repo, "renders", "art", "system2")
    tmpdir = os.path.join(outdir, "_vis_tmp")
    os.makedirs(outdir, exist_ok=True)
    os.makedirs(tmpdir, exist_ok=True)

    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)

    roots, body, hinfo = MF.import_hero(a.repo)
    rig = next((o for o in roots if o.type == 'ARMATURE'), None)
    assert rig is not None, "no armature in the hero glb"
    assert hinfo["posed"], "hero is in REST pose - the idle action did not take"
    bpy.context.view_layer.update()
    gear_path = a.gear or os.path.join(os.path.dirname(os.path.abspath(a.repo)),
                                       "jests-hd-medieval-adventure", "scripts", "gear.gd")
    if not os.path.exists(gear_path):
        raise SystemExit("WEAPONFIT FAIL - cannot read the engine carry at %s. This "
                         "register mirrors gear.gd; without it every cell would be "
                         "measuring an assumption." % gear_path)
    OVR = gear_overrides(gear_path)
    print("WEAPONFIT engine carry read from %s: %s" % (gear_path, json.dumps(OVR)))
    pb = rig.pose.bones["handslot.r"]
    base = rig.matrix_world @ pb.matrix
    slot = base @ Vector((0, 0, 0))

    scene = bpy.context.scene
    G.set_engine(scene)
    scene.render.resolution_x, scene.render.resolution_y = CELL_X, CELL_Y
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    if scene.world is None:
        scene.world = bpy.data.worlds.new("w")
    scene.world.use_nodes = True
    for nm, rot, en in (("key", (-0.95, 0.0, 0.7), 3.2), ("fill", (-1.2, 0.0, -2.1), 1.3)):
        if nm not in bpy.data.objects:
            ld = bpy.data.lights.new(nm, 'SUN')
            ld.energy = en
            lo = bpy.data.objects.new(nm, ld)
            lo.rotation_euler = rot
            bpy.context.collection.objects.link(lo)

    body_trees = []
    dg = bpy.context.evaluated_depsgraph_get()
    for ob in body:
        try:
            body_trees.append(bvhtree.BVHTree.FromObject(ob, dg))
        except Exception:
            pass
    assert body_trees, "no BVH built from the body - the clip test would read 0 over nothing"

    bmn, bmx, bpts = G.world_bounds(body)
    cz = (FRAME_H / 2.0) - GROUND_UP

    reg, errors, blanks, clipped_frames, blind, laths = {}, [], [], [], [], []
    # *** FAULT 7, FOUND IN THIS SAME RUN, 21 NOV CT, AND IT IS THIS FILE'S OWN. ***
    # `ground` - "vertices below z=0 (the weapon dragging through the floor)" in
    # this file's own docstring - has been measured and PRINTED on every cell
    # since pass 1 and gated on NOTHING. `ok` conjoined errors, blanks,
    # frame_clips, blind_views and laths, so a weapon could hang through the
    # floor on every tier and the register would still say GREEN. It did: the
    # staff breaks the floor on all three tiers and this register called the
    # sheet green while printing the number that says otherwise. That is the
    # unearned-pass family this lane has now hit three times - a metric beside
    # the verdict is not in the verdict.
    floor_breaks = []
    body_only = {}

    for fam in fams:
        for tier in TIERS:
            key = "%s_%s" % (fam, tier)
            objs, path = load_model(a.repo, fam, tier)
            meshes = [o for o in objs if o.type == 'MESH']
            if not meshes:
                errors.append("%s: no mesh imported from %s" % (key, path))
                for o in objs:
                    bpy.data.objects.remove(o, do_unlink=True)
                continue
            hs = OVR[fam]["scale"] if fam in OVR else HAND_SCALE
            S = Matrix.Diagonal((hs,) * 3).to_4x4()
            # The `show` denominator, taken BEFORE the carry is applied so no
            # rotation can shrink it. See the note above SHOW_MIN.
            lv = world_verts(meshes)
            local_ext = (sorted([max(v[i] for v in lv) - min(v[i] for v in lv)
                                 for i in range(3)]) if lv else None)
            if fam in SLOT_ROT:
                Rslot, roll_applied = slot_matrix(
                    fam, OVR[fam]["engine_rot_deg"] if fam in OVR else None)
            else:
                Rslot, roll_applied = Matrix.Identity(4), 0.0
            for o in objs:
                if o.parent is None:
                    o.matrix_world = base @ Rslot @ S @ o.matrix_world
            bpy.context.view_layer.update()
            wv = world_verts(meshes)
            if not wv:
                errors.append("%s: zero vertices - the clip test would be empty" % key)
                for o in objs:
                    bpy.data.objects.remove(o, do_unlink=True)
                continue
            zs = [v.z for v in wv]
            far = [v for v in wv if (v - slot).length > FIST_R]
            if not far:
                errors.append("%s: every vertex is inside the fist sphere - clip test empty" % key)
            n_clip = sum(1 for v in far if inside(body_trees, v))
            n_ground = sum(1 for v in wv if v.z < -0.002)
            floor_depth = round(max(0.0, -min(zs)), 4)
            rec = dict(model=os.path.relpath(path, a.repo).replace("\\", "/"),
                       verts=len(wv), checked=len(far),
                       reach=round(max(zs) - slot.z, 3), drop=round(slot.z - min(zs), 3),
                       span=round(max(v.x for v in wv) - min(v.x for v in wv), 3),
                       tip_z=round(max(zs), 3), hero_h=round(hinfo["h"], 3),
                       clip=n_clip, ground=n_ground, floor_depth=floor_depth,
                       hand_scale=hs,
                       engine_mirrored=(fam in OVR),
                       engine_rot_deg=(OVR[fam]["engine_rot_deg"] if fam in OVR else None),
                       roll_applied_deg=round(roll_applied, 3))
            if n_ground:
                floor_breaks.append(
                    "%s: %d vertices below the floor, deepest %.3f m under it - "
                    "the carry drags this weapon through the ground"
                    % (key, n_ground, floor_depth))
            allpts = bpts + wv
            outs, proving = {}, 0
            for vname, az in views:
                cam = make_cam(az, cz, allpts)
                outs[vname] = frame_outside(cam, allpts)

                # A - the body alone, through this exact camera. Identical for
                # every cell in a view, so it is rendered once and cached.
                if vname not in body_only:
                    show(meshes, False)
                    body_only[vname] = render_to(os.path.join(tmpdir, "_body_%s.png" % vname))
                    show(meshes, True)
                A = body_only[vname]

                # B - the cell itself: body + weapon.
                png = os.path.join(outdir, "%s_%s.png" % (key, vname))
                B = render_to(png)

                # C - the weapon alone: what it COULD contribute if unoccluded.
                show(body, False)
                C = render_to(os.path.join(tmpdir, "_w_%s_%s.png" % (key, vname)))
                show(body, True)

                cm = C[:, :, 3] > DIFF_EPS
                if int(cm.sum()) >= 2:
                    cys, cxs = np.nonzero(cm)
                    rec.setdefault("minor", {})[vname] = int(min(cxs.max() - cxs.min() + 1,
                                                                 cys.max() - cys.min() + 1))
                op = int((B[:, :, 3] > DIFF_EPS).sum())
                if op == 0:
                    blanks.append(os.path.basename(png))
                b = max(float(B[0, :, 3].max()), float(B[-1, :, 3].max()),
                        float(B[:, 0, 3].max()), float(B[:, -1, 3].max()))
                if b > DIFF_EPS:
                    clipped_frames.append(os.path.basename(png))

                changed = np.abs(B - A).max(axis=2) > DIFF_EPS
                mask = C[:, :, 3] > DIFF_EPS
                delta = int(changed.sum())
                alone = int(mask.sum())
                # BOUNDED TO THE WEAPON'S OWN SILHOUETTE ON PURPOSE. The raw
                # diff `delta` also catches pixels the weapon changed ON THE
                # BODY - its cast shadow - and the first run of this instrument
                # returned seen 1.20-1.26 for the three crossbows because of it.
                # A fraction that can exceed 1.0 is a fraction of nothing I can
                # name, so `seen` counts only pixels the weapon itself covers
                # AND changed. `delta` is kept beside it rather than dropped:
                # the gap between them is the shadow, and it is worth seeing.
                covered = int((changed & mask).sum())
                if alone == 0:
                    errors.append("%s/%s: the weapon renders EMPTY alone - the seen "
                                  "fraction would be computed over nothing" % (key, vname))
                    seen = 0.0
                else:
                    seen = covered / float(alone)
                if seen >= SEEN_MIN and covered >= VIS_MIN:
                    proving += 1
                rec.setdefault("opaque", {})[vname] = op
                rec.setdefault("border", {})[vname] = round(b, 4)
                rec.setdefault("vis", {})[vname] = covered
                rec.setdefault("delta", {})[vname] = delta
                rec.setdefault("alone", {})[vname] = alone
                rec.setdefault("seen", {})[vname] = round(seen, 4)
                bpy.data.objects.remove(cam, do_unlink=True)
            rec["outside"] = outs
            ext = sorted([max(v[i] for v in wv) - min(v[i] for v in wv) for i in range(3)])
            mid_px = (local_ext[1] * hs * PX_PER_M) if local_ext else 0.0
            rec["ext"] = [round(e, 4) for e in ext]
            rec["local_ext"] = [round(e, 4) for e in local_ext] if local_ext else None
            rec["mid_px"] = round(mid_px, 1)
            rec["mid_px_world_was"] = round(ext[1] * PX_PER_M, 1)
            mins = rec.get("minor", {})
            if mid_px <= 1.0 or not mins:
                # RED ON EMPTY. A `show` over a zero-width mesh, or over no
                # measured view at all, is a ratio of nothing and must not read
                # as a pass just because it computed.
                errors.append("%s: cannot compute `show` - mid_px %.2f over %d measured "
                              "views. This is a FAIL, not a 1.0." % (key, mid_px, len(mins)))
            else:
                rec["best_minor"] = max(mins.values())
                rec["show"] = round(rec["best_minor"] / mid_px, 3)
                if rec["show"] < SHOW_MIN:
                    laths.append("%s: show %.2f (best view turns %d px of a possible %.0f to "
                                 "the camera) - the carry never shows this weapon's broad face"
                                 % (key, rec["show"], rec["best_minor"], mid_px))
            # the control camera is a measurement OF THE OLD VIEW, not evidence
            # for the cell - it must not be able to rescue a cell by existing.
            if (a.control and rec["seen"].get(CONTROL_VIEW[0], 0.0) >= SEEN_MIN
                    and rec["vis"].get(CONTROL_VIEW[0], 0) >= VIS_MIN):
                proving -= 1
            rec["proving_views"] = proving
            if proving < MIN_PROVING:
                blind.append("%s: only %d of %d views show the weapon "
                             "(seen>=%.2f AND vis>=%d px) - %s"
                             % (key, proving, len(VIEWS), SEEN_MIN, VIS_MIN,
                                ", ".join("%s seen %.3f vis %d" % (v, rec["seen"][v], rec["vis"][v])
                                          for v, _ in VIEWS)))
            reg[key] = rec
            for o in objs:
                bpy.data.objects.remove(o, do_unlink=True)

    want = len(fams) * len(TIERS)
    if len(reg) != want:
        errors.append("register has %d of %d cells" % (len(reg), want))
    if not reg:
        errors.append("EMPTY REGISTER - nothing was measured, this is a FAIL not a pass")
    ok = ((not errors) and (not blanks) and (not clipped_frames)
          and (not blind) and (not laths) and (not floor_breaks))
    out = dict(verdict="GREEN" if ok else "FAIL", ok=ok, hero=hinfo,
               handslot=[round(v, 4) for v in slot], cells=len(reg),
               views=[v for v, _ in views], seen_min=SEEN_MIN, vis_min=VIS_MIN,
               min_proving=MIN_PROVING, show_min=SHOW_MIN, px_per_m=PX_PER_M,
               roll_applied_deg={k: v["roll_applied_deg"] for k, v in reg.items()
                                 if v.get("roll_applied_deg")},
               slot_rot_cal=SLOT_ROT_CAL,
               laths=laths, floor_breaks=floor_breaks,
               blanks=blanks, frame_clips=clipped_frames, blind_views=blind,
               errors=errors, models=reg)
    rp = os.path.join(outdir, "_fit_register.json")
    with open(rp, "w") as f:
        json.dump(out, f, indent=1)
    print("WEAPONFIT verdict=%s cells=%d blanks=%d frameclips=%d blind=%d laths=%d "
          "floor=%d errors=%d"
          % (out["verdict"], len(reg), len(blanks), len(clipped_frames), len(blind),
             len(laths), len(floor_breaks), len(errors)))
    for e in errors:
        print("  ERROR", e)
    for e in blind:
        print("  BLIND", e)
    for e in laths:
        print("  LATH", e)
    for e in floor_breaks:
        print("  FLOOR", e)
    print("WEAPONFIT_DONE", rp)


if __name__ == "__main__":
    main()
