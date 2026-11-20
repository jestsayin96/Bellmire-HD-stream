"""Measure the Leech's T-pose span_x / span_y - asked for by the game build's
S58 row (05:58 CT 20 Nov): bestiary.gd:127-128 carries no "span" key, so the
third bestiary-carried miniboss is exempt from the corridor check entirely.
The row said: get it MEASURED into the register, do not invent one.

*** 07:5x CT 20 NOV: THE FLOORGEOM BLOCK THIS FILE PUBLISHES NOW CARRIES ITS
TREE, AND REFUSES TO BE WRITTEN OUT OF A STALE ONE. ***
The first version of this file published `lid_y_m 7.0 / lid_underside_m 6.5`
with `errors: []` beside it.  Both were true of W5 (pre-S56) and FALSE of the
dungeon that ships - origin/main has carried 10.0 since S56.  Nothing in the
JSON said which tree it was, so the number could be quoted straight into a
wrong gate.  floorgeom.require_current() now refuses the write unless the
parsed floorgen.gd agrees with origin/main's, term by term, and the stamp
(tree, branch, file sha, ref commit, lid line verbatim) goes INTO the file.
Point it at the tree that ships with FLOORGEOM_TREE; the creature's own GLB and
register are still read from this worktree, because those are art's.
Set FLOORGEOM_ALLOW_STALE=1 to flag instead of refuse - and then the file says
`floorgeom_stale: true` in its own body, loudly, where a reader cannot miss it.

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

GEOM_TREE = os.environ.get("FLOORGEOM_TREE") or REPO
ALLOW_STALE = os.environ.get("FLOORGEOM_ALLOW_STALE") == "1"
geom = FG.read(GEOM_TREE)
try:
    prov = FG.require_current(geom, allow_stale=ALLOW_STALE)   # raises on drift
except FG.StaleTreeError as e:
    # *** BLENDER -P SWALLOWS AN EXCEPTION AND STILL EXITS 0. ***
    # Measured 07:41 CT: the refusal below fired, wrote nothing, and the process
    # returned rc 0 - a caller reading rc would have scored the refusal a pass.
    # os._exit is used because Blender also catches SystemExit.
    sys.stderr.write("LEECH_SPAN REFUSED - %s\n" % e)
    sys.stderr.flush()
    sys.stdout.write("LEECH_SPAN REFUSED (nothing written)\n")
    sys.stdout.flush()
    os._exit(3)
print("LEECH_SPAN " + FG.stamp(geom))
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
        # THE STAMP.  Without these a number in this file cannot be told apart
        # from the same number read out of a tree that does not ship.
        "read_from_tree": prov["repo"],
        "read_from_branch": prov["branch"],
        "read_from_head": prov["head"],
        "gd_sha256_8": prov["gd_sha256_8"],
        "gd_lid_line": prov["gd_lid_line"],
        "ref": prov["ref"],
        "ref_commit": prov["ref_commit"],
        "ref_gd_sha256_8": prov["ref_gd_sha256_8"],
        "verified_against_ref": prov["verified"],
        "matches_ref": prov["matches_ref"],
        "drift": prov["drift"],
        "provenance_notes": prov["notes"],
        "stamp": FG.stamp(geom),
    },
    "floorgeom_stale": bool(prov["drift"]) or not prov["verified"],
    "verdict": {k2: v[k2] for k2 in ("corridor", "corridor_margin_m", "lid", "lid_clear_m", "fits")},
    "verdict_errors": errs,
}
json.dump(res, open(OUT, "w", encoding="utf-8"), indent=1, sort_keys=True)
print("LEECH_SPAN " + json.dumps(res["verdict"]))
print("LEECH_SPAN span_x=%s span_y=%s h=%s (native %s, k %s)"
      % (span_x, span_y, got_h, round(native_h, 5), round(k, 5)))
