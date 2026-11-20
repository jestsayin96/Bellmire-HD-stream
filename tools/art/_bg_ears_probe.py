# BROODGLUT ear probe - lists the rig and locates the ear geometry.
# Run: blender -b -noaudio -P this.py -- <glb> <outjson>
import bpy, sys, json, mathutils

argv = sys.argv[sys.argv.index("--")+1:]
GLB, OUT = argv[0], argv[1]

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=GLB)

arm = next((o for o in bpy.data.objects if o.type == 'ARMATURE'), None)
body = bpy.data.objects.get("Puglin_Body")

out = {"glb": GLB, "bones": [], "ear_bones": [], "body": None}

if arm:
    for b in arm.data.bones:
        h = arm.matrix_world @ b.head_local
        t = arm.matrix_world @ b.tail_local
        out["bones"].append({
            "name": b.name,
            "head": [round(v, 4) for v in h],
            "tail": [round(v, 4) for v in t],
            "len": round(b.length, 4),
            "parent": b.parent.name if b.parent else None,
        })
    out["ear_bones"] = [b.name for b in arm.data.bones
                        if any(k in b.name.lower() for k in ("ear", "oreille"))]

if body:
    mw = body.matrix_world
    cos = [mw @ v.co for v in body.data.vertices]
    xs = [c.x for c in cos]; ys = [c.y for c in cos]; zs = [c.z for c in cos]
    out["body"] = {
        "verts": len(cos),
        "bounds_min": [round(min(xs), 4), round(min(ys), 4), round(min(zs), 4)],
        "bounds_max": [round(max(xs), 4), round(max(ys), 4), round(max(zs), 4)],
        "groups": sorted(g.name for g in body.vertex_groups),
    }
    # per-group weighted vertex count + weighted centroid, to find the ears by mass
    gi = {g.index: g.name for g in body.vertex_groups}
    acc = {}
    for v in body.data.vertices:
        for ge in v.groups:
            if ge.weight < 0.5:
                continue
            n = gi.get(ge.group)
            if n is None:
                continue
            a = acc.setdefault(n, {"n": 0, "sx": 0.0, "sy": 0.0, "sz": 0.0})
            c = mw @ v.co
            a["n"] += 1; a["sx"] += c.x; a["sy"] += c.y; a["sz"] += c.z
    out["group_mass"] = sorted(
        [{"g": k, "n": a["n"],
          "centroid": [round(a["sx"]/a["n"], 4), round(a["sy"]/a["n"], 4), round(a["sz"]/a["n"], 4)]}
         for k, a in acc.items()],
        key=lambda d: -d["n"])

with open(OUT, "w", encoding="utf-8") as f:
    json.dump(out, f, indent=1)
print("WROTE", OUT)
