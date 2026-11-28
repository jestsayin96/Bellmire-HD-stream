"""_hallprobe - WHAT IS ALREADY ON DISK FOR THE HALL. Measure, do not remember.

  blender -b -noaudio -P tools/art/_hallprobe.py -- --repo <repo>

Asks of lm_hall.glb (and its siblings) the only questions that matter before
authoring a tier ladder: how BIG is it against the measured 2.45 m KayKit
figure, how many meshes/materials does it carry, and could it stand as one of
the three tiers rather than being rebuilt.
"""
import argparse, json, os, sys
import bpy
from mathutils import Vector

W5 = r"C:\hd adventure\bellmire-art"


def purge():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def bounds(objs):
    pts = []
    for o in objs:
        for c in o.bound_box:
            pts.append(o.matrix_world @ Vector(c))
    if not pts:
        return None, None, []
    mn = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    mx = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    return mn, mx, pts


def probe(path):
    purge()
    bpy.ops.import_scene.gltf(filepath=path)
    bpy.context.view_layer.update()
    meshes = [o for o in bpy.data.objects if o.type == 'MESH']
    mn, mx, _ = bounds(meshes)
    mats = sorted({m.name for o in meshes for m in o.data.materials if m})
    return {
        "file": os.path.basename(path),
        "bytes": os.path.getsize(path),
        "n_mesh": len(meshes),
        "mesh_names": sorted(o.name for o in meshes)[:24],
        "n_vert": sum(len(o.data.vertices) for o in meshes),
        "n_tri": sum(len(o.data.polygons) for o in meshes),
        "dims": [round(v, 4) for v in (mx.x - mn.x, mx.y - mn.y, mx.z - mn.z)] if mn else None,
        "min_z": round(mn.z, 4) if mn else None,
        "n_mat": len(mats),
        "materials": mats[:24],
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", default=W5)
    a = ap.parse_args(sys.argv[sys.argv.index("--") + 1:])
    bd = os.path.join(a.repo, "assets", "buildings")
    out = {"probed": []}
    for name in ("lm_hall.glb", "lm_barracks.glb", "lm_chapel.glb"):
        p = os.path.join(bd, name)
        if os.path.isfile(p):
            try:
                out["probed"].append(probe(p))
            except Exception as e:
                out["probed"].append({"file": name, "error": repr(e)[:300]})
    dest = os.path.join(a.repo, "renders", "art", "town", "_probe", "_hall_existing.json")
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    with open(dest, "w") as f:
        json.dump(out, f, indent=1)
    print("HALLPROBE " + json.dumps(out))


main()
