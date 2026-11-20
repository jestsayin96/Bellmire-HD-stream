# Measure the BROODGLUT head/ear geometry so the droop is derived, not guessed.
# Run: blender -b -noaudio -P this.py -- <glb> <outjson>
import bpy, sys, json

argv = sys.argv[sys.argv.index("--")+1:]
GLB, OUT = argv[0], argv[1]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=GLB)

body = bpy.data.objects["Puglin_Body"]
mw = body.matrix_world
gi = {g.name: g.index for g in body.vertex_groups}
head_i = gi["Head"]

def dom(v):
    """Name of the group with the greatest weight on this vertex."""
    best, bw = None, -1.0
    for ge in v.groups:
        if ge.weight > bw:
            bw, best = ge.weight, ge.group
    return best

rows = []
for v in body.data.vertices:
    c = mw @ v.co
    rows.append((dom(v), c.x, c.y, c.z))

out = {}
# per-dominant-group x extent, to see which group owns the widest geometry
per = {}
for g, x, y, z in rows:
    a = per.setdefault(g, {"n": 0, "xmax": -9, "xmin": 9, "zmin": 9, "zmax": -9})
    a["n"] += 1
    a["xmax"] = max(a["xmax"], x); a["xmin"] = min(a["xmin"], x)
    a["zmin"] = min(a["zmin"], z); a["zmax"] = max(a["zmax"], z)
inv = {i: n for n, i in gi.items()}
out["per_group"] = sorted(
    [{"g": inv.get(k, str(k)), **{kk: (round(vv, 4) if isinstance(vv, float) else vv)
                                  for kk, vv in a.items()}} for k, a in per.items()],
    key=lambda d: -d["xmax"])[:12]

# Head-dominant verts only: x histogram, and z-extent per x slice.
head = [(x, y, z) for g, x, y, z in rows if g == head_i]
out["head_verts"] = len(head)
hist = []
for i in range(0, 16):
    lo, hi = i * 0.05, (i + 1) * 0.05
    sl = [(x, y, z) for x, y, z in head if lo <= abs(x) < hi]
    if sl:
        hist.append({"x": [round(lo, 3), round(hi, 3)], "n": len(sl),
                     "z": [round(min(s[2] for s in sl), 4), round(max(s[2] for s in sl), 4)],
                     "y": [round(min(s[1] for s in sl), 4), round(max(s[1] for s in sl), 4)]})
out["head_x_hist"] = hist
out["head_xmax"] = round(max(abs(x) for x, y, z in head), 4)
with open(OUT, "w", encoding="utf-8") as f:
    json.dump(out, f, indent=1)
print("WROTE", OUT)
