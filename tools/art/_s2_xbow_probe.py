"""_s2_xbow_probe - measure the three shipped crossbows in their OWN local frame.

Asks only what the stirrup/bowstring route needs to know before any geometry
is authored:
  * local dims, and WHICH axis is the `show` denominator (the MIDDLE extent),
    because a stirrup that pushes the middle extent up would pay for its own
    pass the way camber did.
  * where the prod tips are (bowstring anchors) and where the stock's front
    face is (stirrup anchor).
  * whether a string or stirrup is already there - the prompt's first rule.

  blender -b -noaudio -P tools/art/_s2_xbow_probe.py -- --repo <repo>
"""
import bpy, sys, os, json
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
repo = argv[argv.index("--repo") + 1] if "--repo" in argv else "."

TIERS = ("common", "uncommon", "rare")
out = {}

for tier in TIERS:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    p = os.path.join(repo, "assets", "gear", "dungeon", "crossbow_%s.glb" % tier)
    bpy.ops.import_scene.gltf(filepath=p)
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    rec = {"file": os.path.basename(p), "objects": len(meshes),
           "names": [o.name for o in meshes]}
    # verts in the importer's world frame, which is the frame weaponfit measures
    pts, tris, mats = [], 0, set()
    for o in meshes:
        mw = o.matrix_world
        for v in o.data.vertices:
            pts.append(mw @ v.co)
        tris += len(o.data.polygons)
        for m in o.data.materials:
            if m:
                mats.add(m.name)
    rec["verts"] = len(pts)
    rec["faces"] = tris
    rec["materials"] = sorted(mats)
    mn = Vector((min(p2.x for p2 in pts), min(p2.y for p2 in pts), min(p2.z for p2 in pts)))
    mx = Vector((max(p2.x for p2 in pts), max(p2.y for p2 in pts), max(p2.z for p2 in pts)))
    dim = mx - mn
    rec["min"] = [round(c, 4) for c in mn]
    rec["max"] = [round(c, 4) for c in mx]
    rec["dim"] = [round(c, 4) for c in dim]
    order = sorted(range(3), key=lambda i: dim[i])
    rec["axis_min"], rec["axis_mid"], rec["axis_max"] = ("XYZ"[order[0]], "XYZ"[order[1]], "XYZ"[order[2]])
    rec["mid_extent"] = round(dim[order[1]], 4)
    rec["min_extent"] = round(dim[order[0]], 4)
    rec["headroom_before_mid_changes"] = round(dim[order[1]] - dim[order[0]], 4)

    # prod tips: extreme X slabs (prod is symmetric on X per the 14:4x probe)
    xs = sorted(p2.x for p2 in pts)
    def slab(sel):
        q = [p2 for p2 in pts if sel(p2)]
        return {"n": len(q),
                "y": [round(min(a.y for a in q), 4), round(max(a.y for a in q), 4)],
                "z": [round(min(a.z for a in q), 4), round(max(a.z for a in q), 4)]}
    rec["tip_xpos"] = slab(lambda a: a.x > mx.x - 0.02)
    rec["tip_xneg"] = slab(lambda a: a.x < mn.x + 0.02)
    # stock front / rear along Y
    rec["front_yslab"] = slab(lambda a: a.y > mx.y - 0.02)
    rec["rear_yslab"] = slab(lambda a: a.y < mn.y + 0.02)
    # is anything already spanning the prod tips at mid-X (a string would be)
    span = [p2 for p2 in pts if abs(p2.x) < 0.02 and p2.y > mx.y - 0.12]
    rec["midx_front_pts"] = len(span)
    out[tier] = rec

print("PROBE " + json.dumps(out))
