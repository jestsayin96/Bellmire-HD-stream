
import json, os, sys
import bpy
from mathutils import Vector
PACK = r"C:\hd adventure\_packs\Medieval_Village_MegaKit\Medieval Village MegaKit[Standard]\glTF"
W5 = r"C:\hd adventure\bellmire-art"
PICK = ["Wall_Plaster_Straight","Wall_Plaster_Door_Round","Wall_UnevenBrick_Straight",
        "Wall_Plaster_Window_Wide_Round","Floor_Brick","Floor_WoodDark",
        "Roof_Wooden_2x1","Roof_RoundTiles_6x8","Roof_RoundTiles_4x6",
        "Roof_Tower_RoundTiles","Roof_Front_Brick6","Stairs_Exterior_Straight",
        "Prop_Chimney","Prop_Support","Corner_Exterior_Brick","Door_1_Round",
        "Window_Wide_Round1","Prop_WoodenFence_Single","Prop_MetalFence_Ornament",
        "Roof_Modular_RoundTiles"]
out = []
for n in PICK:
    p = os.path.join(PACK, n + ".gltf")
    if not os.path.isfile(p):
        out.append({"name": n, "error": "missing"}); continue
    bpy.ops.wm.read_factory_settings(use_empty=True)
    try:
        bpy.ops.import_scene.gltf(filepath=p)
    except Exception as e:
        out.append({"name": n, "error": repr(e)[:200]}); continue
    bpy.context.view_layer.update()
    ms = [o for o in bpy.data.objects if o.type == 'MESH']
    pts = [o.matrix_world @ Vector(c) for o in ms for c in o.bound_box]
    if not pts:
        out.append({"name": n, "error": "no geom"}); continue
    mn = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    mx = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    mats = sorted({m.name for o in ms for m in o.data.materials if m})
    imgs = sorted({i.name for i in bpy.data.images if i.name != 'Render Result'})
    out.append({"name": n, "n_mesh": len(ms),
                "n_tri": sum(len(o.data.polygons) for o in ms),
                "dims": [round(v,4) for v in (mx.x-mn.x, mx.y-mn.y, mx.z-mn.z)],
                "min": [round(mn.x,4), round(mn.y,4), round(mn.z,4)],
                "mats": mats, "images": imgs})
dest = os.path.join(W5, "renders", "art", "town", "_probe", "_megakit_modules.json")
os.makedirs(os.path.dirname(dest), exist_ok=True)
json.dump(out, open(dest,"w"), indent=1)
print("MODPROBE OK")
