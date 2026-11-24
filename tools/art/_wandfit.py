"""_wandfit - THE FIT PROOF MR. E'S OWN WAND HAS NEVER HAD.

  blender -b -noaudio -P tools/art/_wandfit.py -- --repo <repo>

WHY THIS FILE EXISTS. `assets/gear/wand_crystal.glb` is Mr. E's own asset. He
dropped it on 16 Nov 05:03 CT and the art lane made it game-weight the same
hour (306,024 tris / 24 MB -> 8,000 tris / 2.38 MB, origin moved to the base
of the grip). It has sat in the repo for EIGHT DAYS and, measured rather than
remembered, there is no render of it on a body anywhere under renders/. The
fit rule is binding and it is this lane's own: a piece that has never been
rendered on a body is NOT DONE. So this is the missing proof and nothing else.

WHY NOT weaponfit.py. That gate resolves models as
`assets/gear/dungeon/<fam>_<tier>.glb` and reads its per-family carry out of
gear.gd. The wand is at neither path and has NO gear.gd entry at all, so
weaponfit cannot see it, and widening a working gate to take one arbitrary
file is how a gate stops meaning what its name says. This file BORROWS
weaponfit's machinery by import - the hero, the calibrated handslot basis, the
BVH clip test, the camera, the blank and frame checks - and changes none of it.

*** THE ONE THING THIS FILE ASSUMES, SAID OUT LOUD BECAUSE IT IS THE WHOLE
*** CAVEAT: THE CARRY. gear.gd has no entry for the wand, so there is no
*** engine carry to read and no calibration record to check a roll against.
*** This file therefore measures it on the STAFF basis - the wand is 0.921
*** long with its origin at the base of the grip and its shaft on local +Z,
*** which is the staff's own geometry - and says so in the register under
*** `carry_assumed`. If the game build wires a different held_rot, every
*** number here is about a carry the game does not ship. That is exactly the
*** fault weaponfit's FAULT 6 describes, and naming it is the only honest
*** thing to do about it until gear.gd has a row.

AND IT GOES RED ON EMPTY, same rule as every instrument this lane ships: a
clip or ground count taken over zero vertices is a FAIL, not a silent green.
"""
import os
import sys
import json
import argparse

import bpy
import numpy as np
from mathutils import Vector, Matrix, bvhtree

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lordgen as G          # noqa: E402
import minibossfit as MF     # noqa: E402
import weaponfit as WF       # noqa: E402

MODEL = os.path.join("assets", "gear", "wand_crystal.glb")
BASIS = "staff"


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    a = ap.parse_args(argv)

    outdir = os.path.join(a.repo, "renders", "art", "wand")
    os.makedirs(outdir, exist_ok=True)
    path = os.path.join(a.repo, MODEL)
    if not os.path.isfile(path):
        raise SystemExit("WANDFIT FAIL - no model at %s" % path)

    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)

    roots, body, hinfo = MF.import_hero(a.repo)
    rig = next((o for o in roots if o.type == 'ARMATURE'), None)
    assert rig is not None, "no armature in the hero glb"
    assert hinfo["posed"], "hero is in REST pose - the idle action did not take"
    bpy.context.view_layer.update()

    scene = bpy.context.scene
    G.set_engine(scene)
    scene.render.resolution_x, scene.render.resolution_y = WF.CELL_X, WF.CELL_Y
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

    pb = rig.pose.bones["handslot.r"]
    base = rig.matrix_world @ pb.matrix
    slot = base @ Vector((0, 0, 0))

    dg = bpy.context.evaluated_depsgraph_get()
    body_trees = []
    for ob in body:
        try:
            body_trees.append(bvhtree.BVHTree.FromObject(ob, dg))
        except Exception:
            pass
    assert body_trees, "no BVH built from the body - the clip test would read 0 over nothing"

    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    wand = [o for o in bpy.data.objects if o not in before and o.type == 'MESH']
    assert wand, "WANDFIT FAIL - the wand glb imported no mesh; every metric below would be over nothing"
    bpy.context.view_layer.update()

    M, roll = WF.slot_matrix(BASIS)
    root = [o for o in bpy.data.objects if o not in before and o.parent is None]
    # *** THE CARRY IS SET, NOT COMPOSED, AND THIS IS THE WHOLE STORY OF PASS 1.
    # `wand_crystal.glb` CARRIES A TRANSLATION OF +30.5 ON X IN ITS OWN NODE
    # TRANSFORM. Measured, not guessed: the imported object's matrix_world is
    # identity with a 30.5 in the X column, and its mesh bounds are
    # x 30.426..30.574. The mesh-local origin IS at the base of the grip, as
    # ASSET_SOURCES.md says - but the NODE above it is thirty metres out.
    # Pass 1 of this file did `base @ M @ o.matrix_world`, carried that 30.5
    # along, and put the wand THIRTY METRES from the hand. Every Z-based
    # number still read perfectly - reach 0.9182, drop 0.0028, clip 0,
    # ground 0 - because reach and drop constrain Z ONLY and the wand was
    # displaced in X. A register full of correct numbers about an object that
    # was not in the picture.
    for o in root:
        o.matrix_world = base @ M
    bpy.context.view_layer.update()

    wv = WF.world_verts(wand)
    assert wv, "WANDFIT FAIL - zero wand vertices in world space"
    bmn, bmx, bpts = G.world_bounds(body)
    allpts = bpts + wv

    # the fist sphere is excluded exactly as weaponfit does: the grip is inside
    # the hand BY DESIGN and is not a clip.
    FIST = 0.16
    clip = sum(1 for p in wv if (p - slot).length > FIST and WF.inside(body_trees, p))
    ground = sum(1 for p in wv if p.z < 0.0)
    reach = max(p.z for p in wv) - slot.z
    drop = slot.z - min(p.z for p in wv)

    cz = (WF.FRAME_H / 2.0) - WF.GROUND_UP
    rows, blanks, framed, blind = {}, [], [], []
    for name, az in WF.VIEWS:
        cam = WF.make_cam(az, cz, allpts)
        out = os.path.join(outdir, "%s.png" % name)
        WF.show(wand, False)
        without = WF.render_to(os.path.join(outdir, "_no_%s.png" % name))
        WF.show(wand, True)
        with_ = WF.render_to(out)
        # THE VIEWER'S QUESTION, not the object's: how many pixels MOVED when
        # the wand was added, through ONE camera, letting the renderer do the
        # depth. A mask of the wand alone would answer how BIG it is and say
        # nothing about whether it can be SEEN. (Pass 11, 17 Nov.)
        moved = int(np.count_nonzero(np.abs(with_ - without).max(axis=2) > 0.01))
        opaque = int(np.count_nonzero(with_[:, :, 3] > 0.5))
        if opaque == 0:
            blanks.append(name)
        # *** AND THE MOVED-PIXEL TEST ON ITS OWN IS NOT ENOUGH EITHER, WHICH
        # *** PASS 1 PROVED AGAINST ME. With the wand thirty metres away this
        # *** test reported moved = 427 / 869 / 539 and `blind_views: []`, and
        # *** the render has NO WAND IN IT. The moving pixels were the SHADOW
        # *** an off-camera object still casts onto the body. So the diff
        # *** answers "did anything change", not "can the viewer see the
        # *** thing" - the same family as the pass-11 mask fault, one level up.
        # *** The guard is cheap and it is a different question: an object with
        # *** NO vertex inside the frame is blind by construction, whatever the
        # *** pixels did. Both terms, and the out-of-frame count is taken over
        # *** the WAND, never over body-plus-wand, or the body's own points
        # *** would dilute it.
        fo_wand = WF.frame_outside(cam, wv)
        fo_all = WF.frame_outside(cam, allpts)
        if moved == 0 or fo_wand >= len(wv):
            blind.append(name)
        if fo_all:
            framed.append([name, int(fo_all)])
        rows[name] = dict(moved=moved, opaque=opaque,
                          wand_verts_outside_frame=int(fo_wand),
                          frame_outside=int(fo_all))
        bpy.data.objects.remove(cam, do_unlink=True)

    # *** AND `clip` IS GATED, WHICH IS THE THIRD THING PASS 1 OF THIS FILE GOT
    # *** WRONG IN ONE SITTING. I copied weaponfit's measures and I copied its
    # *** FAULT 7 with them: `clip` was computed, printed, and conjoined into
    # *** NOTHING, so the register said GREEN over 938 wand vertices buried
    # *** inside the body. A number that gates on nothing is decoration. It is
    # *** a fault here exactly as it was there, and it is counted now.
    ok = ((not blanks) and (not blind) and (not framed)
          and ground == 0 and clip == 0 and len(wv) > 0)
    rep = dict(verdict="GREEN" if ok else "RED", ok=ok, model=MODEL,
               carry_assumed=BASIS,
               carry_note="gear.gd has NO entry for this model - the carry is "
                          "borrowed from the staff basis and is NOT a read of "
                          "the engine. If the game build wires a different "
                          "held_rot these numbers describe a carry the game "
                          "does not ship.",
               verts=len(wv), reach=round(reach, 4), drop=round(drop, 4),
               clip=int(clip), ground=int(ground),
               handslot=[round(v, 4) for v in slot], views=rows,
               blanks=blanks, blind_views=blind, frame_clipped=framed,
               hero=hinfo)
    with open(os.path.join(outdir, "_report.json"), "w") as f:
        json.dump(rep, f, indent=1)
    print("WANDFIT_REPORT " + json.dumps(rep))


if __name__ == "__main__":
    main()
