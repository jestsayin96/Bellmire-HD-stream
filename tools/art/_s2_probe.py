"""_s2_probe - measure the hero's hands and every dungeon-pack weapon model.

Nothing is rendered here. This answers the two questions a fit pass cannot
guess: WHERE the posed fist is, and HOW BIG each bought model is in its own
axes - because the pack is authored at a scale that has nothing to do with the
body and a model dropped in raw is either a toothpick or a telegraph pole.
"""
import os, sys, json, argparse
import bpy
from mathutils import Vector

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lordgen as G          # noqa: E402
import minibossfit as MF     # noqa: E402

FAMS = ["sword", "axe", "hammer", "dagger", "staff", "crossbow", "axeDouble", "shield"]
TIERS = ["common", "uncommon", "rare"]


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--out", required=True)
    a = ap.parse_args(argv)

    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)

    roots, meshes, info = MF.import_hero(a.repo)
    rig = next((o for o in roots if o.type == 'ARMATURE'), None)
    bones = {}
    if rig is not None:
        bpy.context.view_layer.update()
        for pb in rig.pose.bones:
            h = rig.matrix_world @ pb.matrix @ Vector((0, 0, 0))
            bones[pb.name] = [round(v, 4) for v in h]

    models = {}
    for fam in FAMS:
        for t in TIERS:
            p = os.path.join(a.repo, "assets", "gear", "dungeon", "%s_%s.glb" % (fam, t))
            if not os.path.isfile(p):
                models["%s_%s" % (fam, t)] = {"missing": True}
                continue
            before = set(bpy.data.objects)
            bpy.ops.import_scene.gltf(filepath=p)
            new = [o for o in bpy.data.objects if o not in before]
            ms = [o for o in new if o.type == 'MESH']
            bpy.context.view_layer.update()
            mn, mx, _ = G.world_bounds(ms)
            models["%s_%s" % (fam, t)] = dict(
                meshes=[o.name for o in ms],
                mn=[round(v, 4) for v in mn], mx=[round(v, 4) for v in mx],
                size=[round(mx.x - mn.x, 4), round(mx.y - mn.y, 4), round(mx.z - mn.z, 4)],
                mats=sorted({m.name for o in ms for m in o.data.materials if m}),
            )
            for o in new:
                bpy.data.objects.remove(o, do_unlink=True)

    out = dict(hero=info, bones=bones, models=models)
    with open(a.out, "w") as f:
        json.dump(out, f, indent=1)
    print("PROBE_OK", a.out)


main()
