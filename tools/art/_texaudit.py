
import json, os
import bpy
W5 = r"C:\hd adventure\bellmire-art"
bd = os.path.join(W5, "assets", "buildings")
rows = {}
for n in sorted(f for f in os.listdir(bd) if f.endswith(".glb")):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    try:
        bpy.ops.import_scene.gltf(filepath=os.path.join(bd, n))
    except Exception as e:
        rows[n] = {"error": repr(e)[:160]}; continue
    imgs = [i for i in bpy.data.images if i.name != 'Render Result']
    linked = 0; total = 0
    for m in bpy.data.materials:
        if not m.use_nodes: continue
        b = next((x for x in m.node_tree.nodes if x.type == 'BSDF_PRINCIPLED'), None)
        if b is None: continue
        total += 1
        if b.inputs['Base Color'].is_linked: linked += 1
    ms = [o for o in bpy.data.objects if o.type == 'MESH']
    rows[n] = {"n_images": len(imgs), "n_mat": total, "base_linked": linked,
               "n_mesh": len(ms), "n_tri": sum(len(o.data.polygons) for o in ms),
               "TEXTURED": linked > 0 and len(imgs) > 0}
dest = os.path.join(W5, "renders", "art", "town", "_probe", "_texaudit.json")
json.dump(rows, open(dest, "w"), indent=1)
print("TEXAUDIT " + json.dumps(rows))
