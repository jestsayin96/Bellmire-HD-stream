"""_mv_probe.py - PART 2 of the 21:50 directive, step 0: MEASURE the candidate
pack creature before deciding anything. Run headless:
  blender -b -noaudio -P tools/art/_mv_probe.py -- <glb> <outjson>
Reports objects, armature, materials, image refs, world-space bounds and tris.
Bounds are taken off the EVALUATED depsgraph after making the scene active, so
trap 3 (an inactive scene never evaluates matrix_world) cannot bite.
"""
import bpy, sys, os, json

argv = sys.argv[sys.argv.index("--") + 1:]
glb, outp = argv[0], argv[1]

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=glb)

dg = bpy.context.evaluated_depsgraph_get()
rep = {"glb": glb, "objects": [], "materials": [], "images": []}
lo = [1e9]*3; hi = [-1e9]*3
tris = 0
SKIP = set(x for x in os.environ.get("MV_SKIP","").split(",") if x)
for o in bpy.data.objects:
    if o.name in SKIP:
        rep.setdefault("skipped", []).append(o.name)
        continue
    ent = {"name": o.name, "type": o.type, "parent": o.parent.name if o.parent else None}
    if o.type == "MESH":
        ev = o.evaluated_get(dg)
        me = ev.to_mesh()
        me.calc_loop_triangles()
        tris += len(me.loop_triangles)
        mw = ev.matrix_world
        for v in me.vertices:
            w = mw @ v.co
            for i in range(3):
                lo[i] = min(lo[i], w[i]); hi[i] = max(hi[i], w[i])
        ent["verts"] = len(me.vertices)
        ent["mats"] = [m.name if m else None for m in o.data.materials]
        ev.to_mesh_clear()
    if o.type == "ARMATURE":
        ent["bones"] = len(o.data.bones)
        ent["bone_names"] = [b.name for b in o.data.bones][:12]
    rep["objects"].append(ent)
rep["bounds_lo"] = [round(v, 5) for v in lo]
rep["bounds_hi"] = [round(v, 5) for v in hi]
rep["size"] = [round(hi[i]-lo[i], 5) for i in range(3)]
rep["tris"] = tris
rep["n_actions"] = len(bpy.data.actions)
rep["actions"] = [a.name for a in bpy.data.actions][:10]
for m in bpy.data.materials:
    e = {"name": m.name, "nodes": []}
    if m.use_nodes:
        for n in m.node_tree.nodes:
            if n.type == "TEX_IMAGE":
                e["nodes"].append({"img": n.image.name if n.image else None,
                                   "src": (n.image.filepath if n.image else None),
                                   "to": [l.to_socket.name for l in n.outputs[0].links]})
    rep["materials"].append(e)
for im in bpy.data.images:
    rep["images"].append({"name": im.name, "size": list(im.size), "filepath": im.filepath, "packed": bool(im.packed_file)})
with open(outp, "w") as f:
    json.dump(rep, f, indent=1)
print("MV_PROBE_OK", outp)
