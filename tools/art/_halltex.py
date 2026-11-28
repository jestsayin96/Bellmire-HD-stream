
import json, os
import bpy
W5 = r"C:\hd adventure\bellmire-art"
PACK = r"C:\hd adventure\_packs\Medieval_Village_MegaKit\Medieval Village MegaKit[Standard]\glTF"
out = {}
def inspect(path, label):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=path)
    imgs = [{"name": i.name, "size": list(i.size), "packed": bool(i.packed_file),
             "filepath": i.filepath, "has_data": bool(i.has_data)}
            for i in bpy.data.images if i.name != 'Render Result']
    mats = []
    for m in bpy.data.materials:
        if not m.use_nodes:
            mats.append({"m": m.name, "nodes": False}); continue
        bsdf = next((n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED'), None)
        if bsdf is None:
            mats.append({"m": m.name, "bsdf": False}); continue
        bc = bsdf.inputs['Base Color']
        mats.append({"m": m.name,
                     "base_linked": bool(bc.is_linked),
                     "base_rgba": [round(v,3) for v in bc.default_value],
                     "link_from": bc.links[0].from_node.type if bc.is_linked else None})
    out[label] = {"n_images": len(imgs), "images": imgs[:6], "n_mat": len(mats), "mats": mats[:8]}
inspect(os.path.join(W5,"assets","buildings","lm_hall.glb"), "lm_hall_glb")
inspect(os.path.join(PACK,"Wall_Plaster_Straight.gltf"), "pack_wall_gltf")
dest = os.path.join(W5,"renders","art","town","_probe","_texcheck.json")
json.dump(out, open(dest,"w"), indent=1)
print("TEXCHECK " + json.dumps(out)[:4000])
