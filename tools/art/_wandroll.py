"""_wandroll - WHAT CARRY WOULD ACTUALLY WORK, MEASURED, SO THE GAME BUILD GETS
A NUMBER AND A PICTURE INSTEAD OF "IT LOOKS WRONG".

  blender -b -noaudio -P tools/art/_wandroll.py -- --repo <repo>

WHY. `_wandfit.py --basis engine` comes back GREEN on the carry gear.gd's own
default arms give this path - clip 0 of 5,959 checked, ground 0, nothing cut by
the frame. The 938-vert clip of pass 1 does NOT survive the engine's real
carry. AND THE PICTURE SAYS THE GREEN IS NOT THE WHOLE ANSWER: at held_rot
ZERO the wand lies HORIZONTAL and ACROSS the body - a 0.55 m baton poking out
of the fist on the front view and a single blue dot at the hip on the side.
That is the S19 fault gear.gd describes in its own words ("a mesh built along
+Y lies horizontal ... the pack staff at x1.9 was a lance"), and my gate has no
term for it, so the gate cannot be the thing that catches it. My eye is.

WHAT THIS FILE MAY AND MAY NOT EXPLORE. weaponfit's `slot_matrix` will only
derive a basis for a ROLL about the slot's forward axis away from a calibrated
record; any other angle has no calibration and it refuses. So this file sweeps
exactly the family that IS derivable: held_rot (0, Y, 90), the staff's
calibrated basis rolled by Y, which is the same move gear.gd made for the
crossbow at S95 (euler (-90, 35, 90) = Ry(35) * the calibrated basis). It does
NOT invent a basis for an arbitrary euler, and it reports the roll it applied
on every row so the number can be checked against gear.gd.

RED ON EMPTY: a clip count over zero checked vertices is a FAIL, not a green.
"""
import os
import sys
import json
import argparse

import bpy
from mathutils import Vector, Matrix, bvhtree

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import minibossfit as MF     # noqa: E402
import weaponfit as WF       # noqa: E402

MODEL = os.path.join("assets", "gear", "wand_crystal.glb")
ROLLS = [-90, -75, -60, -45, -30, -15, 0, 15, 30, 45, 60, 75, 90]
SCALES = [0.62, 1.0]


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    a = ap.parse_args(argv)

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

    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=os.path.join(a.repo, MODEL))
    mesh = [o for o in bpy.data.objects if o not in before and o.type == 'MESH']
    root = [o for o in bpy.data.objects if o not in before and o.parent is None]
    assert mesh, "the wand glb imported no mesh"
    bpy.context.view_layer.update()

    rows = []
    for hs in SCALES:
        S = Matrix.Diagonal((hs,) * 3).to_4x4()
        for y in ROLLS:
            R, roll = WF.slot_matrix("staff", ("0", str(y), "90"))
            for o in root:
                o.matrix_world = base @ R @ S
            bpy.context.view_layer.update()
            wv = WF.world_verts(mesh)
            far = [p for p in wv if (p - slot).length > WF.FIST_R]
            if not far:
                rows.append(dict(held_rot=[0, y, 90], hand_scale=hs,
                                 ERROR="every vertex inside the fist sphere - "
                                       "clip taken over nothing"))
                continue
            zs = [p.z for p in wv]
            rows.append(dict(held_rot=[0, y, 90], hand_scale=hs,
                             roll_applied=round(roll, 2),
                             checked=len(far),
                             clip=sum(1 for p in far if WF.inside(trees, p)),
                             ground=sum(1 for p in wv if p.z < -0.002),
                             tip_z=round(max(zs), 3),
                             reach=round(max(zs) - slot.z, 3),
                             span_x=round(max(p.x for p in wv) - min(p.x for p in wv), 3),
                             span_y=round(max(p.y for p in wv) - min(p.y for p in wv), 3),
                             span_z=round(max(zs) - min(zs), 3)))
    out = dict(model=MODEL, handslot=[round(v, 4) for v in slot],
               hero_h=round(hinfo["h"], 3), basis="staff (0,0,90) rolled about slot +Y",
               note="ONLY the roll family is derivable from a calibrated basis; "
                    "no other euler is explored here and none is recommended "
                    "without a calibration record.",
               rows=rows)
    d = os.path.join(a.repo, "renders", "art", "wand")
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, "_roll_sweep.json"), "w") as f:
        json.dump(out, f, indent=1)
    print("WANDROLL " + json.dumps(out))


if __name__ == "__main__":
    main()
