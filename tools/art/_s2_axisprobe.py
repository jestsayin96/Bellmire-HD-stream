"""_s2_axisprobe - MEASURE, do not guess: the handslot frame in Blender world axes,
and each DUN weapon mesh's own local bbox axes. Nothing is written to the register.
Run: blender -b -noaudio -P tools/art/_s2_axisprobe.py -- --repo <repo>
"""
import sys, os, json, argparse
import bpy
from mathutils import Vector
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import minibossfit as MF          # noqa: E402
import weaponfit as WF            # noqa: E402

ap = argparse.ArgumentParser()
ap.add_argument("--repo", required=True)
a = ap.parse_args(sys.argv[sys.argv.index("--") + 1:])

roots, body, hinfo = MF.import_hero(a.repo)
rig = next(o for o in roots if o.type == 'ARMATURE')
bpy.context.view_layer.update()
pb = rig.pose.bones["handslot.r"]
base = rig.matrix_world @ pb.matrix
R = base.to_3x3()
out = {"slot_origin": [round(v, 4) for v in (base @ Vector((0, 0, 0)))],
       "slot_axes_world": {ax: [round(v, 4) for v in (R @ Vector(u)).normalized()]
                           for ax, u in (("+X", (1, 0, 0)), ("+Y", (0, 1, 0)), ("+Z", (0, 0, 1)))},
       "hero_h": hinfo["h"], "meshes": {}}

for fam in ("crossbow", "staff", "sword"):
    objs, path = WF.load_model(a.repo, fam, "common")
    ms = [o for o in objs if o.type == 'MESH']
    pts = []
    for o in ms:
        for c in o.bound_box:
            pts.append(o.matrix_world @ Vector(c))
    if pts:
        mn = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
        mx = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
        d = mx - mn
        out["meshes"][fam] = {"file": os.path.basename(path),
                              "min": [round(v, 3) for v in mn], "max": [round(v, 3) for v in mx],
                              "dim": [round(v, 3) for v in d],
                              "long_axis": "XYZ"[max(range(3), key=lambda i: d[i])]}
    for o in objs:
        bpy.data.objects.remove(o, do_unlink=True)

print("AXISPROBE " + json.dumps(out))
