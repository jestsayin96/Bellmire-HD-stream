"""Measure the Leech's T-pose span_x / span_y - asked for by the game build's
S58 row (05:58 CT 20 Nov): bestiary.gd:127-128 carries no "span" key, so the
third bestiary-carried miniboss is exempt from the corridor check entirely.
The row said: get it MEASURED into the register, do not invent one.

Same instrument as the variants' span_x: lordgen.world_bounds (evaluated
depsgraph), scaled so z-height equals the SHIPPED creature_h, span taken off
the world AABB.  Nothing is hard-coded but the shipped height, and that is read
from the register, not typed.
"""
import json
import os
import sys

import bpy

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))  # tools/art -> repo root
sys.path.insert(0, HERE)
import lordgen as G  # noqa: E402
import floorgeom as FG  # noqa: E402

GLB = os.path.join(REPO, "assets", "monsters", "minibosses", "leech.glb")
REG = os.path.join(REPO, "renders", "art", "minibosses", "_fit_leech_register.json")
OUT = os.path.join(REPO, "renders", "art", "minibosses", "_leech_span.json")

# never touch an open scene - this runs -b, but be explicit
bpy.ops.wm.read_homefile(use_empty=True)

reg = json.load(open(REG, encoding="utf-8"))
shipped_h = float(reg["pairs"]["leech"]["creature_h"])

before = set(bpy.data.objects)
bpy.ops.import_scene.gltf(filepath=GLB)
new = [o for o in bpy.data.objects if o not in before]
meshes = [o for o in new if o.type == 'MESH']
roots = [o for o in new if o.parent is None]
if not meshes:
    raise RuntimeError("no meshes imported from %s - refusing to report a span" % GLB)
bpy.context.view_layer.update()

mn, mx, pts = G.world_bounds(meshes)
native_h = mx.z - mn.z
if native_h <= 1e-6:
    raise RuntimeError("native height %r - refusing to scale" % native_h)
k = shipped_h / native_h
for o in roots:
    o.scale = (o.scale.x * k, o.scale.y * k, o.scale.z * k)
    o.location = (o.location.x * k, o.location.y * k, o.location.z * k)
bpy.context.view_layer.update()
mn, mx, pts = G.world_bounds(meshes)

span_x = round(mx.x - mn.x, 4)
span_y = round(mx.y - mn.y, 4)
got_h = round(mx.z - mn.z, 4)

geom = FG.read(REPO)
v, errs = FG.verdict(geom, max(span_x, span_y), got_h)

res = {
    "key": "leech",
    "glb": os.path.relpath(GLB, REPO).replace("\\", "/"),
    "meshes": sorted(o.name for o in meshes),
    "verts": len(pts),
    "native_h": round(native_h, 5),
    "scale_k": round(k, 5),
    "shipped_creature_h": shipped_h,
    "measured_h": got_h,
    "span_x": span_x,
    "span_y": span_y,
    "span_used": max(span_x, span_y),
    "floorgeom": {
        "corridor_clear_m": geom["corridor_clear_m"],
        "lid_underside_m": geom["lid_underside_m"],
        "lid_y_m": geom["lid_y_m"],
        "read_from": geom["at"],
        "errors": geom["errors"],
    },
    "verdict": {k2: v[k2] for k2 in ("corridor", "corridor_margin_m", "lid", "lid_clear_m", "fits")},
    "verdict_errors": errs,
}
json.dump(res, open(OUT, "w", encoding="utf-8"), indent=1, sort_keys=True)
print("LEECH_SPAN " + json.dumps(res["verdict"]))
print("LEECH_SPAN span_x=%s span_y=%s h=%s (native %s, k %s)"
      % (span_x, span_y, got_h, round(native_h, 5), round(k, 5)))
