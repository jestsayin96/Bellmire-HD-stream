"""_s2_xbow_probe2 - the two anchors the stirrup/bowstring route needs, measured.

  (1) the prod's shape: y and z as a function of x, so the string's anchors are
      the LATH TIPS and not a guess, and so a forward sweep (if any) is known.
  (2) the stock's underside at the nose: where a stirrup can hang from without
      starting inside the stock, and whether anything is already down there.
"""
import bpy, sys, os, json
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
repo = argv[argv.index("--repo") + 1] if "--repo" in argv else "."
out = {}
for tier in ("common", "uncommon", "rare"):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=os.path.join(repo, "assets", "gear", "dungeon",
                                                    "crossbow_%s.glb" % tier))
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    pts, per_mat = [], {}
    for o in meshes:
        mw = o.matrix_world
        mats = [m.name if m else "none" for m in o.data.materials] or ["none"]
        for po in o.data.polygons:
            mn = mats[min(po.material_index, len(mats) - 1)]
            for vi in po.vertices:
                p = mw @ o.data.vertices[vi].co
                per_mat.setdefault(mn, []).append(p)
        for v in o.data.vertices:
            pts.append(mw @ v.co)
    mnx = min(p.x for p in pts); mxx = max(p.x for p in pts)
    mny = min(p.y for p in pts); mxy = max(p.y for p in pts)
    mnz = min(p.z for p in pts); mxz = max(p.z for p in pts)
    rec = {}
    # prod profile: 9 slices across X
    prof = []
    for i in range(9):
        lo = mnx + (mxx - mnx) * i / 9.0
        hi = mnx + (mxx - mnx) * (i + 1) / 9.0
        q = [p for p in pts if lo <= p.x < hi]
        prof.append({"x": [round(lo, 3), round(hi, 3)], "n": len(q),
                     "y": [round(min(p.y for p in q), 3), round(max(p.y for p in q), 3)] if q else None,
                     "z": [round(min(p.z for p in q), 3), round(max(p.z for p in q), 3)] if q else None})
    rec["prod_profile_x"] = prof
    # centre column (the stock): y profile in 8 slices, with z extent
    col = []
    for i in range(8):
        lo = mny + (mxy - mny) * i / 8.0
        hi = mny + (mxy - mny) * (i + 1) / 8.0
        q = [p for p in pts if lo <= p.y < hi and abs(p.x) < 0.06]
        col.append({"y": [round(lo, 3), round(hi, 3)], "n": len(q),
                    "z": [round(min(p.z for p in q), 3), round(max(p.z for p in q), 3)] if q else None,
                    "x_abs_max": round(max(abs(p.x) for p in q), 3) if q else None})
    rec["stock_column_y"] = col
    # material split by bbox, so the stirrup can take the tier's own metal
    rec["materials"] = {k: {"n": len(v),
                            "y": [round(min(p.y for p in v), 3), round(max(p.y for p in v), 3)],
                            "z": [round(min(p.z for p in v), 3), round(max(p.z for p in v), 3)],
                            "x_abs_max": round(max(abs(p.x) for p in v), 3)}
                        for k, v in per_mat.items()}
    rec["bbox"] = {"x": [round(mnx, 4), round(mxx, 4)], "y": [round(mny, 4), round(mxy, 4)],
                   "z": [round(mnz, 4), round(mxz, 4)]}
    out[tier] = rec
print("PROBE2 " + json.dumps(out))
