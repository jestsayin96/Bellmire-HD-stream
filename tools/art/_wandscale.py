"""_wandscale - THE CONTROL THE CLIP GATE HAS NEVER HAD, AND THE SCALES THE
ROLL SWEEP NEVER TRIED.

  blender -b -noaudio -P tools/art/_wandscale.py -- --repo <repo>

WHY THIS FILE EXISTS. `_wandroll.py` swept the derivable roll family and the
result is a TRAP, not a choice: clip and reach trade off monotonically. The
ONLY clip-0 row is (0, 90, 90), and there reach collapses to 0.046 - which is
the horizontal baton the sweep was written to escape, merely rolled the other
way. Every carry that stands the wand UP (reach > 0.4) buries 400-1400
vertices in the body.

TWO THINGS WERE NEVER MEASURED, AND BOTH ARE MINE:

(1) THE CLIP GATE HAS NO CONTROL. `clip == 0` is asserted as the pass mark and
    has never once been checked against a weapon THIS GAME ALREADY SHIPS at
    its own shipped carry. A held shaft grazing the forearm may well be normal
    and every upright weapon in the game may do it. If the shipped staff
    clips 500 verts, then "clip 0" is not a standard, it is a number I made
    up, and I have been rejecting good carries with it. SO THE STAFF IS
    MEASURED FIRST, at the carry gear.gd really gives it, read through
    gearcarry and not assumed, and the wand is judged against THAT.

(2) THE SWEEP ONLY TRIED hand_scale 0.62 AND 1.0. The wand is 0.921 long.
    At 0.62 it is 0.571 m in the fist - that is a SHORT STAFF, which is the
    open question ASSET_SOURCES has carried since 16 Nov. Nobody has tried
    the scales that would make it a WAND. A shorter shaft has less length to
    bury, so scale and clip are not independent and the roll sweep could not
    have seen it.

RED ON EMPTY, same as every instrument this lane ships: a clip count taken
over zero checked vertices is a FAIL, never a silent green.
"""
import os
import sys
import json
import argparse

import bpy
import numpy as np
from mathutils import Vector, Matrix, bvhtree

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import minibossfit as MF     # noqa: E402
import weaponfit as WF       # noqa: E402
import gearcarry as GC       # noqa: E402

WAND = os.path.join("assets", "gear", "wand_crystal.glb")
# the controls: weapons the game SHIPS, measured at the carry gear.gd really
# gives them. Read through gearcarry - never typed in here.
CONTROLS = [
    ("staff_B",      os.path.join("assets", "gear", "staff_B.gltf"),
     "res://assets/gear/staff_B.gltf"),
    ("staff_rare",   os.path.join("assets", "gear", "dungeon", "staff_rare.glb"),
     "res://assets/gear/dungeon/staff_rare.glb"),
]
SCALES = [0.35, 0.45, 0.55, 0.62]
ROLLS = [0, 15, 30, 45]


def import_mesh(path):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    new = [o for o in bpy.data.objects if o not in before]
    mesh = [o for o in new if o.type == 'MESH']
    root = [o for o in new if o.parent is None]
    assert mesh, "no mesh imported from %s" % path
    bpy.context.view_layer.update()
    return mesh, root, new


def measure(mesh, slot, trees):
    wv = WF.world_verts(mesh)
    assert wv, "zero vertices in world space"
    far = [p for p in wv if (p - slot).length > WF.FIST_R]
    if not far:
        return None, wv
    zs = [p.z for p in wv]
    return dict(checked=len(far),
                clip=sum(1 for p in far if WF.inside(trees, p)),
                clip_pct=round(100.0 * sum(1 for p in far
                                           if WF.inside(trees, p)) / len(far), 1),
                ground=sum(1 for p in wv if p.z < -0.002),
                tip_z=round(max(zs), 3),
                reach=round(max(zs) - slot.z, 3),
                span_z=round(max(zs) - min(zs), 3),
                verts=len(wv)), wv


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    a = ap.parse_args(argv)
    gear_path = os.path.join(a.repo, "scripts", "gear.gd")

    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    roots, body, hinfo = MF.import_hero(a.repo)
    rig = next((o for o in roots if o.type == 'ARMATURE'), None)
    assert rig is not None and hinfo["posed"], "hero missing or in rest pose"
    bpy.context.view_layer.update()
    pb = rig.pose.bones["handslot.r"]
    base = rig.matrix_world @ pb.matrix
    slot = base @ Vector((0, 0, 0))

    dg = bpy.context.evaluated_depsgraph_get()
    trees = []
    for ob in body:
        try:
            trees.append(bvhtree.BVHTree.FromObject(ob, dg))
        except Exception:
            pass
    assert trees, "no BVH from the body - every clip count would be over nothing"

    out = dict(hero_h=round(hinfo["h"], 3),
               handslot=[round(v, 4) for v in slot],
               note="controls are SHIPPED weapons at the carry gearcarry reads "
                    "out of gear.gd; the wand grid is judged against them, not "
                    "against clip==0.")

    # ---- (1) THE CONTROLS ----------------------------------------------
    ctl = []
    for name, rel, res in CONTROLS:
        p = os.path.join(a.repo, rel)
        if not os.path.exists(p):
            ctl.append(dict(name=name, ERROR="missing on disk: %s" % rel))
            continue
        cc = GC.carry(gear_path, res)
        hr = cc["held_rot_deg"]
        hs = cc["hand_scale"]
        mesh, root, new = import_mesh(p)
        # the same calibrated derivation the roll sweep is held to
        if hr == [0.0, 0.0, 0.0]:
            R = Matrix.Identity(4)
            roll = 0.0
        else:
            R, roll = WF.slot_matrix("staff", (str(hr[0]), str(hr[1]), str(hr[2])))
        S = Matrix.Diagonal((hs,) * 3).to_4x4()
        for o in root:
            o.matrix_world = base @ R @ S
        bpy.context.view_layer.update()
        m, _ = measure(mesh, slot, trees)
        row = dict(name=name, res_path=res, held_rot=hr, hand_scale=hs,
                   held_rot_arm=cc["held_rot_arm"],
                   hand_scale_arm=cc["hand_scale_arm"],
                   roll_applied=round(roll, 2))
        row.update(m if m else {"ERROR": "all verts inside fist"})
        ctl.append(row)
        for o in new:
            bpy.data.objects.remove(o, do_unlink=True)
    out["controls"] = ctl

    # ---- (2) THE WAND GRID ---------------------------------------------
    mesh, root, new = import_mesh(os.path.join(a.repo, WAND))
    rows = []
    for hs in SCALES:
        S = Matrix.Diagonal((hs,) * 3).to_4x4()
        for y in ROLLS:
            R, roll = WF.slot_matrix("staff", ("0", str(y), "90"))
            for o in root:
                o.matrix_world = base @ R @ S
            bpy.context.view_layer.update()
            m, _ = measure(mesh, slot, trees)
            r = dict(held_rot=[0, y, 90], hand_scale=hs,
                     roll_applied=round(roll, 2),
                     length_in_hand=round(0.921 * hs, 3))
            r.update(m if m else {"ERROR": "all verts inside fist - "
                                           "clip would be over nothing"})
            rows.append(r)
    out["wand_grid"] = rows

    d = os.path.join(a.repo, "renders", "art", "wand")
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, "_scale_sweep.json"), "w") as f:
        json.dump(out, f, indent=1)
    print("WANDSCALE " + json.dumps(out))


if __name__ == "__main__":
    main()
