"""Measure, for every shipped weapon cell, the world-space AABB of the carried
mesh and the MIDDLE of its three extents - the width of the broadest face the
weapon has to offer a camera. No renders; this exists only to set the `show`
threshold off data instead of off a guess."""
import json, os, sys
import bpy
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import minibossfit as MF      # noqa: E402
import weaponfit as W         # noqa: E402
from mathutils import Matrix

repo = sys.argv[sys.argv.index("--") + 1]
for o in list(bpy.data.objects):
    bpy.data.objects.remove(o, do_unlink=True)
roots, body, hinfo = MF.import_hero(repo)
rig = next(o for o in roots if o.type == 'ARMATURE')
bpy.context.view_layer.update()
gear = os.path.join(os.path.dirname(os.path.abspath(repo)), "jests-hd-medieval-adventure", "scripts", "gear.gd")
OVR = W.gear_overrides(gear)
base = rig.matrix_world @ rig.pose.bones["handslot.r"].matrix
PXM = W.CELL_Y / W.FRAME_H
out = {}
for fam in W.FAMS:
    for tier in W.TIERS:
        key = "%s_%s" % (fam, tier)
        objs, path = W.load_model(repo, fam, tier)
        meshes = [o for o in objs if o.type == 'MESH']
        if not meshes:
            out[key] = None
            continue
        hs = OVR[fam]["scale"] if fam in OVR else W.HAND_SCALE
        R = W.slot_matrix(fam) if fam in W.SLOT_ROT else Matrix.Identity(4)
        for o in objs:
            if o.parent is None:
                o.matrix_world = base @ R @ Matrix.Diagonal((hs,) * 3).to_4x4() @ o.matrix_world
        bpy.context.view_layer.update()
        wv = W.world_verts(meshes)
        ext = sorted([max(v[i] for v in wv) - min(v[i] for v in wv) for i in range(3)])
        out[key] = dict(ext=[round(e, 4) for e in ext], mid_px=round(ext[1] * PXM, 1),
                        hand_scale=hs)
        for o in objs:
            bpy.data.objects.remove(o, do_unlink=True)
p = os.path.join(repo, "renders", "art", "system2", "_mid.json")
json.dump(dict(px_per_m=PXM, cells=out), open(p, "w"), indent=1)
print("S2_MID_DONE", p)
