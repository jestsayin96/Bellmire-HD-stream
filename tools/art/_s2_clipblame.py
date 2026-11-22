"""Which PART is inside the hero? The register says clip rose 40->64 on every
tier - exactly +24 of the 116 verts the stirrup/string/bolt add - and "+24
somewhere" is not a fault report. This carries the augmented mesh exactly as
weaponfit does and prints every intruding vertex IN THE MESH'S OWN LOCAL
FRAME, bucketed by the part its coordinates place it in."""
import os, sys, json
import bpy
from mathutils import Matrix, Vector
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lordgen as G          # noqa: E402
import minibossfit as MF     # noqa: E402
import weaponfit as W        # noqa: E402
from mathutils import bvhtree  # noqa: E402

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
repo = argv[argv.index("--repo") + 1]
gear = argv[argv.index("--gear") + 1]
roll = float(argv[argv.index("--roll") + 1]) if "--roll" in argv else 0.0

for o in list(bpy.data.objects):
    bpy.data.objects.remove(o, do_unlink=True)
roots, body, hinfo = MF.import_hero(repo)
rig = next(o for o in roots if o.type == 'ARMATURE')
bpy.context.view_layer.update()
OVR = W.gear_overrides(gear)
hs = OVR["crossbow"]["scale"]
base = rig.matrix_world @ rig.pose.bones["handslot.r"].matrix
slot = base @ Vector((0, 0, 0))
dg = bpy.context.evaluated_depsgraph_get()
trees = [bvhtree.BVHTree.FromObject(o, dg) for o in body]
assert trees, "no body BVH - the clip test would be empty"

out = {}
for tier in ("common", "uncommon", "rare"):
    objs, path = W.load_model(repo, "crossbow", tier)
    meshes = [o for o in objs if o.type == 'MESH']
    local = [(o, [v.co.copy() for v in o.data.vertices]) for o in meshes]
    Rslot = W.slot_matrix("crossbow")
    import math
    Rroll = Matrix.Rotation(math.radians(roll), 4, 'Y')
    S = Matrix.Diagonal((hs,) * 3).to_4x4()
    for o in objs:
        if o.parent is None:
            o.matrix_world = base @ Rroll @ Rslot @ S @ o.matrix_world
    bpy.context.view_layer.update()
    buckets = {}
    pts = []
    for o, lv in local:
        mw = o.matrix_world
        for co in lv:
            wv = mw @ co
            if (wv - slot).length <= W.FIST_R:
                continue
            if W.inside(trees, wv):
                pts.append(co.copy())
    # bucket in the IMPORTER frame the parts were authored in
    rec = {"n_inside": len(pts), "roll": roll,
           "local_xyz": [[round(c, 3) for c in p] for p in pts[:40]]}
    out[tier] = rec
    for o in objs:
        bpy.data.objects.remove(o, do_unlink=True)
print("CLIPBLAME " + json.dumps(out))
